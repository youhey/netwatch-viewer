//
//  StatusHistory.swift
//  NetwatchViewer
//
//  Created by Codex on 2026/06/07.
//

import Foundation

struct ObservedStatusPoint: Identifiable, Codable {
    let id: UUID
    let observedAt: Date
    let level: MonitoringLevel
    let statusId: String?

    init(id: UUID = UUID(), observedAt: Date, level: MonitoringLevel, statusId: String?) {
        self.id = id
        self.observedAt = observedAt
        self.level = level
        self.statusId = statusId
    }
}

struct StatusHistoryBucket: Identifiable {
    var id: Date { start }

    let start: Date
    let end: Date
    let level: MonitoringLevel
}

enum StatusHistorySource: Equatable {
    case api
    case observed
    case unavailable
}

struct StatusHistoryStore {
    private static let lookback: TimeInterval = 24 * 60 * 60

    private let storage: UserDefaults
    private let storageKey: String
    private var points: [ObservedStatusPoint]

    init(storage: UserDefaults = .standard, storageKey: String = "netwatch.statusHistory") {
        self.storage = storage
        self.storageKey = storageKey
        points = Self.loadPoints(storage: storage, storageKey: storageKey)
    }

    var hasPoints: Bool {
        !points.isEmpty
    }

    mutating func record(status: MonitoringStatus, observedAt: Date = Date()) -> [StatusHistoryBucket] {
        points.append(
            ObservedStatusPoint(
                observedAt: observedAt,
                level: status.level,
                statusId: status.statusId
            )
        )
        prune(now: observedAt)
        save()
        return buckets(now: observedAt)
    }

    mutating func buckets(now: Date = Date()) -> [StatusHistoryBucket] {
        prune(now: now)
        return Self.makeBuckets(points: points, now: now)
    }

    private mutating func prune(now: Date) {
        let cutoff = now.addingTimeInterval(-Self.lookback)
        points.removeAll { $0.observedAt < cutoff }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(points) else {
            return
        }

        storage.set(data, forKey: storageKey)
    }

    private static func loadPoints(storage: UserDefaults, storageKey: String) -> [ObservedStatusPoint] {
        guard let data = storage.data(forKey: storageKey),
              let points = try? JSONDecoder().decode([ObservedStatusPoint].self, from: data)
        else {
            return []
        }

        return points
    }

    private static func makeBuckets(points: [ObservedStatusPoint], now: Date) -> [StatusHistoryBucket] {
        let calendar = Calendar.current
        let currentHourStart = calendar.dateInterval(of: .hour, for: now)?.start ?? now

        return (0..<24).map { offset in
            let start = calendar.date(byAdding: .hour, value: offset - 23, to: currentHourStart) ?? currentHourStart
            let end = calendar.date(byAdding: .hour, value: 1, to: start) ?? start.addingTimeInterval(60 * 60)
            let bucketPoints = points.filter { point in
                point.observedAt >= start && point.observedAt < end
            }

            return StatusHistoryBucket(start: start, end: end, level: bucketLevel(for: bucketPoints))
        }
    }

    private static func bucketLevel(for points: [ObservedStatusPoint]) -> MonitoringLevel {
        guard let level = points.map(\.level).min(by: { lhs, rhs in
            lhs.sortPriority < rhs.sortPriority
        }) else {
            return .unknown
        }

        return level
    }
}

extension MonitoringStatusHistoryResponse {
    var historyBuckets: [StatusHistoryBucket] {
        points
            .sorted { $0.bucketStart < $1.bucketStart }
            .map { point in
                StatusHistoryBucket(
                    start: point.bucketStart,
                    end: point.bucketEnd ?? point.bucketStart.addingTimeInterval(TimeInterval(bucketSeconds ?? 3600)),
                    level: point.level
                )
            }
    }
}
