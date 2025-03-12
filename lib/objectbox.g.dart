// GENERATED CODE - DO NOT MODIFY BY HAND
// This code was generated by ObjectBox. To update it run the generator again
// with `dart run build_runner build`.
// See also https://docs.objectbox.io/getting-started#generate-objectbox-code

// ignore_for_file: camel_case_types, depend_on_referenced_packages
// coverage:ignore-file

import 'dart:typed_data';

import 'package:flat_buffers/flat_buffers.dart' as fb;
import 'package:objectbox/internal.dart'
    as obx_int; // generated code can access "internal" functionality
import 'package:objectbox/objectbox.dart' as obx;
import 'package:objectbox_sync_flutter_libs/objectbox_sync_flutter_libs.dart';

import 'models/coin_generator.dart';
import 'models/currency.dart';
import 'models/health_data_entry.dart';
import 'models/shop_items.dart';

export 'package:objectbox/objectbox.dart'; // so that callers only have to import this file

final _entities = <obx_int.ModelEntity>[
  obx_int.ModelEntity(
      id: const obx_int.IdUid(1, 8970713413303252018),
      name: 'Currency',
      lastPropertyId: const obx_int.IdUid(9, 1103942004918786733),
      flags: 0,
      properties: <obx_int.ModelProperty>[
        obx_int.ModelProperty(
            id: const obx_int.IdUid(2, 411610756409811407),
            name: 'count',
            type: 8,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(3, 2153748619588745951),
            name: 'totalSpent',
            type: 8,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(4, 4769501277755131512),
            name: 'totalEarned',
            type: 8,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(6, 4916751470591575964),
            name: 'id',
            type: 6,
            flags: 129),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(8, 6709896111414846563),
            name: 'baseMax',
            type: 8,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(9, 1103942004918786733),
            name: 'maxMultiplier',
            type: 8,
            flags: 0)
      ],
      relations: <obx_int.ModelRelation>[],
      backlinks: <obx_int.ModelBacklink>[]),
  obx_int.ModelEntity(
      id: const obx_int.IdUid(3, 7897766162698443189),
      name: 'CoinGenerator',
      lastPropertyId: const obx_int.IdUid(5, 2457321709930163773),
      flags: 0,
      properties: <obx_int.ModelProperty>[
        obx_int.ModelProperty(
            id: const obx_int.IdUid(2, 8997851123245017231),
            name: 'count',
            type: 6,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(3, 5801636019966271860),
            name: 'level',
            type: 6,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(4, 3181080062182307300),
            name: 'tier',
            type: 6,
            flags: 129),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(5, 2457321709930163773),
            name: 'isUnlocked',
            type: 1,
            flags: 0)
      ],
      relations: <obx_int.ModelRelation>[],
      backlinks: <obx_int.ModelBacklink>[]),
  obx_int.ModelEntity(
      id: const obx_int.IdUid(5, 604859576841525103),
      name: 'HealthDataEntry',
      lastPropertyId: const obx_int.IdUid(6, 5977650328934603192),
      flags: 0,
      properties: <obx_int.ModelProperty>[
        obx_int.ModelProperty(
            id: const obx_int.IdUid(1, 4745966459735341277),
            name: 'id',
            type: 6,
            flags: 1),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(2, 81048633074782967),
            name: 'timestamp',
            type: 6,
            flags: 8,
            indexId: const obx_int.IdUid(2, 6046711262050609894)),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(3, 7708077465627102502),
            name: 'duration',
            type: 6,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(4, 4892005414219992245),
            name: 'recordedAt',
            type: 6,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(5, 6816389771923756793),
            name: 'value',
            type: 8,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(6, 5977650328934603192),
            name: 'type',
            type: 9,
            flags: 0)
      ],
      relations: <obx_int.ModelRelation>[],
      backlinks: <obx_int.ModelBacklink>[]),
  obx_int.ModelEntity(
      id: const obx_int.IdUid(6, 3093373672220765882),
      name: 'ShopItem',
      lastPropertyId: const obx_int.IdUid(8, 2249982543274755836),
      flags: 0,
      properties: <obx_int.ModelProperty>[
        obx_int.ModelProperty(
            id: const obx_int.IdUid(1, 677716417256338725),
            name: 'id',
            type: 6,
            flags: 129),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(8, 2249982543274755836),
            name: 'level',
            type: 6,
            flags: 0)
      ],
      relations: <obx_int.ModelRelation>[],
      backlinks: <obx_int.ModelBacklink>[])
];

/// Shortcut for [obx.Store.new] that passes [getObjectBoxModel] and for Flutter
/// apps by default a [directory] using `defaultStoreDirectory()` from the
/// ObjectBox Flutter library.
///
/// Note: for desktop apps it is recommended to specify a unique [directory].
///
/// See [obx.Store.new] for an explanation of all parameters.
///
/// For Flutter apps, also calls `loadObjectBoxLibraryAndroidCompat()` from
/// the ObjectBox Flutter library to fix loading the native ObjectBox library
/// on Android 6 and older.
Future<obx.Store> openStore(
    {String? directory,
    int? maxDBSizeInKB,
    int? maxDataSizeInKB,
    int? fileMode,
    int? maxReaders,
    bool queriesCaseSensitiveDefault = true,
    String? macosApplicationGroup}) async {
  await loadObjectBoxLibraryAndroidCompat();
  return obx.Store(getObjectBoxModel(),
      directory: directory ?? (await defaultStoreDirectory()).path,
      maxDBSizeInKB: maxDBSizeInKB,
      maxDataSizeInKB: maxDataSizeInKB,
      fileMode: fileMode,
      maxReaders: maxReaders,
      queriesCaseSensitiveDefault: queriesCaseSensitiveDefault,
      macosApplicationGroup: macosApplicationGroup);
}

/// Returns the ObjectBox model definition for this project for use with
/// [obx.Store.new].
obx_int.ModelDefinition getObjectBoxModel() {
  final model = obx_int.ModelInfo(
      entities: _entities,
      lastEntityId: const obx_int.IdUid(6, 3093373672220765882),
      lastIndexId: const obx_int.IdUid(2, 6046711262050609894),
      lastRelationId: const obx_int.IdUid(0, 0),
      lastSequenceId: const obx_int.IdUid(0, 0),
      retiredEntityUids: const [2493137042954685248, 219102169117428336],
      retiredIndexUids: const [],
      retiredPropertyUids: const [
        1612088624750524307,
        1221735629759989076,
        7739014744985074402,
        2465340859862322629,
        2427394359739034951,
        3598368693352972001,
        3238954471475910745,
        7990707600546979225,
        8940347419837491692,
        7308206853943299864,
        1298175783779309702,
        5086729266335392220,
        5407859144525862516,
        4297493175054291291,
        944104226892207343,
        2037289546189049172,
        2255176740307486357,
        745509794462133064,
        6946102241664551198
      ],
      retiredRelationUids: const [],
      modelVersion: 5,
      modelVersionParserMinimum: 5,
      version: 1);

  final bindings = <Type, obx_int.EntityDefinition>{
    Currency: obx_int.EntityDefinition<Currency>(
        model: _entities[0],
        toOneRelations: (Currency object) => [],
        toManyRelations: (Currency object) => {},
        getId: (Currency object) => object.id,
        setId: (Currency object, int id) {
          object.id = id;
        },
        objectToFB: (Currency object, fb.Builder fbb) {
          fbb.startTable(10);
          fbb.addFloat64(1, object.count);
          fbb.addFloat64(2, object.totalSpent);
          fbb.addFloat64(3, object.totalEarned);
          fbb.addInt64(5, object.id);
          fbb.addFloat64(7, object.baseMax);
          fbb.addFloat64(8, object.maxMultiplier);
          fbb.finish(fbb.endTable());
          return object.id;
        },
        objectFromFB: (obx.Store store, ByteData fbData) {
          final buffer = fb.BufferContext(fbData);
          final rootOffset = buffer.derefObject(0);
          final idParam =
              const fb.Int64Reader().vTableGet(buffer, rootOffset, 14, 0);
          final countParam =
              const fb.Float64Reader().vTableGet(buffer, rootOffset, 6, 0);
          final baseMaxParam =
              const fb.Float64Reader().vTableGet(buffer, rootOffset, 18, 0);
          final object = Currency(
              id: idParam, count: countParam, baseMax: baseMaxParam)
            ..totalSpent =
                const fb.Float64Reader().vTableGet(buffer, rootOffset, 8, 0)
            ..totalEarned =
                const fb.Float64Reader().vTableGet(buffer, rootOffset, 10, 0)
            ..maxMultiplier =
                const fb.Float64Reader().vTableGet(buffer, rootOffset, 20, 0);

          return object;
        }),
    CoinGenerator: obx_int.EntityDefinition<CoinGenerator>(
        model: _entities[1],
        toOneRelations: (CoinGenerator object) => [],
        toManyRelations: (CoinGenerator object) => {},
        getId: (CoinGenerator object) => object.tier,
        setId: (CoinGenerator object, int id) {
          object.tier = id;
        },
        objectToFB: (CoinGenerator object, fb.Builder fbb) {
          fbb.startTable(6);
          fbb.addInt64(1, object.count);
          fbb.addInt64(2, object.level);
          fbb.addInt64(3, object.tier);
          fbb.addBool(4, object.isUnlocked);
          fbb.finish(fbb.endTable());
          return object.tier;
        },
        objectFromFB: (obx.Store store, ByteData fbData) {
          final buffer = fb.BufferContext(fbData);
          final rootOffset = buffer.derefObject(0);
          final tierParam =
              const fb.Int64Reader().vTableGet(buffer, rootOffset, 10, 0);
          final object = CoinGenerator(tier: tierParam)
            ..count = const fb.Int64Reader().vTableGet(buffer, rootOffset, 6, 0)
            ..level = const fb.Int64Reader().vTableGet(buffer, rootOffset, 8, 0)
            ..isUnlocked =
                const fb.BoolReader().vTableGet(buffer, rootOffset, 12, false);

          return object;
        }),
    HealthDataEntry: obx_int.EntityDefinition<HealthDataEntry>(
        model: _entities[2],
        toOneRelations: (HealthDataEntry object) => [],
        toManyRelations: (HealthDataEntry object) => {},
        getId: (HealthDataEntry object) => object.id,
        setId: (HealthDataEntry object, int id) {
          object.id = id;
        },
        objectToFB: (HealthDataEntry object, fb.Builder fbb) {
          final typeOffset = fbb.writeString(object.type);
          fbb.startTable(7);
          fbb.addInt64(0, object.id);
          fbb.addInt64(1, object.timestamp);
          fbb.addInt64(2, object.duration);
          fbb.addInt64(3, object.recordedAt);
          fbb.addFloat64(4, object.value);
          fbb.addOffset(5, typeOffset);
          fbb.finish(fbb.endTable());
          return object.id;
        },
        objectFromFB: (obx.Store store, ByteData fbData) {
          final buffer = fb.BufferContext(fbData);
          final rootOffset = buffer.derefObject(0);
          final timestampParam =
              const fb.Int64Reader().vTableGet(buffer, rootOffset, 6, 0);
          final durationParam =
              const fb.Int64Reader().vTableGet(buffer, rootOffset, 8, 0);
          final valueParam =
              const fb.Float64Reader().vTableGet(buffer, rootOffset, 12, 0);
          final typeParam = const fb.StringReader(asciiOptimization: true)
              .vTableGet(buffer, rootOffset, 14, '');
          final recordedAtParam =
              const fb.Int64Reader().vTableGet(buffer, rootOffset, 10, 0);
          final object = HealthDataEntry(
              timestamp: timestampParam,
              duration: durationParam,
              value: valueParam,
              type: typeParam,
              recordedAt: recordedAtParam)
            ..id = const fb.Int64Reader().vTableGet(buffer, rootOffset, 4, 0);

          return object;
        }),
    ShopItem: obx_int.EntityDefinition<ShopItem>(
        model: _entities[3],
        toOneRelations: (ShopItem object) => [],
        toManyRelations: (ShopItem object) => {},
        getId: (ShopItem object) => object.id,
        setId: (ShopItem object, int id) {
          object.id = id;
        },
        objectToFB: (ShopItem object, fb.Builder fbb) {
          fbb.startTable(9);
          fbb.addInt64(0, object.id);
          fbb.addInt64(7, object.level);
          fbb.finish(fbb.endTable());
          return object.id;
        },
        objectFromFB: (obx.Store store, ByteData fbData) {
          final buffer = fb.BufferContext(fbData);
          final rootOffset = buffer.derefObject(0);
          final idParam =
              const fb.Int64Reader().vTableGet(buffer, rootOffset, 4, 0);
          final levelParam =
              const fb.Int64Reader().vTableGet(buffer, rootOffset, 18, 0);
          final object = ShopItem(id: idParam, level: levelParam);

          return object;
        })
  };

  return obx_int.ModelDefinition(model, bindings);
}

/// [Currency] entity fields to define ObjectBox queries.
class Currency_ {
  /// See [Currency.count].
  static final count =
      obx.QueryDoubleProperty<Currency>(_entities[0].properties[0]);

  /// See [Currency.totalSpent].
  static final totalSpent =
      obx.QueryDoubleProperty<Currency>(_entities[0].properties[1]);

  /// See [Currency.totalEarned].
  static final totalEarned =
      obx.QueryDoubleProperty<Currency>(_entities[0].properties[2]);

  /// See [Currency.id].
  static final id =
      obx.QueryIntegerProperty<Currency>(_entities[0].properties[3]);

  /// See [Currency.baseMax].
  static final baseMax =
      obx.QueryDoubleProperty<Currency>(_entities[0].properties[4]);

  /// See [Currency.maxMultiplier].
  static final maxMultiplier =
      obx.QueryDoubleProperty<Currency>(_entities[0].properties[5]);
}

/// [CoinGenerator] entity fields to define ObjectBox queries.
class CoinGenerator_ {
  /// See [CoinGenerator.count].
  static final count =
      obx.QueryIntegerProperty<CoinGenerator>(_entities[1].properties[0]);

  /// See [CoinGenerator.level].
  static final level =
      obx.QueryIntegerProperty<CoinGenerator>(_entities[1].properties[1]);

  /// See [CoinGenerator.tier].
  static final tier =
      obx.QueryIntegerProperty<CoinGenerator>(_entities[1].properties[2]);

  /// See [CoinGenerator.isUnlocked].
  static final isUnlocked =
      obx.QueryBooleanProperty<CoinGenerator>(_entities[1].properties[3]);
}

/// [HealthDataEntry] entity fields to define ObjectBox queries.
class HealthDataEntry_ {
  /// See [HealthDataEntry.id].
  static final id =
      obx.QueryIntegerProperty<HealthDataEntry>(_entities[2].properties[0]);

  /// See [HealthDataEntry.timestamp].
  static final timestamp =
      obx.QueryIntegerProperty<HealthDataEntry>(_entities[2].properties[1]);

  /// See [HealthDataEntry.duration].
  static final duration =
      obx.QueryIntegerProperty<HealthDataEntry>(_entities[2].properties[2]);

  /// See [HealthDataEntry.recordedAt].
  static final recordedAt =
      obx.QueryIntegerProperty<HealthDataEntry>(_entities[2].properties[3]);

  /// See [HealthDataEntry.value].
  static final value =
      obx.QueryDoubleProperty<HealthDataEntry>(_entities[2].properties[4]);

  /// See [HealthDataEntry.type].
  static final type =
      obx.QueryStringProperty<HealthDataEntry>(_entities[2].properties[5]);
}

/// [ShopItem] entity fields to define ObjectBox queries.
class ShopItem_ {
  /// See [ShopItem.id].
  static final id =
      obx.QueryIntegerProperty<ShopItem>(_entities[3].properties[0]);

  /// See [ShopItem.level].
  static final level =
      obx.QueryIntegerProperty<ShopItem>(_entities[3].properties[1]);
}
