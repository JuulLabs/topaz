import Design
import SwiftUI

public struct CustomToggle: View {
    @Binding public var isOn: Bool

    private let offBorder = Color(hex: "#BABABA")!
    private let offFill = Color(hex: "#535353")!

    public init(isOn: Binding<Bool>) {
        self._isOn = isOn
    }

    public var body: some View {
        Button {
            isOn.toggle()
        } label: {
            HStack(spacing: 8) {
                if isOn {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.white, Color.topaz300)
                        .padding(.leading, 6)
                } else {
                    Image(systemName: "circle.fill")
                        .foregroundStyle(Color.black)
                        .padding(.leading, 6)
                }
                Text(isOn ? "On" : "Off")
                    .foregroundStyle(Color.topaz050)
                    .font(.dogpatch(.headline))
                    .padding(.trailing, 13)
            }
            .padding(.vertical, 4)
            .background {
                Capsule(style: .continuous)
                    .stroke(isOn ? Color.topaz050 : offBorder, lineWidth: 2)
                    .fill(isOn ? Color.topaz800 : offFill)
                    .frame(minWidth: 68)
            }
        }
        .buttonStyle(NoAnimation())
        .animation(.default.speed(2.0), value: isOn)
    }
}

private struct NoAnimation: PrimitiveButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(.rect)
            .onTapGesture(perform: configuration.trigger)
    }
}

#Preview {
    @Previewable @State var isOn: Bool = true
    ZStack {
        Color.gray
        CustomToggle(isOn: $isOn)
    }
    .ignoresSafeArea()
}
