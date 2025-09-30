import 'package:flutter/material.dart';
import 'package:pos_app/features/reports/presentation/recentactivity_controller.dart';
import 'package:sizer/sizer.dart';

class RecentActivityView extends StatefulWidget {
  const RecentActivityView({Key? key}) : super(key: key);

  @override
  State<RecentActivityView> createState() => _RecentActivityViewState();
}

class _RecentActivityViewState extends State<RecentActivityView> {
  List<String> _activities = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final activities = await RecentActivityController.loadActivities();
    setState(() => _activities = activities);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Recent Activities")),
      body: Padding(
        padding: EdgeInsets.all(3.h),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Activity List", style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold)),
              ],
            ),
            Expanded(
              child: _activities.isEmpty
                  ? Center(child: Text("No activities yet.", style: TextStyle(fontSize: 20.sp)))
                  : ListView.separated(
                      itemCount: _activities.length,
                      separatorBuilder: (_, __) => Divider(height: 2.h),
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: const Icon(Icons.history),
                          title: ExpandableText(text: _activities[index]),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

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
    final lines = widget.text.split('\n');
    final displayLines = _expanded ? lines : lines.take(3).toList();

    return GestureDetector(
      onTap: () {
  setState(() => _expanded = !_expanded);  print(displayLines); // Ekrana yazdır

},

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...displayLines.map((line) => Text(
                line,
                style: TextStyle(fontSize: 18.sp),
              )),
          if (lines.length > 3)
            Text(
              _expanded ? "show less" : "...show more",
              style: TextStyle(fontSize: 18.sp, color: Colors.blue),
            ),
        ],
      ),
    );
  }
}
