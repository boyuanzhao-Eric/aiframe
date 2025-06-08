//
//  ImageAnalysisService.swift
//  aicam
//
//  Created by Boyuan Zhao on 6/7/25.
//

import UIKit
import Vision
import CoreML

// 人体分析结果数据结构
struct PersonAnalysis {
    let boundingBox: CGRect          // 人体边界框
    let bodyRatio: Float             // 人体占画面比例
    let position: PersonPosition     // 人体位置信息
    let shootingAngle: ShootingAngle // 拍摄角度
    let headBodyRatio: Float         // 头身比例
}

struct FaceAnalysis {
    let boundingBox: CGRect          // 面部边界框
    let shadowAreas: [CGRect]        // 阴影区域
    let lightingDirection: LightingDirection // 光线方向
    let lightingQuality: LightingQuality     // 光线质量
}

enum PersonPosition {
    case center, left, right, top, bottom
    case topLeft, topRight, bottomLeft, bottomRight
    
    var description: String {
        switch self {
        case .center: return "居中"
        case .left: return "偏左"
        case .right: return "偏右"
        case .top: return "偏上"
        case .bottom: return "偏下"
        case .topLeft: return "左上"
        case .topRight: return "右上"
        case .bottomLeft: return "左下"
        case .bottomRight: return "右下"
        }
    }
}

enum ShootingAngle {
    case overhead    // 俯拍
    case eyeLevel    // 平视
    case lowAngle    // 仰拍
    case unknown
    
    var description: String {
        switch self {
        case .overhead: return "俯拍角度"
        case .eyeLevel: return "平视角度"
        case .lowAngle: return "仰拍角度"
        case .unknown: return "角度未知"
        }
    }
}

enum LightingDirection {
    case front, back, left, right, top, bottom
    case frontLeft, frontRight, backLeft, backRight
    case unknown
    
    var description: String {
        switch self {
        case .front: return "正面光"
        case .back: return "背光"
        case .left: return "左侧光"
        case .right: return "右侧光"
        case .top: return "顶光"
        case .bottom: return "底光"
        case .frontLeft: return "左前侧光"
        case .frontRight: return "右前侧光"
        case .backLeft: return "左后侧光"
        case .backRight: return "右后侧光"
        case .unknown: return "光线方向未知"
        }
    }
}

enum LightingQuality {
    case excellent, good, fair, poor
    
    var description: String {
        switch self {
        case .excellent: return "光线优秀"
        case .good: return "光线良好"
        case .fair: return "光线一般"
        case .poor: return "光线较差"
        }
    }
    
    var color: UIColor {
        switch self {
        case .excellent: return .systemGreen
        case .good: return .systemBlue
        case .fair: return .systemOrange
        case .poor: return .systemRed
        }
    }
}

class ImageAnalysisService: ObservableObject {
    
    // MARK: - 分析参考照片
    func analyzeReferenceImage(_ image: UIImage, completion: @escaping (PersonAnalysis?, FaceAnalysis?, Error?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let personAnalysis = try self.detectPersonInImage(image)
                let faceAnalysis = try self.analyzeFaceInImage(image)
                
                DispatchQueue.main.async {
                    completion(personAnalysis, faceAnalysis, nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(nil, nil, error)
                }
            }
        }
    }
    
    // MARK: - 实时相机画面分析
    func analyzeRealtimeFrame(_ image: UIImage, referenceAnalysis: PersonAnalysis?, completion: @escaping (PersonAnalysis?, [String]) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let currentAnalysis = try self.detectPersonInImage(image)
                let suggestions = self.generateCameraSuggestions(current: currentAnalysis, reference: referenceAnalysis)
                
                DispatchQueue.main.async {
                    completion(currentAnalysis, suggestions)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(nil, ["人体检测失败"])
                }
            }
        }
    }
    
    // MARK: - 人体检测
    private func detectPersonInImage(_ image: UIImage) throws -> PersonAnalysis {
        guard let cgImage = image.cgImage else {
            throw AnalysisError.invalidImage
        }
        
        // 使用 Vision 框架进行人体检测
        let request = VNDetectHumanBodyPoseRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        try handler.perform([request])
        
        guard let results = request.results, !results.isEmpty else {
            throw AnalysisError.noPersonDetected
        }
        
        let observation = results[0]
        
        // 计算人体边界框 - 从关键点计算
        let boundingBox = calculateBoundingBoxFromPose(observation: observation)
        
        // 计算人体占画面比例
        let bodyRatio = Float(boundingBox.width * boundingBox.height)
        
        // 分析人体位置
        let position = determinePersonPosition(from: boundingBox)
        
        // 分析拍摄角度和头身比
        let (shootingAngle, headBodyRatio) = try analyzeBodyProportions(observation: observation)
        
        return PersonAnalysis(
            boundingBox: boundingBox,
            bodyRatio: bodyRatio,
            position: position,
            shootingAngle: shootingAngle,
            headBodyRatio: headBodyRatio
        )
    }
    
    // MARK: - 从姿态计算边界框
    private func calculateBoundingBoxFromPose(observation: VNHumanBodyPoseObservation) -> CGRect {
        guard let recognizedPoints = try? observation.recognizedPoints(.all) else {
            return CGRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5) // 默认值
        }
        
        // 获取所有有效的点
        let validPoints = recognizedPoints.values.compactMap { point -> CGPoint? in
            guard point.confidence > 0.3 else { return nil }
            return point.location
        }
        
        guard !validPoints.isEmpty else {
            return CGRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5) // 默认值
        }
        
        // 计算边界框
        let minX = validPoints.map { $0.x }.min() ?? 0.25
        let maxX = validPoints.map { $0.x }.max() ?? 0.75
        let minY = validPoints.map { $0.y }.min() ?? 0.25
        let maxY = validPoints.map { $0.y }.max() ?? 0.75
        
        // 扩展边界框以包含整个人体
        let padding: CGFloat = 0.1
        let expandedMinX = max(0, minX - padding)
        let expandedMinY = max(0, minY - padding)
        let expandedMaxX = min(1, maxX + padding)
        let expandedMaxY = min(1, maxY + padding)
        
        return CGRect(
            x: expandedMinX,
            y: expandedMinY,
            width: expandedMaxX - expandedMinX,
            height: expandedMaxY - expandedMinY
        )
    }
    
    // MARK: - 面部分析
    private func analyzeFaceInImage(_ image: UIImage) throws -> FaceAnalysis {
        guard let cgImage = image.cgImage else {
            throw AnalysisError.invalidImage
        }
        
        let faceRequest = VNDetectFaceRectanglesRequest()
        let landmarksRequest = VNDetectFaceLandmarksRequest()
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([faceRequest, landmarksRequest])
        
        guard let faceResults = faceRequest.results, !faceResults.isEmpty else {
            throw AnalysisError.noFaceDetected
        }
        
        let faceObservation = faceResults[0]
        let boundingBox = faceObservation.boundingBox
        
        // 分析面部阴影
        let shadowAreas = analyzeFaceShadows(in: image, faceBox: boundingBox)
        
        // 分析光线方向和质量
        let (lightingDirection, lightingQuality) = analyzeLighting(shadowAreas: shadowAreas, faceBox: boundingBox)
        
        return FaceAnalysis(
            boundingBox: boundingBox,
            shadowAreas: shadowAreas,
            lightingDirection: lightingDirection,
            lightingQuality: lightingQuality
        )
    }
    
    // MARK: - 位置分析
    private func determinePersonPosition(from boundingBox: CGRect) -> PersonPosition {
        let centerX = boundingBox.midX
        let centerY = boundingBox.midY
        
        let leftThreshold: CGFloat = 0.33
        let rightThreshold: CGFloat = 0.67
        let topThreshold: CGFloat = 0.33
        let bottomThreshold: CGFloat = 0.67
        
        if centerY < topThreshold {
            if centerX < leftThreshold {
                return .topLeft
            } else if centerX > rightThreshold {
                return .topRight
            } else {
                return .top
            }
        } else if centerY > bottomThreshold {
            if centerX < leftThreshold {
                return .bottomLeft
            } else if centerX > rightThreshold {
                return .bottomRight
            } else {
                return .bottom
            }
        } else {
            if centerX < leftThreshold {
                return .left
            } else if centerX > rightThreshold {
                return .right
            } else {
                return .center
            }
        }
    }
    
    // MARK: - 角度和比例分析
    private func analyzeBodyProportions(observation: VNHumanBodyPoseObservation) throws -> (ShootingAngle, Float) {
        // 获取关键点
        guard let recognizedPoints = try? observation.recognizedPoints(.all) else {
            return (.unknown, 1.0)
        }
        
        // 检测头部和身体关键点
        let headPoints = [
            recognizedPoints[.nose],
            recognizedPoints[.leftEye],
            recognizedPoints[.rightEye]
        ].compactMap { $0 }
        
        let bodyPoints = [
            recognizedPoints[.neck],
            recognizedPoints[.root]
        ].compactMap { $0 }
        
        guard !headPoints.isEmpty && !bodyPoints.isEmpty else {
            return (.unknown, 1.0)
        }
        
        // 计算头身比例
        let headY = headPoints.map { $0.location.y }.min() ?? 0
        let bodyY = bodyPoints.map { $0.location.y }.max() ?? 1
        let headBodyRatio = Float(abs(bodyY - headY))
        
        // 分析拍摄角度
        let shootingAngle = determineShootingAngle(headPoints: headPoints, bodyPoints: bodyPoints)
        
        return (shootingAngle, headBodyRatio)
    }
    
    private func determineShootingAngle(headPoints: [VNRecognizedPoint], bodyPoints: [VNRecognizedPoint]) -> ShootingAngle {
        // 简化的角度检测逻辑
        let avgHeadY = headPoints.map { Float($0.location.y) }.reduce(0, +) / Float(headPoints.count)
        let avgBodyY = bodyPoints.map { Float($0.location.y) }.reduce(0, +) / Float(bodyPoints.count)
        
        let yDifference = avgHeadY - avgBodyY
        
        if yDifference > 0.1 {
            return .overhead  // 俯拍
        } else if yDifference < -0.1 {
            return .lowAngle  // 仰拍
        } else {
            return .eyeLevel  // 平视
        }
    }
    
    // MARK: - 阴影分析
    private func analyzeFaceShadows(in image: UIImage, faceBox: CGRect) -> [CGRect] {
        // 简化的阴影检测算法
        // 实际实现中可以使用更复杂的图像处理算法
        var shadowAreas: [CGRect] = []
        
        // 模拟阴影检测结果
        shadowAreas.append(CGRect(
            x: faceBox.minX + 0.1,
            y: faceBox.minY + 0.2,
            width: faceBox.width * 0.3,
            height: faceBox.height * 0.4
        ))
        
        return shadowAreas
    }
    
    // MARK: - 光线分析
    private func analyzeLighting(shadowAreas: [CGRect], faceBox: CGRect) -> (LightingDirection, LightingQuality) {
        if shadowAreas.isEmpty {
            return (.front, .excellent)
        }
        
        // 简化的光线分析
        let shadowCenter = shadowAreas[0]
        let faceCenter = CGPoint(x: faceBox.midX, y: faceBox.midY)
        
        let deltaX = shadowCenter.midX - faceCenter.x
        let deltaY = shadowCenter.midY - faceCenter.y
        
        var direction: LightingDirection = .unknown
        
        if abs(deltaX) > abs(deltaY) {
            direction = deltaX > 0 ? .left : .right
        } else {
            direction = deltaY > 0 ? .top : .bottom
        }
        
        let shadowRatio = shadowAreas.reduce(0) { $0 + $1.width * $1.height } / (faceBox.width * faceBox.height)
        
        let quality: LightingQuality
        if shadowRatio < 0.1 {
            quality = .excellent
        } else if shadowRatio < 0.2 {
            quality = .good
        } else if shadowRatio < 0.4 {
            quality = .fair
        } else {
            quality = .poor
        }
        
        return (direction, quality)
    }
    
    // MARK: - 相机建议生成
    private func generateCameraSuggestions(current: PersonAnalysis?, reference: PersonAnalysis?) -> [String] {
        var suggestions: [String] = []
        
        guard let current = current else {
            suggestions.append("未检测到人体，请调整相机角度")
            return suggestions
        }
        
        if let reference = reference {
            // 比较当前画面与参考照片
            
            // 比例建议
            let ratioVifference = abs(current.bodyRatio - reference.bodyRatio)
            if ratioVifference > 0.1 {
                if current.bodyRatio < reference.bodyRatio {
                    suggestions.append("人物太小，请靠近一些或放大画面")
                } else {
                    suggestions.append("人物太大，请后退一些或缩小画面")
                }
            }
            
            // 位置建议
            if current.position != reference.position {
                suggestions.append("调整位置：目标位置为\(reference.position.description)，当前为\(current.position.description)")
            }
            
            // 角度建议
            if current.shootingAngle != reference.shootingAngle {
                suggestions.append("调整拍摄角度：目标角度为\(reference.shootingAngle.description)")
            }
            
        } else {
            // 通用建议
            suggestions.append("已检测到人体，位置：\(current.position.description)")
            suggestions.append("当前角度：\(current.shootingAngle.description)")
            suggestions.append("人体占比：\(Int(current.bodyRatio * 100))%")
        }
        
        if suggestions.isEmpty {
            suggestions.append("构图很好，可以拍摄了！")
        }
        
        return suggestions
    }
}

// MARK: - 错误定义
enum AnalysisError: Error, LocalizedError {
    case invalidImage
    case noPersonDetected
    case noFaceDetected
    case analysisFailure
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "无效的图片"
        case .noPersonDetected:
            return "未检测到人体"
        case .noFaceDetected:
            return "未检测到面部"
        case .analysisFailure:
            return "分析失败"
        }
    }
} 