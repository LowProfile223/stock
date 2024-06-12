import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pstock/screen/%E0%B8%BABill.dart';

class CashPage extends StatelessWidget {
  final List<Map<String, dynamic>> cart;
  final double total;

  const CashPage({Key? key, required this.cart, required this.total})
      : super(key: key);
  String generateRandomBillNumber() {
    Random random = Random();
    int randomNumber = random.nextInt(90000) + 10000;
    return randomNumber.toString();
  }

  void main() {
    initializeDateFormatting('th');
  }

  void updateProductQuantity(List<Map<String, dynamic>> cart) async {
    String currentUserUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    bool isSuccess = true;

    for (var product in cart) {
      QuerySnapshot querySnapshot = await firestore
          .collection("product")
          .where("barcodenumber", isEqualTo: product['barcode'] as String)
          .where("userId", isEqualTo: currentUserUid)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final productData =
            querySnapshot.docs.first.data() as Map<String, dynamic>;
        String documentId = querySnapshot.docs.first.id;
        int currentQuantity = productData['total'] ?? 0;
        int purchasedQuantity = product['total'] as int;

        int updatedQuantity = currentQuantity - purchasedQuantity;
        if (updatedQuantity < 0) {
          updatedQuantity = 0;
        }

        await firestore.collection("product").doc(documentId).update({
          'total': updatedQuantity,
        });

        isSuccess = true;
      } else {
        isSuccess = false;
        break;
      }
    }

    if (isSuccess) {
      print('Product quantities updated successfully!');
    } else {
      print(
          'Failed to update product quantities. Product not found in database.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ชำระเงิน'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: cart.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(
                    cart[index]['nameitem'],
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'ราคา: ฿${cart[index]['price']} จำนวน: ${cart[index]['total']}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              'ราคารวม: ฿$total',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10.1, bottom: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    double updatedTotal = total;
                    cart.forEach((product) {
                      updatedTotal -= product['price'] * product['total'];
                    });

                    updateProductQuantity(cart);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BillPage(
                          cart: cart,
                          total: total,
                          billNumber: generateRandomBillNumber(),
                          billTime: DateTime.now(),
                          paymentMethod: 'เงินสด',
                        ),
                      ),
                    );
                  },
                  style: ButtonStyle(
                    minimumSize: MaterialStateProperty.all(Size(150, 50)),
                  ),
                  child: Text('เงินสด', style: TextStyle(fontSize: 18)),
                ),
                ElevatedButton(
                  onPressed: () {
                    double updatedTotal = total;
                    cart.forEach((product) {
                      updatedTotal -= product['price'] * product['total'];
                    });

                    updateProductQuantity(cart);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BillPage(
                          cart: cart,
                          total: total,
                          billNumber: generateRandomBillNumber(),
                          billTime: DateTime.now(),
                          paymentMethod: 'สแกนจ่าย',
                        ),
                      ),
                    );
                  },
                  style: ButtonStyle(
                    minimumSize: MaterialStateProperty.all(Size(150, 50)),
                  ),
                  child: Text('สแกนจ่าย', style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
