// SettingsView.swift — Arena Protocol
// Wind-down time, habit management, arena management

import SwiftUI
import UserNotifications

struct SettingsView: View {
    @Environment(DataStore.self) private var store
    var navigate: (Screen) -> Void

    @State private var windDownTime: Date = {
        let parts = (UserDefaults.standard.string(forKey: "arena_settings")
            .flatMap { try? JSONDecoder().decode(AppSettings.self, from: $0.data(using: .utf8)!) }?.windDownTime ?? "21:30").split(separator: ":")
        var cal = Calendar.current
        var comps = cal.dateComponents([.year, .month, .day], from: Date())
        comps.hour   = Int(parts.first ?? "21")
        comps.minute = Int(parts.last  ?? "30")
        return cal.date(from: comps) ?? Date()
    }()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                Button { navigate(.home) } label: {
                    Text("← BACK")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.35))
                        .kerning(4)
                }
                .buttonStyle(.plain)
                .padding(.top, 52)
                .padding(.bottom, 28)

                Text("CONFIGURE")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.25))
                    .kerning(7)
                    .padding(.bottom, 4)
                Text("SETTINGS")
                    .font(.system(size: 26, weight: .bold, design: .monospaced))
                    .kerning(2)
                    .padding(.bottom, 28)

                VStack(spacing: 16) {
                    // Wind-down time
                    VStack(alignment: .leading, spacing: 12) {
                        Text("WIND-DOWN TIME")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.22))
                            .kerning(5)
                        Text("Daily notification to begin your wind-down ritual")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.white.opacity(0.3))

                        DatePicker("", selection: $windDownTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .colorScheme(.dark)
                            .frame(height: 100)
                            .clipped()
                            .onChange(of: windDownTime) { _, newVal in
                                let fmt = DateFormatter(); fmt.dateFormat = "HH:mm"
                                store.settings.windDownTime = fmt.string(from: newVal)
                                store.saveSettings()
                                scheduleWindDownNotification()
                            }
                    }
                    .padding(16)
                    .background(Color.white.opacity(0.02))
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.white.opacity(0.07), lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    // Manage Habits
                    Button { navigate(.habits) } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("MANAGE HABITS")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundStyle(Color(hex: "#B794F4"))
                                    .kerning(2)
                                Text("Track what matters daily")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color.white.opacity(0.3))
                            }
                            Spacer()
                            Text("›").font(.system(size: 18)).foregroundStyle(Color.white.opacity(0.2))
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.02))
                        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color(hex: "#B794F4").opacity(0.2), lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)

                    // Manage Arenas
                    Button { navigate(.arenaEditor) } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("MANAGE ARENAS")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundStyle(Color(hex: "#E8C547"))
                                    .kerning(2)
                                Text("Add, edit, or remove your life pillars")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color.white.opacity(0.3))
                            }
                            Spacer()
                            Text("›").font(.system(size: 18)).foregroundStyle(Color.white.opacity(0.2))
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.02))
                        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color(hex: "#E8C547").opacity(0.2), lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 32)
            }
            .padding(.horizontal, 22)
        }
    }

    private func scheduleWindDownNotification() {
        let parts = store.settings.windDownTime.split(separator: ":")
        guard let hour = Int(parts.first ?? ""), let min = Int(parts.last ?? "") else { return }
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["winddown_daily"])
        let content = UNMutableNotificationContent()
        content.title = "Wind Down"
        content.body  = "Time to close the day. Open Arena Protocol."
        content.sound = .default
        var comps = DateComponents(); comps.hour = hour; comps.minute = min
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        center.add(UNNotificationRequest(identifier: "winddown_daily", content: content, trigger: trigger))
    }
}
