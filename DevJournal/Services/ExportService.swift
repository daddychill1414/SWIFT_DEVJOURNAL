//
//  ExportService.swift
//  DevJournal
//
//  Handles exporting journal entries as Markdown or PDF files,
//  presented via UIActivityViewController share sheet.
//

import Foundation
import UIKit

final class ExportService {
    
    // MARK: - Markdown Export
    
    static func exportAsMarkdown(entries: [JournalEntry]) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        
        var md = "# DevJournal Export\n\n"
        md += "> **Exported:** \(DateFormatter.localizedString(from: Date(), dateStyle: .long, timeStyle: .short))\n"
        md += "> **Total Entries:** \(entries.count)\n\n"
        md += "---\n\n"
        
        let sorted = entries.sorted { $0.date > $1.date }
        
        for entry in sorted {
            md += "## \(entry.title)\n\n"
            md += "| Field | Value |\n"
            md += "|-------|-------|\n"
            md += "| 📅 Date | \(dateFormatter.string(from: entry.date)) |\n"
            md += "| \(entry.mood) Mood | \(entry.mood) |\n"
            md += "| 🎯 Focus | \(entry.focusLevel) |\n"
            md += "| ⏱ Hours | \(String(format: "%.1f", entry.hoursSpent))h |\n"
            if let repo = entry.gitHubRepoName, !repo.isEmpty {
                md += "| 🔗 Repo | \(repo) |\n"
            }
            md += "\n"
            
            if !entry.tags.isEmpty {
                let tagLine = entry.tags.map { "`\($0)`" }.joined(separator: " ")
                md += "**Tags:** \(tagLine)\n\n"
            }
            
            md += "\(entry.content)\n\n"
            md += "---\n\n"
        }
        
        return md
    }
    
    // MARK: - PDF Export
    
    static func exportAsPDF(entries: [JournalEntry]) -> Data? {
        let htmlContent = buildHTMLContent(entries: entries)
        let printFormatter = UIMarkupTextPrintFormatter(markupText: htmlContent)
        let renderer = UIPrintPageRenderer()
        renderer.addPrintFormatter(printFormatter, startingAtPageAt: 0)
        
        // US Letter page size
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let printableRect = pageRect.insetBy(dx: 40, dy: 40)
        
        renderer.setValue(NSValue(cgRect: pageRect), forKey: "paperRect")
        renderer.setValue(NSValue(cgRect: printableRect), forKey: "printableRect")
        
        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, pageRect, nil)
        for i in 0..<renderer.numberOfPages {
            UIGraphicsBeginPDFPage()
            renderer.drawPage(at: i, in: UIGraphicsGetPDFContextBounds())
        }
        UIGraphicsEndPDFContext()
        
        return pdfData as Data
    }
    
    private static func buildHTMLContent(entries: [JournalEntry]) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        var rows = ""
        for entry in entries.sorted(by: { $0.date > $1.date }) {
            rows += """
            <div class="entry">
                <h2>\(entry.title)</h2>
                <div class="meta">
                    \(dateFormatter.string(from: entry.date)) &bull;
                    \(entry.mood) &bull;
                    Focus: \(entry.focusLevel) &bull;
                    \(String(format: "%.1f", entry.hoursSpent))h
                </div>
                <p>\(entry.content.replacingOccurrences(of: "\n", with: "<br>"))</p>
                <div class="tags">\(entry.tags.map { "<span class='tag'>\($0)</span>" }.joined(separator: " "))</div>
            </div>
            """
        }
        
        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <style>
            body { font-family: -apple-system, sans-serif; padding: 20px; color: #111; }
            h1 { font-size: 24px; color: #1a1a2e; border-bottom: 2px solid #6c63ff; padding-bottom: 8px; }
            .entry { margin-bottom: 24px; padding-bottom: 16px; border-bottom: 1px solid #eee; }
            h2 { font-size: 16px; margin: 0 0 4px; }
            .meta { font-size: 11px; color: #888; margin-bottom: 8px; }
            p { font-size: 13px; line-height: 1.6; margin: 0 0 8px; }
            .tags { margin-top: 6px; }
            .tag { background: #f0f0ff; color: #6c63ff; border-radius: 4px; padding: 2px 6px; font-size: 10px; margin-right: 4px; }
        </style>
        </head>
        <body>
        <h1>DevJournal Export — \(entries.count) Entries</h1>
        \(rows)
        </body>
        </html>
        """
    }
    
    // MARK: - Share
    
    @MainActor
    static func shareMarkdown(entries: [JournalEntry]) {
        let content = exportAsMarkdown(entries: entries)
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("DevJournal_Export_\(Int(Date().timeIntervalSince1970)).md")
        try? content.write(to: tempURL, atomically: true, encoding: .utf8)
        present(items: [tempURL])
    }
    
    @MainActor
    static func sharePDF(entries: [JournalEntry]) {
        guard let data = exportAsPDF(entries: entries) else { return }
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("DevJournal_Export_\(Int(Date().timeIntervalSince1970)).pdf")
        try? data.write(to: tempURL)
        present(items: [tempURL])
    }
    
    @MainActor
    private static func present(items: [Any]) {
        let activityVC = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else { return }
        
        // iPad popover support
        activityVC.popoverPresentationController?.sourceView = rootVC.view
        activityVC.popoverPresentationController?.sourceRect = CGRect(
            x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY,
            width: 0, height: 0
        )
        rootVC.present(activityVC, animated: true)
    }
}
