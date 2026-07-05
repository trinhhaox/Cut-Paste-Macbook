import Cocoa

class StatusBarController: NSObject {
    private var statusItem: NSStatusItem!
    private var cutCountItem: NSMenuItem!
    private var cancelCutItem: NSMenuItem!
    private var undoMoveItem: NSMenuItem!
    private var launchAtLoginItem: NSMenuItem!
    private let eventTapManager = EventTapManager()
    private let loginItemManager = LoginItemManager()

    // Current state, kept so the menu can be rebuilt (e.g. on language change).
    private var currentFileCount = 0
    private var canUndo = false

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

        NotificationCenter.default.addObserver(
            self, selector: #selector(rebuildMenu),
            name: L.languageChanged, object: nil
        )

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

        menu.addItem(makeLanguageMenuItem())

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: L.t("menu.quit"), action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
        applyCurrentState()
    }

    private func makeLanguageMenuItem() -> NSMenuItem {
        let languageItem = NSMenuItem(title: L.t("menu.language"), action: nil, keyEquivalent: "")
        let submenu = NSMenu()
        for lang in AppLanguage.allCases {
            let item = NSMenuItem(title: lang.displayName, action: #selector(changeLanguage(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = lang.rawValue
            item.state = (L.current == lang) ? .on : .off
            submenu.addItem(item)
        }
        languageItem.submenu = submenu
        return languageItem
    }

    // Re-applies dynamic state (cut count, undo visibility) after a rebuild.
    private func applyCurrentState() {
        if currentFileCount > 0 {
            cutCountItem.title = L.t("menu.pending_count", currentFileCount)
            cancelCutItem.isHidden = false
        } else {
            cutCountItem.title = L.t("menu.no_cut")
            cancelCutItem.isHidden = true
        }
        undoMoveItem.isHidden = !canUndo
    }

    @objc private func rebuildMenu() {
        DispatchQueue.main.async { [weak self] in
            self?.setupMenu()
        }
    }

    private func updateStatus(fileCount: Int) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.currentFileCount = fileCount
            if fileCount > 0 {
                self.statusItem.button?.image = NSImage(systemSymbolName: "scissors.badge.ellipsis", accessibilityDescription: "CutPaste - \(fileCount) file")
            } else {
                self.statusItem.button?.image = NSImage(systemSymbolName: "scissors", accessibilityDescription: "CutPaste")
            }
            self.applyCurrentState()
        }
    }

    private func updateUndoAvailability(_ canUndo: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.canUndo = canUndo
            self.undoMoveItem.isHidden = !canUndo
        }
    }

    @objc private func changeLanguage(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let lang = AppLanguage(rawValue: raw) else { return }
        L.current = lang
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
