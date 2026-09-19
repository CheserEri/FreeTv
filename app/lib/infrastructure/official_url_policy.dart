import 'package:flutter/foundation.dart';

import 'official_pages.dart';

/// 白名单判定结果的原因。
enum UrlPolicyReason {
  /// 允许导航。
  allowed,

  /// 无法解析为合法 URI，或根本没有主机名。
  malformed,

  /// 协议不是 HTTPS（拒绝 `http:`、`file:`、`javascript:`、`data:` 等）。
  unsupportedScheme,

  /// 主机名不在官方白名单内。
  untrustedHost,

  /// 使用了非默认 HTTPS 端口。
  unexpectedPort,
}

/// 白名单判定结果。
@immutable
class UrlPolicyDecision {
  const UrlPolicyDecision(this.reason, this.host);

  final UrlPolicyReason reason;

  /// 仅保留主机名，不含路径与查询参数，避免把参数写进日志或界面。
  final String? host;

  bool get allowed => reason == UrlPolicyReason.allowed;
}

/// 官方页面地址白名单判定。
///
/// 规则对应《WebView POC 白名单与隐私测试清单》：
/// - 只允许 HTTPS，其余协议一律拒绝（W-5）；
/// - 主机名必须落在白名单可注册域的**标签边界**上，即等于该域或以 `.该域` 结尾（W-6）；
/// - 只允许默认 HTTPS 端口（W-5）。
///
/// 采用可注册域后缀匹配而非精确主机名，依据是真机域名观测：
/// 官方电视页一次加载涉及 `yangshipin.cn` 下 13 个子域，逐项登记会随官方
/// 调整 CDN 而静默失效。放宽仅限「标签边界」，不接受 `cctv.cn` 这类全域泛化。
///
/// 本类不接触网页内容、Cookie 或网络请求，只对一段字符串做判定，
/// 因此可以在不联网的情况下完整验证。
abstract final class OfficialUrlPolicy {
  static const _allowedSchemes = <String>{'https'};
  static const _allowedPorts = <int>{443};

  /// 判定 [url] 是否允许在官方播放承载中导航。
  static UrlPolicyDecision check(String? url) {
    if (url == null || url.isEmpty) {
      return const UrlPolicyDecision(UrlPolicyReason.malformed, null);
    }

    final Uri uri;
    try {
      uri = Uri.parse(url);
    } on FormatException {
      return const UrlPolicyDecision(UrlPolicyReason.malformed, null);
    }

    final host = _normalizeHost(uri.host);

    if (!_allowedSchemes.contains(uri.scheme.toLowerCase())) {
      return UrlPolicyDecision(UrlPolicyReason.unsupportedScheme, host);
    }
    if (host == null || !_isTrustedHost(host)) {
      return UrlPolicyDecision(UrlPolicyReason.untrustedHost, host);
    }
    if (uri.hasPort && !_allowedPorts.contains(uri.port)) {
      return UrlPolicyDecision(UrlPolicyReason.unexpectedPort, host);
    }

    return UrlPolicyDecision(UrlPolicyReason.allowed, host);
  }

  /// 标签边界匹配：`host` 必须等于白名单域，或以 `.白名单域` 结尾。
  ///
  /// 用点号锚定边界而不是 `endsWith(域)`，因此
  /// `evil-yangshipin.cn`、`yangshipin.cn.evil.com`、
  /// `notyangshipin.cn` 都不会被放行。
  static bool _isTrustedHost(String host) {
    for (final domain in OfficialDomains.trusted) {
      if (host == domain || host.endsWith('.$domain')) return true;
    }
    return false;
  }

  /// 主机名归一化：转小写并去掉 FQDN 末尾的点。
  ///
  /// 只做等价变换，不改变标签结构。
  static String? _normalizeHost(String rawHost) {
    var host = rawHost.toLowerCase();
    while (host.endsWith('.')) {
      host = host.substring(0, host.length - 1);
    }
    return host.isEmpty ? null : host;
  }
}