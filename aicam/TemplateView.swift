//
//  TemplateView.swift
//  aicam
//
//  Created by Boyuan Zhao on 6/7/25.
//

import SwiftUI

struct TemplateView: View {
    @Environment(\.presentationMode) var presentationMode
    
    let templates = [
        Template(id: 1, name: "经典人像", icon: "person.crop.rectangle", description: "专业人像拍摄模板", color: .blue),
        Template(id: 2, name: "风景摄影", icon: "mountain.2", description: "自然风光拍摄模板", color: .green),
        Template(id: 3, name: "食物拍摄", icon: "fork.knife", description: "美食摄影专用模板", color: .orange),
        Template(id: 4, name: "产品展示", icon: "cube.box", description: "商品展示拍摄模板", color: .purple),
        Template(id: 5, name: "黑白艺术", icon: "photo.artframe", description: "艺术黑白摄影模板", color: .gray),
        Template(id: 6, name: "街拍风格", icon: "building.2", description: "城市街拍摄影模板", color: .red)
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 导航栏
                HStack {
                    Button("关闭") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.blue)
                    .font(.headline)
                    
                    Spacer()
                    
                    Text("选择模板")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    // 占位符保持对称
                    Text("关闭")
                        .foregroundColor(.clear)
                        .font(.headline)
                }
                .padding(.horizontal)
                .padding(.vertical, 15)
                .background(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 15),
                        GridItem(.flexible(), spacing: 15)
                    ], spacing: 20) {
                        ForEach(templates) { template in
                            TemplateCard(template: template) {
                                // 处理模板选择
                                selectTemplate(template)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 25)
                }
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(.systemBackground),
                            Color.blue.opacity(0.02)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .navigationBarHidden(true)
    }
    
    private func selectTemplate(_ template: Template) {
        // 这里可以添加模板选择的逻辑
        print("选择了模板: \(template.name)")
        presentationMode.wrappedValue.dismiss()
    }
}

struct Template: Identifiable {
    let id: Int
    let name: String
    let icon: String
    let description: String
    let color: Color
}

struct TemplateCard: View {
    let template: Template
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 15) {
                // 图标区域
                ZStack {
                    Circle()
                        .fill(template.color.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: template.icon)
                        .font(.system(size: 25, weight: .medium))
                        .foregroundColor(template.color)
                }
                
                // 文字区域
                VStack(spacing: 5) {
                    Text(template.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(template.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 15)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: template.color.opacity(0.2), radius: 8, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(template.color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    TemplateView()
} 