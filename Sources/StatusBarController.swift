import Cocoa

class StatusBarController: NSObject {
    private var statusItem: NSStatusItem!
    private var cutCountItem: NSMenuItem!
    private var cancelCutItem: NSMenuItem!
    private var undoMoveItem: NSMenuItem!
    private var launchAtLoginItem: NSMenuItem!
    private let eventTapManager = EventTapManager()
    private let loginItemManager = LoginItemManager()

    override init() {
        super.init()

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "scissors", accessibilityDescription: "CutPaste")
            button.image?.size = NSSize(width: 16, height: 16)
        }

        setupMenu()

        eventTapManager.onCutBufferChanged = { [weak self] fileCount in
            self?.updateStatus(fileCount: fileCount)
        }
        eventTapManager.onMoveHistoryChanged = { [weak self] canUndo in
            self?.updateUndoAvailability(canUndo)
        }

        eventTapManager.start()
    }

    private func setupMenu() {
        let menu = NSMenu()

        let titleItem = NSMenuItem(title: "CutPaste", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)

        menu.addItem(NSMenuItem.separator())

        cutCountItem = NSMenuItem(title: L.t("menu.no_cut"), action: nil, keyEquivalent: "")
        cutCountItem.isEnabled = false
        menu.addItem(cutCountItem)

        cancelCutItem = NSMenuItem(title: L.t("menu.cancel_cut"), action: #selector(cancelCut), keyEquivalent: "")
        cancelCutItem.target = self
        cancelCutItem.isHidden = true
        menu.addItem(cancelCutItem)

        undoMoveItem = NSMenuItem(title: L.t("menu.undo_move"), action: #selector(undoMove), keyEquivalent: "")
        undoMoveItem.target = self
        undoMoveItem.isHidden = true
        menu.addItem(undoMoveItem)

        menu.addItem(NSMenuItem.separator())

        launchAtLoginItem = NSMenuItem(title: L.t("menu.launch_login"), action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        launchAtLoginItem.target = self
        launchAtLoginItem.state = loginItemManager.isEnabled ? .on : .off
        menu.addItem(launchAtLoginItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: L.t("menu.quit"), action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    private func updateStatus(fileCount: Int) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if fileCount > 0 {
                self.statusItem.button?.image = NSImage(systemSymbolName: "scissors.badge.ellipsis", accessibilityDescription: "CutPaste - \(fileCount) file")
                self.cutCountItem.title = L.t("menu.pending_count", fileCount)
                self.cancelCutItem.isHidden = false
            } else {
                self.statusItem.button?.image = NSImage(systemSymbolName: "scissors", accessibilityDescription: "CutPaste")
                self.cutCountItem.title = L.t("menu.no_cut")
                self.cancelCutItem.isHidden = true
            }
        }
    }

    private func updateUndoAvailability(_ canUndo: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.undoMoveItem.isHidden = !canUndo
        }
    }

    @objc private func cancelCut() {
        eventTapManager.clearCutBuffer()
    }

    @objc private func undoMove() {
        eventTapManager.undoLastMove()
    }

    @objc private func toggleLaunchAtLogin() {
        let newState = !loginItemManager.isEnabled
        loginItemManager.setEnabled(newState)
        launchAtLoginItem.state = newState ? .on : .off
    }

    @objc private func quit() {
        eventTapManager.stop()
        NSApp.terminate(nil)
    }
}
