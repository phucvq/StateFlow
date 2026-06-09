import WidgetKit
import SwiftUI

// Widget Extension deployment target is iOS 16.2+, so no #available guard needed.
@main
struct FlowStateWidgetsBundle: WidgetBundle {
    var body: some Widget {
        FlowStateWidget()
        FlowStateLiveActivityWidget()
    }
}
