import SwiftUI
import MessageUI

// MARK: - FeedbackScreen
struct FeedbackScreen: View {

    @Environment(\.dismiss) private var dismiss

    enum FeedbackType: String, CaseIterable {
        case bug        = "Bug Report"
        case feature    = "Feature Request"
        case compliment = "Compliment 🙌"
        case other      = "Other"

        var icon: String {
            switch self {
            case .bug:        return "ant.fill"
            case .feature:    return "lightbulb.fill"
            case .compliment: return "heart.fill"
            case .other:      return "ellipsis.bubble.fill"
            }
        }
        var color: Color {
            switch self {
            case .bug:        return Color(hex: "#E07A7A")
            case .feature:    return AppColors.amber
            case .compliment: return AppColors.sage
            case .other:      return AppColors.textMuted
            }
        }
    }

    @State private var name: String = ""
    @State private var replyEmail: String = ""
    @State private var feedbackType: FeedbackType = .feature
    @State private var message: String = ""

    @State private var showMailComposer = false
    @State private var showMailFallbackAlert = false
    @State private var showSentConfirmation = false

    private let recipientEmail = "phucvq2@gmail.com"

    private var isMessageEmpty: Bool { message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var body: some View {
        ZStack {
            AppColors.night.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {

                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Send Feedback")
                            .font(AppTypography.titleLarge)
                            .foregroundStyle(AppColors.text)
                        Text("Bug, idea, or just want to say hi? We read every message.")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textMuted)
                            .lineSpacing(3)
                    }

                    // Type Picker
                    VStack(alignment: .leading, spacing: 10) {
                        fieldLabel("Feedback type")
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            ForEach(FeedbackType.allCases, id: \.self) { type in
                                typeButton(type)
                            }
                        }
                    }

                    // Name (optional)
                    VStack(alignment: .leading, spacing: 8) {
                        fieldLabel("Your name (optional)")
                        textField("e.g. Minh Anh", text: $name)
                    }

                    // Reply email (optional)
                    VStack(alignment: .leading, spacing: 8) {
                        fieldLabel("Reply email (optional)")
                        textField("So we can get back to you", text: $replyEmail)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }

                    // Message
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            fieldLabel("Message")
                            Spacer()
                            if isMessageEmpty {
                                Text("Required")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color(hex: "#E07A7A").opacity(0.7))
                            }
                        }
                        textEditor(placeholder: messagePlaceholder, text: $message)
                    }

                    // Send Button
                    Button {
                        sendFeedback()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Send Feedback")
                                .font(AppTypography.labelMedium)
                        }
                        .foregroundStyle(isMessageEmpty ? AppColors.textDim : Color(hex: "#1A0F00"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background {
                            if isMessageEmpty {
                                AppColors.surface2
                            } else {
                                LinearGradient(
                                    colors: [AppColors.amber, AppColors.amberLight],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(isMessageEmpty)

                    // Confirmation
                    if showSentConfirmation {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(AppColors.sage)
                            Text("Feedback sent! Thank you 🙏")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.sage)
                        }
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
            }
        }
        .navigationTitle("Feedback")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.night, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showMailComposer) {
            MailComposerView(
                toRecipients: [recipientEmail],
                subject: mailSubject,
                body: mailBody,
                isPresented: $showMailComposer,
                onSent: {
                    withAnimation { showSentConfirmation = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation { showSentConfirmation = false }
                    }
                }
            )
        }
        .alert("Mail not configured", isPresented: $showMailFallbackAlert) {
            Button("Copy email address") {
                UIPasteboard.general.string = recipientEmail
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please set up Mail on your device, or send your feedback directly to \(recipientEmail)")
        }
    }

    // MARK: - Helpers

    private var messagePlaceholder: String {
        switch feedbackType {
        case .bug:        return "Describe what happened and how to reproduce it…"
        case .feature:    return "Tell us about your idea…"
        case .compliment: return "Made our day already! What would you like to share?"
        case .other:      return "What's on your mind?"
        }
    }

    private var mailSubject: String {
        "FlowState Feedback: \(feedbackType.rawValue)"
    }

    private var mailBody: String {
        var lines: [String] = []
        if !name.isEmpty   { lines.append("Name: \(name)") }
        if !replyEmail.isEmpty { lines.append("Reply to: \(replyEmail)") }
        lines.append("Type: \(feedbackType.rawValue)")
        lines.append("")
        lines.append(message)
        lines.append("")
        lines.append("---")
        lines.append("App version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?")")
        lines.append("iOS: \(UIDevice.current.systemVersion)")
        return lines.joined(separator: "\n")
    }

    private func sendFeedback() {
        if MFMailComposeViewController.canSendMail() {
            showMailComposer = true
        } else {
            // Fall back to mailto: URL
            let subject = mailSubject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let body = mailBody.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let urlString = "mailto:\(recipientEmail)?subject=\(subject)&body=\(body)"
            if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                showMailFallbackAlert = true
            }
        }
    }

    // MARK: - Sub-views

    private func fieldLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(AppColors.textDim)
            .tracking(1.2)
    }

    private func typeButton(_ type: FeedbackType) -> some View {
        let selected = feedbackType == type
        return Button { feedbackType = type } label: {
            HStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(selected ? type.color : AppColors.textDim)
                Text(type.rawValue)
                    .font(.system(size: 13, weight: selected ? .semibold : .regular))
                    .foregroundStyle(selected ? AppColors.text : AppColors.textMuted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(selected ? type.color.opacity(0.1) : AppColors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(selected ? type.color.opacity(0.5) : AppColors.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    private func textField(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .font(AppTypography.body)
            .foregroundStyle(AppColors.text)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(AppColors.surface)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppColors.border, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func textEditor(placeholder: String, text: Binding<String>) -> some View {
        ZStack(alignment: .topLeading) {
            if text.wrappedValue.isEmpty {
                Text(placeholder)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textDim)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 16)
                    .allowsHitTesting(false)
            }
            TextEditor(text: text)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.text)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 120)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
        }
        .background(AppColors.surface)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppColors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - MailComposerView (UIKit bridge)
struct MailComposerView: UIViewControllerRepresentable {
    let toRecipients: [String]
    let subject: String
    let body: String
    @Binding var isPresented: Bool
    var onSent: (() -> Void)?

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        vc.setToRecipients(toRecipients)
        vc.setSubject(subject)
        vc.setMessageBody(body, isHTML: false)
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(isPresented: $isPresented, onSent: onSent)
    }

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        @Binding var isPresented: Bool
        let onSent: (() -> Void)?

        init(isPresented: Binding<Bool>, onSent: (() -> Void)?) {
            _isPresented = isPresented
            self.onSent = onSent
        }

        func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: Error?
        ) {
            isPresented = false
            if result == .sent { onSent?() }
        }
    }
}

#Preview {
    NavigationStack { FeedbackScreen() }
        .preferredColorScheme(.dark)
}
