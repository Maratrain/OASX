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
  static const lightGlowViolet = Color(0x4D7C5BFA);
  static const lightGlowBlue = Color(0x523898FF);
  static const lightGlowGreen = Color(0x2E12B26B);
  static const darkGlowViolet = Color(0x4D7C5BFA);
  static const darkGlowBlue = Color(0x453898FF);
  static const darkGlowGreen = Color(0x2E18B26B);

  /// 分隔线。
  static const lightHairline = Color(0x171E283A);
  static const darkHairline = Color(0x1FFFFFFF);

  /// 设计稿 B「晨雾玻璃」的功能色。
  static const accent = Color(0xFF5B7CFA);
  static const accent2 = Color(0xFF7C5BFA);
  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, accent2],
  );
  static const runGreen = Color(0xFF18B26B);
  static const runGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2BD183), runGreen],
  );
  static const warnOrange = Color(0xFFE8930C);
  static const stopGrey = Color(0xFF9AA3B8);
}

/// 晨雾渐变页面背景：雾蓝→淡紫底色 + 角部柔色光斑，亮暗模式各自取色。
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
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? const [MistPalette.darkBase, Color(0xFF161A28)]
                    : const [MistPalette.lightBase, Color(0xFFF6F4FF)],
              ),
            ),
          ),
          _buildGlow(
            color: isDark
                ? MistPalette.darkGlowViolet
                : MistPalette.lightGlowViolet,
            center: const Alignment(0.82, -1.05),
            radius: 0.62,
          ),
          _buildGlow(
            color: isDark
                ? MistPalette.darkGlowBlue
                : MistPalette.lightGlowBlue,
            center: const Alignment(-0.95, 1.0),
            radius: 0.66,
          ),
          _buildGlow(
            color: isDark
                ? MistPalette.darkGlowGreen
                : MistPalette.lightGlowGreen,
            center: const Alignment(0.35, 1.18),
            radius: 0.52,
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildGlow({
    required Color color,
    required Alignment center,
    required double radius,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: center,
          radius: radius,
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}

/// 晨雾玻璃共享装饰：玻璃面板 / 胶囊按钮 / 渐变胶囊。
abstract final class MistDecor {
  /// 圆角玻璃面板（卡片内容面）。
  static BoxDecoration glass({double radius = 16, bool isDark = false}) {
    return BoxDecoration(
      color: isDark ? MistPalette.darkGlass : MistPalette.lightGlass,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: isDark
            ? MistPalette.darkGlassBorder
            : MistPalette.lightGlassBorder,
      ),
      boxShadow: isDark
          ? null
          : const [
              BoxShadow(
                color: Color(0x213C5064),
                blurRadius: 34,
                offset: Offset(0, 10),
              ),
            ],
    );
  }

  /// 靛紫渐变强调胶囊（导航选中 / 主按钮）。
  static BoxDecoration accentCapsule({double radius = 999}) {
    return BoxDecoration(
      gradient: MistPalette.accentGradient,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: const [
        BoxShadow(
          color: Color(0x6B5B7CFA),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
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
    elevation: 3,
    margin: EdgeInsets.zero,
    color: MistPalette.lightGlass,
    surfaceTintColor: Colors.transparent,
    shadowColor: const Color(0x3C3C5064),
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
    backgroundColor: Colors.transparent,
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
