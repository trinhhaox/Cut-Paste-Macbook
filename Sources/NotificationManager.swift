import Cocoa
import UserNotifications

// Non-intrusive banner notifications (UNUserNotificationCenter) with sound feedback.
// Falls back to a modal NSAlert only for errors when banners aren't authorized.
final class NotificationManager {
    static let shared = NotificationManager()

    private var authorized = false

    // UNUserNotificationCenter crashes for a bare executable with no bundle identifier.
    // Guard against that so the app still runs if launched outside a proper .app bundle.
    private var center: UNUserNotificationCenter? {
        guard Bundle.main.bundleIdentifier != nil else { return nil }
        return UNUserNotificationCenter.current()
    }

    func requestAuthorization() {
        center?.requestAuthorization(options: [.alert, .sound]) { [weak self] granted, _ in
            self?.authorized = granted
        }
    }

    // Best-effort success banner (cut / paste / undo).
    func notify(title: String, body: String) {
        guard let center = center else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        center.add(request) { error in
            if let error = error {
                NSLog("CutPaste notification error: \(error)")
            }
        }
    }

    // Errors must be seen: banner if authorized, otherwise a modal alert.
    func notifyError(title: String, body: String) {
        if authorized {
            notify(title: title, body: body)
        } else {
            DispatchQueue.main.async {
                NSApp.activate(ignoringOtherApps: true)
                let alert = NSAlert()
                alert.messageText = title
                alert.informativeText = body
                alert.alertStyle = .warning
                alert.runModal()
            }
        }
    }

    // System sound feedback for cut / paste / undo actions.
    func playSound(_ name: String) {
        NSSound(named: NSSound.Name(name))?.play()
    }
}
