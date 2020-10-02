//
//  KyberWidget.swift
//  KyberWidget
//
//  Created by Ta Minh Quan on 9/29/20.
//

import WidgetKit
import SwiftUI


struct Provider: TimelineProvider {
  func readContents() -> WidgetContent? {
    var contents: WidgetContent? = nil
    let archiveURL =
      FileManager.sharedContainerURL()
        .appendingPathComponent("contents.json")
    print(">>> \(archiveURL)")

    let decoder = JSONDecoder()
    if let codeData = try? Data(contentsOf: archiveURL) {
      do {
        contents = try decoder.decode(WidgetContent.self, from: codeData)
      } catch {
        print("Error: Can't decode contents")
      }
    }
    return contents
  }
  
  func placeholder(in context: Context) -> WidgetContent {
    WidgetContent(date: Date(), usdPrice: 5.0, change24h: 30.0)
  }
  
  func getSnapshot(in context: Context, completion: @escaping (WidgetContent) -> ()) {
    let entry = WidgetContent(date: Date(), usdPrice: 5.0, change24h: 30.0)
    completion(entry)
  }
  
  func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
    let entry = self.readContents()
    
    if let notNilEntry = entry {
      let timeline = Timeline(entries: [notNilEntry], policy: .atEnd)
      completion(timeline)
    }
    
  }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
}

@main
struct KyberWidget: Widget {
    let kind: String = "KyberWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
          WidgetView(entry: entry)
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
    }
}

struct KyberWidget_Previews: PreviewProvider {
    static var previews: some View {
      WidgetView(entry: WidgetContent(date: Date(), usdPrice: 5.0, change24h: 40.0))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
