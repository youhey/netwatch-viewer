//
//  AlertController.swift
//  NetwatchViewer
//
//  Created by Codex on 2026/06/07.
//

import Combine
import Foundation

struct AlertState: Codable, Equatable {
    var lastObservedStatusId: String? = nil
    var lastObservedLevel: MonitoringLevel? = nil
    var lastNotifiedStatusId: String? = nil
    var lastNotifiedAt: Date? = nil
    var acknowledgedStatusId: String? = nil
    var mutedUntil: Date? = nil
}

@MainActor
final class AlertController: ObservableObject {
    nonisolated static let defaultStorageKey = "netwatch.alertState"

    @Published private(set) var state: AlertState

    private let userDefaults: UserDefaults
    private let storageKey: String
    private let criticalRepeatInterval: TimeInterval

    init(
        userDefaults: UserDefaults = .standard,
        storageKey: String = AlertController.defaultStorageKey,
        criticalRepeatInterval: TimeInterval = 30 * 60
    ) {
        self.userDefaults = userDefaults
        self.storageKey = storageKey
        self.criticalRepeatInterval = criticalRepeatInterval
        state = Self.loadState(userDefaults: userDefaults, storageKey: storageKey)
    }

    func shouldNotify(status: MonitoringStatus, now: Date = Date()) -> Bool {
        guard status.alert else {
            return false
        }

        guard status.level == .warning || status.level == .critical else {
            return false
        }

        if isMuted(now: now) {
            return false
        }

        if let statusId = status.statusId, state.acknowledgedStatusId == statusId {
            return false
        }

        if let statusId = status.statusId {
            if state.lastNotifiedStatusId != statusId {
                return true
            }

            return shouldRepeatCritical(status: status, now: now)
        }

        return state.lastObservedLevel != status.level
    }

    func recordNotification(status: MonitoringStatus, now: Date = Date()) {
        state.lastNotifiedStatusId = status.statusId
        state.lastNotifiedAt = now
        recordObserved(status, saveImmediately: false)
        save()
    }

    func recordObserved(_ status: MonitoringStatus) {
        recordObserved(status, saveImmediately: true)
    }

    func acknowledge(status: MonitoringStatus) {
        guard status.alert, status.level == .warning || status.level == .critical, let statusId = status.statusId else {
            return
        }

        state.acknowledgedStatusId = statusId
        save()
    }

    func mute(for interval: TimeInterval = 60 * 60, now: Date = Date()) {
        state.mutedUntil = now.addingTimeInterval(interval)
        save()
    }

    func unmute() {
        state.mutedUntil = nil
        save()
    }

    func isAcknowledged(status: MonitoringStatus?) -> Bool {
        guard let statusId = status?.statusId else {
            return false
        }

        return state.acknowledgedStatusId == statusId
    }

    func isMuted(now: Date = Date()) -> Bool {
        guard let mutedUntil = state.mutedUntil else {
            return false
        }

        return mutedUntil > now
    }

    private func shouldRepeatCritical(status: MonitoringStatus, now: Date) -> Bool {
        guard status.level == .critical else {
            return false
        }

        guard let lastNotifiedAt = state.lastNotifiedAt else {
            return true
        }

        return now.timeIntervalSince(lastNotifiedAt) >= criticalRepeatInterval
    }

    private func recordObserved(_ status: MonitoringStatus, saveImmediately: Bool) {
        if status.level == .ok {
            state.acknowledgedStatusId = nil
        }

        state.lastObservedStatusId = status.statusId
        state.lastObservedLevel = status.level

        if saveImmediately {
            save()
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(state)
            userDefaults.set(data, forKey: storageKey)
        } catch {
            userDefaults.removeObject(forKey: storageKey)
        }
    }

    private static func loadState(userDefaults: UserDefaults, storageKey: String) -> AlertState {
        guard let data = userDefaults.data(forKey: storageKey) else {
            return AlertState()
        }

        do {
            return try JSONDecoder().decode(AlertState.self, from: data)
        } catch {
            userDefaults.removeObject(forKey: storageKey)
            return AlertState()
        }
    }
}
