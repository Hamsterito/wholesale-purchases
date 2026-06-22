import 'package:flutter/material.dart';

/// AnimationController для bottom sheet: 220 мс открытие, 180 мс закрытие.
/// Сам диспозится после закрытия - короткая, резкая, без рывков.
AnimationController smoothBottomSheetController(BuildContext context) {
  final ac = BottomSheet.createAnimationController(Navigator.of(context));
  ac.duration = const Duration(milliseconds: 220);
  ac.reverseDuration = const Duration(milliseconds: 180);
  ac.addStatusListener((status) {
    if (status == AnimationStatus.dismissed) {
      Future.delayed(const Duration(milliseconds: 50), () => ac.dispose());
    }
  });
  return ac;
}
