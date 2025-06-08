//
//  HomeView.swift
//  aicam
//
//  Created by Boyuan Zhao on 6/7/25.
//

import SwiftUI

struct HomeView: View {
    @State private var showingPhotoUpload = false
    @State private var showingTemplates = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Logo 区域 - 中上方
                VStack(spacing: 20) {
                    Spacer()
                    
                    // Logo 占位符 - 可以后续替换为实际logo图片
                    VStack(spacing: 15) {
                        // 主Logo图标
                        Image(systemName: "camera.aperture")
                            .font(.system(size: 80, weight: .light))
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [.blue, .purple]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        // 应用名称
                        Text("AI 相机")
                            .font(.system(size: 32, weight: .light, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [.primary, .secondary]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        // 副标题
                        Text("智能图像处理工具")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                }
                .frame(maxHeight: .infinity)
                
                // 按钮区域 - 下方
                VStack(spacing: 20) {
                    // 自行提供照片按钮
                    Button(action: {
                        showingPhotoUpload = true
                    }) {
                        HStack(spacing: 15) {
                            Image(systemName: "photo.fill.on.rectangle.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("自行提供照片")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text("上传或拍摄您的照片")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "arrow.right")
                                .font(.title3)
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 25)
                        .padding(.vertical, 20)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.blue,
                                    Color.blue.opacity(0.8)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // 已有模板按钮
                    Button(action: {
                        showingTemplates = true
                    }) {
                        HStack(spacing: 15) {
                            Image(systemName: "rectangle.grid.3x2.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("已有模板")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text("从预设模板开始创作")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "arrow.right")
                                .font(.title3)
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 25)
                        .padding(.vertical, 20)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.purple,
                                    Color.purple.opacity(0.8)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // 底部间距
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 40)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 50)
            }
            .background(
                // 背景渐变
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(.systemBackground), location: 0.0),
                        .init(color: Color.blue.opacity(0.05), location: 0.5),
                        .init(color: Color.purple.opacity(0.05), location: 1.0)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showingPhotoUpload) {
            PhotoUploadView()
        }
        .sheet(isPresented: $showingTemplates) {
            TemplateView()
        }
    }
}

#Preview {
    HomeView()
} 