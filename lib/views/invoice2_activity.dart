import 'dart:math';

import 'package:flutter/material.dart';
import 'package:pos_app/controllers/refundlist_controller.dart';
import 'package:pos_app/models/refundlist_model.dart';
import 'package:pos_app/providers/cartcustomer_provider.dart';
import 'package:pos_app/providers/orderinfo_provider.dart';
import 'package:pos_app/views/cart_view.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';

class Invoice2Activity extends StatefulWidget {
  const Invoice2Activity({Key? key}) : super(key: key);

  @override
  State<Invoice2Activity> createState() => _Invoice2ActivityState();
}

class _Invoice2ActivityState extends State<Invoice2Activity> {
  String orderNo = "123456";
  String comment = "";
  String? selectedPaymentMethod;
  DateTime selectedPaymentDate = DateTime.now();
  DateTime selectedDeliveryDate = DateTime.now();
  List<String> _refundProductNames=[];
  List<Refund> refunds = [];


  final List<String> paymentMethods = [
    "Cash on Delivery",
    "Cheque",
    "Paid",
    "Balance",
    "Partial",
    "Bank",
    "No Payment",
  ];

  Future<void> _selectPaymentDate(BuildContext context) async {
      final orderInfoProvider = Provider.of<OrderInfoProvider>(context, listen: false);

    final picked = await showDatePicker(
      context: context,
      initialDate: selectedPaymentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => selectedPaymentDate = picked);
String formattedDate = DateFormat('dd.MM.yyyy').format(selectedPaymentDate);
orderInfoProvider.paymentDate=formattedDate;
    }
  }

   _loadRefunds(String cariKod) async {
    
    RefundListController refundListController = RefundListController();
    refunds = await refundListController.fetchRefunds(cariKod);

    // refund urunAdi'larını sayfa içinde al
      _refundProductNames =
          refunds
              .map((r) => r.urunAdi)
              .toSet()
              .toList(); // Tekilleştir
print("bunlarrr $_refundProductNames");
  }
  
  Future<void> _selectDeliveryDate(BuildContext context) async {      final orderInfoProvider = Provider.of<OrderInfoProvider>(context, listen: false);

    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDeliveryDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => selectedDeliveryDate = picked);
      String formattedDate = DateFormat('dd.MM.yyyy').format(selectedDeliveryDate);
  orderInfoProvider.deliveryDate=formattedDate;
    }
  }

  void _showPaymentBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 5.w,
            right: 5.w,
            top: 3.h,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Select Payment Method", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 2.h),
              ...paymentMethods.map((method) {
                return RadioListTile<String>(
                  title: Text(method, style: TextStyle(fontSize: 16.sp)),
                  value: method,
                  groupValue: selectedPaymentMethod,
                  onChanged: (value) {
                          final orderInfoProvider = Provider.of<OrderInfoProvider>(context, listen: false);
                          orderInfoProvider.paymentType=value??"No Payment";
                    setState(() => selectedPaymentMethod = value);
                    Navigator.pop(context);
                  },
                );
              }),
              SizedBox(height: 2.h),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {    
    final customer =
        Provider.of<SalesCustomerProvider>(context).selectedCustomer;
    final dateFormat = DateFormat('dd.MM.yyyy');
                              final now = DateTime.now();
  final orderInfoProvider = Provider.of<OrderInfoProvider>(context, listen: false);
  String orderNo=generateFisNo(now);
    orderInfoProvider.orderNo=orderNo;

    return Scaffold(
      appBar: AppBar(
        title: Text("Order", style: TextStyle(fontSize: 18.sp)),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(5.w),
        child: SingleChildScrollView(
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(5.w),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(3.w),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade400,
                  blurRadius: 4,
                  offset: Offset(2, 2),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Order No", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                SizedBox(height: 1.h),
                Text(orderNo, style: TextStyle(fontSize: 15.sp)),

                SizedBox(height: 2.h),
                Text("Comment", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                SizedBox(height: 1.h),
                TextField(
                  maxLines: 3,
                  onChanged: (val) => comment = val,
 onSubmitted: (value) {
    FocusScope.of(context).unfocus(); // klavyeyi kapatır
  },                  style: TextStyle(fontSize: 14.sp),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "Enter comment...",
                    contentPadding: EdgeInsets.all(3.w),
                  ),
                ),

                SizedBox(height: 2.h),
                Center(
                  child: ElevatedButton(
                    onPressed: _showPaymentBottomSheet,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 2.5.h),
                    ),
                    child: Text("Choose Payment Type", style: TextStyle(fontSize: 16.sp)),
                  ),
                ),
                if (selectedPaymentMethod != null) ...[
                  SizedBox(height: 2.h),
                  Center(
                    child: Text(
                      "Selected Payment: $selectedPaymentMethod",
                      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],Divider(),
SizedBox(height: 2.h),
               Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [Divider(),
    Text("Date", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
    Text(dateFormat.format(selectedPaymentDate), style: TextStyle(fontSize: 18.sp)),
 Divider(), ],
),
SizedBox(height: 1.h),
Center(
  child: ElevatedButton(
    onPressed: () => _selectPaymentDate(context),
    child: Text("Select Date", style: TextStyle(fontSize: 14.sp)),
  ),
),Divider(),


                SizedBox(height: 2.h),
                Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Text("Delivery Date", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
    Text(dateFormat.format(selectedDeliveryDate), style: TextStyle(fontSize: 18.sp)),
  ],
),
SizedBox(height: 1.h),
Center(
  child: ElevatedButton(
    onPressed: () => _selectDeliveryDate(context),
    child: Text("Select Date", style: TextStyle(fontSize: 14.sp)),
  ),
),Divider(),
SizedBox(height: 1.h,),
                Center(
                  child: ElevatedButton(
                    onPressed: () async{
                     await _loadRefunds(customer!.kod!);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => CartView(refundProductNames: _refundProductNames, refunds: refunds,)),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 2.5.h),
                      backgroundColor: Colors.white,
                    ),
                    child: Text("Select Products", style: TextStyle(fontSize: 16.sp)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
  String generateFisNo(DateTime now) {
    final yy = now.year % 100; // Yılın son iki hanesi
    final mm = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');

    final random = Random();
    final randomNumber = random
        .nextInt(1000)
        .toString()
        .padLeft(4, '0'); // 0000 - 9999

    return "MO$yy$mm$dd$randomNumber";
  }