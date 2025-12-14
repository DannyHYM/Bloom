import Foundation
import SwiftUI
import OSLog
import Starscream

class BloomClient: WebSocketDelegate {
    private var socket: WebSocket?
    private var pingTimer: Timer?
    
    // Public message handler
    var onMessage: ((BloomMessage) -> Void)?
    var onConnectionStateChange: ((ConnectionState) -> Void)?
    
    enum ConnectionState {
        case connecting
        case connected
        case disconnected(Error?)
    }
    
    private let url: URL
    
    init(hostname: URL = URL("wss://opbloom.fly.dev"), userId: UUID = UUID(), roomCode: String) {
        // Ensure scheme is websocket compatible
        var components = URLComponents(url: hostname, resolvingAgainstBaseURL: true)
        if components?.scheme == "https" {
            components?.scheme = "wss"
        } else if components?.scheme == "http" {
            components?.scheme = "ws"
        }
        
        let wsURL = components?.url ?? hostname
        
        self.url = wsURL
            .appending(component: "ws")
            .appending(component: "bloom")
            .appending(queryItems: [
                .init(name: "userId", value: userId.uuidString),
                .init(name: "roomCode", value: roomCode)
            ])
        
        var request = URLRequest(url: self.url)
        request.timeoutInterval = 5
        
        // Starscream sets default headers, but let's be safe against proxy stripping
        request.setValue("websocket", forHTTPHeaderField: "Upgrade")
        request.setValue("Upgrade", forHTTPHeaderField: "Connection")
        request.setValue("13", forHTTPHeaderField: "Sec-WebSocket-Version")
        request.setValue("permessage-deflate; client_max_window_bits", forHTTPHeaderField: "Sec-WebSocket-Extensions")
        
        self.socket = WebSocket(request: request)
        self.socket?.delegate = self
    }
    
    func connect() {
        onConnectionStateChange?(.connecting)
        socket?.connect()
        startHeartbeat()
    }
    
    func disconnect() {
        stopHeartbeat()
        socket?.disconnect()
        // Delegate will handle the state change
    }
    
    func send(_ message: BloomMessage) async throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(message)
        if let text = String(data: data, encoding: .utf8) {
            socket?.write(string: text)
        }
    }
    
    // MARK: - Starscream Delegate
    
    func didReceive(event: WebSocketEvent, client: WebSocketClient) {
        switch event {
        case .connected(let headers):
            print("websocket is connected: \(headers)")
            DispatchQueue.main.async {
                self.onConnectionStateChange?(.connected)
            }
            
        case .disconnected(let reason, let code):
            print("websocket is disconnected: \(reason) with code: \(code)")
            DispatchQueue.main.async {
                self.onConnectionStateChange?(.disconnected(nil))
            }
            
        case .text(let string):
            print("Received text: \(string)")
            guard
                let data = string.data(using: .utf8),
                let message = try? JSONDecoder().decode(BloomMessage.self, from: data)
            else {
                return
            }
            
            DispatchQueue.main.async {
                self.onMessage?(message)
            }
            
        case .binary(let data):
            print("Received data: \(data.count)")
            
        case .ping(_):
            break
            
        case .pong(_):
            break
            
        case .viabilityChanged(_):
            break
            
        case .reconnectSuggested(_):
            break
            
        case .cancelled:
            DispatchQueue.main.async {
                self.onConnectionStateChange?(.disconnected(nil))
            }
            
        case .error(let error):
            print("websocket error: \(String(describing: error))")
            DispatchQueue.main.async {
                self.onConnectionStateChange?(.disconnected(error))
            }
            
        case .peerClosed:
             DispatchQueue.main.async {
                self.onConnectionStateChange?(.disconnected(nil))
            }
        }
    }
    
    // MARK: - Heartbeat
    
    private func startHeartbeat() {
        // Stop any existing timer first
        stopHeartbeat()
        
        pingTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.socket?.write(ping: Data())
        }
    }
    
    private func stopHeartbeat() {
        pingTimer?.invalidate()
        pingTimer = nil
    }
    
    deinit {
        socket?.disconnect()
        stopHeartbeat()
    }
}

enum BloomError: LocalizedError {
    case notConnected
    var errorDescription: String? { return "WebSocket is not connected" }
}

extension URL {
    init(_ string: StaticString) {
        self.init(string: "\(string)")!
    }
}
