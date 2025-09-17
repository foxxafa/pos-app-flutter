import 'package:flutter/material.dart';
import 'package:pos_app/controllers/recentactivity_controller.dart';
import 'package:pos_app/providers/cartcustomer_provider.dart';
import 'package:pos_app/views/expandabletext_widget.dart';
import 'package:pos_app/views/refundlist2_view.dart';
import 'package:pos_app/views/transaction_view.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

class CollectionActivity extends StatefulWidget {
  const CollectionActivity({Key? key}) : super(key: key);

  @override
  State<CollectionActivity> createState() => _CollectionActivityState();
}

class _CollectionActivityState extends State<CollectionActivity> {
  List<String> _refundActivities = [];

  @override
  void initState() {
    super.initState();
    _loadRefundActivities();
  }

  Future<void> _loadRefundActivities() async {
    final allActivities = await RecentActivityController.loadActivities();
    final customer = Provider.of<SalesCustomerProvider>(context, listen: false).selectedCustomer;
    final customerCode = customer?.kod;

    if (customerCode?.isEmpty ?? true) {
      setState(() {
        _refundActivities = [];
      });
      return;
    }

    final filtered = allActivities.where((activity) {
      return activity.contains("Collect") && activity.contains("$customerCode");
    }).toList();

    setState(() {
      _refundActivities = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Collections")),
      body: Padding(
        padding: EdgeInsets.all(3.h),
        child: Column(
          children: [
            Expanded(
              child: _refundActivities.isEmpty
                  ? Center(child: Text("No collection for this customer.", style: TextStyle(fontSize: 18.sp)))
                  : ListView.separated(
                      itemCount: _refundActivities.length,
                      separatorBuilder: (_, __) => Divider(height: 2.h),
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: const Icon(Icons.history),
                          title: ExpandableText(text: _refundActivities[index]),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    floatingActionButton: SizedBox(
  width: 20.w, // Genişlik
  height: 20.w, // Yükseklik
  child: FloatingActionButton(
    onPressed: () {
      Navigator.push(context, MaterialPageRoute(builder: (_) => TransactionPage()));
    },
    backgroundColor: Colors.blue,
    shape: RoundedRectangleBorder( // İsteğe bağlı: köşe yumuşatma
      borderRadius: BorderRadius.circular(100),
    ),
    child: Icon(
      Icons.add,
      size: 10.w, // İkon büyüklüğü
    ),
  ),
),

    );
  }
}
