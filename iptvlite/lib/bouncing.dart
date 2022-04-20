import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

//Bouncing For Bottom FAB
class Bouncing extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;

  Bouncing({required this.child, required this.onPressed})
      : assert(child != null);

  @override
  _BouncingState createState() => _BouncingState();
}

class _BouncingState extends State<Bouncing>
    with SingleTickerProviderStateMixin {
  late double _scale;
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 50),
      lowerBound: 0.0,
      upperBound: 0.1,
    );
    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _scale = 1 - _controller.value;
    var _scale2 = 1.1 + _controller.value;
    return Listener(
      onPointerHover: (PointerHoverEvent event) {
        _controller.reverse();
      },
      onPointerDown: (PointerDownEvent event) {
        if (widget.onPressed != null) {
          _controller.forward();
        }
      },
      onPointerUp: (PointerUpEvent event) {
        if (widget.onPressed != null) {
          _controller.reverse();
          widget.onPressed();
        }
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.scale(
            scale: _scale,
            child: Container(
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 183, 147, 255),
                  borderRadius: BorderRadius.all(Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: Offset(1, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(30.0),
                )),
          ),
          Transform.scale(
            scale: _scale2,
            child: Container(
              child: widget.child,
            ),
          )
        ],
      ),
    );
  }
}
