//
//  ArenaProtocolWidgetBundle.swift
//  ArenaProtocolWidget
//
//  Created by Baloo on 3/16/26.
//

import WidgetKit
import SwiftUI

@main
struct ArenaProtocolWidgetBundle: WidgetBundle {
    var body: some Widget {
        ArenaProtocolWidget()
        ArenaProtocolWidgetControl()
        ArenaProtocolWidgetLiveActivity()
    }
}
