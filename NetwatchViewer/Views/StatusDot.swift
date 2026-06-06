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
        Circle()
            .fill(ok ? Color.green : Color.red)
            .frame(width: 8, height: 8)
            .accessibilityLabel(ok ? "OK" : "Error")
    }
}
