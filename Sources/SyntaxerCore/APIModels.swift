import Foundation

public struct GenerateRequest: Codable {
    public let dslCode: String
    public let timeout: TimeInterval?
    
    public init(dslCode: String, timeout: TimeInterval? = nil) {
        self.dslCode = dslCode
        self.timeout = timeout
    }
}

public struct GenerateResponse: Codable {
    public let generatedCode: String
    public let success: Bool
    public let message: String?
    
    public init(generatedCode: String, success: Bool = true, message: String? = nil) {
        self.generatedCode = generatedCode
        self.success = success
        self.message = message
    }
}

public struct ErrorResponse: Codable {
    public let error: String
    public let success: Bool
    
    public init(error: String) {
        self.error = error
        self.success = false
    }
}