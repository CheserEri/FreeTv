# YTV 央视频私人客户端

YTV 是一个面向个人使用的跨平台电视客户端规划项目。内容仅通过官方正常页面、账号和授权流程使用；不提供、不实现任何绕过登录、会员、DRM 或访问限制的能力。

当前阶段为 **Phase 1：合规技术验证与 MVP 设计**。官网公开电视页已验证可访问、可展示频道和节目单，并能在浏览器中播放。播放层采用浏览器媒体流水线，故 MVP 选择官方页面 WebView 承载，不把网页内部播放信息当作可复用接口。

## 文档导航

- [产品需求与范围](docs/02-需求分析/PRD-v0.1.md)
- [前端设计规范](docs/03-产品设计/前端设计规范-v0.1.md)
- [系统架构与服务契约](docs/04-系统设计/系统架构与服务契约-v0.1.md)
- [WebView POC 白名单与隐私测试清单](docs/06-测试/WebView-POC-白名单与隐私测试清单-v0.1.md)
- [实施路线与验收](docs/08-项目管理/实施路线与验收-v0.1.md)

## 工程与运行

Flutter 工程位于 `app/`。

```powershell
cd app
flutter analyze
flutter test
flutter run -d windows
```

当前环境限制：本机已装 Flutter 3.44.6（stable，Dart 3.12.2），但**未安装 Visual Studio 的「使用 C++ 的桌面开发」工作负载**，因此 `flutter run -d windows` 暂不可用。开发期可用 `flutter build web` / `flutter run -d chrome` 做界面验证，但 Web 结论不能替代 Windows 真机验收。

## 当前进度

Phase 1A 工程与视觉骨架已完成：主题令牌、路由、种子频道目录、首页/频道/收藏/设置/播放壳层页面、统一焦点表现、Esc 全局返回，以及 12 项自动化测试。

尚未开始：Phase 1B 官方 WebView 承载 POC（含 `OfficialWebPlaybackGateway`）、Phase 1C SQLite 本地闭环。

## 当前决策

| 决策 | 结论 |
|---|---|
| MVP 播放 | Flutter WebView 承载官方电视页 |
| 自定义 UI | 首页、频道导航、收藏、历史、设置由 YTV 实现 |
| 登录 | 仅通过官方页面完成；YTV 不读取、解析或上传凭据 |
| 服务端 | P0 不部署云端；以本地 Repository / Adapter 契约开发 |
| 原生播放器 | 仅在取得官方允许的稳定接入方式后另立 POC |

