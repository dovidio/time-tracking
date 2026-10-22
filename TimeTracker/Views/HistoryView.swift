import SwiftUI

struct HistoryView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        NavigationStack {
            List {
                Section("Balance") {
                    HStack {
                        Text("This week")
                        Spacer()
                        BalancePill(balance: model.week.balance)
                    }
                    HStack {
                        Text("This month")
                        Spacer()
                        BalancePill(balance: model.month.balance)
                    }
                }

                Section("Days") {
                    if model.history.isEmpty {
                        ContentUnavailableView(
                            "No stamps yet",
                            systemImage: "clock",
                            description: Text("Stamp from the Today tab and days will show up here.")
                        )
                    } else {
                        ForEach(model.history) { summary in
                            NavigationLink(value: summary.day.date) {
                                row(for: summary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("History")
            .navigationDestination(for: Date.self) { date in
                DayDetailView(date: date, model: model)
            }
        }
    }

    private func row(for summary: DaySummary) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(Format.dayLabel(summary.day.date))
                    .font(.subheadline.weight(.medium))
                Text(subtitle(for: summary))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if summary.day.stamps.contains(where: \.isManual) {
                Image(systemName: "pencil")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !summary.anomalies.isEmpty {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            Text(Format.duration(summary.worked))
                .font(.subheadline)
                .monospacedDigit()

            BalancePill(balance: summary.balance)
        }
        .padding(.vertical, 2)
    }

    private func subtitle(for summary: DaySummary) -> String {
        if summary.day.stamps.isEmpty {
            return model.overrides[summary.day.date] != nil ? "Cleared" : "No stamps"
        }
        return "\(summary.day.stamps.count) stamps"
    }
}

struct DayDetailView: View {
    let date: Date
    @ObservedObject var model: AppModel
    @State private var showEditor = false

    /// Recomputed from the model rather than passed in, so an edit is visible
    /// the moment the editor closes.
    private var summary: DaySummary {
        model.engine.summary(for: date, existing: model.days, now: model.now)
    }

    private var overrideNote: String? {
        model.overrides[model.calendar.startOfDay(for: date)]?.note
    }

    var body: some View {
        List {
            Section {
                HStack {
                    StatColumn(title: "Worked", value: Format.duration(summary.worked))
                    Divider().frame(height: 30)
                    StatColumn(title: "Target", value: Format.duration(summary.target))
                    Divider().frame(height: 30)
                    StatColumn(
                        title: "Balance",
                        value: Format.signedDuration(summary.balance),
                        tint: summary.balance.balanceTint
                    )
                }
                .padding(.vertical, 4)

                if summary.lunchDeduction > 0 {
                    Text("Presence \(Format.duration(summary.present)) · \(Format.duration(summary.lunchDeduction)) standard lunch")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if summary.day.stamps.isEmpty {
                Section("Stamps") {
                    Text(model.overrides[model.calendar.startOfDay(for: date)] != nil
                         ? "This day was cleared manually."
                         : "No stamps recorded.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } else {
                Section("Stamps") {
                    ForEach(summary.day.stamps) { stamp in
                        HStack {
                            Text(Format.time(stamp.timestamp))
                                .monospacedDigit()
                            if stamp.isManual {
                                Image(systemName: "pencil")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                    }
                }

                Section("Timeline") {
                    ForEach(summary.day.segments) { segment in
                        HStack(spacing: 10) {
                            Image(systemName: segment.kind == .work ? "briefcase" : "cup.and.saucer")
                                .foregroundStyle(segment.kind == .work ? .blue : .secondary)
                                .frame(width: 22)

                            Text(segment.kind == .work ? "Work" : "Break")

                            Spacer()

                            VStack(alignment: .trailing, spacing: 1) {
                                Text("\(Format.time(segment.start)) – \(segment.end.map { Format.time($0) } ?? "…")")
                                    .monospacedDigit()
                                Text(Format.duration(segment.duration ?? 0))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            if let note = overrideNote, !note.isEmpty {
                Section("Edit note") {
                    Text(note)
                        .font(.footnote)
                }
            }

            if !summary.anomalies.isEmpty {
                Section("Check") {
                    ForEach(summary.anomalies, id: \.self) { anomaly in
                        Label(anomaly.message, systemImage: "exclamationmark.triangle.fill")
                            .font(.footnote)
                            .foregroundStyle(.orange)
                    }
                }
            }
        }
        .navigationTitle(Format.longDayLabel(date))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showEditor = true
                } label: {
                    Image(systemName: "square.and.pencil")
                }
            }
        }
        .sheet(isPresented: $showEditor) {
            DayEditorView(model: model, date: date)
        }
    }
}
