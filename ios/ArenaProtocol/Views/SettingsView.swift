// SettingsView.swift — Arena Protocol
// Wind-down time, habit management, arena management, calendar, clock timezone

import SwiftUI
import UserNotifications
import EventKit

struct SettingsView: View {
    @Environment(DataStore.self) private var store
    var navigate: (Screen) -> Void

    @State private var calStatus: EKAuthorizationStatus = EKEventStore.authorizationStatus(for: .event)

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

                    // Clock Timezone
                    VStack(alignment: .leading, spacing: 12) {
                        Text("CLOCK TIMEZONE")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.22))
                            .kerning(5)
                        Text("End time shown on every active timer")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.white.opacity(0.3))
                        Picker("", selection: Binding(
                            get: { store.settings.clockTimezone },
                            set: { store.settings.clockTimezone = $0; store.saveSettings() }
                        )) {
                            ForEach(CLOCK_TIMEZONES) { tz in
                                Text(tz.label).tag(tz.id)
                            }
                        }
                        .pickerStyle(.segmented)
                        .colorScheme(.dark)
                    }
                    .padding(16)
                    .background(Color.white.opacity(0.02))
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.white.opacity(0.07), lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    // Calendar
                    VStack(alignment: .leading, spacing: 12) {
                        Text("CALENDAR")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.22))
                            .kerning(5)
                        Text("Write focus blocks to an \"Arena Protocol\" calendar in your Calendar app (syncs to Google Calendar if connected)")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.white.opacity(0.3))
                            .lineSpacing(3)

                        if calStatus == .fullAccess {
                            HStack(spacing: 10) {
                                Circle().fill(Color(hex: "#34D399")).frame(width: 8, height: 8)
                                Text("FULL ACCESS — write + calendar feed active")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundStyle(Color(hex: "#34D399").opacity(0.8))
                                    .kerning(1)
                            }
                        } else if calStatus == .writeOnly {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 10) {
                                    Circle().fill(Color(hex: "#E8C547")).frame(width: 8, height: 8)
                                    Text("WRITE ONLY — sessions logged, feed disabled")
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundStyle(Color(hex: "#E8C547").opacity(0.8))
                                        .kerning(1)
                                }
                                Button {
                                    Task {
                                        _ = await CalendarManager.shared.requestFullAccess()
                                        calStatus = EKEventStore.authorizationStatus(for: .event)
                                        store.settings.calendarEnabled = true
                                        store.saveSettings()
                                    }
                                } label: {
                                    Text("UPGRADE TO FULL ACCESS (ENABLES FEED)")
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .foregroundStyle(Color(hex: "#080810"))
                                        .kerning(2)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color(hex: "#60A5FA"))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                                .buttonStyle(.plain)
                            }
                        } else if calStatus == .denied || calStatus == .restricted {
                            HStack(spacing: 10) {
                                Circle().fill(Color.red.opacity(0.7)).frame(width: 8, height: 8)
                                Text("PERMISSION DENIED — enable in iOS Settings → Privacy → Calendars")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundStyle(Color.red.opacity(0.6))
                                    .kerning(1)
                            }
                        } else {
                            Button {
                                Task {
                                    let granted = await CalendarManager.shared.requestFullAccess()
                                    calStatus = EKEventStore.authorizationStatus(for: .event)
                                    if granted {
                                        store.settings.calendarEnabled = true
                                        store.saveSettings()
                                    }
                                }
                            } label: {
                                Text("GRANT CALENDAR ACCESS")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundStyle(Color(hex: "#080810"))
                                    .kerning(3)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color(hex: "#60A5FA"))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                    .background(Color.white.opacity(0.02))
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color(hex: "#60A5FA").opacity(0.2), lineWidth: 1))
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
