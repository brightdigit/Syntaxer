//
//  GenerateResponse.swift
//  Syntaxer
//
//  Created by Leo Dion on 7/10/25.
//



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