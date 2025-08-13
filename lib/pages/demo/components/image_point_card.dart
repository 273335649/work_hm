
import 'package:flutter/material.dart';
import './circle_number_widget.dart';

class ImagePointCard extends StatefulWidget {
  final String imagePath;
  final double imageWidth;
  final List<Map<String, dynamic>> fetchPoints;
  final int activeIndex;

  const ImagePointCard({
    Key? key,
    required this.imagePath,
    this.imageWidth = 300,
    this.activeIndex = 0,
    required this.fetchPoints,
  }) : super(key: key);

  @override
  _ImagePointCardState createState() => _ImagePointCardState();
}

class _ImagePointCardState extends State<ImagePointCard> {
  static const double _kCircleSize = 36.0;
  double? imageAspectRatio;
  List<Map<String, dynamic>> points = [];

  @override
  void initState() {
    super.initState();
    _convertFetchPointsToPoints(widget.fetchPoints);
  }

  @override
  void didUpdateWidget(covariant ImagePointCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeIndex != oldWidget.activeIndex) {
      _convertFetchPointsToPoints(widget.fetchPoints);
    }
  }

  void _convertFetchPointsToPoints(List<Map<String, dynamic>> data) {
    points = data.asMap().entries.map((entry) {
      return {
        'pos': Offset(entry.value['x']!.toDouble(), entry.value['y']!.toDouble()),
        'active': entry.key == widget.activeIndex, // Assuming initial active index is 0 or handled elsewhere
      };
    }).toList();
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadImageAspectRatio();
  }

  Future<void> _loadImageAspectRatio() async {
    final image = AssetImage(widget.imagePath);
    final config = createLocalImageConfiguration(context);
    final ImageStream stream = image.resolve(config);
    stream.addListener(
        ImageStreamListener((ImageInfo info, bool synchronousCall) {
      if (mounted) {
        setState(() {
          imageAspectRatio = info.image.width / info.image.height;
        });
      }
    }));
  }

  @override
  Widget build(BuildContext context) {
    if (imageAspectRatio == null) {
      return Center(child: CircularProgressIndicator());
    }
    print(widget.imagePath);
    return LayoutBuilder(builder: (context, constraints) {
      // 计算图片实际渲染高度
      return Stack(
        children: [
          // 使用 AspectRatio 确保图片按比例渲染
          SizedBox(
            width: widget.imageWidth,
            child: AspectRatio(
              aspectRatio: imageAspectRatio!,
              child: Image(
                image: AssetImage(widget.imagePath),
                fit: BoxFit.cover,
              ),
            ),
          ),
          ...points.asMap().entries.map((entry) {
            int index = entry.key;
            Map<String, dynamic> pointData = entry.value;
            Offset point = pointData['pos'];
            bool isActive = pointData['active'];
            return Positioned(
              left: (point.dx / 100 * widget.imageWidth) - (_kCircleSize / 2),
              top: (point.dy / 100 * widget.imageWidth / imageAspectRatio!) - (_kCircleSize / 2),
              child: CircleNumberWidget(
                size: _kCircleSize,
                number: index + 1,
                isBlinking: isActive,
              ),
            );
          }).toList(),
        ],
      );
    });
  }
}
