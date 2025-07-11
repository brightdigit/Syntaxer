import Foundation

public actor PerformanceMetrics {
    private var metrics: [String: [TimeInterval]] = [:]
    private let maxMetricsPerKey = 100
    
    public init() {}
    
    public func record(metric: String, duration: TimeInterval) {
        if metrics[metric] == nil {
            metrics[metric] = []
        }
        
        metrics[metric]?.append(duration)
        
        // Keep only the most recent metrics
        if let count = metrics[metric]?.count, count > maxMetricsPerKey {
            metrics[metric] = Array(metrics[metric]!.suffix(maxMetricsPerKey))
        }
    }
    
    public func getAverageTime(for metric: String) -> TimeInterval? {
        guard let times = metrics[metric], !times.isEmpty else { return nil }
        return times.reduce(0, +) / Double(times.count)
    }
    
    public func getMetricsSummary() -> [String: MetricSummary] {
        var summary: [String: MetricSummary] = [:]
        
        for (key, times) in metrics {
            guard !times.isEmpty else { continue }
            
            let sorted = times.sorted()
            summary[key] = MetricSummary(
                count: times.count,
                average: times.reduce(0, +) / Double(times.count),
                min: sorted.first!,
                max: sorted.last!,
                median: sorted[sorted.count / 2]
            )
        }
        
        return summary
    }
    
    public func clear() {
        metrics.removeAll()
    }
}
