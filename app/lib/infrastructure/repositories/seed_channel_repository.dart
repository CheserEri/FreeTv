import 'package:flutter/foundation.dart';

import '../../domain/models/channel.dart';
import '../../domain/repositories/channel_repository.dart';
import '../official_pages.dart';

/// 内置种子目录。
///
/// 目录内容依据 2026-09-19 对官方电视页的人工观测确定：在官方页面**自身已经
/// 渲染出来**的频道列表中读出频道名、分类与 `pid`，逐条登记为静态种子。
/// 观测只读页面内存数据，不调用官方接口、不重放请求、不解析播放流，因此符合
/// 《系统架构与服务契约》对「开发期人工观测官方公开页面」的预期方法。
///
/// 每个频道的 [Channel.officialPageUrl] 都是单频道直达地址
/// （[OfficialPages.tvChannel]）：在应用内点击频道即定位到对应官方频道，
/// 不需要在官方页面内二次点击切换。
class SeedChannelRepository implements ChannelRepository {
  const SeedChannelRepository();

  static final List<Channel> _channels =
      List<Channel>.unmodifiable(_seeds.map(_toChannel));

  @override
  Future<List<Channel>> list({ChannelCategory? category}) async {
    if (category == null) return _channels;
    return _channels
        .where((channel) => channel.category == category)
        .toList(growable: false);
  }

  @override
  Future<List<Channel>> search(String query) async {
    final keyword = query.trim().toLowerCase();
    if (keyword.isEmpty) return _channels;
    return _channels
        .where((channel) => channel.name.toLowerCase().contains(keyword))
        .toList(growable: false);
  }

  @override
  Future<Channel?> getById(String id) async {
    for (final channel in _channels) {
      if (channel.id == id) return channel;
    }
    return null;
  }

  static Channel _toChannel(_Seed seed) => Channel(
        id: seed.id,
        name: seed.name,
        category: seed.category,
        officialPageUrl: OfficialPages.tvChannel(seed.pid),
        availability: seed.restricted
            ? ChannelAvailability.restricted
            : ChannelAvailability.available,
      );

  /// 观测到的官方频道清单：官方电视页「CCTV」页签 40 条 +「卫视」页签 33 条。
  static const List<_Seed> _seeds = <_Seed>[
    // —— 官方电视页「CCTV」页签 ——
    _Seed('cctv-1', 'CCTV1', '600001859'),
    _Seed('cctv-2', 'CCTV2', '600001800'),
    _Seed('cctv-3', 'CCTV3', '600001801'),
    _Seed('cctv-4', 'CCTV4', '600001814'),
    _Seed('cctv-5', 'CCTV5', '600001818'),
    _Seed('cctv-5-plus', 'CCTV5+', '600001817'),
    _Seed('cctv-6', 'CCTV6', '600108442'),
    _Seed('cctv-7', 'CCTV7', '600004092'),
    _Seed('cctv-8', 'CCTV8', '600001803'),
    _Seed('cctv-9', 'CCTV9', '600004078'),
    _Seed('cctv-10', 'CCTV10', '600001805'),
    _Seed('cctv-11', 'CCTV11', '600001806'),
    _Seed('cctv-12', 'CCTV12', '600001807'),
    _Seed('cctv-13', 'CCTV13', '600001811'),
    _Seed('cctv-14', 'CCTV14', '600001809'),
    _Seed('cctv-15', 'CCTV15', '600001815'),
    _Seed('cctv-16-hd', 'CCTV16-HD', '600098637'),
    _Seed('cctv-16-4k', 'CCTV16(4K)', '600099502'),
    _Seed('cctv-17', 'CCTV17', '600001810'),
    _Seed('cctv-4k', 'CCTV4K', '600002264'),
    _Seed('cctv-8k', 'CCTV8K', '600156816'),
    _Seed('cgtn', 'CGTN', '600014550'),
    _Seed('cgtn-french', 'CGTN法语频道', '600084704'),
    _Seed('cgtn-russian', 'CGTN俄语频道', '600084758'),
    _Seed('cgtn-arabic', 'CGTN阿拉伯语频道', '600084782'),
    _Seed('cgtn-spanish', 'CGTN西班牙语频道', '600084744'),
    _Seed('cgtn-documentary', 'CGTN外语纪录频道', '600084781'),
    _Seed('cctv-fengyun-theatre', 'CCTV风云剧场频道', '600099658'),
    _Seed('cctv-first-theatre', 'CCTV第一剧场频道', '600099655'),
    _Seed('cctv-nostalgia-theatre', 'CCTV怀旧剧场频道', '600099620'),
    _Seed('cctv-world-geography', 'CCTV世界地理频道', '600099637',
        restricted: true),
    _Seed('cctv-fengyun-music', 'CCTV风云音乐频道', '600099660',
        restricted: true),
    _Seed('cctv-weapon-tech', 'CCTV兵器科技频道', '600099649',
        restricted: true),
    _Seed('cctv-fengyun-football', 'CCTV风云足球频道', '600099636',
        restricted: true),
    _Seed('cctv-golf-tennis', 'CCTV高尔夫·网球频道', '600099659',
        restricted: true),
    _Seed('cctv-women-fashion', 'CCTV女性时尚频道', '600099650',
        restricted: true),
    _Seed('cctv-culture-classic', 'CCTV央视文化精品频道', '600099653',
        restricted: true),
    _Seed('cctv-billiards', 'CCTV央视台球频道', '600099652', restricted: true),
    _Seed('cctv-tv-guide', 'CCTV电视指南频道', '600099656', restricted: true),
    _Seed('cctv-health', 'CCTV卫生健康频道', '600099651', restricted: true),

    // —— 官方电视页「卫视」页签 ——
    _Seed('satellite-beijing', '北京卫视', '600002309',
        category: ChannelCategory.satellite),
    _Seed('satellite-jiangsu', '江苏卫视', '600002521',
        category: ChannelCategory.satellite),
    _Seed('satellite-dongfang', '东方卫视', '600002483',
        category: ChannelCategory.satellite),
    _Seed('satellite-zhejiang', '浙江卫视', '600002520',
        category: ChannelCategory.satellite),
    _Seed('satellite-hunan', '湖南卫视', '600002475',
        category: ChannelCategory.satellite),
    _Seed('satellite-hubei', '湖北卫视', '600002508',
        category: ChannelCategory.satellite),
    _Seed('satellite-guangdong', '广东卫视', '600002485',
        category: ChannelCategory.satellite),
    _Seed('satellite-guangxi', '广西卫视', '600002509',
        category: ChannelCategory.satellite),
    _Seed('satellite-heilongjiang', '黑龙江卫视', '600002498',
        category: ChannelCategory.satellite),
    _Seed('satellite-hainan', '海南卫视', '600002506',
        category: ChannelCategory.satellite),
    _Seed('satellite-chongqing', '重庆卫视', '600002531',
        category: ChannelCategory.satellite),
    _Seed('satellite-shenzhen', '深圳卫视', '600002481',
        category: ChannelCategory.satellite),
    _Seed('satellite-sichuan', '四川卫视', '600002516',
        category: ChannelCategory.satellite),
    _Seed('satellite-henan', '河南卫视', '600002525',
        category: ChannelCategory.satellite),
    _Seed('satellite-fujian-southeast', '福建东南卫视', '600002484',
        category: ChannelCategory.satellite),
    _Seed('satellite-guizhou', '贵州卫视', '600002490',
        category: ChannelCategory.satellite),
    _Seed('satellite-jiangxi', '江西卫视', '600002503',
        category: ChannelCategory.satellite),
    _Seed('satellite-liaoning', '辽宁卫视', '600002505',
        category: ChannelCategory.satellite),
    _Seed('satellite-anhui', '安徽卫视', '600002532',
        category: ChannelCategory.satellite),
    _Seed('satellite-hebei', '河北卫视', '600002493',
        category: ChannelCategory.satellite),
    _Seed('satellite-shandong', '山东卫视', '600002513',
        category: ChannelCategory.satellite),
    _Seed('satellite-tianjin', '天津卫视', '600152137',
        category: ChannelCategory.satellite),
    _Seed('satellite-jilin', '吉林卫视', '600190405',
        category: ChannelCategory.satellite),
    _Seed('satellite-shaanxi', '陕西卫视', '600190400',
        category: ChannelCategory.satellite),
    _Seed('satellite-gansu', '甘肃卫视', '600190408',
        category: ChannelCategory.satellite),
    _Seed('satellite-ningxia', '宁夏卫视', '600190737',
        category: ChannelCategory.satellite),
    _Seed('satellite-neimenggu', '内蒙古卫视', '600190401',
        category: ChannelCategory.satellite),
    _Seed('satellite-yunnan', '云南卫视', '600190402',
        category: ChannelCategory.satellite),
    _Seed('satellite-shanxi', '山西卫视', '600190407',
        category: ChannelCategory.satellite),
    _Seed('satellite-qinghai', '青海卫视', '600190406',
        category: ChannelCategory.satellite),
    _Seed('satellite-xizang', '西藏卫视', '600190403',
        category: ChannelCategory.satellite),
    _Seed('cetv-1', '中国教育电视台1频道', '600171827',
        category: ChannelCategory.other),
    _Seed('satellite-xinjiang', '新疆卫视', '600152138',
        category: ChannelCategory.satellite),
  ];
}

/// 观测到的一条官方频道记录。
@immutable
class _Seed {
  const _Seed(
    this.id,
    this.name,
    this.pid, {
    this.category = ChannelCategory.cctv,
    this.restricted = false,
  });

  /// YTV 稳定 ID。
  final String id;

  /// 官方页面上的频道名，原样登记。
  final String name;

  /// 官方公开地址中的频道标识。
  final String pid;

  final ChannelCategory category;

  /// 官方页面标注「(VIP)」的频道需要会员，登记为受限。
  /// 标注「(限免)」表示限时免费，仍按可观看登记。
  final bool restricted;
}
