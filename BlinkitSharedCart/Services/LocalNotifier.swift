//
//  LocalNotifier.swift
//  BlinkitSharedCart
//
//  Fires real iOS local notifications (banner + Join/Ignore actions) so the
//  guest phone visibly "gets a push" the instant the host invites — no APNs
//  or server required for the demo.
//

import Foundation
import UserNotifications

@MainActor
final class LocalNotifier: NSObject, UNUserNotificationCenterDelegate {
    static let shared = LocalNotifier()

    static let inviteCategory = "GROUP_INVITE"
    static let joinAction = "JOIN_ORDER"
    static let ignoreAction = "IGNORE_ORDER"

    /// Called when the user taps the notification / the Join action.
    var onJoinTapped: (() -> Void)?

    func configure() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self

        let join = UNNotificationAction(identifier: Self.joinAction, title: "Join Order", options: [.foreground])
        let ignore = UNNotificationAction(identifier: Self.ignoreAction, title: "Ignore", options: [.destructive])
        let category = UNNotificationCategory(identifier: Self.inviteCategory,
                                              actions: [join, ignore],
                                              intentIdentifiers: [], options: [])
        center.setNotificationCategories([category])
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            print("[Notif] authorization granted: \(granted)")
        }
    }

    func postGroupInvite(hostName: String, remaining: Double) {
        let content = UNMutableNotificationContent()
        content.title = "\(hostName) is placing a Zipp order"
        content.body = remaining > 0
            ? "Only \(rupees(remaining)) more is needed to unlock free delivery. Want to add something?"
            : "You've been invited to a shared group cart. Want to add something?"
        content.categoryIdentifier = Self.inviteCategory
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    func postSimple(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
    }

    // Show banners even while the app is in the foreground.
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            willPresent notification: UNNotification,
                                            withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .list])
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            didReceive response: UNNotificationResponse,
                                            withCompletionHandler completionHandler: @escaping () -> Void) {
        let action = response.actionIdentifier
        Task { @MainActor in
            if action == Self.joinAction || action == UNNotificationDefaultActionIdentifier {
                self.onJoinTapped?()
            }
        }
        completionHandler()
    }
}
