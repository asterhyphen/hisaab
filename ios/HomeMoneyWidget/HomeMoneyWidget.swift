import WidgetKit
import SwiftUI

struct MoneyEntry: TimelineEntry {
  let date: Date
}

struct MoneyProvider: TimelineProvider {
  func placeholder(in context: Context) -> MoneyEntry {
    MoneyEntry(date: Date())
  }

  func getSnapshot(in context: Context, completion: @escaping (MoneyEntry) -> Void) {
    completion(MoneyEntry(date: Date()))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<MoneyEntry>) -> Void) {
    let entry = MoneyEntry(date: Date())
    let timeline = Timeline(entries: [entry], policy: .never)
    completion(timeline)
  }
}

struct HomeMoneyWidgetView: View {
  var entry: MoneyProvider.Entry

  var body: some View {
    VStack(spacing: 10) {
      Text("Hisaab")
        .font(.headline)
      HStack(spacing: 8) {
        Link(destination: URL(string: "hisaab://txn/add")!) {
          Text("+")
            .font(.system(size: 22, weight: .bold))
            .frame(maxWidth: .infinity, minHeight: 40)
            .foregroundColor(.black)
            .background(Color.green)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        Link(destination: URL(string: "hisaab://txn/subtract")!) {
          Text("-")
            .font(.system(size: 22, weight: .bold))
            .frame(maxWidth: .infinity, minHeight: 40)
            .foregroundColor(.black)
            .background(Color.red)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
      }
    }
    .padding(12)
    .containerBackground(.fill.tertiary, for: .widget)
  }
}

struct HomeMoneyWidget: Widget {
  let kind: String = "HomeMoneyWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: MoneyProvider()) { entry in
      HomeMoneyWidgetView(entry: entry)
    }
    .configurationDisplayName("Hisaab Actions")
    .description("Quickly add or remove money from the homescreen.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

