import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:pstock/screen/poscash.dart';

class PosPage extends StatefulWidget {
  const PosPage({Key? key}) : super(key: key);

  @override
  State<PosPage> createState() => _PosPageState();
}

class _PosPageState extends State<PosPage> {
  late TextEditingController searchController;
  List<Map<String, dynamic>> cart = [];

  void addToCart(Map<String, dynamic> product) {
    setState(() {
      bool productExists = false;
      for (var item in cart) {
        if (item['barcode'] == product['barcode']) {
          item['total'] += product['total'];
          productExists = true;
          break;
        }
      }
      if (!productExists) {
        cart.add(product);
      }
    });
  }

  void removeFromCart(int index) {
    setState(() {
      if (cart[index]['total'] > 1) {
        cart[index]['total']--;
      } else {
        cart.removeAt(index);
      }
    });
  }

  double calculateTotal() {
    double total = 0;
    for (var item in cart) {
      int price = item['price'];
      int totalItems = item['total'];
      total += price * totalItems;
    }
    return total;
  }

  void _scanBarcode() async {
    String barcodeResult = await FlutterBarcodeScanner.scanBarcode(
      '#FF0000',
      'Cancel',
      true,
      ScanMode.BARCODE,
    );

    if (!mounted || barcodeResult == '-1') return;

    String currentUserUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    FirebaseFirestore.instance
        .collection("product")
        .where("barcodenumber", isEqualTo: barcodeResult)
        .where("userId", isEqualTo: currentUserUid)
        .get()
        .then((querySnapshot) {
      if (querySnapshot.docs.isNotEmpty) {
        final productData =
            querySnapshot.docs.first.data() as Map<String, dynamic>;
        Map<String, dynamic> product = {
          'nameitem': productData['nameitem'],
          'price': productData['price'],
          'total': 1,
          'imageUrl': productData['imageUrl'],
          'barcode': barcodeResult,
        };
        addToCart(product);
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("ไม่พบสินค้า"),
              content: Text("ไม่พบสินค้าที่มีบาร์โค้ดนี้"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("OK"),
                ),
              ],
            );
          },
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "รายการสินค้า",
        ),
        actions: [
          IconButton(
            onPressed: () {
              _scanBarcode();
            },
            icon: Icon(Icons.camera),
          ),
        ],
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
                    "ราคา: \฿${cart[index]['price']}",
                    style: TextStyle(fontSize: 18),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove),
                        onPressed: () => removeFromCart(index),
                      ),
                      Text(
                        "${cart[index]['total']}",
                      ),
                      IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () {
                          setState(() {
                            cart[index]['total']++;
                          });
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "ราคารวม: \฿${calculateTotal()}",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                if (cart.isNotEmpty)
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CashPage(
                            cart: cart,
                            total: calculateTotal(),
                          ),
                        ),
                      );
                    },
                    style: ButtonStyle(
                      minimumSize: MaterialStateProperty.all(Size(100, 50)),
                    ),
                    child: Text(
                      'ชำระเงิน',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
