import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct TrayView: View {
    @ObservedObject var trayManager: TrayManager

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Tray").font(.headline)
                Spacer()
                Button("Clear", action: trayManager.clear)
                    .disabled(trayManager.items.isEmpty)
                    .accessibilityLabel("Clear tray")
                    .accessibilityHint("Removes all \(trayManager.items.count) items")
            }
            .padding()

            if trayManager.items.isEmpty {
                Spacer()
                Text("Drag files onto the tray tab to hold them here.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                Spacer()
            } else {
                List {
                    ForEach(trayManager.items) { item in
                        TrayRow(item: item, onRemove: { trayManager.remove(item) })
                            .onDrag { NSItemProvider(contentsOf: item.url) ?? NSItemProvider() }
                    }
                }
                .listStyle(.plain)
            }
        }
        .frame(width: 280, height: 360)
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            for provider in providers {
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    guard let url else { return }
                    Task { @MainActor in trayManager.add([url]) }
                }
            }
            return true
        }
    }
}

private struct TrayRow: View {
    let item: TrayItem
    let onRemove: () -> Void

    var body: some View {
        HStack {
            Image(nsImage: NSWorkspace.shared.icon(forFile: item.url.path))
                .resizable().frame(width: 28, height: 28)
            VStack(alignment: .leading) {
                Text(item.displayName).lineLimit(1)
                Text(sizeString).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove \(item.displayName) from tray")
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { NSWorkspace.shared.open(item.url) }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.displayName), \(sizeString)")
        .accessibilityHint("Double-tap to open. Swipe or drag to remove.")
    }

    private var sizeString: String {
        guard let bytes = item.byteSize else { return "—" }
        return ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}
