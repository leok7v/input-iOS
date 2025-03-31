import SwiftUI

@main struct app: App {
    var body: some Scene { WindowGroup { ContentView() } }
}

class KeyboardObserver: ObservableObject {
    
    @Published var height: CGFloat = 0
    
    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChangeFrame),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardDidChangeFrame),
            name: UIResponder.keyboardDidChangeFrameNotification,
            object: nil
        )
    }
    
    @objc func keyboardWillChangeFrame(_ note: Notification) {
        if let info = note.userInfo,
           let frame = info[UIResponder.keyboardFrameEndUserInfoKey]
             as? CGRect {
            let screen = UIScreen.main.bounds
            let top = screen.height - frame.origin.y
            height = max(0, top)
            print("keyboardWillChangeFrame height: \(height) screen: \(screen) frame: \(frame) top: \(top)")
        }
    }

    @objc func keyboardDidChangeFrame(_ note: Notification) {
        // This function is not necessary - it's here for now just to confirm
        // that keyboardWillChangeFrame/keyboardDidChangeFrame have the same
        // geometry
        if let info = note.userInfo,
           let frame = info[UIResponder.keyboardFrameEndUserInfoKey]
             as? CGRect {
            let screen = UIScreen.main.bounds
            let top = screen.height - frame.origin.y
            height = max(0, top)
            print("keyboardDidChangeFrame height: \(height) screen: \(screen) frame: \(frame) top: \(top)")
        }
    }
}

struct MultilineTextView: UIViewRepresentable {
    
    @Binding var text: String
    let placeholder: String
    let maxHeight: CGFloat
    let minHeight: CGFloat

    func addPlaceholder(_ tv: UITextView) {
        let label = UILabel()
        label.text = placeholder
        label.font = tv.font
        label.textColor = .placeholderText
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        tv.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: tv.leadingAnchor,
                                           constant: 5),
            label.topAnchor.constraint(equalTo: tv.topAnchor,
                                       constant: 8),
            label.widthAnchor.constraint(equalTo: tv.widthAnchor,
                                         constant: -10)
        ])
        label.isHidden = !text.isEmpty
    }

    func addAccessory(_ context: Context, _ tv: UITextView) {
        let accessory = UIView()
        accessory.backgroundColor = .systemGray6
        let done = UIButton(type: .system)
        done.setImage(
            UIImage(systemName: "keyboard.chevron.compact.down"),
            for: .normal
        )
        done.addTarget(context.coordinator,
            action: #selector(Coordinator.dismissKeyboard),
            for: .touchUpInside)
        done.translatesAutoresizingMaskIntoConstraints = false
        accessory.addSubview(done)
        NSLayoutConstraint.activate([
            done.trailingAnchor.constraint(
                equalTo: accessory.trailingAnchor, constant: -16),
            done.centerYAnchor.constraint(equalTo: accessory.centerYAnchor)
        ])
        tv.inputAccessoryView = accessory
    }
    
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
        print("MultilineTextView.updateUIView: \(uiView.frame)")
        print("MultilineTextView.updateUIView: \(uiView.bounds)")
        if uiView.text != text { uiView.text = text }
        if let label = uiView.subviews.compactMap({ $0 as? UILabel }).first {
            label.isHidden = !uiView.text.isEmpty
        }
        updateHeight(for: uiView)
    }

    func updateHeight(for tv: UITextView) {
        let size = tv.sizeThatFits(CGSize(width: tv.bounds.width, height: .greatestFiniteMagnitude))
        let calculated_height = min(max(size.height, minHeight), maxHeight)
        if tv.frame.height != calculated_height {
            DispatchQueue.main.async {
                tv.isScrollEnabled = size.height > maxHeight
                tv.invalidateIntrinsicContentSize()
            }
        }
    }

    class Coordinator: NSObject, UITextViewDelegate {

        var parent: MultilineTextView
        
        init(_ parent: MultilineTextView) { self.parent = parent }
        
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
                to: nil, from: nil, for: nil
            )
        }
        
    }
    
}

struct ContentView: View {
    
    @State private var input = ""
    @StateObject private var observer = KeyboardObserver()
    static let line_height: CGFloat = 17
    static let min_height: CGFloat = line_height * 2
    
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                Text("Header").font(.title).padding()
                    .background(GeometryReader { g in
                        Color.clear.onAppear { print("Header: \(g.frame(in: .global))") }
                    })
                List(1...33, id: \.self) { Text("Paragraph \($0)") }
                    .listStyle(.plain)
                    .background(GeometryReader { g in
                        Color.clear.onAppear { print("List: \(g.frame(in: .global))") }
                    })
                Spacer()
                MultilineTextView(
                    text: $input,
                    placeholder: "Ask Anything...",
                    maxHeight: Self.line_height * 5,
                    minHeight: Self.min_height
                )
                .frame(minHeight: Self.min_height,
                       maxHeight: Self.line_height * 5)
                .border(Color.gray, width: 1)
                .padding()
                .background(Color(uiColor: .systemBackground))
                .background(GeometryReader { g in
                    Color.clear.onAppear { print("MultilineTextView: \(g.frame(in: .global))") }
                })
            }
            .frame(width: geo.size.width, height: geo.size.height,
                   alignment: .bottom)
            .padding(.bottom, observer.height)
            .animation(.easeOut(duration: 0.25),
                       value: observer.height)
        }
        .edgesIgnoringSafeArea(.bottom)
    }
}

#Preview { ContentView() }
