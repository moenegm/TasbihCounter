import SwiftUI

// The realistic clicker image, with the live count, reset ring, and state icons drawn on top
struct ClickerView: View {
    var count: Int
    var height: CGFloat
    var theme: ThemeColor
    var isLocked: Bool
    var isMoving: Bool
    var isFinished: Bool
    var pressed: Bool
    var onResetHold: () -> Void

    @State private var holding = false
    @State private var resets = 0

    // Width ÷ height of the clicker images (632 × 791)
    static let aspect: CGFloat = 632.0 / 791.0

    var body: some View {
        let w = height * Self.aspect
        let h = height

        ZStack {
            Image(theme.clickerImage)
                .resizable()
                .interpolation(.high)
                .frame(width: w, height: h)
                .shadow(color: .black.opacity(0.35), radius: 12, y: 8)

            // LCD contents
            lcd(width: w * 0.617, height: h * 0.172)
                .position(x: w * 0.5047, y: h * 0.3085)

            // Big button darkens slightly when pressed
            Circle()
                .fill(Color.black.opacity(pressed ? 0.25 : 0))
                .frame(width: w * 0.2975, height: w * 0.2975)
                .position(x: w * 0.4905, y: h * 0.6953)

            // Small reset button: hold to reset
            smallReset(size: w * 0.111)
                .position(x: w * 0.7484, y: h * 0.6068)

            if isMoving {
                RoundedRectangle(cornerRadius: w * 0.3, style: .continuous)
                    .strokeBorder(.white.opacity(0.9),
                                  style: StrokeStyle(lineWidth: 3, dash: [10, 6]))
                    .frame(width: w, height: h)
            }
        }
        .frame(width: w, height: h)
        .scaleEffect(pressed ? 0.985 : 1)
    }

    private func lcd(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            HStack(spacing: 0) {
                Spacer(minLength: 0)
                ZStack(alignment: .trailing) {
                    Text("8888").foregroundStyle(.black.opacity(0.06))
                    Text("\(count % 10000)").foregroundStyle(.black.opacity(0.8))
                }
                .font(.custom("DBLCDTempBlack", size: height * 0.72))
                .padding(.trailing, width * 0.06)
            }

            if isMoving || isLocked || isFinished {
                Image(systemName: isMoving ? "arrow.up.and.down.and.arrow.left.and.right"
                                  : isLocked ? "lock.fill" : "checkmark")
                    .font(.system(size: height * 0.28, weight: .bold))
                    .foregroundStyle(.black.opacity(0.6))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(height * 0.12)
            }
        }
        .frame(width: width, height: height)
    }

    private func smallReset(size: CGFloat) -> some View {
        Circle()
            .fill(Color.white.opacity(0.001))
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .trim(from: 0, to: holding ? 1 : 0)
                    .stroke(theme == .white ? Color.black : Color.white,
                            style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .padding(-4)
            )
            .padding(size * 0.3)
            .contentShape(Circle())
            .onTapGesture { }   // a single tap does nothing
            .onLongPressGesture(minimumDuration: 0.6) {
                resets += 1
                onResetHold()
            } onPressingChanged: { pressing in
                withAnimation(pressing ? .linear(duration: 0.6) : .easeOut(duration: 0.15)) {
                    holding = pressing
                }
            }
            .sensoryFeedback(.impact(weight: .heavy), trigger: resets)
            .accessibilityLabel("Hold to reset")
    }
}
