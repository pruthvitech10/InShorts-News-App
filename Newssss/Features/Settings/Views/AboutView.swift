//
//  AboutView.swift
//  dailynews
//
//  About app information using StoreKit and MessageUI
//

import SwiftUI
import StoreKit
import MessageUI
import Combine


// AboutView

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AboutViewModel()
    
    var body: some View {
        List {
            appInfoSection
            actionsSection
            supportSection
            developerSection
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $viewModel.showMailComposer) {
            MailComposeView(
                recipient: "support@dailynews.app",
                subject: "DailyNews Support",
                body: viewModel.supportEmailBody
            )
        }
        .sheet(isPresented: $viewModel.showShareSheet) {
            ShareSheet(items: [viewModel.shareText])
        }
    }
    
    // App Info Section
    
    private var appInfoSection: some View {
        Section {
            VStack(spacing: 20) {
                // App Icon
                Image("AppIcon")
                    .resizable()
                    .frame(width: 100, height: 0.500)
                    .cornerRadius(22)
                    .shadow(color: Color.black.opacity(0.2), radius: 10)
                
                // App Name
                Text("Inshorts")
                    .font(.title2)
                    .fontWeight(.bold)
                
               
                // Tagline
                Text("Your intelligent news companion")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .listRowBackground(Color.clear)
        }
    }
    
    // Actions Section
    
    private var actionsSection: some View {
        Section {
            Button {
                viewModel.requestReview()
            } label: {
                Label {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Rate DailyNews")
                        Text("Show us some love")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } icon: {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                }
            }
            
            Button {
                viewModel.shareApp()
            } label: {
                Label {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Share App")
                        Text("Tell your friends")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } icon: {
                    Image(systemName: "square.and.arrow.up.fill")
                        .foregroundColor(.blue)
                }
            }
            
            Button {
                viewModel.checkForUpdates()
            } label: {
                Label {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Check for Updates")
                        if viewModel.updateAvailable {
                            Text("Update available!")
                                .font(.caption)
                                .foregroundColor(.green)
                        } else {
                            Text("You're up to date")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } icon: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundColor(.green)
                }
            }
        } header: {
            Text("Actions")
        }
    }
    
    // Support Section
    
    private var supportSection: some View {
        Section {
            Button {
                viewModel.contactSupport()
            } label: {
                Label("Contact Support", systemImage: "envelope.fill")
            }
            
            Button {
                viewModel.openFAQ()
            } label: {
                Label("FAQ", systemImage: "questionmark.circle.fill")
            }
        } header: {
            Text("Support & Help")
        }
    }
    
    // Developer Section
    
    private var developerSection: some View {
        Section {
            HStack {
                Text("Developed by")
                    .foregroundColor(.secondary)
                Spacer()
                Text("Raja Punada ")
                    .fontWeight(.medium)
            }
            
            HStack {
                Text("Country")
                    .foregroundColor(.secondary)
                Spacer()
                Text("🇮🇳 India")
                    .fontWeight(.medium)
            }
            
            HStack {
                Text("Copyright")
                    .foregroundColor(.secondary)
                Spacer()
                Text("© 2025 DailyNews")
                    .fontWeight(.medium)
            }
        } footer: {
            Text("Made with ❤️ for news enthusiasts")
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 20)
        }
    }
}

// AboutViewModel

@MainActor
final class AboutViewModel: ObservableObject {
    @Published var showMailComposer = false
    @Published var showShareSheet = false
    @Published var updateAvailable = false
    
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    var shareText: String {
        "Check out DailyNews - Your intelligent news companion! https://dailynews.app"
    }
    
    var supportEmailBody: String {
        """
        
        
        ---
        App Version: \(appVersion) (\(buildNumber))
        iOS Version: \(UIDevice.current.systemVersion)
        Device: \(UIDevice.current.model)
        """
    }
    
    // Actions
    
    func requestReview() {
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
            Logger.debug("⭐ Review requested", category: .general)
        }
    }
    
    func shareApp() {
        showShareSheet = true
    }
    
    func checkForUpdates() {
        // In a real app, check App Store for updates
        updateAvailable = false
        Logger.debug("🔄 Checking for updates", category: .general)
    }
    
    func contactSupport() {
        if MFMailComposeViewController.canSendMail() {
            showMailComposer = true
        } else {
            // Fallback to mailto URL
            if let url = URL(string: "ppunada25@fed.idserve.it") {
                Task { @MainActor in
                    await UIApplication.shared.open(url)
                }
            }
        }
    }
    
    func openFAQ() {
        guard let url = URL(string: "https://dailynews.app/faq") else { return }
        Task { @MainActor in
            await UIApplication.shared.open(url)
        }
    }
}

// MailComposeView

struct MailComposeView: UIViewControllerRepresentable {
    let recipient: String
    let subject: String
    let body: String
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        vc.setToRecipients([recipient])
        vc.setSubject(subject)
        vc.setMessageBody(body, isHTML: false)
        return vc
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let parent: MailComposeView
        
        init(_ parent: MailComposeView) {
            self.parent = parent
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            parent.dismiss()
        }
    }
}

// ShareSheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// Preview

#Preview {
    NavigationStack {
        AboutView()
    }
}
