// Copyright SIX DAY LLC. All rights reserved.

import SwiftUI
import WidgetKit


struct LineView: View {
    var data: [(Double)]
  var height: CGFloat

  public init(data: [Double], height: CGFloat) {
        self.data = data
    self.height = height
    }
    
    public var body: some View {
        GeometryReader{ geometry in
            VStack(alignment: .leading, spacing: 8) {
                ZStack{
                    GeometryReader{ reader in
                        Line(data: self.data,
                             frame: .constant(CGRect(x: 0, y: 0, width: reader.frame(in: .local).width , height: reader.frame(in: .local).height))
                        )
                            .offset(x: 0, y: 0)
                    }
                    .frame(width: geometry.frame(in: .local).size.width, height: self.height)
                    .offset(x: 0, y: -100)

                }
                .frame(width: geometry.frame(in: .local).size.width, height: self.height)
        
            }
        }
    }
}

struct Line: View {
    var data: [(Double)]
    @Binding var frame: CGRect

    let padding:CGFloat = 30
    
    var stepWidth: CGFloat {
        if data.count < 2 {
            return 0
        }
        return frame.size.width / CGFloat(data.count-1)
    }
    var stepHeight: CGFloat {
        var min: Double?
        var max: Double?
        let points = self.data
        if let minPoint = points.min(), let maxPoint = points.max(), minPoint != maxPoint {
            min = minPoint
            max = maxPoint
        }else {
            return 0
        }
        if let min = min, let max = max, min != max {
            if (min <= 0){
                return (frame.size.height-padding) / CGFloat(max - min)
            }else{
                return (frame.size.height-padding) / CGFloat(max + min)
            }
        }
        
        return 0
    }
    var path: Path {
        let points = self.data
        return Path.lineChart(points: points, step: CGPoint(x: stepWidth, y: stepHeight))
    }
    
    public var body: some View {
        
        ZStack {
            self.path
                .stroke(Color.green ,style: StrokeStyle(lineWidth: 3, lineJoin: .round))
                .rotationEffect(.degrees(180), anchor: .center)
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                .drawingGroup()
        }
    }
}

extension Path {
    static func lineChart(points:[Double], step:CGPoint) -> Path {
        var path = Path()
        if (points.count < 2){
            return path
        }
        guard let offset = points.min() else { return path }
        let p1 = CGPoint(x: 0, y: CGFloat(points[0]-offset)*step.y)
        path.move(to: p1)
        for pointIndex in 1..<points.count {
            let p2 = CGPoint(x: step.x * CGFloat(pointIndex), y: step.y*CGFloat(points[pointIndex]-offset))
            path.addLine(to: p2)
        }
        return path
    }
}

struct WidgetView: View {
  var entry: WidgetContent
  
  var body: some View {
    VStack(alignment: .leading) {
      HStack(alignment: .center) {
        Image("knc")
          .resizable()
          .frame(width: 40, height: 40)
          .alignmentGuide(VerticalAlignment.center) { d in d[VerticalAlignment.center] + 4 }
        VStack(alignment: .leading) {
          Text("KNC")
            .font(.title)
            .offset(x: 0, y: -3)
          Text("$\(entry.usdPrice, specifier: "%.4f")").font(.subheadline)
        }
        Text("24H CHANGE")
          .font(.subheadline)
        Text("\(entry.change24h, specifier: "%.2f")%").font(.system(size: 13))
        
      }
      LineView(data: [8,23,54,32,12,37,7,23,43,32,12,37,7,23,43,32,12,37,7,23,43,180], height: 100)
        .padding(EdgeInsets(top: 60, leading: 0, bottom: 0, trailing: 0))
        
    }
    .background(Color.orange)
  }
}

