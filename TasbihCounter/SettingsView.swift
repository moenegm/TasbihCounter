import SwiftUI
import PhotosUI

struct SettingsView: View {
    @Bindable var store: TasbihStore
    @Environment(\.dismiss) private var dismiss

    @AppStorage("counterStyle") private var counterStyle: CounterStyle = .button
    @AppStorage("themeColor") private var themeColor: ThemeColor = .black
    @AppStorage("buttonIcon") private var buttonIcon = "hand.tap.fill"
    @AppStorage("appearance") private var appearance: Appearance = .system
    @AppStorage("showLabels") private var showLabels = true
    @AppStorage("buttonX") private var buttonX = 0.5
    @AppStorage("buttonY") private var buttonY = 0.6
    @AppStorage("buttonSize") private var buttonSize = 200.0
    @AppStorage("background") private var background = "plain"
    @AppStorage("photoDim") private var photoDim = 0.35
    @AppStorage("photoVersion") private var photoVersion = 0

    @State private var showPresets = false
    @State private var pickerItem: PhotosPickerItem?
    @State private var photo: UIImage?
    private let columns = Array(repeating: GridItem(.flexible()), count: 4)

    // The clicker only comes in colors that have an image
    private var availableColors: [ThemeColor] {
        counterStyle == .clicker ? ThemeColor.allCases.filter(\.hasClicker) : ThemeColor.allCases
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Presets
                Section("Presets") {
                    Button {
                        showPresets = true
                    } label: {
                        Label("Edit presets", systemImage: "pencil")
                    }
                }

                // MARK: Counter
                Section("Counter") {
                    Picker("Style", selection: $counterStyle) {
                        ForEach(CounterStyle.allCases) { Text($0.name).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Color")
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(availableColors) { theme in
                                Circle()
                                    .fill(theme.color)
                                    .frame(width: 44, height: 44)
                                    .overlay(Circle().strokeBorder(Color.secondary.opacity(0.3), lineWidth: 1))
                                    .overlay {
                                        if theme == themeColor {
                                            Image(systemName: "checkmark")
                                                .font(.headline)
                                                .foregroundStyle(theme.foreground)
                                        }
                                    }
                                    .onTapGesture { themeColor = theme }
                                    .accessibilityLabel(theme.name)
                            }
                        }
                    }
                    .padding(.vertical, 4)

                    if counterStyle == .button {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Icon")
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(buttonIcons, id: \.self) { icon in
                                    Image(systemName: icon)
                                        .font(.title3)
                                        .frame(width: 44, height: 44)
                                        .foregroundStyle(icon == buttonIcon ? themeColor.foreground : .primary)
                                        .background(icon == buttonIcon ? themeColor.color : Color.secondary.opacity(0.12),
                                                    in: Circle())
                                        .onTapGesture { buttonIcon = icon }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    VStack(alignment: .leading) {
                        Text("Size")
                        Slider(value: $buttonSize, in: 120...320)
                    }

                    Button("Reset position and size") {
                        buttonX = 0.5
                        buttonY = 0.6
                        buttonSize = 200
                    }
                }

                // MARK: Background
                Section("Background") {
                    // Pictures + your own photo
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(builtInBackgrounds) { option in
                                tile(key: option.key, name: option.name)
                                    .onTapGesture { background = option.key }
                            }

                            if photo != nil {
                                tile(key: "photo", name: "My photo")
                                    .onTapGesture { background = "photo" }
                            }

                            PhotosPicker(selection: $pickerItem, matching: .images) {
                                VStack(spacing: 6) {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.secondary.opacity(0.12))
                                        .frame(width: 70, height: 120)
                                        .overlay(Image(systemName: "photo.badge.plus").font(.title2))
                                    Text(photo == nil ? "Add photo" : "Change").font(.caption2)
                                }
                                .frame(width: 76)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 4)
                    }

                    // Solid colors
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Solid colors")
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(SolidBackground.allCases) { solid in
                                Circle()
                                    .fill(solid.color)
                                    .frame(width: 44, height: 44)
                                    .overlay(Circle().strokeBorder(Color.secondary.opacity(0.35), lineWidth: 1))
                                    .overlay {
                                        if background == solid.key {
                                            Image(systemName: "checkmark")
                                                .font(.headline)
                                                .foregroundStyle(solid.isDark ? .white : .black)
                                        }
                                    }
                                    .onTapGesture { background = solid.key }
                                    .accessibilityLabel(solid.name)
                            }
                        }
                    }
                    .padding(.vertical, 4)

                    if background == "photo" {
                        VStack(alignment: .leading) {
                            Text("Dim photo")
                            Slider(value: $photoDim, in: 0...0.8)
                        }
                    }

                    if photo != nil {
                        Button("Remove my photo", role: .destructive) {
                            PhotoStore.delete()
                            if background == "photo" { background = "plain" }
                            photoVersion += 1
                        }
                    }
                }

                // MARK: Display
                Section("Display") {
                    Picker("Appearance", selection: $appearance) {
                        ForEach(Appearance.allCases) { Text($0.name).tag($0) }
                    }
                    Toggle("Show round labels", isOn: $showLabels)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showPresets) {
                PresetsView(store: store)
            }
            .task(id: photoVersion) { photo = PhotoStore.load() }
            .onChange(of: counterStyle) {
                if counterStyle == .clicker && !themeColor.hasClicker { themeColor = .black }
            }
            .onChange(of: pickerItem) {
                guard let item = pickerItem else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let img = UIImage(data: data) {
                        PhotoStore.save(img)
                        photoVersion += 1
                        background = "photo"
                    }
                    pickerItem = nil
                }
            }
        }
    }

    private func tile(key: String, name: String) -> some View {
        VStack(spacing: 6) {
            BackgroundView(key: key, photo: photo, dim: photoDim)
                .frame(width: 70, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(background == key ? Color.accentColor : Color.secondary.opacity(0.3),
                                      lineWidth: background == key ? 3 : 1)
                )
            Text(name).font(.caption2).lineLimit(1)
        }
        .frame(width: 76)
    }
}
