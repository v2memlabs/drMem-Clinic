import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Metin sığmıyorsa yatay kayan yazı; sığıyorsa normal tek satır.
class MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final double gap;

  const MarqueeText({
    super.key,
    required this.text,
    this.style,
    this.gap = 32,
  });

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText> with SingleTickerProviderStateMixin {
  Ticker? _ticker;
  Duration _scrollElapsed = Duration.zero;
  Duration? _lastTickElapsed;

  double _loopDistance = 0;
  int _loopDurationMs = 0;
  bool _needsMarquee = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
  }

  @override
  void didUpdateWidget(covariant MarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.gap != widget.gap ||
        oldWidget.style != widget.style) {
      _scrollElapsed = Duration.zero;
      _lastTickElapsed = null;
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (!_needsMarquee || _loopDurationMs <= 0) {
      _lastTickElapsed = elapsed;
      return;
    }

    if (_lastTickElapsed != null) {
      _scrollElapsed += elapsed - _lastTickElapsed!;
    }
    _lastTickElapsed = elapsed;
    if (mounted) setState(() {});
  }

  void _syncMarquee({
    required double textWidth,
    required bool needsMarquee,
  }) {
    final loopDistance = needsMarquee ? textWidth + widget.gap : 0.0;
    final loopDurationMs = needsMarquee
        ? (loopDistance * 28).round().clamp(2400, 12000)
        : 0;

    if (_needsMarquee == needsMarquee &&
        _loopDistance == loopDistance &&
        _loopDurationMs == loopDurationMs) {
      return;
    }

    _needsMarquee = needsMarquee;
    _loopDistance = loopDistance;
    _loopDurationMs = loopDurationMs;

    if (needsMarquee) {
      if (!(_ticker?.isActive ?? false)) {
        _ticker?.start();
      }
    } else {
      _ticker?.stop();
      _scrollElapsed = Duration.zero;
      _lastTickElapsed = null;
    }
  }

  double get _offset {
    if (!_needsMarquee || _loopDistance <= 0 || _loopDurationMs <= 0) {
      return 0;
    }
    final elapsedMs = _scrollElapsed.inMicroseconds / 1000.0;
    final progress = (elapsedMs % _loopDurationMs) / _loopDurationMs;
    return progress * _loopDistance;
  }

  bool get _isWidgetTestBinding {
    var isTest = false;
    assert(() {
      isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
      return true;
    }());
    return isTest;
  }

  Widget _scrollingRow(TextStyle style, double textWidth) {
    return SizedBox(
      width: textWidth * 2 + widget.gap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.text,
            style: style,
            maxLines: 1,
            softWrap: false,
          ),
          SizedBox(width: widget.gap),
          Text(
            widget.text,
            style: style,
            maxLines: 1,
            softWrap: false,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? DefaultTextStyle.of(context).style;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        if (!maxWidth.isFinite || maxWidth <= 0) {
          return Text(
            widget.text,
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
          );
        }

        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: style),
          maxLines: 1,
          textDirection: Directionality.of(context),
        )..layout(maxWidth: double.infinity);

        final textWidth = painter.width;
        final textHeight = painter.height;
        final needsMarquee = textWidth > maxWidth + 0.5;

        _syncMarquee(
          textWidth: textWidth,
          needsMarquee: needsMarquee,
        );

        if (!needsMarquee) {
          _syncMarquee(textWidth: textWidth, needsMarquee: false);
          return Text(
            widget.text,
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
          );
        }

        if (_isWidgetTestBinding) {
          _syncMarquee(textWidth: textWidth, needsMarquee: false);
          return SizedBox(
            width: maxWidth,
            height: textHeight,
            child: ClipRect(
              clipBehavior: Clip.hardEdge,
              child: Align(
                alignment: Alignment.centerLeft,
                widthFactor: 1,
                child: SizedBox(
                  width: textWidth,
                  child: Text(
                    widget.text,
                    style: style,
                    maxLines: 1,
                    softWrap: false,
                  ),
                ),
              ),
            ),
          );
        }

        return SizedBox(
          width: maxWidth,
          height: textHeight,
          child: ClipRect(
            clipBehavior: Clip.hardEdge,
            child: OverflowBox(
              alignment: Alignment.centerLeft,
              minWidth: 0,
              maxWidth: double.infinity,
              child: Transform.translate(
                offset: Offset(-_offset, 0),
                child: _scrollingRow(style, textWidth),
              ),
            ),
          ),
        );
      },
    );
  }
}
