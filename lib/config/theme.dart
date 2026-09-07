import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:chinese_font_library/chinese_font_library.dart';

const List<String> _webChineseFontFallback = <String>[
  'PingFang SC',
  'Hiragino Sans GB',
  'Microsoft YaHei',
  'Noto Sans SC',
  'Noto Sans CJK SC',
  'Source Han Sans SC',
  'WenQuanYi Micro Hei',
  'sans-serif',
];

/// 用枚举太麻烦了
enum ColorSeed {
  baseColor('M3 Baseline', Color(0xff5b7cfa)),
  indigo('Indigo', Colors.indigo),
  blue('Blue', Colors.blue),
  teal('Teal', Colors.teal),
  green('Green', Colors.green),
  yellow('Yellow', Colors.yellow),
  orange('Orange', Colors.orange),
  deepOrange('Deep Orange', Colors.deepOrange),
  pink('Pink', Colors.pink);

  const ColorSeed(this.label, this.color);
  final String label;
  final Color color;
}

const Map<String, Color> colorSeedMap = {
  'M3 Baseline': Color(0xff5b7cfa),
  'Indigo': Colors.indigo,
  'Blue': Colors.blue,
  'Teal': Colors.teal,
  'Green': Colors.green,
  'Yellow': Colors.yellow,
  'Orange': Colors.orange,
  'Deep Orange': Colors.deepOrange,
  'Pink': Colors.pink
};

/// 「晨雾玻璃」主题色板。
///
/// 浅色模式以雾蓝为底、靛紫作强调，卡片为半透明白配白色描边；
/// 深色模式沿用同一强调色，底色换成夜雾蓝黑。
abstract final class MistPalette {
  /// 页面渐变的最底色（同时作为 scaffoldBackgroundColor，避免出现透明穿透）。
  static const lightBase = Color(0xFFEAF0F8);
  static const darkBase = Color(0xFF10131C);

  /// 卡片玻璃面与描边。
  static const lightGlass = Color(0x9EFFFFFF); // 白 62%
  static const lightGlassBorder = Color(0xBFFFFFFF); // 白 75%
  static const darkGlass = Color(0x0AFFFFFF); // 白 4%
  static const darkGlassBorder = Color(0x14FFFFFF); // 白 8%

  /// 导航栏 / 标题栏的玻璃面。
  static const lightRailGlass = Color(0x73FFFFFF); // 白 45%
  static const darkRailGlass = Color(0x0DFFFFFF); // 白 5%

  /// 渐变光斑（页面四角的柔色晕染）。
  static const lightGlowViolet = Color(0x247C5BFA);
  static const lightGlowBlue = Color(0x243898FF);
  static const lightGlowGreen = Color(0x1412B26B);
  static const darkGlowViolet = Color(0x2E7C5BFA);
  static const darkGlowBlue = Color(0x263898FF);
  static const darkGlowGreen = Color(0x1A18B26B);

  /// 分隔线。
  static const lightHairline = Color(0x171E283A);
  static const darkHairline = Color(0x1FFFFFFF);
}

/// 晨雾渐变页面背景：底色 + 三个柔色光斑，亮暗模式各自取色。
class MistBackground extends StatelessWidget {
  const MistBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: isDark ? MistPalette.darkBase : MistPalette.lightBase,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.9, -1.15),
                radius: 0.9,
                colors: [
                  isDark ? MistPalette.darkGlowViolet : MistPalette.lightGlowViolet,
                  Colors.transparent,
                ],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-1.05, 1.1),
                radius: 1.0,
                colors: [
                  isDark ? MistPalette.darkGlowBlue : MistPalette.lightGlowBlue,
                  Colors.transparent,
                ],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.45, 1.3),
                radius: 0.8,
                colors: [
                  isDark ? MistPalette.darkGlowGreen : MistPalette.lightGlowGreen,
                  Colors.transparent,
                ],
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

ThemeData lightTheme = ThemeData(
  colorSchemeSeed: ColorSeed.baseColor.color,
  useMaterial3: true,
  brightness: Brightness.light,
  textTheme: _buildTextTheme(Brightness.light),
  scaffoldBackgroundColor: MistPalette.lightBase,
  dividerColor: MistPalette.lightHairline,
  appBarTheme: const AppBarThemeData(
    backgroundColor: MistPalette.lightRailGlass,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
  ),
  dividerTheme: const DividerThemeData(
    color: MistPalette.lightHairline,
    thickness: 1,
    space: 1,
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    margin: EdgeInsets.zero,
    color: MistPalette.lightGlass,
    surfaceTintColor: Colors.transparent,
    shadowColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: MistPalette.lightGlassBorder),
    ),
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: const Color(0xFFFFFFFF),
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
  navigationRailTheme: const NavigationRailThemeData(
    backgroundColor: MistPalette.lightRailGlass,
    indicatorColor: Color(0xFFFFFFFF),
    elevation: 0,
  ),
  navigationBarTheme: const NavigationBarThemeData(
    backgroundColor: MistPalette.lightRailGlass,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
  ),
  tabBarTheme: const TabBarThemeData(
    dividerColor: MistPalette.lightHairline,
  ),
);

ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  colorSchemeSeed: ColorSeed.baseColor.color,
  brightness: Brightness.dark,
  textTheme: _buildTextTheme(Brightness.dark),
  scaffoldBackgroundColor: MistPalette.darkBase,
  dividerColor: MistPalette.darkHairline,
  appBarTheme: const AppBarThemeData(
    backgroundColor: MistPalette.darkRailGlass,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
  ),
  dividerTheme: const DividerThemeData(
    color: MistPalette.darkHairline,
    thickness: 1,
    space: 1,
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    margin: EdgeInsets.zero,
    color: MistPalette.darkGlass,
    surfaceTintColor: Colors.transparent,
    shadowColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: MistPalette.darkGlassBorder),
    ),
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: const Color(0xFF1A1F2C),
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
  navigationRailTheme: const NavigationRailThemeData(
    backgroundColor: MistPalette.darkRailGlass,
    elevation: 0,
  ),
  navigationBarTheme: const NavigationBarThemeData(
    backgroundColor: MistPalette.darkRailGlass,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
  ),
  tabBarTheme: const TabBarThemeData(
    dividerColor: MistPalette.darkHairline,
  ),
);

TextTheme _buildTextTheme(Brightness brightness) {
  const baseTheme = TextTheme(
    bodyLarge: TextStyle(),
    bodyMedium: TextStyle(),
    bodySmall: TextStyle(),
    labelLarge: TextStyle(),
    labelMedium: TextStyle(),
    labelSmall: TextStyle(),
    titleLarge: TextStyle(),
    titleMedium: TextStyle(),
    titleSmall: TextStyle(),
  );
  if (kIsWeb) {
    return _applyFontFallback(baseTheme, _webChineseFontFallback);
  }
  return baseTheme.apply(fontFamily: 'LatoLato').useSystemChineseFont(
        brightness,
      );
}

TextTheme _applyFontFallback(TextTheme textTheme, List<String> fallback) {
  return textTheme.copyWith(
    bodyLarge: _applyTextStyleFallback(textTheme.bodyLarge, fallback),
    bodyMedium: _applyTextStyleFallback(textTheme.bodyMedium, fallback),
    bodySmall: _applyTextStyleFallback(textTheme.bodySmall, fallback),
    labelLarge: _applyTextStyleFallback(textTheme.labelLarge, fallback),
    labelMedium: _applyTextStyleFallback(textTheme.labelMedium, fallback),
    labelSmall: _applyTextStyleFallback(textTheme.labelSmall, fallback),
    titleLarge: _applyTextStyleFallback(textTheme.titleLarge, fallback),
    titleMedium: _applyTextStyleFallback(textTheme.titleMedium, fallback),
    titleSmall: _applyTextStyleFallback(textTheme.titleSmall, fallback),
  );
}

TextStyle? _applyTextStyleFallback(TextStyle? style, List<String> fallback) {
  return style?.copyWith(fontFamilyFallback: fallback);
}
