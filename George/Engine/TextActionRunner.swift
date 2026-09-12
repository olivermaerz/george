import AppKit

enum TextActionRunner {
    static func run(point: CGPoint, phrase: String, pressEnter: Bool) async {
        await MouseSimulator.moveHuman(to: point)
        if Task.isCancelled { return }
        await MouseSimulator.click(count: 1)
        if await sleepCancelled(nanoseconds: 200_000_000) { return }

        let pasteboard = NSPasteboard.general
        let preserved = preserve(pasteboard)
        defer { restore(pasteboard, items: preserved) }
        pasteboard.clearContents()
        pasteboard.setString(phrase, forType: .string)
        if await sleepCancelled(nanoseconds: 50_000_000) { return }

        if Task.isCancelled { return }
        Keyboard.paste()
        if await sleepCancelled(nanoseconds: 90_000_000) { return }

        if pressEnter {
            if Task.isCancelled { return }
            Keyboard.enter()
            _ = await sleepCancelled(nanoseconds: 70_000_000)
        }
    }

    private static func sleepCancelled(nanoseconds: UInt64) async -> Bool {
        do {
            try await Task.sleep(nanoseconds: nanoseconds)
            return false
        } catch {
            return true
        }
    }

    private static func preserve(_ pasteboard: NSPasteboard) -> [NSPasteboardItem] {
        guard let items = pasteboard.pasteboardItems else { return [] }
        return items.map { item in
            let copy = NSPasteboardItem()
            for type in item.types {
                if let data = item.data(forType: type) {
                    copy.setData(data, forType: type)
                }
            }
            return copy
        }
    }

    private static func restore(_ pasteboard: NSPasteboard, items: [NSPasteboardItem]) {
        pasteboard.clearContents()
        if !items.isEmpty {
            pasteboard.writeObjects(items)
        }
    }
}
