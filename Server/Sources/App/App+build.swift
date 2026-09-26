import Hummingbird
import HummingbirdWebSocket
import Logging
import Foundation
import HTTPTypes

/// Application arguments protocol. We use a protocol so we can call
/// `buildApplication` inside Tests as well as in the App executable. 
/// Any variables added here also have to be added to `App` in App.swift and 
/// `TestArguments` in AppTest.swift
package protocol AppArguments {
    var hostname: String { get }
    var port: Int { get }
    var logLevel: Logger.Level? { get }
}

// Request context used by application
typealias AppRequestContext = BasicWebSocketRequestContext

///  Build application
/// - Parameter arguments: application arguments
func buildApplication(_ arguments: some AppArguments) async throws -> some ApplicationProtocol {
    let environment = Environment()
    let logger = {
        var logger = Logger(label: "PlayPenBloom")
        logger.logLevel =
            arguments.logLevel ??
            environment.get("LOG_LEVEL").flatMap { Logger.Level(rawValue: $0) } ??
            .info
        return logger
    }()
    
    let connectionManager = ConnectionManager(logger: logger)
    
    // HTTP Router
    let router = try buildRouter()
    
    // WebSocket Router (Separate)
    let wsRouter = Router(context: BasicWebSocketRequestContext.self)
    wsRouter.ws("/ws/bloom") { request, context in
        context.logger.info("WebSocket upgrade request received: \(request.uri)")
        return .upgrade([:])
    } onUpgrade: { inbound, outbound, context in
        context.logger.info("WebSocket connection upgraded")
        
        // Extract parameters from request
        let userIdString = context.request.uri.queryParameters["userId"].map(String.init) ?? UUID().uuidString
        let roomCode = context.request.uri.queryParameters["roomCode"].map(String.init) ?? "DEFAULT"
        let userId = UUID(uuidString: userIdString) ?? UUID()
        
        context.logger.info("Client connected: \(userId) in room \(roomCode)")
        
        let outputStream = connectionManager.addUser(
            userId: userId,
            roomCode: roomCode,
            inbound: inbound,
            outbound: outbound
        )
        
        // Loop through output stream and write to WebSocket
        do {
            for await message in outputStream {
                try await outbound.write(message)
            }
        } catch {
            context.logger.error("WebSocket write error: \(error)")
        }
        context.logger.info("WebSocket connection closed")
    }
    
    var app = Application(
        router: router,
        server: .http1WebSocketUpgrade(webSocketRouter: wsRouter),
        configuration: .init(
            address: .hostname(arguments.hostname, port: arguments.port),
            serverName: "PlayPenBloom"
        ),
        logger: logger
    )
    
    // Add connection manager service
    app.addServices(connectionManager)
    
    return app
}

/// Build router
func buildRouter() throws -> Router<AppRequestContext> {
    let router = Router(context: AppRequestContext.self)
    
    // Add default endpoint
    router.get("/") { _,_ in
        return "Hello! Bloom Server is running."
    }
    
    return router
}
