import ArgumentParser
import AsyncAlgorithms
import Foundation
import Hummingbird
import HummingbirdWebSocket
import Logging
import ServiceLifecycle

typealias OutputStream = AsyncChannel<WebSocketOutboundWriter.OutboundFrame>

actor OutboundConnections {
    var outboundWriters: [UUID: OutputStream]
    
    init() {
        self.outboundWriters = [:]
    }
    
    func send(_ output: String) async {
        for outbound in outboundWriters.values {
            await outbound.send(.text(output))
        }
    }
    
    func add(id: UUID, outbound: OutputStream) async {
        outboundWriters[id] = outbound
    }
    
    func remove(id: UUID) async {
        outboundWriters[id] = nil
    }
    
    func isEmpty() -> Bool {
        return outboundWriters.isEmpty
    }
}

struct ConnectionManager: Service {
    let connectionStream: AsyncStream<Connection>
    let connectionContinuation: AsyncStream<Connection>.Continuation
    let logger: Logger

    init(logger: Logger) {
        let stream = AsyncStream<Connection>.makeStream()
        self.connectionStream = stream.stream
        self.connectionContinuation = stream.continuation
        self.logger = logger
    }

    func run() async {
        await withGracefulShutdownHandler {
            await withDiscardingTaskGroup { group in
                let roomManager = RoomManager(logger: logger)
                
                for await connection in connectionStream {
                    group.addTask {
                        logger.info("New connection in room: \(connection.roomCode)")
                        
                        let room = await roomManager.getOrCreateRoom(code: connection.roomCode)
                        await room.outboundConnections.add(
                            id: connection.userId,
                            outbound: connection.outbound
                        )

                        do {
                            for try await input in connection.inbound.messages(maxSize: 1_000_000) {
                                guard case .text(let text) = input else { continue }
                                
                                // Broadcast everything to everyone in the room
                                // Clients filter what they care about
                                await room.outboundConnections.send(text)
                            }
                        } catch {
                            logger.error("Connection error: \(error)")
                        }

                        await room.outboundConnections.remove(id: connection.userId)
                        await roomManager.removeEmptyRoom(code: connection.roomCode)
                        connection.outbound.finish()
                    }
                }
            }
        } onGracefulShutdown: {
            connectionContinuation.finish()
        }
    }

    func addUser(userId: UUID, roomCode: String, inbound: WebSocketInboundStream, outbound: WebSocketOutboundWriter) -> OutputStream {
        let outputStream = OutputStream()
        let connection = Connection(
            userId: userId,
            roomCode: roomCode,
            inbound: inbound,
            outbound: outputStream
        )
        connectionContinuation.yield(connection)
        return outputStream
    }
}

struct Connection {
    let userId: UUID
    let roomCode: String
    let inbound: WebSocketInboundStream
    let outbound: OutputStream
}

struct Room {
    let code: String
    let outboundConnections: OutboundConnections
    
    init(code: String) {
        self.code = code
        self.outboundConnections = OutboundConnections()
    }
}

actor RoomManager {
    private var rooms: [String: Room] = [:]
    private let logger: Logger
    
    init(logger: Logger) {
        self.logger = logger
    }
    
    func getOrCreateRoom(code: String) -> Room {
        let normalizedCode = code.uppercased()
        if let room = rooms[normalizedCode] {
            return room
        }
        
        let newRoom = Room(code: normalizedCode)
        rooms[normalizedCode] = newRoom
        logger.info("Created room: \(normalizedCode)")
        return newRoom
    }
    
    func removeEmptyRoom(code: String) async {
        let normalizedCode = code.uppercased()
        guard let room = rooms[normalizedCode] else { return }
        
        if await room.outboundConnections.isEmpty() {
            rooms.removeValue(forKey: normalizedCode)
            logger.info("Removed empty room: \(normalizedCode)")
        }
    }
}
