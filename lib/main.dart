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

  runApp(const QuestOfKingsApp());
}

class QuestOfKingsApp extends StatelessWidget {
  const QuestOfKingsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quest of Kings',
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF4C430),
          brightness: Brightness.dark,
        ),
      ),
      initialBinding: InitialBinding(),
      initialRoute: '/',
      defaultTransition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 700),
      getPages: [
        GetPage(name: '/', page: () => const MenuScreen()),
        GetPage(name: '/game', page: () => const GameScreen(), binding: GameBinding()),
      ],
    );
  }
}
