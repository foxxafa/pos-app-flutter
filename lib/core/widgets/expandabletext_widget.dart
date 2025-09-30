import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class ExpandableText extends StatefulWidget {
  final String text;

  const ExpandableText({Key? key, required this.text}) : super(key: key);

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final lines = widget.text
        .split('\n') // 👈 önemli değişiklik
        .map((e) => e.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    final displayLines = _expanded ? lines : lines.take(5).toList();

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...displayLines.map((line) => Text(
                line,
                style: TextStyle(fontSize: 18.sp),
              )),
          if (lines.length > 5)
            Padding(
              padding: EdgeInsets.only(top: 1.h),
              child: Text(
                _expanded ? "▲ show less" : "▼ ...show more",
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
