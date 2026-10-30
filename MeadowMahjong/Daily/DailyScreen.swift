import SwiftUI

/// S03: a month calendar with a trophy on each solved day.
struct DailyScreen: View {
    let onPlay: (DayKey) -> Void
    let onBack: () -> Void

    @Environment(PlayerProgress.self) private var progress
    @State private var month = DayKey.today
    @State private var selected = DayKey.today

    private let calendar = Calendar.current
    private let today = DayKey.today

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                RoundIconButton(systemName: "chevron.left", label: "Back", action: onBack)
                Spacer()
                Text("Daily Challenge")
                    .font(Theme.title(24))
                    .foregroundStyle(Theme.leafDeep)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(.ultraThinMaterial))
                Spacer()
                Color.clear.frame(width: 48, height: 48)
            }
            .padding(.horizontal, 16)

            VStack(spacing: 14) {
                HStack {
                    monthButton("chevron.left", by: -1, enabled: canGoBack)
                    Spacer()
                    VStack(spacing: 2) {
                        Text(month.date().formatted(.dateTime.month(.wide).year()))
                            .font(Theme.title(22))
                        Label("\(progress.trophies(inYear: month.year, month: month.month)) / \(daysInMonth)", systemImage: "trophy.fill")
                            .font(Theme.body(15))
                            .foregroundStyle(Color(hex: 0xC98A00))
                    }
                    Spacer()
                    monthButton("chevron.right", by: 1, enabled: canGoForward)
                }

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 8) {
                    ForEach(0..<7, id: \.self) { i in
                        Text(weekdaySymbols[i])
                            .font(Theme.body(14))
                            .foregroundStyle(Theme.ink.opacity(0.5))
                    }
                    ForEach(0..<leadingBlanks, id: \.self) { _ in Color.clear.frame(height: 44) }
                    ForEach(1...daysInMonth, id: \.self) { day in
                        dayCell(DayKey(year: month.year, month: month.month, day: day))
                    }
                }
            }
            .foregroundStyle(Theme.ink)
            .card()
            .padding(.horizontal, 16)

            Spacer(minLength: 0)

            Button {
                onPlay(selected)
            } label: {
                VStack(spacing: 2) {
                    Text(progress.isSolved(selected) ? "Play Again" : "Play")
                        .font(Theme.display(30))
                    Text(selected.date().formatted(.dateTime.weekday(.wide).month(.wide).day()))
                        .font(Theme.body(16))
                        .opacity(0.9)
                }
            }
            .buttonStyle(PrimaryButtonStyle(tint: Theme.blossom))
            .padding(.horizontal, 40)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: Theme.contentWidth)
        .padding(.top, 8)
    }

    // MARK: -

    private var firstOfMonth: Date { DayKey(year: month.year, month: month.month, day: 1).date(calendar: calendar) }
    private var daysInMonth: Int { calendar.range(of: .day, in: .month, for: firstOfMonth)?.count ?? 30 }

    private var leadingBlanks: Int {
        let weekday = calendar.component(.weekday, from: firstOfMonth)
        return (weekday - calendar.firstWeekday + 7) % 7
    }

    private var weekdaySymbols: [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let first = calendar.firstWeekday - 1
        return (0..<7).map { symbols[(first + $0) % 7] }
    }

    /// A year of history is plenty; future months have nothing to play.
    private var canGoBack: Bool {
        (today.year * 12 + today.month) - (month.year * 12 + month.month) < 12
    }

    private var canGoForward: Bool { month.year * 12 + month.month < today.year * 12 + today.month }

    private func monthButton(_ symbol: String, by delta: Int, enabled: Bool) -> some View {
        Button {
            let shifted = calendar.date(byAdding: .month, value: delta, to: firstOfMonth) ?? firstOfMonth
            withAnimation(.snappy) { month = DayKey(shifted, calendar: calendar) }
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .bold))
                .frame(width: 44, height: 44)
                .background(Circle().fill(Theme.leaf.opacity(0.12)))
        }
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.3)
        .accessibilityLabel(delta < 0 ? "Previous month" : "Next month")
    }

    private func dayCell(_ day: DayKey) -> some View {
        let isFuture = day > today
        let isSolved = progress.isSolved(day)
        let isSelected = day == selected
        return Button {
            selected = day
        } label: {
            ZStack {
                Circle()
                    .fill(isSelected ? Theme.blossom : (day == today ? Theme.leaf.opacity(0.15) : .clear))
                if isSolved {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(isSelected ? .white : Color(hex: 0xE0A100))
                } else {
                    Text("\(day.day)")
                        .font(Theme.body(17))
                        .foregroundStyle(isSelected ? .white : Theme.ink.opacity(isFuture ? 0.3 : 0.9))
                }
            }
            .frame(height: 44)
        }
        .buttonStyle(.plain)
        .disabled(isFuture)
        .accessibilityLabel(day.date(calendar: calendar).formatted(date: .complete, time: .omitted))
        .accessibilityValue(isSolved ? "Solved" : "")
    }
}
