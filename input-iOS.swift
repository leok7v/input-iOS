import SwiftUI
import GameController

@main
struct app: App {
    var body: some Scene { WindowGroup { ContentView() } }
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
        tv.setContentHuggingPriority(.defaultHigh, for: .vertical)
        tv.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        addAccessory(context, tv)
        addPlaceholder(tv)
        DispatchQueue.main.async { tv.becomeFirstResponder() }
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
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        tv.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: tv.leadingAnchor, constant: 5),
            label.topAnchor.constraint(equalTo: tv.topAnchor, constant: 8),
            label.widthAnchor.constraint(equalTo: tv.widthAnchor, constant: -10)
        ])
        label.isHidden = !text.isEmpty
    }

    func addAccessory(_ context: Context, _ tv: UITextView) {
        if tv.inputAccessoryView != nil { return }
        let accessory = UIView()
        accessory.backgroundColor = .systemGray6
        accessory.translatesAutoresizingMaskIntoConstraints = false
        let height = isKeyboardConnected() ? 70.0 : 44.0
        accessory.heightAnchor.constraint(equalToConstant: height).isActive = true
        let done = UIButton(type: .system)
        done.setImage(UIImage(systemName: "keyboard.chevron.compact.down"), for: .normal)
        done.addTarget(context.coordinator, action: #selector(Coordinator.dismissKeyboard), for: .touchUpInside)
        done.translatesAutoresizingMaskIntoConstraints = false
        accessory.addSubview(done)
        NSLayoutConstraint.activate([
            done.trailingAnchor.constraint(equalTo: accessory.trailingAnchor, constant: -30),
            done.centerYAnchor.constraint(equalTo: accessory.centerYAnchor),
            done.widthAnchor.constraint(equalToConstant: 30),
            done.heightAnchor.constraint(equalToConstant: 30)
        ])
        tv.inputAccessoryView = accessory
    }
        
    class Coordinator: NSObject, UITextViewDelegate {
        
        var parent: MultilineTextView
        weak var textView: UITextView?
        
        init(_ parent: MultilineTextView) {
            self.parent = parent
            super.init()
            NotificationCenter.default.addObserver(self,
                selector: #selector(keyboardWillShow),
                name: UIResponder.keyboardWillShowNotification, object: nil)
            NotificationCenter.default.addObserver(self,
                selector: #selector(keyboardWillHide),
                name: UIResponder.keyboardWillHideNotification, object: nil)
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
        
        @objc func keyboardWillShow(notification: Notification) {
            print("isKeyboardConnected \(isKeyboardConnected())")
        }

        @objc func keyboardWillHide(notification: Notification) {
            print("isKeyboardConnected \(isKeyboardConnected())")
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
        .safeAreaInset(edge: .bottom, alignment: .leading, spacing: 0) {
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
    }
}

#Preview { ContentView() }
