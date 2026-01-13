import 'dart:ui';
import 'package:flutter/material.dart';

class GlassMorphism extends StatelessWidget {
  final double blur;
  final double opacity;
  final Widget child;
  final BorderRadius? borderRadius;

  const GlassMorphism({
    super.key,
    required this.blur,
    required this.opacity,
    required this.child,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(20);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: opacity),
            borderRadius: radius,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

// 帶紫色發光效果的 Glassmorphism Widget
class GlassWithGlow extends StatefulWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;
  final Color glowColor;
  final double glowSpread;
  final double glowBlur;
  final double? glowAlpha; // 新增：可自定義 alpha
  final double innerGlowIntensity; // 內發光強度（0.0 - 1.0）
  final VoidCallback? onTap; // 新增：點擊回調

  const GlassWithGlow({
    super.key,
    required this.child,
    this.blur = 10,
    this.opacity = 0.1,
    this.borderRadius,
    this.padding,
    this.glowColor = const Color(0xFF9C27B0),
    this.glowSpread = 2,
    this.glowBlur = 15,
    this.glowAlpha, // 如果為 null 則使用預設值
    this.innerGlowIntensity = 0.25, // 預設為原本的四分之一
    this.onTap, // 可選的點擊回調
  });

  @override
  State<GlassWithGlow> createState() => _GlassWithGlowState();
}

class _GlassWithGlowState extends State<GlassWithGlow> with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _glowAnimation;
  Animation<double>? _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 80),
      vsync: this,
    );
    _glowAnimation = CurvedAnimation(
      parent: _controller!,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.985,
    ).animate(CurvedAnimation(
      parent: _controller!,
      curve: Curves.easeInOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    ));
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(20);
    // 如果 glowBlur 或 glowSpread 為 0，則不顯示發光效果
    final shouldShowGlow = widget.glowBlur > 0 || widget.glowSpread > 0;
    final effectiveAlpha = widget.glowAlpha ?? 0.3;
    
    // 如果 controller 還沒初始化，返回簡單版本
    if (_controller == null || _glowAnimation == null || _scaleAnimation == null) {
      return Container(
        padding: widget.padding,
        decoration: BoxDecoration(
          color: Color(0xFF0D0118).withValues(alpha: 0.98),
          borderRadius: radius,
          border: Border.all(
            color: widget.glowColor.withValues(alpha: 0.3),
            width: 1.0,
          ),
        ),
        child: widget.child,
      );
    }
    
    return GestureDetector(
      onTapDown: (_) => _controller!.forward(),
      onTapUp: (_) {
        _controller!.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller!.reverse(),
      child: AnimatedBuilder(
        animation: _controller!,
        builder: (context, child) {
          final glowStrength = _glowAnimation!.value;
          final scale = _scaleAnimation!.value;
          
          return Transform.scale(
            scale: scale,
            child: Container(
            decoration: BoxDecoration(
              borderRadius: radius,
              // 外部陰影（原本的發光效果）
              boxShadow: shouldShowGlow ? [
                BoxShadow(
                  color: widget.glowColor.withValues(alpha: effectiveAlpha),
                  spreadRadius: widget.glowSpread,
                  blurRadius: widget.glowBlur,
                  offset: Offset(0, 0),
                ),
              ] : null,
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: Stack(
                children: [
                  // 主要內容容器
                  Container(
                    padding: widget.padding,
                    decoration: BoxDecoration(
                      color: Color(0xFF0D0118).withValues(alpha: 0.98),
                      borderRadius: radius,
                      border: Border.all(
                        color: widget.glowColor.withValues(alpha: 0.3),
                        width: 1.0,
                      ),
                    ),
                    child: widget.child,
                  ),
                  // 內發光層：四個角發光效果
                  if (glowStrength > 0)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Stack(
                          children: [
                            // 左上角發光
                            Positioned(
                              top: 0,
                              left: 0,
                              width: 60,
                              height: 60,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.only(
                                    topLeft: radius.topLeft,
                                  ),
                                  gradient: RadialGradient(
                                    center: Alignment.topLeft,
                                    radius: 1.0,
                                    colors: [
                                      widget.glowColor.withValues(alpha: 0.6 * glowStrength * widget.innerGlowIntensity),
                                      widget.glowColor.withValues(alpha: 0.3 * glowStrength * widget.innerGlowIntensity),
                                      Colors.transparent,
                                    ],
                                    stops: [0.0, 0.5, 1.0],
                                  ),
                                ),
                              ),
                            ),
                            // 右上角發光
                            Positioned(
                              top: 0,
                              right: 0,
                              width: 60,
                              height: 60,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.only(
                                    topRight: radius.topRight,
                                  ),
                                  gradient: RadialGradient(
                                    center: Alignment.topRight,
                                    radius: 1.0,
                                    colors: [
                                      widget.glowColor.withValues(alpha: 0.6 * glowStrength * widget.innerGlowIntensity),
                                      widget.glowColor.withValues(alpha: 0.3 * glowStrength * widget.innerGlowIntensity),
                                      Colors.transparent,
                                    ],
                                    stops: [0.0, 0.5, 1.0],
                                  ),
                                ),
                              ),
                            ),
                            // 左下角發光
                            Positioned(
                              bottom: 0,
                              left: 0,
                              width: 60,
                              height: 60,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.only(
                                    bottomLeft: radius.bottomLeft,
                                  ),
                                  gradient: RadialGradient(
                                    center: Alignment.bottomLeft,
                                    radius: 1.0,
                                    colors: [
                                      widget.glowColor.withValues(alpha: 0.6 * glowStrength * widget.innerGlowIntensity),
                                      widget.glowColor.withValues(alpha: 0.3 * glowStrength * widget.innerGlowIntensity),
                                      Colors.transparent,
                                    ],
                                    stops: [0.0, 0.5, 1.0],
                                  ),
                                ),
                              ),
                            ),
                            // 右下角發光
                            Positioned(
                              bottom: 0,
                              right: 0,
                              width: 60,
                              height: 60,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.only(
                                    bottomRight: radius.bottomRight,
                                  ),
                                  gradient: RadialGradient(
                                    center: Alignment.bottomRight,
                                    radius: 1.0,
                                    colors: [
                                      widget.glowColor.withValues(alpha: 0.6 * glowStrength * widget.innerGlowIntensity),
                                      widget.glowColor.withValues(alpha: 0.3 * glowStrength * widget.innerGlowIntensity),
                                      Colors.transparent,
                                    ],
                                    stops: [0.0, 0.5, 1.0],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ));
        },
      ),
    );
  }
}
