# PawPrint - Flutter App

AI-powered pet health monitoring application.

## 项目结构

```
lib/
├── main.dart                    # 应用入口
├── core/                        # 核心模块
│   ├── config/
│   │   └── app_config.dart      # 应用配置（Supabase URL/Key 等）
│   ├── theme/
│   │   └── app_theme.dart       # 主题、颜色、样式定义
│   ├── router/
│   │   └── app_router.dart      # 路由配置
│   ├── providers/
│   │   └── auth_provider.dart   # 认证相关 Provider
│   ├── models/
│   │   ├── enums.dart           # 枚举定义
│   │   ├── pet.dart             # 宠物相关模型
│   │   ├── health_record.dart   # 健康记录模型
│   │   ├── forum.dart           # 论坛相关模型
│   │   └── models.dart          # 统一导出
│   └── shell/
│       └── main_shell.dart      # 主框架（底部导航）
│
└── features/                    # 功能模块（按功能划分）
    ├── auth/                    # 认证模块
    │   └── presentation/
    │       └── pages/
    │           ├── login_page.dart
    │           └── register_page.dart
    │
    ├── onboarding/              # 引导流程
    │   └── presentation/
    │       └── pages/
    │           └── onboarding_page.dart
    │
    ├── home/                    # 首页
    │   └── presentation/
    │       └── pages/
    │           └── home_page.dart
    │
    ├── health_records/          # 健康记录
    │   └── presentation/
    │       └── pages/
    │           └── health_records_page.dart
    │
    ├── ai_analysis/             # AI 分析
    │   └── presentation/
    │       └── pages/
    │           └── ai_analysis_page.dart
    │
    ├── forum/                   # 论坛
    │   └── presentation/
    │       └── pages/
    │           └── forum_page.dart
    │
    ├── profile/                 # 个人中心
    │   └── presentation/
    │       └── pages/
    │           └── profile_page.dart
    │
    └── cards/                   # 卡牌系统
        └── presentation/
            └── pages/
                └── card_shop_page.dart
```

## 开始使用

### 1. 配置 Supabase

编辑 `lib/core/config/app_config.dart`，填入你的 Supabase 配置：

```dart
static const String supabaseUrl = 'https://your-project-ref.supabase.co';
static const String supabaseAnonKey = 'your-anon-key';
```

### 2. 安装依赖

```bash
cd flutter
flutter pub get
```

### 3. 运行应用

```bash
# iOS
flutter run -d ios

# Android
flutter run -d android

# 列出可用设备
flutter devices
```

### 4. 构建发布版本

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release
```

## 技术栈

- **状态管理**: Riverpod
- **路由**: GoRouter
- **后端**: Supabase (Auth, Database, Storage, Edge Functions)
- **本地存储**: Hive, SharedPreferences
- **UI**: Material Design 3 + 自定义主题

## 待完成功能

- [ ] 完善 Onboarding 流程（表单验证、图片上传）
- [ ] 实现健康记录的 CRUD 操作
- [ ] 实现 AI 分析功能（调用 Edge Function）
- [ ] 实现论坛功能（发帖、评论、点赞）
- [ ] 实现卡牌收集系统
- [ ] 添加推送通知
- [ ] 添加图表展示（fl_chart）
- [ ] 深色模式支持
- [ ] 国际化支持

## 架构说明

项目采用 **Feature-first** 架构：

```
features/
└── feature_name/
    ├── data/           # 数据层（Repository, DataSource）
    ├── domain/         # 领域层（Entity, UseCase）
    └── presentation/   # 表现层（Page, Widget, Provider）
```

当前版本为快速原型，主要包含 `presentation` 层。
后续可根据需要添加 `data` 和 `domain` 层实现更清晰的分层架构。
