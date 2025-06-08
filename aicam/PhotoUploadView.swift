//
//  PhotoUploadView.swift
//  aicam
//
//  Created by Boyuan Zhao on 6/7/25.
//

import SwiftUI
import PhotosUI

struct PhotoUploadView: View {
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingCameraView = false
    @State private var showingPhotoPicker = false
    @State private var showingSmartCamera = false
    @State private var imagePickerSourceType: UIImagePickerController.SourceType = .camera
    @Environment(\.presentationMode) var presentationMode
    
    // 图像分析相关状态
    @StateObject private var analysisService = ImageAnalysisService()
    @State private var personAnalysis: PersonAnalysis?
    @State private var faceAnalysis: FaceAnalysis?
    @State private var isAnalyzing = false
    @State private var analysisError: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 导航栏
                HStack {
                    Button("返回") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.blue)
                    .font(.headline)
                    
                    Spacer()
                    
                    Text("照片上传")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    // 占位符保持对称
                    Text("返回")
                        .foregroundColor(.clear)
                        .font(.headline)
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 显示选中的图片
                        if let selectedImage = selectedImage {
                            VStack {
                                Image(uiImage: selectedImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxHeight: 350)
                                    .cornerRadius(15)
                                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                                
                                // 图片信息
                                HStack {
                                    Text("尺寸: \(Int(selectedImage.size.width)) × \(Int(selectedImage.size.height))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                                .padding(.horizontal)
                            }
                        } else {
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(height: 350)
                                .cornerRadius(15)
                                .overlay(
                                    VStack(spacing: 15) {
                                        Image(systemName: "photo.artframe")
                                            .font(.system(size: 60))
                                            .foregroundColor(.gray)
                                        Text("选择或拍摄照片")
                                            .foregroundColor(.gray)
                                            .font(.headline)
                                        Text("点击下方按钮开始使用")
                                            .foregroundColor(.gray)
                                            .font(.subheadline)
                                    }
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [10]))
                                )
                                .padding(.horizontal)
                        }
                        
                        // 分析结果显示区域
                        if let selectedImage = selectedImage {
                            AnalysisResultView(
                                isAnalyzing: isAnalyzing,
                                personAnalysis: personAnalysis,
                                faceAnalysis: faceAnalysis,
                                analysisError: analysisError
                            )
                        }
                        
                        // 功能按钮
                        VStack(spacing: 15) {
                            // 拍照按钮
                            Button(action: {
                                showingCameraView = true
                            }) {
                                HStack {
                                    Image(systemName: "camera.fill")
                                        .font(.title2)
                                    Text("拍摄照片")
                                        .font(.headline)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                                .shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 3)
                            }
                            
                            // 从相册选择按钮
                            if #available(iOS 16.0, *) {
                                Button(action: {
                                    showingPhotoPicker = true
                                }) {
                                    HStack {
                                        Image(systemName: "photo.on.rectangle.angled")
                                            .font(.title2)
                                        Text("从相册选择")
                                            .font(.headline)
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 15)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.green, Color.green.opacity(0.8)]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(12)
                                    .shadow(color: .green.opacity(0.3), radius: 5, x: 0, y: 3)
                                }
                            } else {
                                Button(action: {
                                    imagePickerSourceType = .photoLibrary
                                    showingImagePicker = true
                                }) {
                                    HStack {
                                        Image(systemName: "photo.on.rectangle.angled")
                                            .font(.title2)
                                        Text("从相册选择")
                                            .font(.headline)
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 15)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.green, Color.green.opacity(0.8)]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(12)
                                    .shadow(color: .green.opacity(0.3), radius: 5, x: 0, y: 3)
                                }
                            }
                            
                            // 分析照片按钮
                            if selectedImage != nil {
                                Button(action: {
                                    analyzeSelectedImage()
                                }) {
                                    HStack {
                                        if isAnalyzing {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                                .foregroundColor(.white)
                                        } else {
                                            Image(systemName: "brain.head.profile")
                                                .font(.title2)
                                        }
                                        Text(isAnalyzing ? "分析中..." : "分析照片")
                                            .font(.headline)
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 15)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.purple, Color.purple.opacity(0.8)]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(12)
                                    .shadow(color: .purple.opacity(0.3), radius: 5, x: 0, y: 3)
                                }
                                .disabled(isAnalyzing)
                            }
                            
                            // 智能相机按钮（有分析结果时显示）
                            if personAnalysis != nil {
                                Button(action: {
                                    showingSmartCamera = true
                                }) {
                                    HStack {
                                        Image(systemName: "camera.metering.spot")
                                            .font(.title2)
                                        Text("智能相机")
                                            .font(.headline)
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 15)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.orange, Color.orange.opacity(0.8)]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(12)
                                    .shadow(color: .orange.opacity(0.3), radius: 5, x: 0, y: 3)
                                }
                            }
                            
                            // 清除按钮
                            if selectedImage != nil {
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        selectedImage = nil
                                        personAnalysis = nil
                                        faceAnalysis = nil
                                        analysisError = nil
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "trash.fill")
                                            .font(.title2)
                                        Text("清除照片")
                                            .font(.headline)
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 15)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.red, Color.red.opacity(0.8)]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(12)
                                    .shadow(color: .red.opacity(0.3), radius: 5, x: 0, y: 3)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .fullScreenCover(isPresented: $showingCameraView) {
            CameraView(selectedImage: $selectedImage, isPresented: $showingCameraView)
        }
        .fullScreenCover(isPresented: $showingSmartCamera) {
            SmartCameraView(
                referenceAnalysis: personAnalysis,
                isPresented: $showingSmartCamera
            )
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage, sourceType: imagePickerSourceType)
        }
        .modifier(ConditionalPhotosPickerModifier(showingPhotoPicker: $showingPhotoPicker, selectedImage: $selectedImage))
        .onChange(of: selectedImage) { newImage in
            if newImage != nil {
                // 图片变化时清除之前的分析结果
                personAnalysis = nil
                faceAnalysis = nil
                analysisError = nil
            }
        }
    }
    
    // MARK: - 分析图片
    private func analyzeSelectedImage() {
        guard let image = selectedImage else { return }
        
        isAnalyzing = true
        analysisError = nil
        
        analysisService.analyzeReferenceImage(image) { personResult, faceResult, error in
            withAnimation {
                isAnalyzing = false
                
                if let error = error {
                    analysisError = error.localizedDescription
                } else {
                    personAnalysis = personResult
                    faceAnalysis = faceResult
                    
                    // 分析成功后自动跳转到智能相机
                    if personResult != nil {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            showingSmartCamera = true
                        }
                    }
                }
            }
        }
    }
}

// MARK: - 分析结果显示组件
struct AnalysisResultView: View {
    let isAnalyzing: Bool
    let personAnalysis: PersonAnalysis?
    let faceAnalysis: FaceAnalysis?
    let analysisError: String?
    
    var body: some View {
        VStack(spacing: 15) {
            if isAnalyzing {
                VStack(spacing: 10) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("正在分析照片...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 20)
            } else if let error = analysisError {
                VStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title2)
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
            } else if let personAnalysis = personAnalysis {
                VStack(spacing: 15) {
                    // 标题
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(.purple)
                        Text("分析结果")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    
                    // 人体分析结果
                    VStack(alignment: .leading, spacing: 10) {
                        AnalysisItemView(
                            title: "人物位置",
                            value: personAnalysis.position.description,
                            icon: "location"
                        )
                        
                        AnalysisItemView(
                            title: "占画面比例",
                            value: "\(Int(personAnalysis.bodyRatio * 100))%",
                            icon: "rectangle.ratio.9.to.16"
                        )
                        
                        AnalysisItemView(
                            title: "拍摄角度",
                            value: personAnalysis.shootingAngle.description,
                            icon: "camera.rotate"
                        )
                        
                        AnalysisItemView(
                            title: "头身比例",
                            value: String(format: "%.2f", personAnalysis.headBodyRatio),
                            icon: "figure.stand"
                        )
                    }
                    
                    // 面部分析结果
                    if let faceAnalysis = faceAnalysis {
                        VStack(alignment: .leading, spacing: 10) {
                            Divider()
                            
                            AnalysisItemView(
                                title: "光线方向",
                                value: faceAnalysis.lightingDirection.description,
                                icon: "sun.max"
                            )
                            
                            HStack {
                                Image(systemName: "lightbulb")
                                    .foregroundColor(Color(faceAnalysis.lightingQuality.color))
                                Text("光线质量")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Spacer()
                                Text(faceAnalysis.lightingQuality.description)
                                    .font(.subheadline)
                                    .foregroundColor(Color(faceAnalysis.lightingQuality.color))
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
            }
        }
    }
}

struct AnalysisItemView: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundColor(.primary)
                .fontWeight(.semibold)
        }
    }
}

struct ConditionalPhotosPickerModifier: ViewModifier {
    @Binding var showingPhotoPicker: Bool
    @Binding var selectedImage: UIImage?
    
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content
                .photosPicker(isPresented: $showingPhotoPicker, selection: Binding<PhotosPickerItem?>(
                    get: { nil },
                    set: { item in
                        Task {
                            if let item = item,
                               let data = try? await item.loadTransferable(type: Data.self),
                               let image = UIImage(data: data) {
                                DispatchQueue.main.async {
                                    withAnimation(.easeInOut(duration: 0.5)) {
                                        selectedImage = image
                                    }
                                }
                            }
                        }
                    }
                ))
        } else {
            content
        }
    }
}

#Preview {
    PhotoUploadView()
} 