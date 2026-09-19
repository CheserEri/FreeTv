# WebView POC 白名单与隐私测试清单 v0.1

**对应任务：** 实施路线 Phase 1A「为 WebView POC 编写白名单和隐私测试清单」
**适用范围：** Phase 1B `OfficialWebPlaybackGateway` 的准入验证
**结论口径：** 任一项不通过即视为闸门未过，按《实施路线与验收》风险闸门处置，不降级为“已知问题”放行。

## 1. 白名单

### 1.1 允许清单（2026-09-19 观测后确定）

以**可注册域**为登记单位，允许该域本身及其任意深度子域。

| 可注册域 | 用途 | 依据 |
|---|---|---|
| `yangshipin.cn` | 官方电视页主文档、静态资源、播放器与接口 | 观测到 13 个子域承载页面与播放链路 |
| `ysp.cctv.cn` | 直播流本体（`*.m3u8` / `*.ts`）与官方上报 | 观测到 `hlsliveali-cdn.ysp.cctv.cn`、`pcsite.ysp.cctv.cn` |

判定规则：

1. **标签边界匹配**：主机名等于白名单域，或以 `.白名单域` 结尾。不做无边界子串匹配；
2. **仅 HTTPS，仅 443**；
3. 不使用通配符放宽，不登记 `cctv.cn` 等更大范围；
4. 每个新增域必须记录：域名、用途、观察到它的请求、审核结论；
5. 非官方第三方域名一律拒绝，即使页面因缺少它而降级；
6. 白名单以独立常量维护，播放层不得接受来自频道数据或网页的任意跳转目标。

**观测到但刻意不放行的主机**：`o.alicdn.com`（阿里 QuickTracking 埋点，缺失只影响埋点）、
`mediadata.xuexi.cn:8443`（与央视无关且使用非 443 端口，疑似链路注入）。

### 1.2 验证项

| 编号 | 检查项 | 通过标准 |
|---|---|---|
| W-1 | 导航拦截 | 目标不在白名单时被拒绝，且不发起请求 |
| W-2 | 事后检测 + 退回 | 白名单内放行、播放；跳往白名单外被记录并退回官方入口；连续越界停止加载进入受限态 |
| W-3 | 不适用（插件能力边界） | 不约束子资源；数据边界（P-1 至 P-10）兜底，17 主机观测结果留档作为残留风险证据 |
| W-4 | 新窗口 / target=_blank | 不打开系统浏览器任意页面；白名单外一律拒绝 |
| W-5 | 协议限制 | 仅允许 HTTPS，拒绝 `http:`、`file:`、`javascript:`、`data:` 导航 |
| W-6 | 域名相似性 | `evil-yangshipin.cn`、`yangshipin.cn.evil.com` 等被拒绝（做标签边界匹配，非子串匹配） |

> **W-2 / W-3 判定口径（2026-09-19 决策）。** 依据是插件能力边界（见 6.2）：重定向与 POST 导航在
> `NavigationStarting` 被直接放行、子资源请求完全不经过 Dart 侧。因此：
> - **W-2 改为「事后检测 + 退回」**：`onPageStarted` 检测到顶层导航离开白名单时，记录证据并
>   `loadRequest` 退回官方入口；反复越界则 `PlaybackRestricted` 停止加载。**不保证事前拦截。**
> - **W-3 判为「不适用」**：原始标准「仅白名单域名的请求成功」在当前承载下无法满足，
>   改由「不导出 Cookie/Token/DOM/媒体地址」的数据边界兜底。

## 2. 隐私与数据边界

### 2.1 禁止项（任一出现即失败）

| 编号 | 禁止行为 |
|---|---|
| P-1 | 读取、导出或上传 Cookie、Token、认证头 |
| P-2 | 注入 JS 读取网页正文、DOM 内容或页面状态用于业务逻辑 |
| P-3 | 从网页中提取媒体流地址，或将其交给第三方播放器 |
| P-4 | 记录 URL 查询参数、认证信息、网页正文、媒体链路到日志或本地库 |
| P-5 | 开启任意 JS bridge 或暴露宿主能力给网页 |
| P-6 | 代理、缓存、转发官方接口请求或媒体内容 |
| P-7 | 在官方登录、授权、版权提示之上叠加可能遮挡它们的控件 |

### 2.2 允许项

| 编号 | 允许行为 |
|---|---|
| A-1 | 在官方页面内由用户自行完成登录与授权 |
| A-2 | 白名单内的单向状态通知（无敏感参数），且需逐项评审 |
| A-3 | 本地仅保存应用偏好、频道 ID、打开时间 |

### 2.3 验证项

| 编号 | 检查项 | 通过标准 |
|---|---|---|
| P-8 | 日志审查 | 打开并播放一个频道后，日志中无参数、Cookie、Token、媒体地址 |
| P-9 | 本地库审查 | 数据库内只有偏好、频道 ID、时间戳；无凭据与流地址 |
| P-10 | 状态通道审查 | 应用其他层无法从 Gateway 拿到 Cookie / DOM / 媒体 URL |
| P-11 | 清除能力 | 清除历史后本地库对应记录确实删除 |
| P-12 | 关闭释放 | 关闭播放页后 WebView 被释放，无残留会话与后台请求 |

## 3. 稳定性闸门

| 编号 | 检查项 | 通过标准 |
|---|---|---|
| S-1 | 连续播放 | Windows 上连续播放 30 分钟无崩溃、无卡死 |
| S-2 | 加载失败 | 页面加载失败时不白屏，显示可恢复的错误态与重试 |
| S-3 | 网络中断 | 断网时给出可理解提示；恢复后能重试成功 |
| S-4 | 需登录态 | 未登录/登录过期时显示“需在官方页面登录”，不尝试替代登录 |
| S-5 | 受限内容 | 会员/地区受限内容显示受限说明，不承诺可播放 |
| S-6 | 全屏与返回 | 全屏切换、Esc 返回、返回后释放资源均正常 |

## 4. 执行方式

1. 在 Windows 真机（已装 Visual Studio C++ 工具链）构建运行，不使用 Web 构建结论代替；
2. 抓包观察实际请求域名，据此逐项补充白名单并记录；
3. 每项结论需附证据：截图、抓包记录或日志片段；
4. 结果记入《实施路线与验收》风险闸门表，未通过项明确写为限制。

## 5. 执行结果（2026-09-18，Windows 真机）

**环境：** Windows 10 22H2 (19045.7663) / Flutter 3.44.6 / WebView2 Runtime 153.0.4234.32 /
VS 2022 生成工具 17.14.41（MSVC 14.44.35207 + Windows SDK 10.0.26100.0）/
承载实现 `webview_win_floating` 3.0.3（WebView2 后端）。

**证据来源：**

| 类型 | 位置 |
|---|---|
| 白名单单元测试（9 项） | `app/test/phase1b_url_policy_test.dart` |
| 真机集成测试 | `app/integration_test/playback_poc_test.dart` |
| 进程计数观测 | `msedgewebview2.exe` 进程总数，基线 13 |
| 截图 | 真机运行截图（首页 / 播放页 / Esc 后），未入库 |

**结论口径：** 任一项「未通过」即视为闸门未过，不降级为「已知问题」放行。

### 5.1 白名单

| 编号 | 结论 | 证据与说明 |
|---|---|---|
| W-1 | 通过 | 入口地址在 `open()` 内先经 `OfficialUrlPolicy.check`，未通过则不调用 `loadRequest`；用户发起的导航由 `onNavigationRequest` 判定。单测覆盖 `null`、空串、相对路径、无主机名。 |
| W-2 | **通过（事后检测模式，2026-09-19 决策）** | 插件对重定向/POST 直接放行（`my_webview.cpp:206-237`），无法事前拦截。已按新口径在 `onPageStarted` 做事后检测并退回官方入口；单次打开最多退回 2 次，超限进入 `PlaybackRestricted`。非网络导航（`about:blank` 等）不误判。 |
| W-3 | **不适用（插件能力边界，2026-09-19 决策）** | 插件未注册 `WebResourceRequested`，子资源不经过白名单。风险由数据边界（P-1~P-10，不导出 Cookie/Token/DOM/媒体地址）兜底，17 主机观测结果在本文档第 6 节留档。 |
| W-4 | 通过 | `add_NewWindowRequested` 已接管并置 `Handled(TRUE)`，不打开系统浏览器；白名单外由 Dart 侧 `prevent`。 |
| W-5 | 通过 | 仅允许 `https`；`http`/`file`/`javascript`/`data`/`about`/`ftp` 一律拒绝，单测覆盖。 |
| W-6 | 通过 | 标签边界匹配（等于白名单域或以 `.白名单域` 结尾）+ 小写归一化 + 去 FQDN 末尾点；`evil-yangshipin.cn`、`notyangshipin.cn`、`yangshipin.cn.evil.com`、`cctv.cn`、`o.alicdn.com`、`mediadata.xuexi.cn:8443` 均拒绝，单测覆盖。 |

### 5.2 隐私与数据边界

| 编号 | 结论 | 证据与说明 |
|---|---|---|
| P-1 | 通过（设计） | 未调用任何 Cookie 读取 API，Cookie 不进入应用层。 |
| P-2 | 通过（设计） | 未调用 `runJavaScript`、未注册 JS channel、未注入 UserScript。 |
| P-3 | 通过（设计） | 不解析、不提取媒体地址。 |
| P-4 | 通过（设计） | 对外只暴露主机名；判定结果不含路径与查询参数（单测覆盖）。 |
| P-5 | 通过（设计） | 无 JS bridge。 |
| P-6 | 通过（设计） | 无代理、无缓存转发。 |
| P-7 | 通过（设计） | 状态视图仅在官方页面未就绪时覆盖，就绪后隐藏；顶部栏位于 WebView 区域之外。 |
| P-8 | 待人工审查 | 需人工核对运行日志。 |
| P-9 | 不适用（Phase 1C） | 本地库尚未引入。 |
| P-10 | 通过（设计） | Gateway 只暴露 `PlaybackState`、被拦截主机名、全屏标记。 |
| P-11 | 不适用（Phase 1C） | 清除历史待本地库落地后验证。 |
| P-12 | 通过 | 进程计数：基线 13 → 进入播放页 20（+7）→ Esc 返回后回到 13，且此时 `ytv.exe` 仍存活，说明 WebView 已释放而非进程退出。 |

### 5.3 稳定性

| 编号 | 结论 | 证据与说明 |
|---|---|---|
| S-1 | 未执行 | 需连续播放 30 分钟，尚未做长稳测试。 |
| S-2 | 通过 | 真机集成测试加载 20 秒无异常；未就绪时由状态视图覆盖，不出现白屏。 |
| S-3 | 未执行 | 需断网与恢复场景。 |
| S-4 | **无法检测（限制）** | 官方登录弹窗由官方页面自行弹出（真机截图可见「短信登录」）；YTV 不读取页面状态，故无法判定登录态，`PlaybackNeedsOfficialLogin` 当前不会被发出。要检测必须读取 DOM，与 P-2 冲突。 |
| S-5 | 未执行 | 需会员 / 地区受限样本。 |
| S-6 | 通过 | Esc 返回首页；返回后 WebView 释放；应用进程存活。 |

### 5.4 待决策事项

1. ~~**W-2 / W-3 的判定口径。**~~ **已决策（2026-09-19）**：降级为「导航级白名单 + 事后检测」，
   W-3 判为不适用，详见 1.2 口径说明。
2. ~~**白名单粒度。**~~ **已决策（2026-09-19）**：以可注册域为登记单位（`yangshipin.cn`、`ysp.cctv.cn`），
   按标签边界匹配，详见 1.1。
3. **S-4 的登录态信号。** 仍需决策：是否需要在不违反 P-2 的前提下引入信号
   （例如仅依据白名单内 URL 路径判定，不读取 DOM、不记录参数）。当前 `PlaybackNeedsOfficialLogin`
   不会被发出，播放页不区分「未登录」与「已登录」。

## 6. 域名观测结果（2026-09-19，Windows 真机）

**方法。** 以 `WEBVIEW2_ADDITIONAL_BROWSER_ARGUMENTS=--remote-debugging-port=9222 --remote-allow-origins=*`
启动集成测试，用 CDP（`Network.enable` + `Page.reload`）采集官方电视页 `https://www.yangshipin.cn/tv/home`
一次完整加载的全部网络请求，按 `协议//主机` 聚合。脚本位于临时目录，不入库。

**观测到 17 个主机。**

| 主机 | 请求数 | 类型 | 归属与用途 |
|---|---|---|---|
| `www.yangshipin.cn` | 246 | Document / Script / Stylesheet / XHR | 官方电视页主文档与自身静态资源 |
| `resources.yangshipin.cn` | 144 | Image | 频道台标、节目海报 |
| `sapi.yangshipin.cn` | 90 | Document / Script / Stylesheet / Fetch | 登录组件（`ysp_account/yspLogin.*`）、WASM 播放内核（`hls.cmg.js`） |
| `img.yangshipin.cn` | 24 | Image | 页面图标 |
| `hlsliveali-cdn.ysp.cctv.cn` | 24 | XHR | **直播流本体**（`*.m3u8` 与 `*.ts` 分片） |
| `btrace.yangshipin.cn` | 21 | XHR | 官方埋点上报 |
| `s.yangshipin.cn` | 20 | Script / Fetch | 官方播放器与埋点 SDK |
| `aatc-api.yangshipin.cn` | 20 | XHR / Preflight | 官方埋点上报 |
| `m.yangshipin.cn` | 13 | Script / Stylesheet | 官方播放器资源（VR 组件） |
| `mediadata.xuexi.cn:8443` | 10 | Script / Ping | **第三方，非央视域，且使用非 443 端口**（`pbe.js` / `rcfg.js` / `v.gif`） |
| `capi.yangshipin.cn` | 8 | XHR | 官方内容接口 |
| `player-api.yangshipin.cn` | 8 | XHR / Preflight | 官方播放鉴权（`/v1/player/auth`） |
| `csapi.yangshipin.cn` | 6 | XHR | 官方时间同步 |
| `h5access.yangshipin.cn` | 4 | Fetch | 官方 H5 访问票据 |
| `o.alicdn.com` | 3 | Script | 第三方，阿里 QuickTracking 埋点 SDK |
| `wimg.yangshipin.cn` | 2 | Image | 官方图片 |
| `pcsite.ysp.cctv.cn` | 2 | Fetch | 官方埋点上报（`cctv.cn` 域） |

### 6.1 由观测得到的事实

1. **播放链路跨两个可注册域。** 直播流与部分官方上报在 `ysp.cctv.cn`，其余在 `yangshipin.cn`。
   若白名单只放 `yangshipin.cn`，播放本身会失败。
2. **单靠 `www.yangshipin.cn` 远远不够。** 实际用到 `yangshipin.cn` 下 13 个不同子域。
3. **出现非 443 端口的第三方请求。** `mediadata.xuexi.cn:8443` 与央视无关，
   路径形如 `/pbe.js`、`/rcfg.js`、`/v.gif`（配置脚本 + 打点像素），
   疑似本地网络链路注入或本机软件注入，非官方页面自身声明。该主机被现有策略的
   `unexpectedPort` 与 `untrustedHost` 双重拒绝，属预期行为；同时说明**链路注入真实存在**。
4. **存在第三方埋点。** `o.alicdn.com`（阿里 QuickTracking）。缺少它只会导致埋点失效，不影响播放。
5. **主框架导航只有一个。** 采集期内 `Document` 类型仅 `www.yangshipin.cn/tv/home` 与
   `sapi.yangshipin.cn`（登录组件 iframe），未观察到跨域顶层跳转。

### 6.2 观测结论对闸门的含义

- W-3（子资源白名单）在观测上被证实**不可能用现有插件实现**：一次页面加载涉及 17 个主机，
  插件未注册 `WebResourceRequested`，全部子资源请求不经过任何 Dart 侧判定。
- W-2（重定向跟随）的**实际暴露面小于预期**：本次未观测到跨域顶层重定向。
  登录流程会引入新页面，但尚未观测（需要真实登录）。
- 因此「导航级白名单」足以覆盖**顶层跳转**风险，子资源风险只能靠「不导出 Cookie/Token/DOM」约束兜底。
