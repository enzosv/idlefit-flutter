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

import 'models/achievement.dart';
import 'models/coin_generator.dart';
import 'models/currency.dart';
import 'models/daily_quest.dart';
import 'models/game_stats.dart';
import 'models/shop_items.dart';
import 'providers/daily_health_provider.dart';

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
            flags: 129)
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
      backlinks: <obx_int.ModelBacklink>[]),
  obx_int.ModelEntity(
      id: const obx_int.IdUid(7, 2119159745219438621),
      name: 'Achievement',
      lastPropertyId: const obx_int.IdUid(13, 5316489849535110872),
      flags: 0,
      properties: <obx_int.ModelProperty>[
        obx_int.ModelProperty(
            id: const obx_int.IdUid(1, 37781412133150881),
            name: 'id',
            type: 6,
            flags: 1),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(10, 2084831577797524984),
            name: 'dateClaimed',
            type: 6,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(11, 6913876187873743667),
            name: 'action',
            type: 9,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(12, 759831562113825008),
            name: 'reqUnit',
            type: 9,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(13, 5316489849535110872),
            name: 'requirement',
            type: 6,
            flags: 0)
      ],
      relations: <obx_int.ModelRelation>[],
      backlinks: <obx_int.ModelBacklink>[]),
  obx_int.ModelEntity(
      id: const obx_int.IdUid(9, 5523549602957263386),
      name: 'DailyHealth',
      lastPropertyId: const obx_int.IdUid(5, 3783688117025317780),
      flags: 0,
      properties: <obx_int.ModelProperty>[
        obx_int.ModelProperty(
            id: const obx_int.IdUid(1, 8642844963959802391),
            name: 'dayTimestamp',
            type: 6,
            flags: 129),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(2, 1793398252997816722),
            name: 'steps',
            type: 6,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(3, 60503497721018850),
            name: 'caloriesBurned',
            type: 8,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(5, 3783688117025317780),
            name: 'lastSync',
            type: 6,
            flags: 0)
      ],
      relations: <obx_int.ModelRelation>[],
      backlinks: <obx_int.ModelBacklink>[]),
  obx_int.ModelEntity(
      id: const obx_int.IdUid(10, 2872500768702225295),
      name: 'DailyQuest',
      lastPropertyId: const obx_int.IdUid(9, 1479415377058000520),
      flags: 0,
      properties: <obx_int.ModelProperty>[
        obx_int.ModelProperty(
            id: const obx_int.IdUid(1, 1164489260566563423),
            name: 'id',
            type: 6,
            flags: 1),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(2, 3835421408976486463),
            name: 'action',
            type: 9,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(3, 4944879687934267496),
            name: 'unit',
            type: 9,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(4, 7110615956344477289),
            name: 'rewardUnit',
            type: 9,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(5, 4782504977527956134),
            name: 'requirement',
            type: 6,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(6, 5425488138789149553),
            name: 'reward',
            type: 6,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(7, 1716198483539255863),
            name: 'progress',
            type: 8,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(8, 7768261059786321014),
            name: 'dateAssigned',
            type: 6,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(9, 1479415377058000520),
            name: 'isClaimed',
            type: 1,
            flags: 0)
      ],
      relations: <obx_int.ModelRelation>[],
      backlinks: <obx_int.ModelBacklink>[]),
  obx_int.ModelEntity(
      id: const obx_int.IdUid(11, 5789196000044242359),
      name: 'GameStats',
      lastPropertyId: const obx_int.IdUid(14, 265469865007037488),
      flags: 0,
      properties: <obx_int.ModelProperty>[
        obx_int.ModelProperty(
            id: const obx_int.IdUid(1, 893166884544179862),
            name: 'dayTimestamp',
            type: 6,
            flags: 129),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(2, 6351126629942900671),
            name: 'generatorsPurchased',
            type: 6,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(3, 9094248306034783738),
            name: 'generatorsUpgraded',
            type: 6,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(4, 8942034238772045237),
            name: 'shopItemsUpgraded',
            type: 6,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(5, 8401614619360643531),
            name: 'generatorsTapped',
            type: 6,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(6, 2985438957966859538),
            name: 'adsWatched',
            type: 6,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(7, 3380051234714815596),
            name: 'caloriesBurned',
            type: 8,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(8, 4771168237768332620),
            name: 'stepsWalked',
            type: 6,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(9, 628362880589176493),
            name: 'coinsCollected',
            type: 8,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(10, 5250183945066197420),
            name: 'spaceCollected',
            type: 8,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(11, 4011021572361102775),
            name: 'energyCollected',
            type: 8,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(12, 3541445096573348319),
            name: 'energySpent',
            type: 8,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(13, 2417318308218713701),
            name: 'coinsSpent',
            type: 8,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(14, 265469865007037488),
            name: 'spaceSpent',
            type: 8,
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
      lastEntityId: const obx_int.IdUid(11, 5789196000044242359),
      lastIndexId: const obx_int.IdUid(2, 6046711262050609894),
      lastRelationId: const obx_int.IdUid(0, 0),
      lastSequenceId: const obx_int.IdUid(0, 0),
      retiredEntityUids: const [
        2493137042954685248,
        219102169117428336,
        8235573318783332755,
        604859576841525103
      ],
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
        6946102241664551198,
        5678817004169731437,
        167161125635220021,
        4278904461843222799,
        4060410116606726424,
        5122690587257086689,
        7633385983348480139,
        5727768307727832225,
        2592235923790219212,
        2545780716478496970,
        9183427040770090315,
        4000991215743677351,
        2450008997855178603,
        7085483785093773366,
        5366385903808278580,
        4743794405710996085,
        2032882936729661744,
        3449366289436579614,
        6172183544316569837,
        4745966459735341277,
        81048633074782967,
        7708077465627102502,
        4892005414219992245,
        6816389771923756793,
        5977650328934603192,
        2457321709930163773,
        6107178178149087951
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
          if (object.id != id) {
            throw ArgumentError('Field Currency.id is read-only '
                '(final or getter-only) and it was declared to be self-assigned. '
                'However, the currently inserted object (.id=${object.id}) '
                "doesn't match the inserted ID (ID $id). "
                'You must assign an ID before calling [box.put()].');
          }
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
          final totalSpentParam =
              const fb.Float64Reader().vTableGet(buffer, rootOffset, 8, 0);
          final totalEarnedParam =
              const fb.Float64Reader().vTableGet(buffer, rootOffset, 10, 0);
          final baseMaxParam =
              const fb.Float64Reader().vTableGet(buffer, rootOffset, 18, 0);
          final maxMultiplierParam =
              const fb.Float64Reader().vTableGet(buffer, rootOffset, 20, 0);
          final object = Currency(
              id: idParam,
              count: countParam,
              totalSpent: totalSpentParam,
              totalEarned: totalEarnedParam,
              baseMax: baseMaxParam,
              maxMultiplier: maxMultiplierParam);

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
          fbb.finish(fbb.endTable());
          return object.tier;
        },
        objectFromFB: (obx.Store store, ByteData fbData) {
          final buffer = fb.BufferContext(fbData);
          final rootOffset = buffer.derefObject(0);
          final tierParam =
              const fb.Int64Reader().vTableGet(buffer, rootOffset, 10, 0);
          final countParam =
              const fb.Int64Reader().vTableGet(buffer, rootOffset, 6, 0);
          final levelParam =
              const fb.Int64Reader().vTableGet(buffer, rootOffset, 8, 0);
          final object = CoinGenerator(
              tier: tierParam, count: countParam, level: levelParam);

          return object;
        }),
    ShopItem: obx_int.EntityDefinition<ShopItem>(
        model: _entities[2],
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
        }),
    Achievement: obx_int.EntityDefinition<Achievement>(
        model: _entities[3],
        toOneRelations: (Achievement object) => [],
        toManyRelations: (Achievement object) => {},
        getId: (Achievement object) => object.id,
        setId: (Achievement object, int id) {
          object.id = id;
        },
        objectToFB: (Achievement object, fb.Builder fbb) {
          final actionOffset = fbb.writeString(object.action);
          final reqUnitOffset = fbb.writeString(object.reqUnit);
          fbb.startTable(14);
          fbb.addInt64(0, object.id);
          fbb.addInt64(9, object.dateClaimed);
          fbb.addOffset(10, actionOffset);
          fbb.addOffset(11, reqUnitOffset);
          fbb.addInt64(12, object.requirement);
          fbb.finish(fbb.endTable());
          return object.id;
        },
        objectFromFB: (obx.Store store, ByteData fbData) {
          final buffer = fb.BufferContext(fbData);
          final rootOffset = buffer.derefObject(0);

          final object = Achievement()
            ..id = const fb.Int64Reader().vTableGet(buffer, rootOffset, 4, 0)
            ..dateClaimed =
                const fb.Int64Reader().vTableGetNullable(buffer, rootOffset, 22)
            ..action = const fb.StringReader(asciiOptimization: true)
                .vTableGet(buffer, rootOffset, 24, '')
            ..reqUnit = const fb.StringReader(asciiOptimization: true)
                .vTableGet(buffer, rootOffset, 26, '')
            ..requirement =
                const fb.Int64Reader().vTableGet(buffer, rootOffset, 28, 0);

          return object;
        }),
    DailyHealth: obx_int.EntityDefinition<DailyHealth>(
        model: _entities[4],
        toOneRelations: (DailyHealth object) => [],
        toManyRelations: (DailyHealth object) => {},
        getId: (DailyHealth object) => object.dayTimestamp,
        setId: (DailyHealth object, int id) {
          object.dayTimestamp = id;
        },
        objectToFB: (DailyHealth object, fb.Builder fbb) {
          fbb.startTable(6);
          fbb.addInt64(0, object.dayTimestamp);
          fbb.addInt64(1, object.steps);
          fbb.addFloat64(2, object.caloriesBurned);
          fbb.addInt64(4, object.lastSync);
          fbb.finish(fbb.endTable());
          return object.dayTimestamp;
        },
        objectFromFB: (obx.Store store, ByteData fbData) {
          final buffer = fb.BufferContext(fbData);
          final rootOffset = buffer.derefObject(0);

          final object = DailyHealth()
            ..dayTimestamp =
                const fb.Int64Reader().vTableGet(buffer, rootOffset, 4, 0)
            ..steps = const fb.Int64Reader().vTableGet(buffer, rootOffset, 6, 0)
            ..caloriesBurned =
                const fb.Float64Reader().vTableGet(buffer, rootOffset, 8, 0)
            ..lastSync =
                const fb.Int64Reader().vTableGet(buffer, rootOffset, 12, 0);

          return object;
        }),
    DailyQuest: obx_int.EntityDefinition<DailyQuest>(
        model: _entities[5],
        toOneRelations: (DailyQuest object) => [],
        toManyRelations: (DailyQuest object) => {},
        getId: (DailyQuest object) => object.id,
        setId: (DailyQuest object, int id) {
          object.id = id;
        },
        objectToFB: (DailyQuest object, fb.Builder fbb) {
          final actionOffset = fbb.writeString(object.action);
          final unitOffset = fbb.writeString(object.unit);
          final rewardUnitOffset = fbb.writeString(object.rewardUnit);
          fbb.startTable(10);
          fbb.addInt64(0, object.id);
          fbb.addOffset(1, actionOffset);
          fbb.addOffset(2, unitOffset);
          fbb.addOffset(3, rewardUnitOffset);
          fbb.addInt64(4, object.requirement);
          fbb.addInt64(5, object.reward);
          fbb.addFloat64(6, object.progress);
          fbb.addInt64(7, object.dateAssigned);
          fbb.addBool(8, object.isClaimed);
          fbb.finish(fbb.endTable());
          return object.id;
        },
        objectFromFB: (obx.Store store, ByteData fbData) {
          final buffer = fb.BufferContext(fbData);
          final rootOffset = buffer.derefObject(0);

          final object = DailyQuest()
            ..id = const fb.Int64Reader().vTableGet(buffer, rootOffset, 4, 0)
            ..action = const fb.StringReader(asciiOptimization: true)
                .vTableGet(buffer, rootOffset, 6, '')
            ..unit = const fb.StringReader(asciiOptimization: true)
                .vTableGet(buffer, rootOffset, 8, '')
            ..rewardUnit = const fb.StringReader(asciiOptimization: true)
                .vTableGet(buffer, rootOffset, 10, '')
            ..requirement =
                const fb.Int64Reader().vTableGet(buffer, rootOffset, 12, 0)
            ..reward =
                const fb.Int64Reader().vTableGet(buffer, rootOffset, 14, 0)
            ..progress =
                const fb.Float64Reader().vTableGet(buffer, rootOffset, 16, 0)
            ..dateAssigned =
                const fb.Int64Reader().vTableGet(buffer, rootOffset, 18, 0)
            ..isClaimed =
                const fb.BoolReader().vTableGet(buffer, rootOffset, 20, false);

          return object;
        }),
    GameStats: obx_int.EntityDefinition<GameStats>(
        model: _entities[6],
        toOneRelations: (GameStats object) => [],
        toManyRelations: (GameStats object) => {},
        getId: (GameStats object) => object.dayTimestamp,
        setId: (GameStats object, int id) {
          object.dayTimestamp = id;
        },
        objectToFB: (GameStats object, fb.Builder fbb) {
          fbb.startTable(15);
          fbb.addInt64(0, object.dayTimestamp);
          fbb.addInt64(1, object.generatorsPurchased);
          fbb.addInt64(2, object.generatorsUpgraded);
          fbb.addInt64(3, object.shopItemsUpgraded);
          fbb.addInt64(4, object.generatorsTapped);
          fbb.addInt64(5, object.adsWatched);
          fbb.addFloat64(6, object.caloriesBurned);
          fbb.addInt64(7, object.stepsWalked);
          fbb.addFloat64(8, object.coinsCollected);
          fbb.addFloat64(9, object.spaceCollected);
          fbb.addFloat64(10, object.energyCollected);
          fbb.addFloat64(11, object.energySpent);
          fbb.addFloat64(12, object.coinsSpent);
          fbb.addFloat64(13, object.spaceSpent);
          fbb.finish(fbb.endTable());
          return object.dayTimestamp;
        },
        objectFromFB: (obx.Store store, ByteData fbData) {
          final buffer = fb.BufferContext(fbData);
          final rootOffset = buffer.derefObject(0);
          final dayTimestampParam =
              const fb.Int64Reader().vTableGet(buffer, rootOffset, 4, 0);
          final generatorsPurchasedParam =
              const fb.Int64Reader().vTableGet(buffer, rootOffset, 6, 0);
          final generatorsUpgradedParam =
              const fb.Int64Reader().vTableGet(buffer, rootOffset, 8, 0);
          final shopItemsUpgradedParam =
              const fb.Int64Reader().vTableGet(buffer, rootOffset, 10, 0);
          final generatorsTappedParam =
              const fb.Int64Reader().vTableGet(buffer, rootOffset, 12, 0);
          final adsWatchedParam =
              const fb.Int64Reader().vTableGet(buffer, rootOffset, 14, 0);
          final caloriesBurnedParam =
              const fb.Float64Reader().vTableGet(buffer, rootOffset, 16, 0);
          final stepsWalkedParam =
              const fb.Int64Reader().vTableGet(buffer, rootOffset, 18, 0);
          final coinsCollectedParam =
              const fb.Float64Reader().vTableGet(buffer, rootOffset, 20, 0);
          final spaceCollectedParam =
              const fb.Float64Reader().vTableGet(buffer, rootOffset, 22, 0);
          final energyCollectedParam =
              const fb.Float64Reader().vTableGet(buffer, rootOffset, 24, 0);
          final energySpentParam =
              const fb.Float64Reader().vTableGet(buffer, rootOffset, 26, 0);
          final coinsSpentParam =
              const fb.Float64Reader().vTableGet(buffer, rootOffset, 28, 0);
          final spaceSpentParam =
              const fb.Float64Reader().vTableGet(buffer, rootOffset, 30, 0);
          final object = GameStats(
              dayTimestamp: dayTimestampParam,
              generatorsPurchased: generatorsPurchasedParam,
              generatorsUpgraded: generatorsUpgradedParam,
              shopItemsUpgraded: shopItemsUpgradedParam,
              generatorsTapped: generatorsTappedParam,
              adsWatched: adsWatchedParam,
              caloriesBurned: caloriesBurnedParam,
              stepsWalked: stepsWalkedParam,
              coinsCollected: coinsCollectedParam,
              spaceCollected: spaceCollectedParam,
              energyCollected: energyCollectedParam,
              energySpent: energySpentParam,
              coinsSpent: coinsSpentParam,
              spaceSpent: spaceSpentParam);

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
}

/// [ShopItem] entity fields to define ObjectBox queries.
class ShopItem_ {
  /// See [ShopItem.id].
  static final id =
      obx.QueryIntegerProperty<ShopItem>(_entities[2].properties[0]);

  /// See [ShopItem.level].
  static final level =
      obx.QueryIntegerProperty<ShopItem>(_entities[2].properties[1]);
}

/// [Achievement] entity fields to define ObjectBox queries.
class Achievement_ {
  /// See [Achievement.id].
  static final id =
      obx.QueryIntegerProperty<Achievement>(_entities[3].properties[0]);

  /// See [Achievement.dateClaimed].
  static final dateClaimed =
      obx.QueryIntegerProperty<Achievement>(_entities[3].properties[1]);

  /// See [Achievement.action].
  static final action =
      obx.QueryStringProperty<Achievement>(_entities[3].properties[2]);

  /// See [Achievement.reqUnit].
  static final reqUnit =
      obx.QueryStringProperty<Achievement>(_entities[3].properties[3]);

  /// See [Achievement.requirement].
  static final requirement =
      obx.QueryIntegerProperty<Achievement>(_entities[3].properties[4]);
}

/// [DailyHealth] entity fields to define ObjectBox queries.
class DailyHealth_ {
  /// See [DailyHealth.dayTimestamp].
  static final dayTimestamp =
      obx.QueryIntegerProperty<DailyHealth>(_entities[4].properties[0]);

  /// See [DailyHealth.steps].
  static final steps =
      obx.QueryIntegerProperty<DailyHealth>(_entities[4].properties[1]);

  /// See [DailyHealth.caloriesBurned].
  static final caloriesBurned =
      obx.QueryDoubleProperty<DailyHealth>(_entities[4].properties[2]);

  /// See [DailyHealth.lastSync].
  static final lastSync =
      obx.QueryIntegerProperty<DailyHealth>(_entities[4].properties[3]);
}

/// [DailyQuest] entity fields to define ObjectBox queries.
class DailyQuest_ {
  /// See [DailyQuest.id].
  static final id =
      obx.QueryIntegerProperty<DailyQuest>(_entities[5].properties[0]);

  /// See [DailyQuest.action].
  static final action =
      obx.QueryStringProperty<DailyQuest>(_entities[5].properties[1]);

  /// See [DailyQuest.unit].
  static final unit =
      obx.QueryStringProperty<DailyQuest>(_entities[5].properties[2]);

  /// See [DailyQuest.rewardUnit].
  static final rewardUnit =
      obx.QueryStringProperty<DailyQuest>(_entities[5].properties[3]);

  /// See [DailyQuest.requirement].
  static final requirement =
      obx.QueryIntegerProperty<DailyQuest>(_entities[5].properties[4]);

  /// See [DailyQuest.reward].
  static final reward =
      obx.QueryIntegerProperty<DailyQuest>(_entities[5].properties[5]);

  /// See [DailyQuest.progress].
  static final progress =
      obx.QueryDoubleProperty<DailyQuest>(_entities[5].properties[6]);

  /// See [DailyQuest.dateAssigned].
  static final dateAssigned =
      obx.QueryIntegerProperty<DailyQuest>(_entities[5].properties[7]);

  /// See [DailyQuest.isClaimed].
  static final isClaimed =
      obx.QueryBooleanProperty<DailyQuest>(_entities[5].properties[8]);
}

/// [GameStats] entity fields to define ObjectBox queries.
class GameStats_ {
  /// See [GameStats.dayTimestamp].
  static final dayTimestamp =
      obx.QueryIntegerProperty<GameStats>(_entities[6].properties[0]);

  /// See [GameStats.generatorsPurchased].
  static final generatorsPurchased =
      obx.QueryIntegerProperty<GameStats>(_entities[6].properties[1]);

  /// See [GameStats.generatorsUpgraded].
  static final generatorsUpgraded =
      obx.QueryIntegerProperty<GameStats>(_entities[6].properties[2]);

  /// See [GameStats.shopItemsUpgraded].
  static final shopItemsUpgraded =
      obx.QueryIntegerProperty<GameStats>(_entities[6].properties[3]);

  /// See [GameStats.generatorsTapped].
  static final generatorsTapped =
      obx.QueryIntegerProperty<GameStats>(_entities[6].properties[4]);

  /// See [GameStats.adsWatched].
  static final adsWatched =
      obx.QueryIntegerProperty<GameStats>(_entities[6].properties[5]);

  /// See [GameStats.caloriesBurned].
  static final caloriesBurned =
      obx.QueryDoubleProperty<GameStats>(_entities[6].properties[6]);

  /// See [GameStats.stepsWalked].
  static final stepsWalked =
      obx.QueryIntegerProperty<GameStats>(_entities[6].properties[7]);

  /// See [GameStats.coinsCollected].
  static final coinsCollected =
      obx.QueryDoubleProperty<GameStats>(_entities[6].properties[8]);

  /// See [GameStats.spaceCollected].
  static final spaceCollected =
      obx.QueryDoubleProperty<GameStats>(_entities[6].properties[9]);

  /// See [GameStats.energyCollected].
  static final energyCollected =
      obx.QueryDoubleProperty<GameStats>(_entities[6].properties[10]);

  /// See [GameStats.energySpent].
  static final energySpent =
      obx.QueryDoubleProperty<GameStats>(_entities[6].properties[11]);

  /// See [GameStats.coinsSpent].
  static final coinsSpent =
      obx.QueryDoubleProperty<GameStats>(_entities[6].properties[12]);

  /// See [GameStats.spaceSpent].
  static final spaceSpent =
      obx.QueryDoubleProperty<GameStats>(_entities[6].properties[13]);
}
