import SwiftUI

struct ContentView: View {
    @State private var store = TasbihStore()

    // Layout (saved). Position is a fraction of the screen so it works on any iPhone size.
    @AppStorage("buttonX") private var buttonX = 0.5
    @AppStorage("buttonY") private var buttonY = 0.6
    @AppStorage("buttonSize") private var buttonSize = 200.0

    // Locks (saved)
    @AppStorage("positionLocked") private var positionLocked = true
    @AppStorage("counterLocked") private var counterLocked = false

    // Settings (saved)
    @AppStorage("counterStyle") private var counterStyle: CounterStyle = .button
    @AppStorage("themeColor") private var themeColor: ThemeColor = .black
    @AppStorage("buttonIcon") private var buttonIcon = "hand.tap.fill"
    @AppStorage("appearance") private var appearance: Appearance = .system
    @AppStorage("showLabels") private var showLabels = true
    @AppStorage("background") private var background = "plain"
    @AppStorage("photoDim") private var photoDim = 0.35
    @AppStorage("photoVersion") private var photoVersion = 0

    @State private var photo: UIImage?
    @State private var dragOffset: CGSize = .zero
    @State private var showSettings = false
    @State private var pressed = false

    // Bottom of the info card and top of the Move/Lock controls, so the counter stays between them
    @State private var topLimit: CGFloat = 0
    @State private var bottomLimit: CGFloat = .infinity

    private var topLocked: Bool { counterLocked || !positionLocked }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                VStack(spacing: 16) {
                    topBar
                    infoCard
                }
                .onGeometryChange(for: CGFloat.self) { $0.frame(in: .named("screen")).maxY } action: {
                    topLimit = $0
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                tapButton
                    .position(buttonPoint(in: geo.size))
                    .gesture(moveGesture(in: geo.size),
                             including: positionLocked ? .subviews : .all)

                bottomControls
                    .onGeometryChange(for: CGFloat.self) { $0.frame(in: .named("screen")).minY } action: {
                        bottomLimit = $0
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, 8)
            }
            .coordinateSpace(.named("screen"))
        }
        .background {
            BackgroundView(key: background, photo: photo, dim: photoDim)
                .ignoresSafeArea()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(store: store)
        }
        .preferredColorScheme(backgroundScheme(background) ?? appearance.colorScheme)
        .task(id: photoVersion) { photo = PhotoStore.load() }
    }

    // MARK: - Top bar (Presets + Settings), gold-trimmed

    private var topBar: some View {
        HStack {
            Menu {
                Picker("Preset", selection: Binding(
                    get: { store.selectedID },
                    set: { store.select($0) }
                )) {
                    ForEach(store.presets) { preset in
                        Text(preset.name).tag(preset.id)
                    }
                }
            } label: {
                Label("Presets", systemImage: "list.bullet")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 16)
                    .frame(height: 44)
                    .goldGlass(Capsule())
            }

            Spacer()

            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.title3)
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
                    .goldGlass(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")
        }
        .disabled(topLocked)
        .opacity(topLocked ? 0.5 : 1)
        .padding(.horizontal, 16)
        .padding(.top, 4)
    }

    // MARK: - Info card: preset name, label, round, count, reset

    private var infoCard: some View {
        VStack(spacing: 8) {
            GoldLabel(text: store.selected.name)

            // Arabic label. Long labels shrink to fit about 3 lines.
            if showLabels, let round = store.currentRound, !round.label.isEmpty {
                Text(round.label)
                    .font(arabicFont(40))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.45)
                    .frame(maxWidth: .infinity)
            }

            // Round 2 of 3 (hidden when there's only one round)
            if store.selected.rounds.count > 1 {
                Text("Round \(store.roundIndex + 1) of \(store.selected.rounds.count)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            if counterStyle == .button {
                // Big number (the clicker shows the count on its own screen)
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(store.count)")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                    if let round = store.currentRound {
                        Text("/ \(round.target)")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                }
            } else if let round = store.currentRound {
                Text("Goal: \(round.target)")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            if store.isFinished {
                Label("Done · \(store.selected.total)", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .foregroundStyle(Gold.mid)
            }

            // The Button style has its own Reset. The clicker uses its small RESET button.
            if counterStyle == .button {
                Button {
                    withAnimation { store.reset() }
                } label: {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .disabled(counterLocked || (store.count == 0 && store.roundIndex == 0 && !store.isFinished))
                .padding(.top, 2)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(maxWidth: 380)
        .goldGlass(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .padding(.horizontal, 20)
    }

    // MARK: - Counter (button or clicker)

    private var clickerHeight: CGFloat { CGFloat(buttonSize) * 1.3 }

    private var itemSize: CGSize {
        counterStyle == .clicker
            ? CGSize(width: clickerHeight * ClickerView.aspect, height: clickerHeight)
            : CGSize(width: buttonSize, height: buttonSize)
    }

    private var buttonColor: Color {
        if !positionLocked { return .blue }
        if counterLocked || store.isFinished { return .gray }
        return themeColor.color
    }

    private var iconName: String {
        if !positionLocked { return "arrow.up.and.down.and.arrow.left.and.right" }
        if counterLocked { return "lock.fill" }
        if store.isFinished { return "checkmark" }
        return buttonIcon
    }

    private var iconColor: Color {
        (positionLocked && !counterLocked && !store.isFinished) ? themeColor.foreground : .white
    }

    // Round button with a gold rim, like the clicker's trim
    private var classicButton: some View {
        Circle()
            .fill(buttonColor.gradient)
            .frame(width: buttonSize, height: buttonSize)
            .overlay(
                // soft dark edge just inside the gold, so it looks like a set rim
                Circle()
                    .strokeBorder(Color.black.opacity(0.35), lineWidth: 2)
                    .padding(max(4, buttonSize * 0.025))
            )
            .overlay(
                Circle().strokeBorder(Gold.gradient, lineWidth: max(4, buttonSize * 0.025))
            )
            .overlay(
                Image(systemName: iconName)
                    .font(.system(size: buttonSize * 0.25))
                    .foregroundStyle(iconColor)
            )
            .overlay {
                if !positionLocked {
                    Circle()
                        .strokeBorder(.white.opacity(0.8),
                                      style: StrokeStyle(lineWidth: 3, dash: [10, 6]))
                        .padding(buttonSize * 0.06)
                }
            }
            .shadow(color: .black.opacity(0.35), radius: 12, y: 8)
            .scaleEffect(pressed ? 0.96 : 1)
    }

    @ViewBuilder
    private var counterView: some View {
        if counterStyle == .clicker {
            ClickerView(
                count: store.count,
                height: clickerHeight,
                theme: themeColor,
                isLocked: counterLocked,
                isMoving: !positionLocked,
                isFinished: store.isFinished,
                pressed: pressed,
                onResetHold: {
                    guard !counterLocked, positionLocked else { return }
                    withAnimation { store.reset() }
                }
            )
        } else {
            classicButton
        }
    }

    private var tapButton: some View {
        counterView
            .contentShape(Rectangle())
            .onTapGesture {
                guard positionLocked, !counterLocked else { return }
                withAnimation { store.tap() }
                pressFlash()
            }
            .sensoryFeedback(.impact(weight: .light), trigger: store.taps)
            .sensoryFeedback(.impact(weight: .heavy), trigger: store.roundEvents)
            .sensoryFeedback(.success, trigger: store.finishEvents)
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel("Count")
    }

    private func pressFlash() {
        withAnimation(.easeOut(duration: 0.06)) { pressed = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.09) {
            withAnimation(.easeOut(duration: 0.1)) { pressed = false }
        }
    }

    // MARK: - Moving

    private func buttonPoint(in size: CGSize) -> CGPoint {
        let halfW = itemSize.width / 2
        let halfH = itemSize.height / 2
        let x = CGFloat(buttonX) * size.width + dragOffset.width
        let y = CGFloat(buttonY) * size.height + dragOffset.height
        // Keep it below the info card and above the Move/Lock buttons.
        // If there isn't room for both, the buttons win so they stay tappable.
        let minY = max(topLimit + 8, 0) + halfH
        let maxY = min(bottomLimit - 8, size.height) - halfH
        return CGPoint(
            x: min(max(x, halfW), max(size.width - halfW, halfW)),
            y: max(min(max(y, minY), maxY), halfH)
        )
    }

    private func moveGesture(in size: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation
            }
            .onEnded { _ in
                let p = buttonPoint(in: size)
                buttonX = Double(p.x / size.width)
                buttonY = Double(p.y / size.height)
                dragOffset = .zero
            }
    }

    // MARK: - Bottom controls (Move / Lock), gold-trimmed

    private var bottomControls: some View {
        VStack(spacing: 12) {
            if !positionLocked {
                VStack(spacing: 8) {
                    Text("Drag anywhere")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    HStack {
                        Image(systemName: "circle").font(.caption)
                        Slider(value: $buttonSize, in: 120...320)
                            .tint(Gold.mid)
                        Image(systemName: "circle").font(.title2)
                    }
                }
                .padding()
                .goldGlass(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .padding(.horizontal)
            }

            HStack(spacing: 12) {
                // Move / Done
                Button {
                    withAnimation { positionLocked.toggle() }
                } label: {
                    Label(positionLocked ? "Move" : "Done",
                          systemImage: positionLocked ? "hand.draw" : "checkmark")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 16)
                        .frame(height: 40)
                        .goldGlass(Capsule(), lineWidth: 1.2)
                }
                .buttonStyle(.plain)
                .disabled(counterLocked)
                .opacity(counterLocked ? 0.5 : 1)

                // Lock: hidden while moving. Tap to lock, hold to unlock.
                if positionLocked {
                    Label(counterLocked ? "Hold to unlock" : "Lock",
                          systemImage: counterLocked ? "lock.fill" : "lock.open")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(counterLocked ? AnyShapeStyle(Color.orange) : AnyShapeStyle(.primary))
                        .padding(.horizontal, 16)
                        .frame(height: 40)
                        .goldGlass(Capsule(), lineWidth: 1.2)
                        .contentShape(Capsule())
                        .onTapGesture {
                            if !counterLocked {
                                withAnimation {
                                    counterLocked = true
                                    positionLocked = true
                                }
                            }
                        }
                        .onLongPressGesture(minimumDuration: 0.6) {
                            withAnimation { counterLocked = false }
                        }
                        .sensoryFeedback(.impact(weight: .medium), trigger: counterLocked)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
