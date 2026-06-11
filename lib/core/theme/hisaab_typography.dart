import 'package:flutter/material.dart';

@immutable
class HisaabTypography extends ThemeExtension<HisaabTypography> {
  const HisaabTypography({required this.contentFontFamily});

  final String contentFontFamily;

  @override
  HisaabTypography copyWith({String? contentFontFamily}) {
    return HisaabTypography(
      contentFontFamily: contentFontFamily ?? this.contentFontFamily,
    );
  }

  @override
  HisaabTypography lerp(HisaabTypography? other, double t) {
    return t < 0.5 || other == null ? this : other;
  }
}

extension HisaabTypographyContext on BuildContext {
  String get hisaabFontFamily =>
      Theme.of(this).extension<HisaabTypography>()!.contentFontFamily;
}
