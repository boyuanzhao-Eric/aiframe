//
//  CameraView.swift
//  aicam
//
//  Created by Boyuan Zhao on 6/7/25.
//

import SwiftUI
import AVFoundation

struct CameraView: View {
    @Binding var selectedImage: UIImage?
    @Binding var isPresented: Bool
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showingSimulatorImagePicker = false
    
    var body: some View {
        NavigationView {
            VStack {
                #if targetEnvironment(simulator)
                // 模拟器专用界面
                VStack(spacing: 30) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("模拟器相机")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("在模拟器中无法访问真实相机\n点击下方按钮选择图片来模拟拍照")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    VStack(spacing: 15) {
                        // 选择图片按钮
                        Button(action: {
                            showingSimulatorImagePicker = true
                        }) {
                            HStack {
                                Image(systemName: "photo.fill")
                                    .font(.title2)
                                Text("选择图片模拟拍照")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.blue, Color.purple]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                            .shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 3)
                        }
                        
                        // 使用示例图片按钮
                        Button(action: {
                            generateSampleImage()
                        }) {
                            HStack {
                                Image(systemName: "wand.and.rays")
                                    .font(.title2)
                                Text("生成示例照片")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.green, Color.teal]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                            .shadow(color: .green.opacity(0.3), radius: 5, x: 0, y: 3)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding()
                #else
                // 真实设备上的相机界面
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    CameraPreview(selectedImage: $selectedImage, isPresented: $isPresented)
                } else {
                    VStack {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 100))
                            .foregroundColor(.gray)
                        Text("相机不可用")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text("请在真实设备上使用相机功能")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
                #endif
            }
            .navigationTitle("拍照")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        isPresented = false
                    }
                }
            }
        }
        .sheet(isPresented: $showingSimulatorImagePicker) {
            ImagePicker(selectedImage: $selectedImage, sourceType: .photoLibrary)
                .onDisappear {
                    if selectedImage != nil {
                        isPresented = false
                    }
                }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("错误"), message: Text(alertMessage), dismissButton: .default(Text("确定")))
        }
    }
    
    // 生成示例图片的函数
    private func generateSampleImage() {
        let size = CGSize(width: 400, height: 300)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let image = renderer.image { context in
            // 渐变背景
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                    colors: [UIColor.systemBlue.cgColor, UIColor.systemPurple.cgColor] as CFArray,
                                    locations: [0.0, 1.0])!
            
            context.cgContext.drawLinearGradient(gradient,
                                               start: CGPoint(x: 0, y: 0),
                                               end: CGPoint(x: size.width, y: size.height),
                                               options: [])
            
            // 添加文字
            let text = "模拟照片\n\(Date().formatted(.dateTime.hour().minute()))"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                .foregroundColor: UIColor.white,
                .strokeColor: UIColor.black,
                .strokeWidth: -2.0
            ]
            
            let attributedText = NSAttributedString(string: text, attributes: attributes)
            let textSize = attributedText.size()
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            
            attributedText.draw(in: textRect)
        }
        
        selectedImage = image
        isPresented = false
    }
}

struct CameraPreview: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var isPresented: Bool
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        picker.cameraDevice = .rear
        picker.cameraFlashMode = .auto
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> CameraCoordinator {
        CameraCoordinator(self)
    }
    
    class CameraCoordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPreview
        
        init(_ parent: CameraPreview) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.selectedImage = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.selectedImage = originalImage
            }
            
            parent.isPresented = false
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
    }
}

#Preview {
    CameraView(selectedImage: .constant(nil), isPresented: .constant(true))
} 