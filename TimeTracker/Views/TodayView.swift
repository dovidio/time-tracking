import SwiftUI

struct TodayView: View {
    @ObservedObject var model: AppModel
    @State private var showEditor = false

    private var summary: DaySummary { model.today }

    private var progress: Double {
        guard summary.target > 0 else { return summary.worked > 0 ? 1 : 0 }
        return summary.worked / summary.target
    }

    private var ringColor: Color {
        if summary.target == 0 { return .gray }
        return summary.balance >= 0 ? .green : .blue
    }

    private var leaveLine: some View {
        Group {
            if summary.isWorking, summary.balance >= 0 {
                Label("Target reached · \(Format.signedDuration(summary.balance))", systemImage: "checkmark.circle")
                    .foregroundStyle(.green)
            } else if let leaveAt = summary.leaveAt {
                Label("Leave at \(Format.time(leaveAt))", systemImage: "door.left.hand.open")
                    .foregroundStyle(.blue)
            } else if summary.isOut {
                Label(Format.signedDuration(summary.balance), systemImage: "pause.circle")
                    .foregroundStyle(.secondary)
            } else {
                Label("Tap to start the day", systemImage: "hand.tap")
                    .foregroundStyle(.secondary)
            }
        }
        .font(.subheadline.weight(.semibold))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    stateCard
                    stampButton
                    if let error = model.lastWriteError {
                        Card {
                            Label(error, systemImage: "exclamationmark.octagon.fill")
                                .font(.footnote)
                                .foregroundStyle(.red)
                        }
                    }
                    if model.todayOverride != nil {
                        Card {
                            HStack(spacing: 10) {
                                Image(systemName: "square.and.pencil")
                                    .foregroundStyle(.orange)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("This day is manually edited")
                                        .font(.footnote.weight(.semibold))
                                    Text("New stamps extend the corrected times.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer(minLength: 0)
                                Button("Revert") {
                                    model.clearOverride(for: model.now)
                                }
                                .font(.footnote.weight(.semibold))
                            }
                        }
                    }
                    if summary.hasStamps {
                        timelineCard
                    }
                    balancesCard
                    if !summary.anomalies.isEmpty {
                        anomalyCard
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
                .padding(.top, 4)
            }
            .background(Color(.systemGroupedBackground))
            .onAppear {
                model.now = .now
                model.reload()
            }
            .navigationTitle("Today")
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
                DayEditorView(model: model, date: model.now)
            }
        }
    }

    private var stateCard: some View {
        Card {
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(Format.longDayLabel(Date()))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(model.stateTitle)
                        .font(.subheadline.weight(.medium))

                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(Format.duration(summary.worked))
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .monospacedDigit()
                        Text("/ \(Format.duration(summary.target))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    leaveLine

                    if summary.lunchDeduction > 0 {
                        Text("Presence \(Format.duration(summary.present)) · \(Format.duration(summary.lunchDeduction)) standard lunch")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 0)

                ProgressRing(progress: progress, color: ringColor)
                    .frame(width: 74, height: 74)
                    .overlay(
                        Text("\(Int(min(max(progress, 0), 1) * 100))%")
                            .font(.caption2.weight(.semibold))
                            .monospacedDigit()
                    )
            }
        }
    }

    private var stampButton: some View {
        VStack(spacing: 10) {
            Button {
                model.stamp()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: model.buttonIcon)
                        .font(.headline.weight(.bold))
                    Text(model.nextActionTitle)
                        .font(.headline.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .foregroundStyle(.white)
                .background(
                    (summary.isWorking ? Color.orange : Color.blue),
                    in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                )
                .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .buttonStyle(.plain)

        }
    }

    private var timelineCard: some View {
        Card {
            VStack(spacing: 0) {
                ForEach(Array(summary.day.stamps.enumerated()), id: \.element.id) { index, stamp in
                    HStack(spacing: 8) {
                        Text(label(for: index))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(width: 84, alignment: .leading)

                        Spacer()

                        Text(Format.time(stamp.timestamp))
                            .font(.body.weight(.medium))
                            .monospacedDigit()
                    }
                    .padding(.vertical, 9)

                    if index < summary.day.stamps.count - 1 {
                        Divider()
                    }
                }
            }
        }
    }

    private var balancesCard: some View {
        Card {
            HStack {
                StatColumn(
                    title: "Today",
                    value: Format.signedDuration(summary.balance),
                    tint: summary.balance.balanceTint
                )
                Divider().frame(height: 30)
                StatColumn(
                    title: "Week",
                    value: Format.signedDuration(model.week.balance),
                    tint: model.week.balance.balanceTint
                )
                Divider().frame(height: 30)
                StatColumn(
                    title: "Month",
                    value: Format.signedDuration(model.month.balance),
                    tint: model.month.balance.balanceTint
                )
            }
        }
    }

    private var anomalyCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(summary.anomalies, id: \.self) { anomaly in
                    Label(anomaly.message, systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                }
            }
        }
    }

    private func label(for index: Int) -> String {
        let count = summary.day.stamps.count
        switch index {
        case 0:
            return "In"
        case 1:
            return count > 2 ? "Lunch out" : "Out"
        case 2:
            return "Back in"
        case 3:
            return "Out"
        default:
            return "Stamp \(index + 1)"
        }
    }
}
