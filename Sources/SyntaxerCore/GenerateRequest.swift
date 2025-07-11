//
//  GenerateRequest.swift
//  Syntaxer
//
//  Created by Leo Dion on 7/10/25.
//

import Foundation


public struct GenerateRequest: Codable {
    public let dslCode: String
    public let timeout: TimeInterval?
    
    public init(dslCode: String, timeout: TimeInterval? = nil) {
        self.dslCode = dslCode
        self.timeout = timeout
    }
}
