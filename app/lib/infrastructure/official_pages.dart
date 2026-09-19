/// 官方页面白名单。播放层只允许导航到这些受信任域名。
///
/// 清单依据 2026-09-19 的真机域名观测结果确定（见
/// 《WebView-POC-白名单与隐私测试清单》第 6 节）。观测到官方电视页一次完整加载
/// 会访问 17 个主机，其中官方自有域两个；直播流本体位于 `ysp.cctv.cn`，
/// 只放 `yangshipin.cn` 会导致播放失败。
///
/// 清单分为官方自有域与登录所需的第三方域两组，见 [OfficialDomains]。
abstract final class OfficialDomains {
  /// 官方自有域（含其全部子域）。
  ///
  /// 刻意不登记观测到的第三方主机（`o.alicdn.com` 埋点、`mediadata.xuexi.cn:8443`
  /// 疑似链路注入）；缺少它们只影响埋点，不影响播放。
  ///
  /// 也刻意不登记 `cctv.cn` 全域：观测只支持 `ysp.cctv.cn`，放宽到全域没有依据。
  static const official = <String>[
    'yangshipin.cn',
    'ysp.cctv.cn',
  ];

  /// 官方登录流程依赖的第三方域（含其全部子域）。
  ///
  /// 依据 2026-09-19 真机观测：在官方登录弹窗内选择「微信登录」时，二维码页由
  /// `open.weixin.qq.com` 以 `window.open` **弹窗**方式打开；被白名单拦下时二维码
  /// 无法显示。
  ///
  /// 放行它可以拿到二维码，但**微信扫码登录在当前承载方案下走不通**：
  /// `webview_win_floating` 把所有弹窗折叠进主框架（`NewWindowRequested` 里
  /// `put_Handled(TRUE)` 后直接 `loadUrl`），于是二维码页顶掉了官方电视页，扫码后
  /// 回调页 `www.yangshipin.cn/ucenter/index.html` 停在「正在登录中...」。
  /// 已验证可用的登录路径是官方页面内的**短信登录**（页内弹层，不依赖弹窗）。
  ///
  /// 这是一处**有意的例外**：`open.weixin.qq.com` 不属于央视，登记它是为了在换用
  /// 支持真实弹窗的承载方案后能直接启用微信扫码。它不进入官方自有域清单，
  /// 便于审计时一眼区分。
  static const thirdPartyLogin = <String>[
    'open.weixin.qq.com',
  ];

  /// 白名单全集：判定时按标签边界匹配这些可注册域。
  static const trusted = <String>[...official, ...thirdPartyLogin];
}

abstract final class OfficialPages {
  /// 央视频官方电视页。已验证可展示 CCTV 与卫视频道及各频道节目单。
  static const tvHome = 'https://www.yangshipin.cn/tv/home';

  /// 单频道直达地址：官方电视页支持 `pid` 查询参数，打开即选中该频道。
  ///
  /// 依据 2026-09-19 观测：官方电视页自身的路由定义为
  /// `{path:'/tv/home', query:{pid}}`；实测 `?pid=600001811` 直达 CCTV13、
  /// `?pid=600002475` 直达湖南卫视，无需在页面内二次点击切换。
  ///
  /// [pid] 是官方公开地址中出现的频道标识，不是接口凭据，也不是媒体地址；
  /// 取值来自官方页面自身渲染出的频道列表，逐条登记在种子目录中。
  static String tvChannel(String pid) => '$tvHome?pid=$pid';
}
