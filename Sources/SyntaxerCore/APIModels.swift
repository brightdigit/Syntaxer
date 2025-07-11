import Foundation



public struct ErrorResponse: Codable {
    public let error: String
    public let success: Bool
    
    public init(error: String) {
        self.error = error
        self.success = false
    }
}
