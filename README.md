# AI智能摄影助手 (AI Frame)

一个基于人工智能的智能摄影助手应用，帮助用户通过分析参考照片来获得专业的拍摄指导。

## 🎯 功能特色

- **📸 参考照片分析**：上传参考照片，AI自动分析人物位置、拍摄角度、画面比例等构图要素
- **🎥 实时智能相机**：基于分析结果提供实时拍摄指导，包括位置调整、距离建议等
- **👤 人体检测**：精确识别人体轮廓，计算头身比例和画面占比
- **😊 面部分析**：检测面部特征，分析光线方向和质量
- **📐 角度识别**：智能判断拍摄角度（俯拍、平视、仰拍）
- **🎨 视觉指导**：实时覆盖层显示拍摄建议和构图辅助线

## 🛠 技术架构

### iOS版本
- **开发语言**：Swift
- **UI框架**：SwiftUI
- **AI框架**：Vision Framework
- **相机功能**：AVFoundation
- **图像处理**：Core Image

### 网页版本
- **前端技术**：HTML5, CSS3, JavaScript
- **AI库**：TensorFlow.js, PoseNet
- **相机API**：WebRTC (getUserMedia)
- **实时处理**：Canvas API

## 📱 支持平台

- **iOS**：iOS 15.0+ (iPhone/iPad)
- **Web**：现代浏览器（Chrome, Safari, Firefox, Edge）

## 🚀 快速开始

### iOS版本

1. 克隆项目：
```bash
git clone https://github.com/boyuanzhao-Eric/aiframe.git
cd aiframe
```

2. 在Xcode中打开项目：
```bash
open aicam.xcodeproj
```

3. 选择目标设备并运行

### 网页版本

1. 启动本地服务器：
```bash
cd web-version
python3 -m http.server 8081
```

2. 在浏览器中访问：
```
http://localhost:8081/index.html
```

## 📋 使用指南

### 基本流程

1. **上传参考照片**：选择或拍摄一张希望模仿的参考照片
2. **AI分析**：系统自动分析照片中的人物构图要素
3. **智能拍摄**：使用智能相机功能，根据AI指导调整拍摄参数
4. **实时反馈**：获得位置、距离、角度等实时拍摄建议

### 分析指标

- **人物位置**：左上、居中、右下等九宫格位置
- **画面比例**：人物在画面中的占比百分比
- **拍摄角度**：俯拍、平视、仰拍角度识别
- **头身比例**：人物头部与身体的比例关系
- **光线分析**：面部光线方向和质量评估

## 🎨 界面预览

### iOS版本
- 现代化SwiftUI设计
- 渐变色彩搭配
- 流畅的动画效果
- 直观的操作界面

### 网页版本
- 响应式设计
- 实时视频覆盖层
- 可视化分析结果
- 移动端适配

## 🔧 开发环境

### iOS版本要求
- Xcode 15.0+
- iOS 15.0+
- Swift 5.0+

### 网页版本要求
- 现代浏览器
- 支持WebRTC
- 支持Canvas API

## 📄 项目结构

```
aiframe/
├── aicam/                    # iOS源代码
│   ├── aicamApp.swift       # 应用入口
│   ├── ContentView.swift    # 主界面
│   ├── HomeView.swift       # 首页
│   ├── PhotoUploadView.swift # 照片上传界面
│   ├── SmartCameraView.swift # 智能相机界面
│   ├── ImageAnalysisService.swift # 图像分析服务
│   └── ...
├── web-version/             # 网页版本
│   ├── index.html          # 主页面
│   └── debug.html          # 调试页面
├── aicam.xcodeproj/        # Xcode项目文件
└── README.md               # 项目说明
```

## 🤝 贡献指南

欢迎提交Issue和Pull Request来改进项目！

## 📝 许可证

此项目仅供学习和研究使用。

## 👨‍💻 作者

**Boyuan Zhao** - [boyuanzhao-Eric](https://github.com/boyuanzhao-Eric)

---

💡 **提示**：这是一个演示项目，展示了AI在摄影辅助领域的应用潜力。 