import 'package:flutter_test/flutter_test.dart';
import 'package:ytv/infrastructure/official_pages.dart';
import 'package:ytv/infrastructure/official_url_policy.dart';

void main() {
  group('W-5 协议限制', () {
    test('放行 HTTPS 官方地址', () {
      for (final url in <String>[
        'https://www.yangshipin.cn/',
        'https://www.yangshipin.cn/tv/home',
        'https://www.yangshipin.cn/tv/home?channel=cctv1',
      ]) {
        expect(
          OfficialUrlPolicy.check(url).allowed,
          isTrue,
          reason: '$url 应放行',
        );
      }
    });

    test('拒绝非 HTTPS 协议', () {
      // 用例中的 `placeholder-user` 是占位用户名，**不代表任何真实用户**，
      // 只用来证明 `file:` 协议会被拒绝。换到别的机器上部署时无需改动。
      final cases = <String, UrlPolicyReason>{
        'http://www.yangshipin.cn/tv/home': UrlPolicyReason.unsupportedScheme,
        'file:///C:/Users/placeholder-user/secrets.html':
            UrlPolicyReason.unsupportedScheme,
        'javascript:alert(document.cookie)': UrlPolicyReason.unsupportedScheme,
        'data:text/html;base64,PHNjcmlwdD4=': UrlPolicyReason.unsupportedScheme,
        'about:blank': UrlPolicyReason.unsupportedScheme,
        'ftp://www.yangshipin.cn/': UrlPolicyReason.unsupportedScheme,
      };
      cases.forEach((url, reason) {
        final decision = OfficialUrlPolicy.check(url);
        expect(decision.allowed, isFalse, reason: '$url 不应放行');
        expect(decision.reason, reason, reason: '$url 的拒绝原因');
      });
    });

    test('拒绝非默认 HTTPS 端口', () {
      final decision =
          OfficialUrlPolicy.check('https://www.yangshipin.cn:8443/tv/home');
      expect(decision.allowed, isFalse);
      expect(decision.reason, UrlPolicyReason.unexpectedPort);
    });

    test('显式 443 端口视为等价', () {
      expect(
        OfficialUrlPolicy
            .check('https://www.yangshipin.cn:443/tv/home')
            .allowed,
        isTrue,
      );
    });
  });

  group('W-6 域名相似性', () {
    test('拒绝伪装域名，且不做子串匹配', () {
      for (final url in <String>[
        'https://evil-yangshipin.cn/',
        'https://notyangshipin.cn/',
        'https://yangshipin.cn.evil.com/',
        'https://www.yangshipin.cn.evil.com/',
        'https://www.yangshipin.cn.attacker.net/tv/home',
        'https://evil-ysp.cctv.cn/',
        'https://ysp.cctv.cn.evil.com/',
      ]) {
        final decision = OfficialUrlPolicy.check(url);
        expect(decision.allowed, isFalse, reason: '$url 应被拒绝');
        expect(decision.reason, UrlPolicyReason.untrustedHost);
      }
    });

    test('不把 cctv.cn 整域放行', () {
      for (final url in <String>[
        'https://cctv.cn/',
        'https://www.cctv.cn/',
        'https://tv.cctv.cn/',
      ]) {
        final decision = OfficialUrlPolicy.check(url);
        expect(decision.allowed, isFalse, reason: '$url 应被拒绝');
        expect(decision.reason, UrlPolicyReason.untrustedHost);
      }
    });

    test('拒绝观测到的链路注入主机（非官方域且非 443）', () {
      final decision = OfficialUrlPolicy.check('https://mediadata.xuexi.cn:8443/pbe.js');
      expect(decision.allowed, isFalse);
      expect(decision.reason, UrlPolicyReason.untrustedHost);
    });

    test('拒绝第三方埋点域', () {
      expect(
        OfficialUrlPolicy.check('https://o.alicdn.com/QTSDK/qt_web.umd.js').allowed,
        isFalse,
      );
    });

    test('主机名大小写与 FQDN 末尾点不影响判定', () {
      expect(OfficialUrlPolicy.check('https://WWW.Yangshipin.CN/').allowed, isTrue);
      expect(OfficialUrlPolicy.check('https://www.yangshipin.cn./').allowed, isTrue);
      expect(
        OfficialUrlPolicy.check('https://EVIL-YANGSHIPIN.CN./').allowed,
        isFalse,
      );
    });
  });

  group('W-6 可注册域后缀粒度', () {
    test('放行白名单域本身', () {
      expect(OfficialUrlPolicy.check('https://yangshipin.cn/').allowed, isTrue);
      expect(OfficialUrlPolicy.check('https://ysp.cctv.cn/').allowed, isTrue);
    });

    test('放行任意深度的官方子域', () {
      for (final url in <String>[
        'https://m.yangshipin.cn/tv/home',
        'https://a.b.c.yangshipin.cn/',
        'https://hlsliveali-cdn.ysp.cctv.cn/stream.m3u8',
      ]) {
        expect(
          OfficialUrlPolicy.check(url).allowed,
          isTrue,
          reason: '$url 应放行',
        );
      }
    });

    test('放行 2026-09-19 观测到的全部官方主机', () {
      // 依据《WebView-POC-白名单与隐私测试清单》第 6 节：一次完整加载的
      // 17 个主机中，属于官方域的 15 个必须全部放行，否则播放链路会断。
      const observedOfficialHosts = <String>[
        'www.yangshipin.cn',
        'resources.yangshipin.cn',
        'sapi.yangshipin.cn',
        'img.yangshipin.cn',
        'hlsliveali-cdn.ysp.cctv.cn',
        'btrace.yangshipin.cn',
        's.yangshipin.cn',
        'aatc-api.yangshipin.cn',
        'm.yangshipin.cn',
        'capi.yangshipin.cn',
        'player-api.yangshipin.cn',
        'csapi.yangshipin.cn',
        'h5access.yangshipin.cn',
        'wimg.yangshipin.cn',
        'pcsite.ysp.cctv.cn',
      ];
      for (final host in observedOfficialHosts) {
        final decision = OfficialUrlPolicy.check('https://$host/');
        expect(
          decision.allowed,
          isTrue,
          reason: '$host 在观测中承载播放链路，应放行（实际 ${decision.reason}）',
        );
      }
    });
  });

  group('W-1 导航拦截', () {
    test('无法解析或缺少主机名的地址一律拒绝', () {
      for (final url in <String?>[
        null,
        '',
        '/tv/home',
        '//www.yangshipin.cn/tv/home',
        'https:///tv/home',
      ]) {
        expect(
          OfficialUrlPolicy.check(url).allowed,
          isFalse,
          reason: '$url 应被拒绝',
        );
      }
    });

    test('判定结果只保留主机名，不携带路径与查询参数', () {
      final decision = OfficialUrlPolicy.check(
        'https://evil.example.com/steal?token=abc123',
      );
      expect(decision.host, 'evil.example.com');
      expect(decision.host, isNot(contains('token')));
      expect(decision.host, isNot(contains('?')));
    });

    test('用户信息段不能把官方主机名伪装成放行目标', () {
      // Uri.host 取的是 @ 之后的部分，此处真实目标是 evil.com。
      final decision = OfficialUrlPolicy.check(
        'https://www.yangshipin.cn@evil.com/tv/home',
      );
      expect(decision.allowed, isFalse);
      expect(decision.host, 'evil.com');
    });
  });

  group('登录流程白名单', () {
    test('放行微信扫码登录页所在域', () {
      // 2026-09-19 真机观测：官方登录弹窗内选择「微信登录」时，二维码页面由
      // open.weixin.qq.com 在子框架加载（mainFrame=false），被拦后二维码不显示。
      for (final url in <String>[
        'https://open.weixin.qq.com/',
        'https://open.weixin.qq.com/connect/qrconnect?appid=wx123&scope=snsapi_login',
      ]) {
        expect(
          OfficialUrlPolicy.check(url).allowed,
          isTrue,
          reason: '$url 是官方登录流程的一环，应放行',
        );
      }
    });

    test('只放行 open.weixin.qq.com，不泛化到 qq.com', () {
      for (final url in <String>[
        'https://qq.com/',
        'https://www.qq.com/',
        'https://wx.qq.com/',
        'https://login.weixin.qq.com/',
        'https://open.weixin.qq.com.evil.com/',
        'https://evil-open.weixin.qq.com/',
      ]) {
        expect(
          OfficialUrlPolicy.check(url).allowed,
          isFalse,
          reason: '$url 不应放行',
        );
      }
    });

    test('登录放行不放松数据边界：判定结果仍只保留主机名', () {
      final decision = OfficialUrlPolicy.check(
        'https://open.weixin.qq.com/connect/qrconnect?appid=wx123&redirect_uri=abc',
      );
      expect(decision.host, 'open.weixin.qq.com');
      expect(decision.host, isNot(contains('appid')));
      expect(decision.host, isNot(contains('?')));
    });
  });

  group('白名单本身', () {
    test('条目规范：无通配符、无前导点、全小写', () {
      expect(OfficialDomains.trusted, isNotEmpty);
      for (final domain in OfficialDomains.trusted) {
        expect(domain, isNot(contains('*')), reason: '禁止通配符放行');
        expect(domain, domain.trim());
        expect(domain, domain.toLowerCase());
        expect(domain, isNot(startsWith('.')), reason: '不要写前导点');
      }
    });

    test('第三方登录域与官方自有域分开登记，不混为一谈', () {
      expect(OfficialDomains.official, isNotEmpty);
      expect(OfficialDomains.thirdPartyLogin, isNotEmpty);
      for (final domain in OfficialDomains.thirdPartyLogin) {
        expect(
          OfficialDomains.official,
          isNot(contains(domain)),
          reason: '$domain 是第三方域，不应混进官方自有域清单',
        );
      }
      expect(
        OfficialDomains.trusted.toSet(),
        <String>{
          ...OfficialDomains.official,
          ...OfficialDomains.thirdPartyLogin,
        },
        reason: 'trusted 应是两组的并集，不能有额外条目',
      );
    });

    test('登记的域之间不互相包含，避免无效条目', () {
      final domains = OfficialDomains.trusted;
      for (final domain in domains) {
        for (final other in domains) {
          if (identical(domain, other)) continue;
          expect(
            domain.endsWith('.$other'),
            isFalse,
            reason: '$domain 已被 $other 覆盖',
          );
        }
      }
    });
  });
}
