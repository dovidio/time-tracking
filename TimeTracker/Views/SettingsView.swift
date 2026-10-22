import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: AppModel
    @State private var holidayDate = Date()
    @State private var holidayName = ""

    private let weekdays: [(label: String, tag: Int)] = [
        ("Monday", 2), ("Tuesday", 3), ("Wednesday", 4), ("Thursday", 5),
        ("Friday", 6), ("Saturday", 7), ("Sunday", 1)
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Stepper(value: $model.config.weeklyHours, in: 0...60, step: 0.5) {
                        HStack {
                            Text("Weekly hours")
                            Spacer()
                            Text(String(format: "%.1f h", model.config.weeklyHours))
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                    }
                    ForEach(weekdays, id: \.tag) { day in
                        Toggle(day.label, isOn: binding(for: day.tag))
                    }
                } header: {
                    Text("Contract")
                } footer: {
                    Text("The daily target is the weekly hours divided by the working days.")
                }

                Section {
                    Picker("Round punches", selection: $model.config.roundingMinutes) {
                        Text("Off").tag(0)
                        Text("5 minutes").tag(5)
                        Text("10 minutes").tag(10)
                        Text("15 minutes").tag(15)
                        Text("30 minutes").tag(30)
                    }
                } header: {
                    Text("Rounding")
                } footer: {
                    Text("Some terminals store rounded punches. Turning this on makes your numbers match theirs more closely.")
                }

                Section {
                    Picker("Standard lunch", selection: $model.config.standardLunchMinutes) {
                        Text("None").tag(0)
                        Text("30 minutes").tag(30)
                        Text("45 minutes").tag(45)
                        Text("60 minutes").tag(60)
                        Text("90 minutes").tag(90)
                    }
                } header: {
                    Text("Lunch")
                } footer: {
                    Text("Deducted on working days where you recorded no break. If you stamp out and back in, the actual break is used instead.")
                }

                Section {
                    ForEach(Array(model.config.holidays.keys).sorted(), id: \.self) { key in
                        HStack {
                            Text(key)
                                .monospacedDigit()
                            Spacer()
                            Text(model.config.holidays[key] ?? "")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .onDelete { indexSet in
                        let keys = Array(model.config.holidays.keys).sorted()
                        for index in indexSet where keys.indices.contains(index) {
                            model.removeHoliday(keys[index])
                        }
                    }

                    HStack {
                        DatePicker("", selection: $holidayDate, displayedComponents: .date)
                            .labelsHidden()
                        TextField("Name", text: $holidayName)
                        Button("Add") {
                            model.addHoliday(holidayDate, name: holidayName)
                            holidayName = ""
                        }
                        .disabled(holidayName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                } header: {
                    Text("Holidays")
                } footer: {
                    Text("Holidays carry a zero target, so they never count as missing hours.")
                }

                Section {
                    ShareLink(item: model.logURL) {
                        Label("Export taps.log", systemImage: "square.and.arrow.up")
                    }
                    Button("Reset tracking start") {
                        model.resetTrackingStart()
                    }
                } header: {
                    Text("Data")
                } footer: {
                    Text("The log is visible in Files → On My iPhone → TimeTracker. It is append-only; nothing is ever rewritten or deleted.")
                }

                Section("About") {
                    LabeledContent("Log entries", value: "\(model.entries.count)")
                    LabeledContent("Tracking since", value: model.config.trackingStart.map { Format.dayLabel($0) } ?? "—")
                    LabeledContent("Version", value: appVersion)
                }
            }
            .navigationTitle("Settings")
            .onChange(of: model.config) { _, _ in
                model.saveConfig()
            }
        }
    }

    private func binding(for tag: Int) -> Binding<Bool> {
        Binding(
            get: { model.config.workdays.contains(tag) },
            set: { isOn in
                if isOn {
                    model.config.workdays.insert(tag)
                } else {
                    model.config.workdays.remove(tag)
                }
                model.saveConfig()
            }
        )
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(version) (\(build))"
    }
}
