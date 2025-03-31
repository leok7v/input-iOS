import SwiftUI
import GameController

@main struct app: App {
    @Environment(\EnvironmentValues.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup { ContentView() }
            .onChange(of: scenePhase) { _, phase in
                if phase != .active {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
    }
}

func endEditing() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                    to: nil, from: nil, for: nil)
}

func isKeyboardConnected() -> Bool {
    return GCKeyboard.coalesced != nil
}

struct MultilineTextView: UIViewRepresentable {
    @Binding var text: String
    let placeholder: String
    let maxHeight: CGFloat
    let minHeight: CGFloat

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.font = .systemFont(ofSize: 17)
        tv.delegate = context.coordinator
        tv.isScrollEnabled = false
        tv.textContainerInset = UIEdgeInsets(top: 8, left: 5, bottom: 8, right: 5)
        tv.setContentHuggingPriority(.defaultHigh, for: .vertical)
        tv.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        if UIDevice.current.userInterfaceIdiom != .pad || isKeyboardConnected() {
            addAccessory(context, tv)
        }
        addPlaceholder(tv)
        return tv
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text { uiView.text = text }
        if let label = uiView.subviews.compactMap({ $0 as? UILabel }).first {
            label.isHidden = !uiView.text.isEmpty
        }
        updateHeight(for: uiView)
    }

    func updateHeight(for tv: UITextView) {
        let size = tv.sizeThatFits(CGSize(width: tv.bounds.width, height: .greatestFiniteMagnitude))
        let calculatedHeight = min(max(size.height, minHeight), maxHeight)
        if tv.frame.height != calculatedHeight {
            DispatchQueue.main.async {
                tv.isScrollEnabled = size.height > maxHeight
                tv.invalidateIntrinsicContentSize()
            }
        }
    }

    func addPlaceholder(_ tv: UITextView) {
        let label = UILabel()
        label.text = placeholder
        label.font = tv.font
        label.textColor = .placeholderText
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        tv.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: tv.leadingAnchor, constant: 10),
            label.topAnchor.constraint(equalTo: tv.topAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: tv.trailingAnchor, constant: -10)
        ])
        label.isHidden = !text.isEmpty
    }

    func addAccessory(_ context: Context, _ tv: UITextView) {
        if tv.inputAccessoryView != nil { return }
        let accessory = UIView()
        accessory.backgroundColor = .systemGray6
        accessory.translatesAutoresizingMaskIntoConstraints = false
        accessory.heightAnchor.constraint(equalToConstant: 44).isActive = true
        let done = UIButton(type: .system)
        done.setImage(UIImage(systemName: "keyboard.chevron.compact.down"), for: .normal)
        done.addTarget(context.coordinator, action: #selector(Coordinator.dismissKeyboard), for: .touchUpInside)
        done.translatesAutoresizingMaskIntoConstraints = false
        accessory.addSubview(done)
        NSLayoutConstraint.activate([
            done.trailingAnchor.constraint(equalTo: accessory.trailingAnchor, constant: -16),
            done.centerYAnchor.constraint(equalTo: accessory.centerYAnchor)
        ])
        tv.inputAccessoryView = accessory
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: MultilineTextView

        init(_ parent: MultilineTextView) {
            self.parent = parent
        }

        func textViewDidChange(_ tv: UITextView) {
            parent.text = tv.text
            parent.updateHeight(for: tv)
            if let label = tv.subviews.compactMap({ $0 as? UILabel }).first {
                label.isHidden = !tv.text.isEmpty
            }
        }

        @objc func dismissKeyboard() {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil, from: nil, for: nil)
        }
    }
}

struct ContentView: View {
    @State private var input = ""

    static let lineHeight: CGFloat = 17
    static let minHeight: CGFloat = lineHeight * 2

    var body: some View {
        VStack(spacing: 0) {
            Text("Header")
                .font(.title)
                .padding()
            List(1...33, id: \.self) { Text("Paragraph \($0)") }
                .listStyle(.plain)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            MultilineTextView(
                text: $input,
                placeholder: "Ask Anything...",
                maxHeight: Self.lineHeight * 5,
                minHeight: Self.minHeight
            )
            .frame(minHeight: Self.minHeight, maxHeight: Self.lineHeight * 5)
            .border(Color.gray, width: 1)
            .padding()
            .background(Color(uiColor: .systemBackground))
        }
        .contentShape(Rectangle())
        .onTapGesture { endEditing() }
    }
}

#Preview { ContentView() }
