import 'package:flutter/material.dart';

import '../../application/ytv_scope.dart';
import '../../domain/models/channel.dart';
import 'load_state_view.dart';

/// 加载频道目录并统一处理 loading / error / empty 三态，data 态交给 builder。
class ChannelCatalogView extends StatefulWidget {
  const ChannelCatalogView({
    super.key,
    required this.builder,
    this.isEmpty,
    this.emptyMessage = '暂无内容',
  });

  final Widget Function(BuildContext context, List<Channel> channels) builder;

  /// 判断已加载目录是否为空态，用于展示空态提示。
  final bool Function(List<Channel> channels)? isEmpty;

  final String emptyMessage;

  @override
  State<ChannelCatalogView> createState() => _ChannelCatalogViewState();
}

class _ChannelCatalogViewState extends State<ChannelCatalogView> {
  Future<List<Channel>>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= YtvScope.of(context).channels.list();
  }

  void _retry() {
    setState(() => _future = YtvScope.of(context).channels.list());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Channel>>(
      future: _future,
      builder: (context, snapshot) {
        final channels = snapshot.data;
        return LoadStateView(
          isLoading: snapshot.connectionState == ConnectionState.waiting,
          errorMessage: snapshot.hasError ? '频道目录加载失败' : null,
          isEmpty: channels != null &&
              (widget.isEmpty?.call(channels) ?? channels.isEmpty),
          emptyMessage: widget.emptyMessage,
          onRetry: _retry,
          builder: (context) => widget.builder(context, channels!),
        );
      },
    );
  }
}