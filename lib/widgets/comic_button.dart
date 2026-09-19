import 'package:flutter/material.dart';

import '../theme/comic_theme.dart';

/// A comic-panel button: thick ink border, flat saturated fill, and a
/// doubled hard-edged shadow (spec §6 — "offset drop shadow", not a
/// material-style blur). Pressing the button collapses onto its near
/// shadow layer, like the panel being pushed flush into the page.
///
/// [background] optionally replaces the flat [fillColor] fill with custom
/// art (e.g. the hard-mode button's painted comic flames) drawn behind the
/// label, inset just enough to leave the ink border ring visible on top.
class ComicButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final Color fillColor;
  final Widget? background;
  final Color labelColor;
  final List<Shadow>? labelShadows;

  const ComicButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.fillColor = ComicColors.sunflowerYellow,
    this.background,
    this.labelColor = ComicColors.ink,
    this.labelShadows,
  });

  @override
  State<ComicButton> createState() => _ComicButtonState();
}

class _ComicButtonState extends State<ComicButton> {
  static const _nearOffset = 5.0;
  static const _farOffset = 10.0;

  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(
          _pressed ? _nearOffset : 0,
          _pressed ? _nearOffset : 0,
          0,
        ),
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: widget.fillColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ComicColors.ink, width: 3),
          boxShadow: _pressed
              ? const []
              : comicHardShadow(nearOffset: _nearOffset, farOffset: _farOffset),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Stack(
            children: [
              Positioned.fill(
                child: widget.background ?? Container(color: widget.fillColor),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 29,
                    vertical: 13,
                  ),
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontFamily: kComicFontFamily,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: widget.labelColor,
                      shadows: widget.labelShadows,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
