//
//  InsightsView.swift
//  DevJournal
//

import SwiftUI
import SwiftData
import Charts

struct FocusTimeData: Identifiable {
    let id = UUID()
    let day: String
    let hours: Double
}

struct InsightsView: View {
    @Query(sort: \JournalEntry.date, order: .reverse) private var journalEntries: [JournalEntry]
    @Query(sort: \FocusSession.startTime, order: .reverse) private var focusSessions: [FocusSession]
    
    private var weeklyData: [FocusTimeData] {
        let calendar = Calendar.current
        let today = Date()
        let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        
        return (0..<7).reversed().map { daysAgo in
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) else {
                return FocusTimeData(day: "", hours: 0)
            }
            let weekday = calendar.component(.weekday, from: date) - 1
            let dayName = dayNames[weekday]
            
            let dayEntries = journalEntries.filter { calendar.isDate($0.date, inSameDayAs: date) }
            let dayFocus = focusSessions.filter { calendar.isDate($0.startTime, inSameDayAs: date) && $0.isCompleted }
            
            let totalHours = dayEntries.reduce(0.0) { $0 + $1.hoursSpent }
                + Double(dayFocus.reduce(0) { $0 + $1.durationMinutes }) / 60.0
            
            return FocusTimeData(day: dayName, hours: totalHours)
        }
    }
    
    private var totalWeeklyHours: Double {
        weeklyData.reduce(0.0) { $0 + $1.hours }
    }
    
    private var dailyAvgHours: Double {
        let activeDays = weeklyData.filter { $0.hours > 0 }.count
        return activeDays > 0 ? totalWeeklyHours / Double(activeDays) : 0
    }
    
    private var longestFocusMinutes: Int {
        focusSessions.filter { $0.isCompleted }.map { $0.durationMinutes }.max() ?? 0
    }
    
    private var productivityScore: Int {
        let hoursScore = min(totalWeeklyHours / 35.0, 1.0) * 60
        let consistencyScore = Double(weeklyData.filter { $0.hours > 0 }.count) / 7.0 * 40
        return min(Int(hoursScore + consistencyScore), 100)
    }
    
    private func formatDuration(_ totalMinutes: Int) -> String {
        let h = totalMinutes / 60
        let m = totalMinutes % 60
        return "\(h)h \(m)m"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AtmosphericBackgroundView()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Title
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Insights")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            Text("This Week")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        
                        // Productivity Score Card
                        GlassCard(style: .regular) {
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Productivity Score")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                                        Text("\(productivityScore)")
                                            .font(.system(size: 48, weight: .bold, design: .rounded))
                                            .foregroundColor(AppColors.accentCyan)
                                        Text("/ 100")
                                            .font(.title3)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Text(productivityScore >= 80 ? "Outstanding productivity this week!" : productivityScore >= 50 ? "Good progress — keep building momentum." : "Log more sessions to boost your score.")
                                        .font(.caption)
                                        .foregroundColor(productivityScore >= 80 ? AppColors.successGreen : .secondary)
                                }
                                Spacer()
                                
                                Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                                    .font(.system(size: 54))
                                    .foregroundStyle(AppColors.primaryIndigo, AppColors.accentCyan)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Key Metrics Row
                        HStack(spacing: 12) {
                            metricBox(title: "Longest Focus", value: formatDuration(longestFocusMinutes), icon: "bolt.fill")
                            metricBox(title: "Total Focus", value: formatDuration(Int(totalWeeklyHours * 60)), icon: "clock.fill")
                            metricBox(title: "Daily Avg", value: formatDuration(Int(dailyAvgHours * 60)), icon: "flame.fill")
                        }
                        .padding(.horizontal, 20)
                        
                        // Focus Time Chart
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Focus Time Trend")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            GlassCard(style: .thin) {
                                Chart(weeklyData) { data in
                                    BarMark(
                                        x: .value("Day", data.day),
                                        y: .value("Hours", data.hours)
                                    )
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [AppColors.primaryIndigo, AppColors.accentCyan],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .cornerRadius(6)
                                }
                                .frame(height: 180)
                                .chartYAxis {
                                    AxisMarks(position: .leading)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Developer Insight Card
                        GlassCard(style: .regular, strokeColor: AppColors.secondaryPurple.opacity(0.4)) {
                            HStack(spacing: 16) {
                                Image(systemName: "lightbulb.max.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(AppColors.warningOrange)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Developer Insight")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(AppColors.warningOrange)
                                    
                                    Text(totalWeeklyHours > 0 ? "You logged \(String(format: "%.1f", totalWeeklyHours)) hours this week." : "Start logging focus sessions to see insights.")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Text(totalWeeklyHours > 0 ? "Keep consistent daily sessions to maximize productivity." : "Add journal entries or complete focus sessions to track your progress.")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 100)
                }
            }
        }
    }
    
    @ViewBuilder
    private func metricBox(title: String, value: String, icon: String) -> some View {
        GlassCard(style: .ultraThin, padding: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(AppColors.accentCyan)
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    InsightsView()
}

