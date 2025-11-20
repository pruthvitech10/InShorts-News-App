import SwiftUI
import PhotosUI

struct AvatarEditorView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isUploading = false
    @State private var showCamera = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    let currentPhotoURL: String?
    let onPhotoSelected: (UIImage) -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Preview
                VStack(spacing: 16) {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 200, height: 200)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.blue, lineWidth: 3))
                    } else if let photoURL = currentPhotoURL, let url = URL(string: photoURL) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .overlay(ProgressView())
                        }
                        .frame(width: 200, height: 200)
                        .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 200, height: 200)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 80))
                                    .foregroundColor(.white)
                            )
                    }
                    
                    Text(selectedImage != nil ? "New Photo Selected" : "Current Photo")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 32)
                
                // Options
                VStack(spacing: 12) {
                    // Gallery Picker
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        HStack {
                            Image(systemName: "photo.on.rectangle")
                                .font(.title3)
                            Text("Choose from Gallery")
                                .fontWeight(.medium)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                    
                    // Camera Button
                    Button(action: {
                        showCamera = true
                    }) {
                        HStack {
                            Image(systemName: "camera.fill")
                                .font(.title3)
                            Text("Take Photo")
                                .fontWeight(.medium)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                    .foregroundColor(.primary)
                    
                    // Remove Photo (if exists)
                    if currentPhotoURL != nil || selectedImage != nil {
                        Button(action: {
                            selectedImage = nil
                            selectedItem = nil
                        }) {
                            HStack {
                                Image(systemName: "trash.fill")
                                    .font(.title3)
                                Text("Remove Photo")
                                    .fontWeight(.medium)
                                Spacer()
                            }
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .foregroundColor(.red)
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Save Button
                if selectedImage != nil {
                    Button(action: {
                        savePhoto()
                    }) {
                        HStack {
                            if isUploading {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text(isUploading ? "Uploading..." : "Save Photo")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isUploading)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Edit Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onChange(of: selectedItem) { oldValue, newValue in
                Task {
                    do {
                        guard let newValue = newValue else { 
                            print("❌ No item selected")
                            return 
                        }
                        
                        print("📷 Loading image from gallery...")
                        
                        guard let data = try await newValue.loadTransferable(type: Data.self) else {
                            print("❌ Failed to load data")
                            await MainActor.run {
                                errorMessage = "Failed to load image data"
                                showError = true
                            }
                            return
                        }
                        
                        print("✅ Data loaded: \(data.count) bytes")
                        
                        guard let image = UIImage(data: data) else {
                            print("❌ Failed to create UIImage from data")
                            await MainActor.run {
                                errorMessage = "Failed to process image"
                                showError = true
                            }
                            return
                        }
                        
                        print("✅ Image created: \(image.size)")
                        
                        await MainActor.run {
                            selectedImage = image
                            print("✅ Image displayed successfully")
                        }
                    } catch {
                        print("❌ Error loading image: \(error.localizedDescription)")
                        await MainActor.run {
                            errorMessage = "Error: \(error.localizedDescription)"
                            showError = true
                        }
                    }
                }
            }
            .sheet(isPresented: $showCamera) {
                ImagePicker(sourceType: .camera) { image in
                    selectedImage = image
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func savePhoto() {
        guard let image = selectedImage else { return }
        
        isUploading = true
        
        // Call the callback with the selected image
        onPhotoSelected(image)
        
        // Dismiss after a short delay to show upload state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isUploading = false
            dismiss()
        }
    }
}

// Camera/Gallery Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    let onImagePicked: (UIImage) -> Void
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImagePicked(image)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
