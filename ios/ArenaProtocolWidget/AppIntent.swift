import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Arena Protocol" }
    static var description: IntentDescription { "Live focus timer and arena stats." }
}
