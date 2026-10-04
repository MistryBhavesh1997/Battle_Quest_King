# 🗡️ 2D RPG Adventure — Flutter Integration Guide (Flame + Tiled + GetX)

## Overview

A top-down RPG with:
- A tile map world built in the free **Tiled** editor
- A player moved by an on-screen joystick, with a camera that follows them
- Walls and collisions
- NPCs with dialogue and a quest
- Enemies that chase and attack
- Item pickups, inventory and potions
- XP, levels and gold
- Save / continue

**Split of work:**

| Flame (game loop)                  | GetX (state & UI)                               |
|------------------------------------|-------------------------------------------------|
| Map, movement, collisions, enemies | HP, XP, level, gold (`PlayerController`)        |
| Camera, joystick, animations       | Inventory (`InventoryController`)               |
| Pickups, NPC proximity             | Quests (`QuestController`)                      |
|                                    | Dialogue box (`DialogueController`)             |
|                                    | Save / load (`SaveService` + GetStorage)        |
|                                    | Menus, HUD, overlays (`Obx`)                    |

**Rule:** Flame components never store game progress. They call GetX controllers, and the UI reacts through `Obx`.

---

## 1. Setup

### pubspec.yaml

```yaml
dependencies:
  flutter:
    sdk: flutter
  flame: ^1.18.0
  flame_tiled: ^1.20.0
  get: ^4.6.6
  get_storage: ^2.1.1

flutter:
  assets:
    - assets/images/
    - assets/tiles/
```

```bash
flutter pub get
```

### Assets

```
assets/
  tiles/
    village.tmx          ← map made in Tiled
  images/
    tileset.png          ← tileset used by the map (16×16 tiles)
    hero.png             ← 4 rows × 4 frames, 32×32 (rows: down, left, right, up)
    slime.png            ← 4 frames in one row, 32×32
    npc.png              ← single 32×32 sprite
    potion.png           ← 16×16
    key.png              ← 16×16
```

> **Tileset path tip:** Flame loads images from `assets/images/`. In Tiled, make the tileset image path relative to the map, for example `../images/tileset.png`.

### Folder structure

```
lib/
  main.dart
  bindings/
    initial_binding.dart
    game_binding.dart
  data/
    items.dart
    quests.dart
  controllers/
    player_controller.dart
    inventory_controller.dart
    quest_controller.dart
    dialogue_controller.dart
    game_controller.dart
  services/
    save_service.dart
  game/
    rpg_game.dart
    player.dart
    npc.dart
    enemy.dart
    pickup.dart
    wall.dart
  ui/
    menu_screen.dart
    game_screen.dart
    overlays.dart
```

---

## 2. Building the map in Tiled

Create `village.tmx` with **16×16 tiles** and these layers:

| Layer name   | Type         | Purpose |
|--------------|--------------|---------|
| `Ground`     | Tile layer   | Grass, paths, water (visual) |
| `Decor`      | Tile layer   | Trees, houses (visual) |
| `Collisions` | Object layer | Rectangles the player can't walk through |
| `Spawns`     | Object layer | Points for player, NPCs, enemies, items |

**Spawn objects.** Use Point objects and add a custom string property `kind`:

| `kind`   | Object name   | Extra custom properties |
|----------|---------------|-------------------------|
| `player` | —             | — |
| `npc`    | `Elder`       | `dialogue` = `Hello traveler!\|Slimes attack our village.\|Please defeat 3 of them.`  •  `quest` = `slime_trouble` (optional)  •  `sprite` = `npc.png` (optional) |
| `enemy`  | —             | `type` = `slime` |
| `item`   | —             | `item` = `potion` or `key` |

Dialogue lines are split by `|`.

---

## 3. main.dart

```dart
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'bindings/game_binding.dart';
import 'bindings/initial_binding.dart';
import 'ui/game_screen.dart';
import 'ui/menu_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  await Flame.device.fullScreen();
  await Flame.device.setLandscape();

  runApp(GetMaterialApp(
    debugShowCheckedModeBanner: false,
    title: '2D RPG Adventure',
    theme: ThemeData.dark(),
    initialBinding: InitialBinding(),
    initialRoute: '/',
    getPages: [
      GetPage(name: '/', page: () => const MenuScreen()),
      GetPage(name: '/game', page: () => const GameScreen(), binding: GameBinding()),
    ],
  ));
}
```

---

## 4. Bindings

### bindings/initial_binding.dart

These controllers are **permanent**. Progress lives here for the whole app session.

```dart
import 'package:get/get.dart';
import '../controllers/dialogue_controller.dart';
import '../controllers/inventory_controller.dart';
import '../controllers/player_controller.dart';
import '../controllers/quest_controller.dart';
import '../services/save_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(SaveService(), permanent: true);
    Get.put(PlayerController(), permanent: true);
    Get.put(InventoryController(), permanent: true);
    Get.put(QuestController(), permanent: true);
    Get.put(DialogueController(), permanent: true);
  }
}
```

### bindings/game_binding.dart

```dart
import 'package:get/get.dart';
import '../controllers/game_controller.dart';

class GameBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut(() => GameController());
}
```

---

## 5. Data

### data/items.dart

```dart
enum ItemType { potion, key, misc }

class Item {
  const Item(this.id, this.name, this.icon, this.type, [this.value = 0]);
  final String id, name, icon;
  final ItemType type;
  final int value; // heal amount for potions
}

class Items {
  static const all = <String, Item>{
    'potion': Item('potion', 'Health Potion', 'potion.png', ItemType.potion, 30),
    'key': Item('key', 'Old Key', 'key.png', ItemType.key),
  };
}
```

### data/quests.dart

```dart
import 'package:get/get.dart';

class Quest {
  Quest({
    required this.id,
    required this.title,
    required this.targetKind,
    required this.required,
    this.rewardXp = 0,
    this.rewardGold = 0,
    this.rewardItem,
  });

  final String id, title, targetKind;
  final int required, rewardXp, rewardGold;
  final String? rewardItem;

  final progress = 0.obs;
  final done = false.obs;

  bool get isReady => !done.value && progress.value >= required;
}

class Quests {
  static Quest create(String id) => switch (id) {
        'slime_trouble' => Quest(
            id: id,
            title: 'Slime Trouble',
            targetKind: 'slime',
            required: 3,
            rewardXp: 50,
            rewardGold: 30,
            rewardItem: 'potion',
          ),
        _ => throw ArgumentError('Unknown quest: $id'),
      };
}
```

---

## 6. Controllers (GetX)

### controllers/player_controller.dart

```dart
import 'package:get/get.dart';

class PlayerController extends GetxController {
  final hp = 100.obs;
  final maxHp = 100.obs;
  final xp = 0.obs;
  final level = 1.obs;
  final gold = 0.obs;
  final attack = 10.obs;

  int get xpToNext => level.value * 50;
  bool get isDead => hp.value <= 0;

  void takeDamage(int d) => hp.value = (hp.value - d).clamp(0, maxHp.value);
  void heal(int v) => hp.value = (hp.value + v).clamp(0, maxHp.value);
  void addGold(int g) => gold.value += g;

  void gainXp(int v) {
    xp.value += v;
    while (xp.value >= xpToNext) {
      xp.value -= xpToNext;
      level.value++;
      maxHp.value += 20;
      attack.value += 3;
      hp.value = maxHp.value;
      Get.rawSnackbar(message: '⭐ Level up! You are now level ${level.value}');
    }
  }

  void reset() {
    hp.value = 100;
    maxHp.value = 100;
    xp.value = 0;
    level.value = 1;
    gold.value = 0;
    attack.value = 10;
  }

  Map<String, dynamic> toJson() => {
        'hp': hp.value,
        'maxHp': maxHp.value,
        'xp': xp.value,
        'level': level.value,
        'gold': gold.value,
        'attack': attack.value,
      };

  void fromJson(Map<String, dynamic> j) {
    maxHp.value = j['maxHp'] ?? 100;
    hp.value = j['hp'] ?? maxHp.value;
    xp.value = j['xp'] ?? 0;
    level.value = j['level'] ?? 1;
    gold.value = j['gold'] ?? 0;
    attack.value = j['attack'] ?? 10;
  }
}
```

### controllers/inventory_controller.dart

```dart
import 'package:get/get.dart';
import '../data/items.dart';
import 'player_controller.dart';

class InventoryController extends GetxController {
  final items = <String, int>{}.obs; // itemId → quantity
  final Set<String> collected = {}; // map pickups already taken

  int count(String id) => items[id] ?? 0;
  bool has(String id) => count(id) > 0;

  void add(String id, [int n = 1]) => items[id] = count(id) + n;

  void pickUp(String spawnKey, String id) {
    collected.add(spawnKey);
    add(id);
    Get.rawSnackbar(
      message: 'Picked up ${Items.all[id]?.name ?? id}',
      duration: const Duration(seconds: 1),
    );
  }

  void use(String id) {
    final item = Items.all[id];
    if (item == null || !has(id)) return;
    if (item.type == ItemType.potion) {
      Get.find<PlayerController>().heal(item.value);
      _removeOne(id);
    }
  }

  void _removeOne(String id) {
    final q = count(id) - 1;
    q <= 0 ? items.remove(id) : items[id] = q;
  }

  void reset() {
    items.clear();
    collected.clear();
  }

  Map<String, dynamic> toJson() => {'items': items, 'collected': collected.toList()};

  void fromJson(Map<String, dynamic> j) {
    items.assignAll(Map<String, int>.from(j['items'] ?? {}));
    collected
      ..clear()
      ..addAll(List<String>.from(j['collected'] ?? []));
  }
}
```

### controllers/quest_controller.dart

```dart
import 'package:get/get.dart';
import '../data/quests.dart';
import 'inventory_controller.dart';
import 'player_controller.dart';

class QuestController extends GetxController {
  final quests = <Quest>[].obs;

  Quest? byId(String id) {
    for (final q in quests) {
      if (q.id == id) return q;
    }
    return null;
  }

  void accept(String id) {
    if (byId(id) != null) return;
    final q = Quests.create(id);
    quests.add(q);
    Get.rawSnackbar(message: '📜 New quest: ${q.title}');
  }

  /// Called by Enemy when it dies.
  void onKill(String kind) {
    for (final q in quests) {
      if (!q.done.value && q.targetKind == kind && q.progress.value < q.required) {
        q.progress.value++;
      }
    }
  }

  void complete(String id) {
    final q = byId(id);
    if (q == null || !q.isReady) return;
    q.done.value = true;
    final p = Get.find<PlayerController>();
    p.gainXp(q.rewardXp);
    p.addGold(q.rewardGold);
    if (q.rewardItem != null) Get.find<InventoryController>().add(q.rewardItem!);
    Get.rawSnackbar(message: '✅ Quest complete: ${q.title}');
  }

  void reset() => quests.clear();

  List<Map<String, dynamic>> toJson() => quests
      .map((q) => {'id': q.id, 'progress': q.progress.value, 'done': q.done.value})
      .toList();

  void fromJson(List data) {
    quests.clear();
    for (final raw in data) {
      final m = Map<String, dynamic>.from(raw);
      final q = Quests.create(m['id']);
      q.progress.value = m['progress'] ?? 0;
      q.done.value = m['done'] ?? false;
      quests.add(q);
    }
  }
}
```

### controllers/dialogue_controller.dart

```dart
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class DialogueController extends GetxController {
  final isOpen = false.obs;
  final speaker = ''.obs;
  final lines = <String>[].obs;
  final index = 0.obs;
  VoidCallback? _onEnd;

  String get text => lines.isEmpty ? '' : lines[index.value];

  void start(String who, List<String> l, {VoidCallback? onEnd}) {
    speaker.value = who;
    lines.assignAll(l);
    index.value = 0;
    _onEnd = onEnd;
    isOpen.value = true;
  }

  void next() {
    if (index.value < lines.length - 1) {
      index.value++;
      return;
    }
    isOpen.value = false;
    final cb = _onEnd;
    _onEnd = null;
    cb?.call();
  }
}
```

### controllers/game_controller.dart

```dart
import 'package:get/get.dart';
import '../game/rpg_game.dart';
import '../services/save_service.dart';
import 'player_controller.dart';

class GameController extends GetxController {
  late final RpgGame game;

  @override
  void onInit() {
    super.onInit();
    Get.find<SaveService>().load(); // no-op when there is no save
    game = RpgGame();
  }

  void saveGame() => Get.find<SaveService>().save(game.player.position);

  void toggleInventory() {
    if (game.overlays.isActive('inventory')) {
      game.overlays.remove('inventory');
      game.resumeEngine();
    } else {
      game.overlays.add('inventory');
      game.pauseEngine();
    }
  }

  void respawn() {
    final p = Get.find<PlayerController>();
    p.hp.value = p.maxHp.value;
    game.player.position.setFrom(game.spawnPoint);
  }
}
```

---

## 7. Save service

### services/save_service.dart

```dart
import 'package:flame/components.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../controllers/inventory_controller.dart';
import '../controllers/player_controller.dart';
import '../controllers/quest_controller.dart';

class SaveService extends GetxService {
  final _box = GetStorage();

  bool get hasSave => _box.hasData('player');

  Vector2? get savedPosition {
    final p = _box.read<List>('pos');
    if (p == null) return null;
    return Vector2((p[0] as num).toDouble(), (p[1] as num).toDouble());
  }

  void save(Vector2 pos) {
    _box.write('player', Get.find<PlayerController>().toJson());
    _box.write('inventory', Get.find<InventoryController>().toJson());
    _box.write('quests', Get.find<QuestController>().toJson());
    _box.write('pos', [pos.x, pos.y]);
    Get.rawSnackbar(message: '💾 Game saved', duration: const Duration(seconds: 1));
  }

  void load() {
    if (!hasSave) return;
    Get.find<PlayerController>().fromJson(Map<String, dynamic>.from(_box.read('player')));
    Get.find<InventoryController>().fromJson(Map<String, dynamic>.from(_box.read('inventory') ?? {}));
    Get.find<QuestController>().fromJson(_box.read<List>('quests') ?? []);
  }

  Future<void> newGame() async {
    await _box.erase();
    Get.find<PlayerController>().reset();
    Get.find<InventoryController>().reset();
    Get.find<QuestController>().reset();
  }
}
```

---

## 8. Game (Flame)

### game/rpg_game.dart

```dart
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/inventory_controller.dart';
import '../services/save_service.dart';
import 'enemy.dart';
import 'npc.dart';
import 'pickup.dart';
import 'player.dart';
import 'wall.dart';

class RpgGame extends FlameGame with HasCollisionDetection {
  late Player player;
  late JoystickComponent joystick;
  Vector2 spawnPoint = Vector2.zero();

  @override
  Color backgroundColor() => const Color(0xFF1B1B2F);

  @override
  Future<void> onLoad() async {
    // 1) Map
    final map = await TiledComponent.load('village.tmx', Vector2.all(16));
    world.add(map);

    // 2) Walls
    final walls = map.tileMap.getLayer<ObjectGroup>('Collisions');
    for (final o in walls?.objects ?? const <TiledObject>[]) {
      world.add(Wall(Vector2(o.x, o.y), Vector2(o.width, o.height)));
    }

    // 3) Spawns
    final inv = Get.find<InventoryController>();
    final spawns = map.tileMap.getLayer<ObjectGroup>('Spawns');
    for (final o in spawns?.objects ?? const <TiledObject>[]) {
      final pos = Vector2(o.x, o.y);
      final props = o.properties;
      switch (props.getValue<String>('kind')) {
        case 'player':
          spawnPoint = pos;
        case 'npc':
          world.add(Npc(
            npcName: o.name,
            position: pos,
            lines: (props.getValue<String>('dialogue') ?? '...').split('|'),
            questId: props.getValue<String>('quest'),
            spriteFile: props.getValue<String>('sprite') ?? 'npc.png',
          ));
        case 'enemy':
          world.add(Enemy(kind: props.getValue<String>('type') ?? 'slime', position: pos));
        case 'item':
          final key = 'item_${o.id}';
          if (!inv.collected.contains(key)) {
            world.add(Pickup(
              spawnKey: key,
              itemId: props.getValue<String>('item') ?? 'potion',
              position: pos,
            ));
          }
      }
    }

    // 4) Player (saved position or spawn)
    player = Player(position: Get.find<SaveService>().savedPosition ?? spawnPoint.clone());
    world.add(player);

    // 5) Camera
    camera.viewfinder.zoom = 2.5;
    camera.follow(player);

    // 6) Joystick (fixed on screen, so it goes on the viewport)
    joystick = JoystickComponent(
      knob: CircleComponent(radius: 22, paint: Paint()..color = Colors.white70),
      background: CircleComponent(radius: 55, paint: Paint()..color = Colors.white24),
      margin: const EdgeInsets.only(left: 40, bottom: 40),
    );
    camera.viewport.add(joystick);
  }
}
```

### game/player.dart

```dart
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:get/get.dart';
import '../controllers/dialogue_controller.dart';
import '../controllers/player_controller.dart';
import 'enemy.dart';
import 'npc.dart';
import 'rpg_game.dart';
import 'wall.dart';

enum Facing { down, left, right, up } // = rows in hero.png

class Player extends SpriteAnimationGroupComponent<Facing>
    with HasGameReference<RpgGame>, CollisionCallbacks {
  Player({required super.position})
      : super(size: Vector2.all(32), anchor: Anchor.center, priority: 10);

  static const speed = 90.0;

  final _stats = Get.find<PlayerController>();
  final _dialogue = Get.find<DialogueController>();
  final _prev = Vector2.zero();
  double _attackCooldown = 0;

  bool get _locked => _dialogue.isOpen.value || _stats.isDead;

  @override
  Future<void> onLoad() async {
    final sheet = SpriteSheet(
      image: await game.images.load('hero.png'),
      srcSize: Vector2.all(32),
    );
    animations = {
      for (final f in Facing.values) f: sheet.createAnimation(row: f.index, stepTime: 0.15),
    };
    current = Facing.down;
    _prev.setFrom(position);

    // Small hitbox at the feet feels best in top-down games
    add(RectangleHitbox(size: Vector2(16, 12), position: Vector2(8, 18)));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _attackCooldown -= dt;

    final d = game.joystick.relativeDelta;
    if (_locked || d.isZero()) {
      playing = false;
      return;
    }

    playing = true;
    _prev.setFrom(position);
    position.add(d * speed * dt);

    current = d.x.abs() > d.y.abs()
        ? (d.x > 0 ? Facing.right : Facing.left)
        : (d.y > 0 ? Facing.down : Facing.up);
  }

  @override
  void onCollision(Set<Vector2> points, PositionComponent other) {
    super.onCollision(points, other);
    if (other is Wall) position.setFrom(_prev); // block movement
  }

  /// TALK button
  void interact() {
    if (_locked) return;
    for (final npc in game.world.children.whereType<Npc>()) {
      if (npc.position.distanceTo(position) < 32) {
        npc.onInteract();
        return;
      }
    }
  }

  /// ATTACK button
  void attack() {
    if (_locked || _attackCooldown > 0) return;
    _attackCooldown = 0.4;
    for (final e in game.world.children.whereType<Enemy>().toList()) {
      if (e.position.distanceTo(position) < 36) e.takeHit(_stats.attack.value);
    }
  }
}
```

### game/wall.dart

```dart
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

class Wall extends PositionComponent {
  Wall(Vector2 position, Vector2 size) : super(position: position, size: size);

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox(collisionType: CollisionType.passive));
  }
}
```

### game/npc.dart

```dart
import 'package:flame/components.dart';
import 'package:get/get.dart';
import '../controllers/dialogue_controller.dart';
import '../controllers/quest_controller.dart';
import 'rpg_game.dart';

class Npc extends SpriteComponent with HasGameReference<RpgGame> {
  Npc({
    required this.npcName,
    required this.lines,
    required super.position,
    this.questId,
    this.spriteFile = 'npc.png',
  }) : super(size: Vector2.all(32), anchor: Anchor.center);

  final String npcName, spriteFile;
  final List<String> lines;
  final String? questId;

  @override
  Future<void> onLoad() async => sprite = await game.loadSprite(spriteFile);

  void onInteract() {
    final d = Get.find<DialogueController>();
    final qc = Get.find<QuestController>();

    if (questId == null) {
      d.start(npcName, lines);
      return;
    }

    final quest = qc.byId(questId!);
    if (quest == null) {
      d.start(npcName, lines, onEnd: () => qc.accept(questId!));
    } else if (quest.isReady) {
      d.start(npcName, ['You did it, hero!', 'Please take this reward.'],
          onEnd: () => qc.complete(questId!));
    } else if (quest.done.value) {
      d.start(npcName, ['The village is safe thanks to you.']);
    } else {
      final left = quest.required - quest.progress.value;
      d.start(npcName, ['Still $left more to go. Be careful out there!']);
    }
  }
}
```

### game/enemy.dart

```dart
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/dialogue_controller.dart';
import '../controllers/player_controller.dart';
import '../controllers/quest_controller.dart';
import 'rpg_game.dart';

class Enemy extends SpriteAnimationComponent with HasGameReference<RpgGame> {
  Enemy({
    required super.position,
    this.kind = 'slime',
    this.hp = 20,
    this.damage = 5,
    this.xp = 10,
    this.gold = 5,
  }) : super(size: Vector2.all(32), anchor: Anchor.center);

  final String kind;
  int hp;
  final int damage, xp, gold;

  static const chaseRange = 120.0, speed = 40.0;
  double _hitCooldown = 0;

  @override
  Future<void> onLoad() async {
    animation = await game.loadSpriteAnimation(
      '$kind.png',
      SpriteAnimationData.sequenced(amount: 4, stepTime: 0.2, textureSize: Vector2.all(32)),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    final stats = Get.find<PlayerController>();
    if (stats.isDead || Get.find<DialogueController>().isOpen.value) return;

    _hitCooldown -= dt;
    final toPlayer = game.player.position - position;
    final dist = toPlayer.length;

    if (dist < chaseRange && dist > 14) {
      position.add(toPlayer.normalized() * speed * dt); // chase
    }
    if (dist < 20 && _hitCooldown <= 0) {
      stats.takeDamage(damage); // contact damage
      _hitCooldown = 1.0;
    }
  }

  void takeHit(int dmg) {
    hp -= dmg;
    add(ColorEffect(
      Colors.white,
      EffectController(duration: 0.1, alternate: true),
      opacityTo: 0.8,
    ));
    if (hp <= 0) {
      final stats = Get.find<PlayerController>();
      stats.gainXp(xp);
      stats.addGold(gold);
      Get.find<QuestController>().onKill(kind);
      removeFromParent();
    }
  }
}
```

### game/pickup.dart

```dart
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:get/get.dart';
import '../controllers/inventory_controller.dart';
import '../data/items.dart';
import 'player.dart';
import 'rpg_game.dart';

class Pickup extends SpriteComponent
    with HasGameReference<RpgGame>, CollisionCallbacks {
  Pickup({required this.spawnKey, required this.itemId, required super.position})
      : super(size: Vector2.all(16), anchor: Anchor.center);

  final String spawnKey, itemId;

  @override
  Future<void> onLoad() async {
    sprite = await game.loadSprite(Items.all[itemId]?.icon ?? 'potion.png');
    add(RectangleHitbox());
  }

  @override
  void onCollisionStart(Set<Vector2> points, PositionComponent other) {
    super.onCollisionStart(points, other);
    if (other is Player) {
      Get.find<InventoryController>().pickUp(spawnKey, itemId);
      removeFromParent();
    }
  }
}
```

---

## 9. UI (Flutter + GetX)

### ui/menu_screen.dart

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/save_service.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final save = Get.find<SaveService>();
    return Scaffold(
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('2D RPG Adventure',
              style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () async {
              await save.newGame();
              Get.offNamed('/game');
            },
            child: const Text('New Game'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: save.hasSave ? () => Get.offNamed('/game') : null,
            child: const Text('Continue'),
          ),
        ]),
      ),
    );
  }
}
```

### ui/game_screen.dart

```dart
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/game_controller.dart';
import 'overlays.dart';

class GameScreen extends GetView<GameController> {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget(
        game: controller.game,
        overlayBuilderMap: {
          'hud': (_, __) => const Hud(),
          'actions': (_, __) => const ActionButtons(),
          'dialogue': (_, __) => const DialogueBox(),
          'inventory': (_, __) => const InventoryPanel(),
          'gameOver': (_, __) => const GameOverView(),
        },
        // dialogue & gameOver show/hide themselves with Obx
        initialActiveOverlays: const ['hud', 'actions', 'dialogue', 'gameOver'],
      ),
    );
  }
}
```

### ui/overlays.dart

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/dialogue_controller.dart';
import '../controllers/game_controller.dart';
import '../controllers/inventory_controller.dart';
import '../controllers/player_controller.dart';
import '../controllers/quest_controller.dart';
import '../data/items.dart';

// ---------------- HUD ----------------
class Hud extends StatelessWidget {
  const Hud({super.key});

  @override
  Widget build(BuildContext context) {
    final p = Get.find<PlayerController>();
    final q = Get.find<QuestController>();
    final g = Get.find<GameController>();

    Widget bar(double value, Color color) => SizedBox(
          width: 160,
          height: 10,
          child: LinearProgressIndicator(
            value: value.clamp(0, 1),
            color: color,
            backgroundColor: Colors.black54,
          ),
        );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Obx(() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Lv ${p.level.value}   HP ${p.hp.value}/${p.maxHp.value}   🪙 ${p.gold.value}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  bar(p.hp.value / p.maxHp.value, Colors.redAccent),
                  const SizedBox(height: 3),
                  bar(p.xp.value / p.xpToNext, Colors.lightBlueAccent),
                ])),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.backpack, color: Colors.white),
              onPressed: g.toggleInventory,
            ),
            IconButton(
              icon: const Icon(Icons.save, color: Colors.white),
              onPressed: g.saveGame,
            ),
          ]),
          const SizedBox(height: 8),
          // Quest tracker
          Obx(() => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: q.quests
                    .where((e) => !e.done.value)
                    .map((e) => Text(
                          '📜 ${e.title}  ${e.progress.value}/${e.required}'
                          '${e.isReady ? '  (return to quest giver)' : ''}',
                          style: const TextStyle(color: Colors.amber),
                        ))
                    .toList(),
              )),
        ]),
      ),
    );
  }
}

// ---------------- Action buttons ----------------
class ActionButtons extends StatelessWidget {
  const ActionButtons({super.key});

  Widget _btn(String label, Color color, VoidCallback onTap) => GestureDetector(
        onTapDown: (_) => onTap(),
        child: Container(
          width: 72,
          height: 72,
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.6), shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(label,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final game = Get.find<GameController>().game;
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            _btn('TALK', Colors.teal, game.player.interact),
            _btn('ATTACK', Colors.red, game.player.attack),
          ]),
        ),
      ),
    );
  }
}

// ---------------- Dialogue box ----------------
class DialogueBox extends StatelessWidget {
  const DialogueBox({super.key});

  @override
  Widget build(BuildContext context) {
    final d = Get.find<DialogueController>();
    return Obx(() {
      if (!d.isOpen.value) return const SizedBox.shrink();
      return GestureDetector(
        onTap: d.next,
        child: Container(
          color: Colors.transparent,
          alignment: Alignment.bottomCenter,
          padding: const EdgeInsets.all(20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black87,
              border: Border.all(color: Colors.amber, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(d.speaker.value,
                  style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 6),
              Text(d.text, style: const TextStyle(color: Colors.white, fontSize: 16)),
              const Align(
                alignment: Alignment.bottomRight,
                child: Text('tap ▶', style: TextStyle(color: Colors.white54)),
              ),
            ]),
          ),
        ),
      );
    });
  }
}

// ---------------- Inventory ----------------
class InventoryPanel extends StatelessWidget {
  const InventoryPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final inv = Get.find<InventoryController>();
    final g = Get.find<GameController>();
    return Container(
      color: Colors.black54,
      alignment: Alignment.center,
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(12)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            const Text('Inventory', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(icon: const Icon(Icons.close), onPressed: g.toggleInventory),
          ]),
          Obx(() {
            if (inv.items.isEmpty) {
              return const Padding(padding: EdgeInsets.all(16), child: Text('Your bag is empty'));
            }
            return Column(
              children: inv.items.entries.map((e) {
                final item = Items.all[e.key];
                return ListTile(
                  leading: Image.asset('assets/images/${item?.icon ?? 'potion.png'}', width: 24),
                  title: Text('${item?.name ?? e.key} × ${e.value}'),
                  trailing: item?.type == ItemType.potion
                      ? TextButton(onPressed: () => inv.use(e.key), child: const Text('Use'))
                      : null,
                );
              }).toList(),
            );
          }),
        ]),
      ),
    );
  }
}

// ---------------- Game over ----------------
class GameOverView extends StatelessWidget {
  const GameOverView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = Get.find<PlayerController>();
    final g = Get.find<GameController>();
    return Obx(() {
      if (!p.isDead) return const SizedBox.shrink();
      return Container(
        color: Colors.black87,
        alignment: Alignment.center,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('You were defeated',
              style: TextStyle(fontSize: 36, color: Colors.redAccent, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: g.respawn, child: const Text('Respawn')),
        ]),
      );
    });
  }
}
```

---

## 10. How the pieces connect

```
Joystick ──► Player.update() ──► moves, blocked by Wall hitboxes
                                   │
TALK button ──► Player.interact() ──► Npc.onInteract()
                                        │
                                        ▼
                               DialogueController.start()  ──► DialogueBox (Obx)
                                        │ onEnd
                                        ▼
                               QuestController.accept() / complete()

ATTACK button ──► Player.attack() ──► Enemy.takeHit()
                                        │ hp <= 0
                                        ▼
                    PlayerController.gainXp()/addGold() + QuestController.onKill()
                                        │
                                        ▼
                               HUD (Obx) updates HP / XP / gold / quest tracker

Enemy touches player ──► PlayerController.takeDamage() ──► isDead ──► GameOverView

Player walks over Pickup ──► InventoryController.pickUp() ──► InventoryPanel (Obx)

Save icon ──► SaveService.save()  ──► GetStorage
Menu "Continue" ──► GameController.onInit() ──► SaveService.load()
```

| Concern               | Where it lives |
|-----------------------|----------------|
| Map & walls           | `village.tmx` → `RpgGame.onLoad()` |
| Movement & animation  | `Player.update()` |
| Combat                | `Player.attack()`, `Enemy.takeHit()` |
| Stats / level up      | `PlayerController` |
| Items                 | `InventoryController` + `data/items.dart` |
| Quests                | `QuestController` + `data/quests.dart` |
| Dialogue              | `DialogueController` + `DialogueBox` |
| Save / load           | `SaveService` (GetStorage) |
| UI                    | `overlays.dart` (all `Obx`) |

---

## 11. Controls

| Action      | Touch |
|-------------|-------|
| Move        | Joystick (bottom-left) |
| Talk        | TALK button, near an NPC |
| Attack      | ATTACK button, near an enemy |
| Next line   | Tap the dialogue box |
| Inventory   | 🎒 icon (pauses the game) |
| Save        | 💾 icon |

---

## 12. Tuning

| Setting                | Location |
|------------------------|----------|
| Player speed           | `Player.speed` |
| Talk / attack range    | `Player.interact()` (32), `Player.attack()` (36) |
| Attack cooldown        | `Player.attack()` (`0.4`) |
| Enemy HP / damage / XP | `Enemy(...)` constructor defaults |
| Enemy chase range      | `Enemy.chaseRange` |
| XP per level           | `PlayerController.xpToNext` |
| Level-up bonuses       | `PlayerController.gainXp()` |
| Camera zoom            | `camera.viewfinder.zoom` in `RpgGame` |
| Potion heal amount     | `Items.all['potion']` |

---

## 13. Adding content

- **New item:** add it to `Items.all`, put its icon in `assets/images/`, and place an `item` spawn in Tiled.
- **New quest:** add a case to `Quests.create()`, then set the `quest` property on an NPC in Tiled.
- **New enemy type:** add `bat.png` (4 frames), then set `type = bat` on an enemy spawn. To give it different stats, read extra Tiled properties and pass them to `Enemy(...)`.
- **New map / area:** make `cave.tmx`, add a `door` spawn kind that calls a `loadMap('cave.tmx')` method in `RpgGame`, which clears `world` and rebuilds it.

---

## 14. Next steps (optional)

- **Keyboard support (web/desktop):** add the `KeyboardEvents` mixin to `RpgGame` and combine WASD with the joystick delta.
- **Shop NPC:** add a `shop` kind that opens a Flutter overlay where players buy potions with `gold`.
- **Enemy respawn:** remember defeated enemies by spawn id (like pickups) or respawn them on a timer.
- **Enemies blocked by walls:** give `Enemy` a hitbox plus the same `_prev` revert used in `Player`.
- **Music & SFX:** add the `flame_audio` package for background music and hit/pickup sounds.
- **Auto-save:** call `SaveService.save()` after each quest completes.

---

## 15. Troubleshooting

| Problem | Fix |
|---------|-----|
| `Unable to load asset: assets/tiles/village.tmx` | Add `assets/tiles/` to pubspec and check the file name. |
| Map shows but the tileset is missing | The tileset image path in Tiled must point to `../images/tileset.png`. |
| Player walks through walls | The object layer must be named exactly `Collisions`, and `RpgGame` needs `HasCollisionDetection`. |
| Nothing spawns | Each Spawns object needs a custom property `kind` (lowercase). |
| Player is tiny or huge | Change `camera.viewfinder.zoom`. |
| HUD not updating | The value must be `.obs` and read inside `Obx(() => ...)`. |
| `Get.find` error: controller not found | Make sure `initialBinding: InitialBinding()` is set in `GetMaterialApp`. |
| Continue button disabled | No save yet. Tap the 💾 icon in-game first. |
