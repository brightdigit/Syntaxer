import Foundation
import Network
import SyntaxerCore

@main
struct SyntaxerAPI {
    static func main() async throws {
        let server = HTTPServerFoundation()
        try await server.start()
    }
}

class HTTPServerFoundation: @unchecked Sendable {
    private let port: UInt16 = 8080
    private let codeGenerationService = CodeGenerationService()
    private var listener: NWListener?
    
    func start() async throws {
        print("🚀 Starting SyntaxerAPI server on http://127.0.0.1:\(port)")
        print("📝 Available endpoints:")
        print("   GET  /health      - Health check")
        print("   POST /api/generate - Generate Swift code from DSL")
        print()
        print("🧪 Test with curl:")
        print("   curl -X GET http://localhost:\(port)/health")
        print("   curl -X POST http://localhost:\(port)/api/generate \\")
        print("        -H \"Content-Type: application/json\" \\")
        print("        -d '{\"dslCode\": \"Function(.public, name: \\\"hello\\\") { Return(\\\"String\\\") }\"}'")
        print()
        print("⏰ Warning: Code generation can take 30+ seconds due to Swift package compilation")
        print("🔄 Server running... Press Ctrl+C to stop")
        print()
        
        let params = NWParameters.tcp
        params.allowLocalEndpointReuse = true
        params.includePeerToPeer = true
        
        let listener = try NWListener(using: params, on: NWEndpoint.Port(rawValue: port)!)
        self.listener = listener
        
        listener.newConnectionHandler = { [weak self] connection in
            self?.handleConnection(connection)
        }
        
        listener.start(queue: .main)
        
        // Keep server running
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                while true {
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                }
            }
        }
    }
    
    private func handleConnection(_ connection: NWConnection) {
        connection.start(queue: .global())
        
        @Sendable func receiveData() {
            connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
                guard let data = data, !data.isEmpty else {
                    if isComplete {
                        connection.cancel()
                    } else {
                        receiveData()
                    }
                    return
                }
                
                Task {
                    await self?.processRequest(data: data, connection: connection)
                }
                
                if !isComplete {
                    receiveData()
                }
            }
        }
        
        receiveData()
    }
    
    private func processRequest(data: Data, connection: NWConnection) async {
        guard let httpRequest = parseHTTPRequest(data) else {
            await sendResponse(connection: connection, statusCode: 400, body: "Bad Request")
            return
        }
        
        print("📨 \(httpRequest.method) \(httpRequest.path)")
        
        let response: (statusCode: Int, contentType: String, body: String)
        
        switch (httpRequest.method, httpRequest.path) {
        case ("GET", "/health"):
            response = (200, "application/json", "{\"status\": \"healthy\", \"service\": \"SyntaxerAPI\"}")
            
        case ("POST", "/api/generate"):
            response = await handleGenerate(httpRequest)
            
        default:
            response = (404, "application/json", "{\"error\": \"Endpoint not found\", \"success\": false}")
        }
        
        await sendResponse(
            connection: connection,
            statusCode: response.statusCode,
            contentType: response.contentType,
            body: response.body
        )
    }
    
    private func handleGenerate(_ request: HTTPRequest) async -> (statusCode: Int, contentType: String, body: String) {
        do {
            guard let bodyData = request.body else {
                return (400, "application/json", "{\"error\": \"Request body required\", \"success\": false}")
            }
            
            // Parse JSON request
            guard let json = try JSONSerialization.jsonObject(with: bodyData) as? [String: Any],
                  let dslCode = json["dslCode"] as? String else {
                return (400, "application/json", "{\"error\": \"Invalid request format. Expected JSON with 'dslCode' field.\", \"success\": false}")
            }
            
            // Validate input
            let trimmedCode = dslCode.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedCode.isEmpty else {
                return (400, "application/json", "{\"error\": \"DSL code cannot be empty\", \"success\": false}")
            }
            
            guard trimmedCode.count <= 100_000 else {
                return (400, "application/json", "{\"error\": \"DSL code too large (max 100KB)\", \"success\": false}")
            }
            
            // Get timeout from request or use default
            let timeout = (json["timeout"] as? Double) ?? 240.0
            guard timeout > 0 && timeout <= 240.0 else {
                return (400, "application/json", "{\"error\": \"Invalid timeout (must be between 1 and 120 seconds)\", \"success\": false}")
            }
            
            print("🔧 Generating code with timeout: \(timeout)s")
            
            // Generate the code
            let options = CodeGenerationService.GenerationOptions(timeout: timeout)
            let generatedCode = try await codeGenerationService.generateCode(from: trimmedCode, options: options)
            
            // Return success response
            let responseData = try JSONSerialization.data(withJSONObject: [
                "generatedCode": generatedCode,
                "success": true
            ])
            
            print("✅ Code generation successful")
            
            return (200, "application/json", String(data: responseData, encoding: .utf8) ?? "{}")
            
        } catch let error as CodeGenerationService.ValidationError {
            print("❌ Validation error: \(error.description)")
            let errorJson = "{\"error\": \"\(error.description.replacingOccurrences(of: "\"", with: "\\\""))\", \"success\": false}"
            return (400, "application/json", errorJson)
            
        } catch {
            print("❌ Internal error: \(error.localizedDescription)")
            let errorJson = "{\"error\": \"Internal server error\", \"success\": false}"
            return (500, "application/json", errorJson)
        }
    }
    
    private func parseHTTPRequest(_ data: Data) -> HTTPRequest? {
        guard let requestString = String(data: data, encoding: .utf8) else { return nil }
        
        let lines = requestString.components(separatedBy: "\r\n")
        guard let requestLine = lines.first else { return nil }
        
        let components = requestLine.components(separatedBy: " ")
        guard components.count >= 3 else { return nil }
        
        let method = components[0]
        let path = components[1]
        
        // Find the blank line that separates headers from body
        var bodyStartIndex = 0
        for (index, line) in lines.enumerated() {
            if line.isEmpty {
                bodyStartIndex = index + 1
                break
            }
        }
        
        let body: Data?
        if bodyStartIndex < lines.count {
            let bodyLines = Array(lines[bodyStartIndex...])
            let bodyString = bodyLines.joined(separator: "\r\n")
            body = bodyString.data(using: .utf8)
        } else {
            body = nil
        }
        
        return HTTPRequest(method: method, path: path, body: body)
    }
    
    private func sendResponse(connection: NWConnection, statusCode: Int, contentType: String = "text/plain", body: String) async {
        let statusText = statusCode == 200 ? "OK" : statusCode == 404 ? "Not Found" : statusCode == 400 ? "Bad Request" : "Internal Server Error"
        let response = """
        HTTP/1.1 \(statusCode) \(statusText)\r
        Content-Type: \(contentType)\r
        Content-Length: \(body.utf8.count)\r
        Access-Control-Allow-Origin: *\r
        Access-Control-Allow-Methods: GET, POST, OPTIONS\r
        Access-Control-Allow-Headers: Content-Type\r
        \r
        \(body)
        """
        
        let responseData = response.data(using: .utf8)!
        
        connection.send(content: responseData, completion: .contentProcessed { error in
            if let error = error {
                print("❌ Error sending response: \(error)")
            }
            connection.cancel()
        })
    }
}

struct HTTPRequest {
    let method: String
    let path: String
    let body: Data?
}
