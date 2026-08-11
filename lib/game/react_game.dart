import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../core/theme/react_colors.dart';

class ReactGame extends FlameGame {
  @override
  Color backgroundColor() => ReactColors.background;
}
