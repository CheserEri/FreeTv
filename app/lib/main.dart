import 'package:flutter/material.dart';

import 'app.dart';
import 'application/ytv_store.dart';
import 'infrastructure/repositories/memory_favorite_repository.dart';
import 'infrastructure/repositories/memory_history_repository.dart';
import 'infrastructure/repositories/seed_channel_repository.dart';

void main() {
  runApp(
    YtvApp(
      store: YtvStore(
        channels: const SeedChannelRepository(),
        favorites: MemoryFavoriteRepository(),
        history: MemoryHistoryRepository(),
      ),
    ),
  );
}