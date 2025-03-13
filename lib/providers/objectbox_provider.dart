import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:idlefit/services/object_box.dart';
import 'package:objectbox/objectbox.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'objectbox_provider.g.dart';

@Riverpod(keepAlive: true)
ObjectBox objectBox(ObjectBoxRef ref) {
  throw UnimplementedError('ObjectBox provider not initialized');
}

@Riverpod(keepAlive: true)
Store objectBoxStore(ObjectBoxStoreRef ref) {
  final objectBox = ref.watch(objectBoxProvider);
  return objectBox.store;
}
