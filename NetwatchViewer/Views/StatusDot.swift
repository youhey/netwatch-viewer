//
//  StatusDot.swift
//  NetwatchViewer
//
//  Created by Codex on 2026/06/06.
//

import SwiftUI

struct StatusDot: View {
    let ok: Bool

    var body: some View {
        Image(ok ? "status-ok" : "status-critical")
            .resizable()
            .frame(width: 10, height: 10)
            .accessibilityLabel(ok ? "OK" : "Error")
    }
}
