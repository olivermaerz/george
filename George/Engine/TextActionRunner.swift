import AppKit

enum TextActionRunner {
    static func run(point: CGPoint, phrase: String, pressEnter: Bool) async {
        await MouseSimulator.moveHuman(to: point)
        await MouseSimulator.click(count: 1)
        try? await Task.sleep(nanoseconds: 200_000_000)

        let pasteboard = NSPasteboard.general
        let preserved = preserve(pasteboard)
        pasteboard.clearContents()
        pasteboard.setString(phrase, forType: .string)
        try? await Task.sleep(nanoseconds: 50_000_000)

        Keyboard.paste()
        try? await Task.sleep(nanoseconds: 90_000_000)

        if pressEnter {
            Keyboard.enter()
            try? await Task.sleep(nanoseconds: 70_000_000)
        }

        restore(pasteboard, items: preserved)
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
