import Foundation

public struct MarkdownReport {
    public let total: Int
    public let processed: Int

}

extension MarkdownReport {
    public var percentage: Double {
        round(Double(processed * 10_000) / Double(total)) / 100.0
    }
}

func + (lhs: MarkdownReport, rhs: MarkdownReport) -> MarkdownReport {
    return MarkdownReport(total: lhs.total + rhs.total, processed: lhs.processed + rhs.processed)
}
