import SwiftUI

/// Edits one day by appending a `day` override to the log.
///
/// The recorded stamps stay in the file; they are simply superseded for that
/// date. "Revert" appends an override with no times, which removes the
/// correction and lets the recorded stamps show through again.
struct DayEditorView: View {
    @ObservedObject var model: AppModel
    let date: Date

    @Environment(\.dismiss) private var dismiss
    @State private var items: [EditableTime]
    @State private var note: String
    @State private var showBlankConfirmation = false

    private let hadOverride: Bool
    private let calendar: Calendar

    struct EditableTime: Identifiable {
        let id = UUID()
        var date: Date
    }

    init(model: AppModel, date: Date) {
        self.model = model
        self.date = date

        let calendar = model.calendar
        let day = calendar.startOfDay(for: date)
        let existing = model.overrides[day]
        let recorded = model.days
            .first { calendar.isDate($0.date, inSameDayAs: date) }?
            .stamps ?? []
        let times = existing?.times ?? recorded.map(\.timestamp)

        _items = State(initialValue: times.map { EditableTime(date: $0) })
        _note = State(initialValue: existing?.note ?? "")
        hadOverride = existing != nil
        self.calendar = calendar
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach($items) { $item in
                        HStack(spacing: 12) {
                            Text(label(for: item.date))
                                .foregroundStyle(.secondary)
                                .frame(width: 84, alignment: .leading)

                            DatePicker("", selection: $item.date, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .environment(\.locale, .current)

                            Spacer()

                            Button(role: .destructive) {
                                items.removeAll { $0.id == item.id }
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                        }
                    }

                    Button {
                        addStamp()
                    } label: {
                        Label("Add stamp", systemImage: "plus.circle")
                    }
                } header: {
                    Text("Stamps")
                } footer: {
                    Text("These times replace the recorded taps for this day. The log itself is never rewritten.")
                }

                Section("Note") {
                    TextField("Why did you edit?", text: $note, axis: .vertical)
                }

                if hadOverride {
                    Section {
                        Button("Revert to recorded stamps", role: .destructive) {
                            model.clearOverride(for: date)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(Format.longDayLabel(date))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
            .confirmationDialog(
                "Remove every stamp from this day?",
                isPresented: $showBlankConfirmation,
                titleVisibility: .visible
            ) {
                Button("Remove all stamps", role: .destructive) {
                    commit([])
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("The recorded taps stay in the log. You can bring them back with “Revert to recorded stamps”.")
            }
        }
    }

    private func label(for time: Date) -> String {
        let sorted = items.map(\.date).sorted()
        let index = sorted.firstIndex(of: time) ?? 0
        switch index {
        case 0: return "In"
        case 1: return sorted.count > 2 ? "Lunch out" : "Out"
        case 2: return "Back in"
        case 3: return "Out"
        default: return "Stamp \(index + 1)"
        }
    }

    private func addStamp() {
        if let last = items.map(\.date).max() {
            items.append(EditableTime(date: last.addingTimeInterval(3600)))
        } else if let start = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: date) {
            items.append(EditableTime(date: start))
        }
    }

    private func save() {
        let times = items.map(\.date).sorted()
        if times.isEmpty {
            showBlankConfirmation = true
            return
        }
        commit(times)
    }

    private func commit(_ times: [Date]) {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        model.setOverride(for: date, times: times, note: trimmed.isEmpty ? nil : trimmed)
        dismiss()
    }
}
