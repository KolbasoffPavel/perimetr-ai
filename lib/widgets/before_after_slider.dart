import 'package:flutter/material.dart';

/// Интерактивный слайдер «до/после»: перетаскиванием разделителя можно
/// сравнить исходное фото и сгенерированную ИИ визуализацию ремонта.
class BeforeAfterSlider extends StatefulWidget {
final ImageProvider beforeImage;
final ImageProvider afterImage;
final double aspectRatio;
const BeforeAfterSlider({
super.key,
required this.beforeImage,
required this.afterImage,
this.aspectRatio = 4 / 3,
});

@override
State<BeforeAfterSlider> createState() => _BeforeAfterSliderState();
}

class _BeforeAfterSliderState extends State<BeforeAfterSlider> {
double _position = 0.5;

@override
Widget build(BuildContext context) {
return ClipRRect(
borderRadius: BorderRadius.circular(10),
child: AspectRatio(
aspectRatio: widget.aspectRatio,
child: LayoutBuilder(
builder: (context, constraints) {
final width = constraints.maxWidth;
final height = constraints.maxHeight;
return GestureDetector(
onHorizontalDragUpdate: (d) {
setState(() {
_position = (_position + d.delta.dx / width).clamp(0.0, 1.0);
});
},
onTapDown: (d) {
setState(() {
_position = (d.localPosition.dx / width).clamp(0.0, 1.0);
});
},
child: Stack(
fit: StackFit.expand,
children: [
Image(image: widget.afterImage, fit: BoxFit.cover),
ClipRect(
clipper: _SliderClipper(_position),
child: Image(image: widget.beforeImage, fit: BoxFit.cover),
),
Positioned(
left: width * _position - 1,
top: 0,
bottom: 0,
child: Container(width: 2, color: Colors.white),
),
Positioned(
left: (width * _position - 16).clamp(0.0, width - 32),
top: height / 2 - 16,
child: Container(
width: 32,
height: 32,
decoration: const BoxDecoration(
color: Colors.white,
shape: BoxShape.circle,
boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 6)],
),
child: const Icon(Icons.drag_indicator, size: 18, color: Colors.black54),
),
),
const Positioned(left: 8, top: 8, child: _Label('До')),
const Positioned(right: 8, top: 8, child: _Label('После')),
],
),
);
},
),
),
);
}
}

class _Label extends StatelessWidget {
final String text;
const _Label(this.text);
@override
Widget build(BuildContext context) {
return Container(
padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
);
}
}

class _SliderClipper extends CustomClipper<Rect> {
final double position;
_SliderClipper(this.position);
@override
Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width * position, size.height);
@override
bool shouldReclip(covariant _SliderClipper oldClipper) => oldClipper.position != position;
}
