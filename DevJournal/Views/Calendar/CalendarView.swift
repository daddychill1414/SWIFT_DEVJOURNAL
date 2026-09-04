//
//  CalendarView.swift
//  DevJournal
//

import SwiftUI

struct CalendarView: View {
    @State private var selectedDate = Date()
    
    let daysInMonth = Array(1...31)
    let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        NavigationStack {
            ZStack {
                AtmosphericBackgroundView()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Title
                        Text("Calendar Log")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                        
                        // Month Header
                        GlassCard(style: .regular) {
                            VStack(spacing: 16) {
                                HStack {
                                    Text("September 2026")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    HStack(spacing: 16) {
                                        Image(systemName: "chevron.left")
                                        Image(systemName: "chevron.right")
                                    }
                                    .font(.title3)
                                    .foregroundColor(AppColors.accentCyan)
                                }
                                
                                // Days of week
                                HStack {
                                    ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                                        Text(day)
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.secondary)
                                            .frame(maxWidth: .infinity)
                                    }
                                }
                                
                                // Month Days Grid
                                LazyVGrid(columns: columns, spacing: 12) {
                                    ForEach(daysInMonth, id: \.self) { day in
                                        VStack(spacing: 4) {
                                            Text("\(day)")
                                                .font(.subheadline)
                                                .fontWeight(day == 4 ? .bold : .regular)
                                                .foregroundColor(day == 4 ? .white : .primary)
                                                .frame(width: 32, height: 32)
                                                .background(day == 4 ? AppColors.primaryIndigo : Color.clear)
                                                .clipShape(Circle())
                                            
                                            // Activity Indicators
                                            HStack(spacing: 2) {
                                                if day % 2 == 0 {
                                                    Circle()
                                                        .fill(AppColors.accentCyan)
                                                        .frame(width: 4, height: 4)
                                                }
                                                if day % 3 == 0 {
                                                    Circle()
                                                        .fill(AppColors.secondaryPurple)
                                                        .frame(width: 4, height: 4)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Selected Day Activity Summary
                        VStack(alignment: .leading, spacing: 12) {
                            Text("September 4, 2026 Activity")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            GlassCard(style: .thin) {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        Image(systemName: "book.closed.fill")
                                            .foregroundColor(AppColors.accentCyan)
                                        Text("1 Journal Entry Logged")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                    }
                                    HStack {
                                        Image(systemName: "hammer.fill")
                                            .foregroundColor(AppColors.primaryIndigo)
                                        Text("4 Commits pushed to DevJournal")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                    }
                                    HStack {
                                        Image(systemName: "clock.fill")
                                            .foregroundColor(AppColors.successGreen)
                                        Text("5h 30m Total Focus Session")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                    }
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
}

#Preview {
    CalendarView()
}
