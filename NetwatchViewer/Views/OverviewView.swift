//
//  OverviewView.swift
//  NetwatchViewer
//
//  Created by Codex on 2026/06/06.
//

import SwiftUI

struct OverviewView: View {
    let latest: LatestResponse?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let latest {
                PingSectionView(samples: latest.ping)
                DNSSectionView(samples: latest.dns)
                HTTPSectionView(samples: latest.http)
                DownloadSectionView(samples: latest.download)
            } else {
                Text("No latest data loaded.")
                    .foregroundStyle(.secondary)
            }
        }
    }
}
