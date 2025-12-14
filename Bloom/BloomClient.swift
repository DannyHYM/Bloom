import Foundation
import SwiftUI
import OSLog

class BloomClient {
    private let socketConnection: URLSessionWebSocketTask
    private let stream: SocketStream
    private var receivingTask: Task<Void, Error>?
    private var pingTimer: Timer?
    
    // Public message handler
    var onMessage: ((BloomMessage) -> Void)?
    var onConnectionStateChange: ((ConnectionState) -> Void)?
    
    enum ConnectionState {
        case connecting
        case connected
        case disconnected(Error?)
    }
    
    init(hostname: URL = URL("ws://127.0.0.1:8080"), userId: UUID = UUID(), roomCode: String) {
        let url = hostname
            .appending(component: "ws")
            .appending(component: "bloom")
            .appending(queryItems: [
                .init(name: "userId", value: userId.uuidString),
                .init(name: "roomCode", value: roomCode)
            ])
        
        let request = URLRequest(url: url)
        let session = URLSession(configuration: .default)
        let task = session.webSocketTask(with: request)
        
        self.socketConnection = task
        self.stream = SocketStream(task: task)
    }
    
    func connect() {
        onConnectionStateChange?(.connecting)
        stream.resume()
        stream.startReceiving()
        startMessageProcessing()
        startHeartbeat()
        
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 100_000_000)
            if socketConnection.state == .running {
                onConnectionStateChange?(.connected)
            } else {
                onConnectionStateChange?(.disconnected(BloomError.notConnected))
            }
        }
    }
    
    private func startMessageProcessing() {
        receivingTask = Task { [weak self] in
            guard let self = self else { return }
            
            do {
                for try await message in self.stream {
                    switch message {
                    case .string(let text):
                        await MainActor.run {
                            guard
                                let data = text.data(using: .utf8),
                                let message = try? JSONDecoder().decode(BloomMessage.self, from: data) else {
                                return
                            }
                            self.onMessage?(message)
                        }
                    case .data:
                        break // Handle binary if needed
                    @unknown default:
                        break
                    }
                }
            } catch {
                await MainActor.run {
                    self.onConnectionStateChange?(.disconnected(error))
                }
            }
            
            self.stopHeartbeat()
        }
    }
    
    func send(_ message: BloomMessage) async throws {
        guard socketConnection.state == .running else {
            throw BloomError.notConnected
        }
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(message)
        if let text = String(data: data, encoding: .utf8) {
            try await socketConnection.send(.string(text))
        }
    }
    
    func disconnect() {
        stopHeartbeat()
        receivingTask?.cancel()
        stream.cancel()
        onConnectionStateChange?(.disconnected(nil))
    }
    
    // MARK: - Heartbeat
    private func startHeartbeat() {
        pingTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { [weak self] in
                await self?.sendPing()
            }
        }
    }
    
    private func stopHeartbeat() {
        pingTimer?.invalidate()
        pingTimer = nil
    }
    
    private func sendPing() async {
        socketConnection.sendPing { error in
            if error != nil {
                self.disconnect()
            }
        }
    }
    
    deinit {
        disconnect()
    }
}

enum BloomError: LocalizedError {
    case notConnected
    var errorDescription: String? { return "WebSocket is not connected" }
}

// Helper Stream classes (Copied from LiveReact logic)
class SocketStream: AsyncSequence {
    typealias AsyncIterator = WebSocketStream.Iterator
    typealias Element = URLSessionWebSocketTask.Message
    
    private let task: URLSessionWebSocketTask
    private let stream: WebSocketStream
    private let continuation: WebSocketStream.Continuation
    
    init(task: URLSessionWebSocketTask) {
        self.task = task
        let (stream, continuation) = WebSocketStream.makeStream()
        self.stream = stream
        self.continuation = continuation
    }
    
    func makeAsyncIterator() -> WebSocketStream.Iterator {
        return stream.makeAsyncIterator()
    }
    
    func resume() {
        task.resume()
    }
    
    func cancel() {
        task.cancel(with: .goingAway, reason: nil)
        continuation.finish()
    }
    
    func startReceiving() {
        Task {
            while task.state == .running {
                do {
                    let message = try await task.receive()
                    continuation.yield(message)
                } catch {
                    continuation.finish(throwing: error)
                    break
                }
            }
            continuation.finish()
        }
    }
}

typealias WebSocketStream = URLSessionWebSocketTask.WebSocketStream

extension URLSessionWebSocketTask {
    typealias WebSocketStream = AsyncThrowingStream<URLSessionWebSocketTask.Message, Error>
    
    var stream: WebSocketStream {
        return WebSocketStream { continuation in
            Task {
                var isAlive = true
                while isAlive && closeCode == .invalid {
                    do {
                        let value = try await receive()
                        continuation.yield(value)
                    } catch {
                        continuation.finish(throwing: error)
                        isAlive = false
                    }
                }
            }
        }
    }
}

extension URL {
    init(_ string: StaticString) {
        self.init(string: "\(string)")!
    }
}
