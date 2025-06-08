//
//  SmartCameraView.swift
//  aicam
//
//  Created by Boyuan Zhao on 6/7/25.
//

import SwiftUI
import AVFoundation
import Combine

struct SmartCameraView: View {
    let referenceAnalysis: PersonAnalysis?
    @Binding var isPresented: Bool
    
    @StateObject private var cameraController = SmartCameraController()
    @StateObject private var analysisService = ImageAnalysisService()
    @State private var currentAnalysis: PersonAnalysis?
    @State private var suggestions: [String] = []
    @State private var capturedImage: UIImage?
    @State private var showingSaveAlert = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 顶部控制栏
                HStack {
                    Button("取消") {
                        isPresented = false
                    }
                    .foregroundColor(.white)
                    .font(.headline)
                    
                    Spacer()
                    
                    Text("智能相机")
                        .foregroundColor(.white)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button("设置") {
                        // 设置功能
                    }
                    .foregroundColor(.white)
                    .font(.headline)
                }
                .padding(.horizontal)
                .padding(.top, 10)
                .background(Color.black.opacity(0.3))
                
                // 相机预览区域
                ZStack {
                    // 相机预览
                    CameraPreviewView(controller: cameraController)
                        .clipped()
                    
                    // 实时分析覆盖层
                    AnalysisOverlayView(
                        currentAnalysis: currentAnalysis,
                        referenceAnalysis: referenceAnalysis
                    )
                    
                    // 网格线（可选）
                    GridOverlayView()
                        .opacity(0.3)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // 底部指导信息
                GuidanceBottomView(
                    suggestions: suggestions,
                    referenceAnalysis: referenceAnalysis,
                    onCapture: {
                        capturePhoto()
                    }
                )
            }
        }
        .onAppear {
            cameraController.startSession()
            startRealtimeAnalysis()
        }
        .onDisappear {
            cameraController.stopSession()
        }
        .alert("照片已保存", isPresented: $showingSaveAlert) {
            Button("确定") { }
        }
    }
    
    // MARK: - 实时分析
    private func startRealtimeAnalysis() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            guard let currentFrame = cameraController.getCurrentFrame() else { return }
            
            analysisService.analyzeRealtimeFrame(
                currentFrame,
                referenceAnalysis: referenceAnalysis
            ) { analysis, newSuggestions in
                DispatchQueue.main.async {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentAnalysis = analysis
                        suggestions = newSuggestions
                    }
                }
            }
        }
    }
    
    // MARK: - 拍照
    private func capturePhoto() {
        cameraController.capturePhoto { image in
            if let image = image {
                capturedImage = image
                // 保存到相册
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                showingSaveAlert = true
            }
        }
    }
}

// MARK: - 相机控制器
class SmartCameraController: ObservableObject {
    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var photoOutput: AVCapturePhotoOutput?
    private var currentVideoFrame: UIImage?
    
    func startSession() {
        setupCamera()
        captureSession?.startRunning()
    }
    
    func stopSession() {
        captureSession?.stopRunning()
    }
    
    func getCurrentFrame() -> UIImage? {
        return currentVideoFrame
    }
    
    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        guard let photoOutput = photoOutput else {
            completion(nil)
            return
        }
        
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: PhotoCaptureDelegate(completion: completion))
    }
    
    private func setupCamera() {
        #if targetEnvironment(simulator)
        // 模拟器模式
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.currentVideoFrame = self.generateSimulatorFrame()
        }
        #else
        // 真实设备相机设置
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .photo
        
        guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: backCamera)
            captureSession?.addInput(input)
            
            // 视频输出
            videoOutput = AVCaptureVideoDataOutput()
            videoOutput?.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: .userInteractive))
            captureSession?.addOutput(videoOutput!)
            
            // 照片输出
            photoOutput = AVCapturePhotoOutput()
            captureSession?.addOutput(photoOutput!)
            
        } catch {
            print("相机设置失败: \(error)")
        }
        #endif
    }
    
    #if targetEnvironment(simulator)
    private func generateSimulatorFrame() -> UIImage {
        let size = CGSize(width: 300, height: 400)
        UIGraphicsBeginImageContext(size)
        
        let context = UIGraphicsGetCurrentContext()!
        
        // 渐变背景
        let colors = [UIColor.blue.cgColor, UIColor.purple.cgColor]
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: nil)!
        context.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: size.width, y: size.height), options: [])
        
        // 模拟人形
        context.setFillColor(UIColor.white.withAlphaComponent(0.8).cgColor)
        let personRect = CGRect(x: size.width * 0.3, y: size.height * 0.2, width: size.width * 0.4, height: size.height * 0.6)
        context.fillEllipse(in: personRect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return image
    }
    #endif
}

#if !targetEnvironment(simulator)
extension SmartCameraController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        
        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
            DispatchQueue.main.async {
                self.currentVideoFrame = UIImage(cgImage: cgImage)
            }
        }
    }
}
#endif

// MARK: - 照片捕获代理
class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let completion: (UIImage?) -> Void
    
    init(completion: @escaping (UIImage?) -> Void) {
        self.completion = completion
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let imageData = photo.fileDataRepresentation(),
           let image = UIImage(data: imageData) {
            completion(image)
        } else {
            completion(nil)
        }
    }
}

// MARK: - 相机预览视图
struct CameraPreviewView: UIViewRepresentable {
    let controller: SmartCameraController
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        
        #if !targetEnvironment(simulator)
        if let captureSession = controller.captureSession {
            let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.frame = view.bounds
            view.layer.addSublayer(previewLayer)
        }
        #else
        // 模拟器显示
        let label = UILabel()
        label.text = "相机预览 (模拟器)"
        label.textColor = .white
        label.textAlignment = .center
        label.frame = view.bounds
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(label)
        #endif
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        #if !targetEnvironment(simulator)
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = uiView.bounds
        }
        #endif
    }
}

// MARK: - 分析覆盖层
struct AnalysisOverlayView: View {
    let currentAnalysis: PersonAnalysis?
    let referenceAnalysis: PersonAnalysis?
    
    var body: some View {
        ZStack {
            if let current = currentAnalysis {
                // 人体边界框
                Rectangle()
                    .stroke(strokeColor, lineWidth: 3)
                    .frame(
                        width: current.boundingBox.width * UIScreen.main.bounds.width,
                        height: current.boundingBox.height * UIScreen.main.bounds.height
                    )
                    .position(
                        x: current.boundingBox.midX * UIScreen.main.bounds.width,
                        y: current.boundingBox.midY * UIScreen.main.bounds.height
                    )
                
                // 位置指示器
                VStack {
                    HStack {
                        if current.position == .center {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "location.circle")
                                .foregroundColor(.orange)
                        }
                        Text(current.position.description)
                            .foregroundColor(.white)
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(8)
                    
                    Spacer()
                }
                .padding(.top, 100)
            }
        }
    }
    
    private var strokeColor: Color {
        guard let current = currentAnalysis,
              let reference = referenceAnalysis else {
            return .yellow
        }
        
        let ratioMatch = abs(current.bodyRatio - reference.bodyRatio) < 0.1
        let positionMatch = current.position == reference.position
        let angleMatch = current.shootingAngle == reference.shootingAngle
        
        if ratioMatch && positionMatch && angleMatch {
            return .green
        } else if ratioMatch || positionMatch {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - 网格覆盖层
struct GridOverlayView: View {
    var body: some View {
        ZStack {
            // 垂直线
            VStack {
                Spacer()
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.white)
                Spacer()
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.white)
                Spacer()
            }
            
            // 水平线
            HStack {
                Spacer()
                Rectangle()
                    .frame(width: 1)
                    .foregroundColor(.white)
                Spacer()
                Rectangle()
                    .frame(width: 1)
                    .foregroundColor(.white)
                Spacer()
            }
        }
    }
}

// MARK: - 底部指导视图
struct GuidanceBottomView: View {
    let suggestions: [String]
    let referenceAnalysis: PersonAnalysis?
    let onCapture: () -> Void
    
    var body: some View {
        VStack(spacing: 15) {
            // 指导信息
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(suggestions, id: \.self) { suggestion in
                        Text(suggestion)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.8))
                            .cornerRadius(15)
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: suggestions.isEmpty ? 0 : 30)
            
            // 参考信息
            if let reference = referenceAnalysis {
                HStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text("目标位置")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.8))
                        Text(reference.position.description)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    
                    VStack(spacing: 4) {
                        Text("目标比例")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.8))
                        Text("\(Int(reference.bodyRatio * 100))%")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    
                    VStack(spacing: 4) {
                        Text("目标角度")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.8))
                        Text(reference.shootingAngle.description)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal)
            }
            
            // 拍照按钮
            Button(action: onCapture) {
                Circle()
                    .stroke(Color.white, lineWidth: 4)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Circle()
                            .fill(Color.white)
                            .frame(width: 65, height: 65)
                    )
            }
            .padding(.bottom, 30)
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.8)]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

#Preview {
    SmartCameraView(
        referenceAnalysis: PersonAnalysis(
            boundingBox: CGRect(x: 0.3, y: 0.2, width: 0.4, height: 0.6),
            bodyRatio: 0.24,
            position: .center,
            shootingAngle: .eyeLevel,
            headBodyRatio: 0.15
        ),
        isPresented: .constant(true)
    )
} 