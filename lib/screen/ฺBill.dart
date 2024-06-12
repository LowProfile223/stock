import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/date_symbol_data_local.dart'; // Import for Thai date format
import 'package:intl/intl.dart'; // Import intl package
import 'package:pstock/main.dart';
import 'package:pstock/screen/welcomescreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('th');
  runApp(MyApp());
}

class BillPage extends StatelessWidget {
  final List<Map<String, dynamic>> cart;
  final double total;
  final String billNumber;
  final DateTime billTime;
  final String paymentMethod;

  const BillPage({
    Key? key,
    required this.cart,
    required this.total,
    required this.billNumber,
    required this.billTime,
    required this.paymentMethod,
  }) : super(key: key);

  Future<void> saveBillToFirestore(
    List<Map<String, dynamic>> cart,
    double total,
    String billNumber,
    DateTime billTime,
    String paymentMethod,
    String userId,
  ) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      List<Map<String, dynamic>> items = [];
      for (var item in cart) {
        items.add({
          'name': item['nameitem'],
          'price': item['price'],
          'quantity': item['total'],
        });
      }

      await FirebaseFirestore.instance.collection('bills').add({
        'userId': user!.uid,
        'items': items,
        'total': total,
        'billNumber': billNumber,
        'billTime': billTime,
        'paymentMethod': paymentMethod,
      });

      for (var item in cart) {
        await FirebaseFirestore.instance.collection('products').add({
          'name': item['nameitem'],
          'price': item['price'],
          'quantity': item['total'],
          'billNumber': billNumber,
          'billTime': billTime,
          'userId': userId,
        });
      }

      Fluttertoast.showToast(
        msg: 'บันทึกข้อมูลบิลเรียบร้อย',
        gravity: ToastGravity.CENTER,
      );
    } catch (e) {
      print('Error saving bill to Firestore: $e');

      Fluttertoast.showToast(
        msg: 'เกิดข้อผิดพลาดในการบันทึกข้อมูลบิล',
        gravity: ToastGravity.CENTER,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    initializeDateFormatting('th');

    User? user = FirebaseAuth.instance.currentUser;

    Future<Map<String, dynamic>> getStoreInformation() async {
      try {
        var snapshot = await FirebaseFirestore.instance
            .collection('profiles')
            .doc(user!.uid)
            .get();

        if (snapshot.exists) {
          return {
            'storeName': snapshot['owner_name'],
            'phoneNumber': snapshot['phone'],
          };
        } else {
          return {'storeName': 'ไม่มีชื่อ', 'phoneNumber': 'ไม่มีเบอร์'};
        }
      } catch (e) {
        print('Error fetching store information: $e');
        return {'storeName': 'ไม่มีชื่อ', 'phoneNumber': 'ไม่มีเบอร์'};
      }
    }

    return FutureBuilder(
      future: getStoreInformation(),
      builder: (context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Center(child: Text('Error loading store information.'));
        }

        final storeData = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: Text('ใบเสร็จ'),
            automaticallyImplyLeading: false,
          ),
          body: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 10),
                Text(
                  'ร้าน ${storeData['storeName']}',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  'เบอร์โทร: ${storeData['phoneNumber']}',
                  style: TextStyle(fontSize: 15),
                ),
                SizedBox(height: 20),
                Text(
                  'รายการสินค้า',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Text(
                  'เลขบิล: $billNumber',
                  style: TextStyle(fontSize: 15),
                ),
                Text(
                  'วันเวลา: ${DateFormat.yMMMMd('th').add_jms().format(DateTime(DateTime.now().year + 543, DateTime.now().month, DateTime.now().day, DateTime.now().hour, DateTime.now().minute, DateTime.now().second))}',
                  style: TextStyle(fontSize: 15),
                ),
                SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: cart.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(
                          cart[index]['nameitem'],
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          'ราคา: ฿${cart[index]['price']} จำนวน: ${cart[index]['total']}',
                          style: TextStyle(
                            fontSize: 18,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Divider(),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'รวมทั้งสิ้น: ฿$total',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 10),
                    Text(
                      paymentMethod,
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      print('Payment Method: $paymentMethod');
                      saveBillToFirestore(
                        cart,
                        total,
                        billNumber,
                        DateTime.now(),
                        paymentMethod,
                        user!.uid,
                      ).then((_) {
                        Fluttertoast.showToast(
                          msg: 'ชำระเงินเสร็จสิ้น',
                          gravity: ToastGravity.CENTER,
                        );

                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (context) => WelcomeScreen()),
                          (route) => false,
                        );
                      }).catchError((error) {});
                    },
                    child: Text('เสร็จสิ้น'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
