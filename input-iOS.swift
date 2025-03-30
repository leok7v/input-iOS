import SwiftUI
import UIKit

@main
struct testApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct MultilineTextView: UIViewRepresentable {
    
    @Binding var text: String

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.font = .systemFont(ofSize: 17)
        tv.delegate = context.coordinator
        tv.isScrollEnabled = true
        let frame = CGRect(x: 0, y: 0,
            width: UIScreen.main.bounds.width, height: 44)
        let accessory = UIView(frame: frame)
        accessory.backgroundColor = .systemGray6
        let done = UIButton(type: .system)
//      done.setTitle("Done", for: .normal)
        done.setImage(UIImage(systemName: "keyboard.chevron.compact.down"),
                      for: .normal)
        done.addTarget(context.coordinator,
                       action: #selector(Coordinator.dismissKeyboard),
                       for: .touchUpInside)
        done.translatesAutoresizingMaskIntoConstraints = false
        accessory.addSubview(done)
        NSLayoutConstraint.activate([
            done.trailingAnchor.constraint(
                equalTo: accessory.trailingAnchor, constant: -16),
            done.centerYAnchor.constraint(
                equalTo: accessory.centerYAnchor)
        ])
        tv.inputAccessoryView = accessory
        DispatchQueue.main.async { tv.becomeFirstResponder() }
        return tv
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: MultilineTextView

        init(_ parent: MultilineTextView) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
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

    var body: some View {
        VStack(spacing: 0) {
            Text("Header").font(.title).padding()
            List(1...33, id: \.self) {
                Text("Paragraph \($0)")
            }
            .listStyle(.plain)
            .frame(maxHeight: .infinity)
        }
        .safeAreaInset(edge: .bottom, alignment: .center) {
            MultilineTextView(text: $input)
                .frame(minHeight: 17 * 1.2, maxHeight: 17 * 1.2 * 4)
                .border(Color.gray, width: 1)
                .padding()
                .background(Color(uiColor: .systemBackground))
        }
    }
}

#Preview {
    ContentView()
}
