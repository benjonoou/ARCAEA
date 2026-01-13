import 'package:flutter/material.dart';

class DraggableWidget extends StatefulWidget {
  final Widget child;
  final Offset initialPosition;
  final Size childSize;

  const DraggableWidget({
    super.key,
    required this.child,
    this.initialPosition = const Offset(50, 100),
    this.childSize = const Size(200, 130),
  });

  @override
  State<DraggableWidget> createState() => _DraggableWidgetState();
}

class _DraggableWidgetState extends State<DraggableWidget>
    with SingleTickerProviderStateMixin {
  late Offset _position;
  Offset _velocity = Offset.zero;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _position = widget.initialPosition;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animationController.addListener(_onAnimationTick);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onAnimationTick() {
    if (!mounted) return;
    setState(() {
      final screenSize = MediaQuery.of(context).size;
      
      // 應用速度到位置
      _position += _velocity * 0.016; // 假設 60fps
      
      // 檢查邊界碰撞並反彈
      double newVelocityX = _velocity.dx;
      double newVelocityY = _velocity.dy;
      
      // 左右邊界
      if (_position.dx <= 0) {
        _position = Offset(0, _position.dy);
        newVelocityX = -_velocity.dx * 0.7; // 反彈並損失30%能量
      } else if (_position.dx >= screenSize.width - widget.childSize.width) {
        _position = Offset(screenSize.width - widget.childSize.width, _position.dy);
        newVelocityX = -_velocity.dx * 0.7;
      }
      
      // 上下邊界
      if (_position.dy <= 0) {
        _position = Offset(_position.dx, 0);
        newVelocityY = -_velocity.dy * 0.7;
      } else if (_position.dy >= screenSize.height - widget.childSize.height) {
        _position = Offset(_position.dx, screenSize.height - widget.childSize.height);
        newVelocityY = -_velocity.dy * 0.7;
      }
      
      _velocity = Offset(newVelocityX, newVelocityY);
      
      // 速度衰減（摩擦力）
      _velocity *= 0.8;
      
      // 如果速度很小就停止動畫
      if (_velocity.distance < 0.1) {
        _animationController.stop();
        _velocity = Offset.zero;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            // 計算新位置
            final newPosition = _position + details.delta;
            final screenSize = MediaQuery.of(context).size;
            
            // 限制在螢幕範圍內
            _position = Offset(
              newPosition.dx.clamp(0.0, screenSize.width - widget.childSize.width),
              newPosition.dy.clamp(0.0, screenSize.height - widget.childSize.height),
            );
            
            // 記錄速度
            _velocity = details.delta;
          });
        },
        onPanEnd: (details) {
          // 使用手勢結束時的速度
          _velocity = details.velocity.pixelsPerSecond * 0.2; // 調整放開後速度比例
          _animationController.repeat();
        },
        child: widget.child,
      ),
    );
  }
}
