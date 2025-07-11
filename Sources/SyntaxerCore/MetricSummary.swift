//
//  MetricSummary.swift
//  Syntaxer
//
//  Created by Leo Dion on 7/10/25.
//

import Foundation



public struct MetricSummary: Codable, Sendable {
    public let count: Int
    public let average: TimeInterval
    public let min: TimeInterval
    public let max: TimeInterval
    public let median: TimeInterval
}
