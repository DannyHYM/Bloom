import Charts
import SwiftUI
import SwiftData

struct HeatMapChart: View {
    @Query var logs: [PracticeLog]
    
    init() {
        // Query logs from last 140 days (20 weeks), aligned to end on Saturday
        let offset = 8 - (Calendar.current.dateComponents([.weekday], from: Date.now).weekday ?? 1)
        if let startDate = Calendar.current.date(byAdding: .day, value: -140 + offset, to: Date.now) {
            let predicate = #Predicate<PracticeLog> {
                $0.date >= startDate
            }
            _logs = Query(filter: predicate, sort: \.date)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                    .font(.title3)
                Text("Consistency")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
            }
            
            Text("You practiced \(logs.count) times in the last 4 months")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
            
            chart
                .padding(.top, 10)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(0.05)))
    }
    
    // THE CORE HEAT MAP CHART
    private var chart: some View {
        Chart(logs) { log in
            Plot {
                RectangleMark(
                    xStart: .value("xStart", relativeWeek(date: log.date)),
                    xEnd: .value("xEnd", relativeWeek(date: log.date) + 1),
                    yStart: .value("yStart", reversedDayOfTheWeek(date: log.date)),
                    yEnd: .value("yEnd", reversedDayOfTheWeek(date: log.date) + 1)
                )
                .foregroundStyle(Color.green.gradient.opacity(0.65).blendMode(.overlay).shadow(.drop(color: .green.opacity(0.65), radius: 5, x: 1, y: 3)))
                .interpolationMethod(.cardinal)
            }
        }
        .chartLegend(.hidden)
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 7, roundLowerBound: false, roundUpperBound: false)) { _ in
                AxisGridLine(stroke: .init(lineWidth: 1, dash: [2]))
                    .foregroundStyle(Color.white.opacity(0.2))
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 20, roundLowerBound: false, roundUpperBound: false)) { _ in
                AxisGridLine(stroke: .init(lineWidth: 1, dash: [2]))
                    .foregroundStyle(Color.white.opacity(0.2))
            }
        }
        .chartYScale(domain: 0...7)
        .chartXScale(domain: 0...20)
        .aspectRatio(21.0/7.0, contentMode: .fit)
    }
    
    // HELPER FUNCTIONS
    private func dayOfTheWeek(date: Date) -> Int {
        (Calendar.current.dateComponents([.weekday], from: date).weekday ?? 1) - 1
    }
    
    private func reversedDayOfTheWeek(date: Date) -> Int {
        return 6 - dayOfTheWeek(date: date)
    }
    
    func daysBetweenDatesWithTime(from date1: Date, to date2: Date) -> Int {
        let calendar = Calendar.current
        let date1Start = calendar.startOfDay(for: date1)
        let date2Start = calendar.startOfDay(for: date2)
        let components = calendar.dateComponents([.day], from: date1Start, to: date2Start)
        let hourDifference = calendar.dateComponents([.hour], from: date1, to: date2).hour ?? 0
        if hourDifference < 0 && components.day == 0 {
            return 1
        }
        return abs(components.day ?? 0)
    }
    
    private func relativeWeek(date: Date) -> Int {
        // Find the start date of the 20-week window
        let offset = 8 - (Calendar.current.dateComponents([.weekday], from: Date.now).weekday ?? 1)
        guard let startDate = Calendar.current.date(byAdding: .day, value: -140 + offset, to: Date.now) else { return 0 }
        
        let daysApart = daysBetweenDatesWithTime(from: startDate, to: date)
        return daysApart / 7
    }
}

#Preview {
    HeatMapChart()
        .preferredColorScheme(.dark)
        .padding()
        .background(Color.black)
}
