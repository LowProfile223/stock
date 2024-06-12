import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:pstock/main.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('th');
  runApp(MyApp());
}

class SalesReportPage extends StatefulWidget {
  @override
  _SalesReportPageState createState() => _SalesReportPageState();
}

class _SalesReportPageState extends State<SalesReportPage> {
  int _selectedMonth = DateTime.now().month;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;

  Map<int, List<BillData>> _monthlyBillsCache = {};

  @override
  void initState() {
    super.initState();
    _auth.authStateChanges().listen((user) {
      setState(() {
        _currentUser = user;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    initializeDateFormatting('th');
    return Scaffold(
      appBar: AppBar(
        title: Text('ยอดขาย'),
        actions: [
          _buildMonthDropdown(),
        ],
      ),
      body: _currentUser == null
          ? Center(child: Text('กรุณาเข้าสู่ระบบ'))
          : Center(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('bills')
                    .where('userId', isEqualTo: _currentUser!.uid)
                    .snapshots(),
                builder: (BuildContext context,
                    AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasError) {
                    return Text('เกิดข้อผิดพลาด: ${snapshot.error}');
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }

                  List<BillData> bills =
                      snapshot.data!.docs.map((DocumentSnapshot document) {
                    Map<String, dynamic> data =
                        document.data() as Map<String, dynamic>;
                    return BillData(
                      cart: data['cart'] ?? [],
                      total: data['total'] ?? 0.0,
                      billTime: (data['billTime'] as Timestamp).toDate(),
                      paymentMethod: data['paymentMethod'] ?? 'Unknown',
                    );
                  }).toList();

                  if (!_monthlyBillsCache.containsKey(_selectedMonth)) {
                    _monthlyBillsCache[_selectedMonth] = bills;
                  }

                  return _buildSalesReport(_monthlyBillsCache[_selectedMonth]!);
                },
              ),
            ),
    );
  }

  Widget _buildMonthDropdown() {
    return DropdownButton<int>(
      value: _selectedMonth,
      style: TextStyle(color: Colors.black),
      items: List.generate(12, (index) {
        return DropdownMenuItem<int>(
          value: index + 1,
          child: Text(
            DateFormat('MMMM', 'th').format(DateTime(2000, index + 1)),
          ),
        );
      }),
      onChanged: (selectedMonth) {
        _updateData(selectedMonth!);
      },
    );
  }

  void _updateData(int selectedMonth) {
    setState(() {
      _selectedMonth = selectedMonth;
    });
  }

  Widget _buildSalesReport(List<BillData> bills) {
    DateTime now = DateTime.now();
    int currentMonth = _selectedMonth;
    int currentYear = now.year;
    List<BillData> currentMonthBills = bills
        .where((bill) =>
            bill.billTime.month == currentMonth &&
            bill.billTime.year == currentYear)
        .toList();

    currentMonthBills.sort((a, b) => a.billTime.compareTo(b.billTime));

    double totalSales = currentMonthBills.fold(
        0.0, (previousValue, element) => previousValue + element.total);

    Map<String, int> paymentMethodPercentages = {};
    int totalBills = currentMonthBills.length;
    currentMonthBills.forEach((bill) {
      paymentMethodPercentages[bill.paymentMethod] =
          (paymentMethodPercentages[bill.paymentMethod] ?? 0) + 1;
    });
    paymentMethodPercentages.forEach((key, value) {
      paymentMethodPercentages[key] = (value / totalBills * 100).toInt();
    });

    Map<String, double> dailySales = {};
    currentMonthBills.forEach((bill) {
      String dayKey = DateFormat.yMMMMd('th').format(DateTime(
        bill.billTime.year + 543, // เพิ่ม 543 เพื่อแปลงปีไทย
        bill.billTime.month,
        bill.billTime.day,
      ));
      dailySales[dayKey] = (dailySales[dayKey] ?? 0.0) + bill.total;
    });

    var sortedDailySalesKeys = dailySales.keys.toList()
      ..sort((a, b) {
        var dateA = DateFormat.yMMMMd('th').parse(a);
        var dateB = DateFormat.yMMMMd('th').parse(b);
        return dateA.compareTo(dateB);
      });

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'ยอดขายเดือนนี้: $totalSales',
          style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 20),
        Text(
          'ยอดขายรายวัน:',
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange),
          textAlign: TextAlign.center,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: sortedDailySalesKeys.map((key) {
            return Text(
              '$key: ${dailySales[key]}',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            );
          }).toList(),
        ),
        SizedBox(height: 20),
        Text(
          'วิธีการชำระเงิน:',
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
          textAlign: TextAlign.center,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: paymentMethodPercentages.entries.map((entry) {
            return Text(
              '${entry.key}: ${entry.value}%',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            );
          }).toList(),
        ),
      ],
    );
  }
}

class BillData {
  final List<dynamic> cart;
  final double total;
  final DateTime billTime;
  final String paymentMethod;

  BillData({
    required this.cart,
    required this.total,
    required this.billTime,
    required this.paymentMethod,
  });
}
