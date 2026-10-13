import SwiftUI
import UIKit

// MARK: - Picture backgrounds

struct BackgroundOption: Identifiable {
    let key: String
    let name: String
    let isDark: Bool
    var id: String { key }
}

// "plain" follows the phone's light/dark mode. "asset:" images live in Assets.
// To add another picture: drag it into Assets, then add a line here with its Assets name.
let builtInBackgrounds: [BackgroundOption] = [
    BackgroundOption(key: "plain",                 name: "Auto",         isDark: false),
    BackgroundOption(key: "asset:bg-teal-velvet",  name: "Teal Velvet",  isDark: true),
    BackgroundOption(key: "asset:bg-night-mosque", name: "Night Mosque", isDark: true),
]

// MARK: - Solid color backgrounds

enum SolidBackground: String, CaseIterable, Identifiable {
    case white, cream, black, blue, green, maroon, purple, pink
    var id: String { rawValue }
    var key: String { "solid:" + rawValue }
    var name: String { rawValue.capitalized }

    var color: Color {
        switch self {
        case .white: return Color(white: 0.98)
        case .cream: return Color(red: 0.98, green: 0.95, blue: 0.88)
        default:     return ThemeColor(rawValue: rawValue)?.color ?? .white
        }
    }

    var isDark: Bool { self != .white && self != .cream }
}

// Which light/dark mode a background needs so text stays readable.
// nil = follow the user's Appearance setting.
func backgroundScheme(_ key: String) -> ColorScheme? {
    if key == "photo" { return .dark }
    if key.hasPrefix("solid:") {
        guard let solid = SolidBackground(rawValue: String(key.dropFirst(6))) else { return nil }
        return solid.isDark ? .dark : .light
    }
    if let option = builtInBackgrounds.first(where: { $0.key == key }) {
        return option.isDark ? .dark : nil
    }
    return nil
}

// MARK: - Saving the user's photo

enum PhotoStore {
    static var url: URL { URL.documentsDirectory.appending(path: "background.jpg") }

    static func save(_ image: UIImage) {
        let maxSide: CGFloat = 2000
        let scale = min(1, maxSide / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let resized = image.preparingThumbnail(of: size) ?? image
        try? resized.jpegData(compressionQuality: 0.85)?.write(to: url)
    }

    static func load() -> UIImage? {
        UIImage(contentsOfFile: url.path())
    }

    static func delete() {
        try? FileManager.default.removeItem(at: url)
    }
}

// MARK: - Background view

struct BackgroundView: View {
    var key: String
    var photo: UIImage?
    var dim: Double

    var body: some View {
        GeometryReader { g in
            content
                .frame(width: g.size.width, height: g.size.height)
                .clipped()
        }
    }

    @ViewBuilder
    private var content: some View {
        if key == "photo", let photo {
            Image(uiImage: photo)
                .resizable()
                .scaledToFill()
                .overlay(Color.black.opacity(dim))
        } else if key.hasPrefix("solid:"), let solid = SolidBackground(rawValue: String(key.dropFirst(6))) {
            solid.color
        } else if key.hasPrefix("asset:") {
            Image(String(key.dropFirst(6)))
                .resizable()
                .scaledToFill()
        } else {
            Color(.systemBackground)
        }
    }
}
