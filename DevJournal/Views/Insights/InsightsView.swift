//
//  InsightsView.swift
//  DevJournal
//

import SwiftUI
import Charts

struct FocusTimeData: Identifiable {
    let id = UUID()
    let day: String
    let hours: Double
}

struct InsightsView: View {
    let weeklyData: [FocusTimeData] = [
        FocusTimeData(day: "Mon", hours: 4.5),
        FocusTimeData(day: "Tue", hours: 6.2),
        FocusTimeData(day: "Wed", hours: 5.8),
        FocusTimeData(day: "Thu", hours: 7.0),
        FocusTimeData(day: "Fri", hours: 6.25),
        FocusTimeData(day: "Sat", hours: 3.5),
        FocusTimeData(day: "Sun", hours: 2.0)
    ]
    
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
                                        Text("85")
                                            .font(.system(size: 48, weight: .bold, design: .rounded))
                                            .foregroundColor(AppColors.accentCyan)
                                        Text("/ 100")
                                            .font(.title3)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Text("Top 5% of active iOS developers this week.")
                                        .font(.caption)
                                        .foregroundColor(AppColors.successGreen)
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
                            metricBox(title: "Longest Focus", value: "3h 20m", icon: "bolt.fill")
                            metricBox(title: "Total Focus", value: "35h 15m", icon: "clock.fill")
                            metricBox(title: "Daily Avg", value: "5h 02m", icon: "flame.fill")
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
                                    
                                    Text("You're most productive in the morning.")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Text("Your focus sessions are strongest between 9 AM and 12 PM.")
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
