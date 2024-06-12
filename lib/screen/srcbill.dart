import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:pstock/main.dart';
import 'package:pstock/screen/editproduct.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('th');
  runApp(MyApp());
}

class HomeBills extends StatefulWidget {
  const HomeBills({
    Key? key,
  }) : super(key: key);

  @override
  State<HomeBills> createState() => _BillsState();
}

class _BillsState extends State<HomeBills> {
  late TextEditingController searchController;
  String _barcodeResult = '';
  DocumentSnapshot? _scannedDocument;
  int limit = 6;

  Future<bool> _checkPhoneNumber(String phoneNumber) async {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user!.uid;

    DocumentSnapshot<Map<String, dynamic>> profileSnapshot =
        await FirebaseFirestore.instance
            .collection('profiles')
            .doc(userId)
            .get();

    if (profileSnapshot.exists) {
      String? userPhoneNumber = profileSnapshot.get('phone');
      if (userPhoneNumber == phoneNumber) {
        return true;
      }
    }
    return false;
  }

  void _showBillDetailsDialog(
      BuildContext context, DocumentSnapshot billDocument) {
    List<Map<String, dynamic>> items =
        List<Map<String, dynamic>>.from(billDocument['items']);
    Timestamp firebaseTimestamp = billDocument["billTime"];
    DateTime billTime = firebaseTimestamp.toDate();

    billTime = DateTime(billTime.year + 543, billTime.month, billTime.day,
        billTime.hour, billTime.minute, billTime.second);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              SizedBox(width: 10),
              Text("รายละเอียดบิล",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("เลขที่บิล: ${billDocument["billNumber"]}"),
              Text(
                "เวลา: ${DateFormat.yMMMMd('th').format(billTime)}",
              ),
              Text("ยอดรวม: ${billDocument["total"]}"),
              Text("ประเภท: ${billDocument["paymentMethod"]}"),
              SizedBox(height: 10),
              Text("รายการสินค้า:",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(items.length, (index) {
                  var item = items[index];
                  return Text(
                      "${item['name']} ราคา: ${item['price']} จำนวน: ${item['quantity']}");
                }),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('ปิด'),
            ),
          ],
        );
      },
    );
  }

  @override
  void _deleteBillAndRestoreInventory(DocumentSnapshot billDocument) {
    FirebaseFirestore.instance
        .collection("bills")
        .doc(billDocument.id)
        .delete();

    List<Map<String, dynamic>> items =
        List<Map<String, dynamic>>.from(billDocument['items']);
    items.forEach((item) {
      String productId = item['productId'];
      int quantity = item['quantity'];
      FirebaseFirestore.instance
          .collection("product")
          .doc(productId)
          .update({"quantity": FieldValue.increment(quantity)});
    });
  }

  void _searchBillByNumber(String billNumber) {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user!.uid;

    FirebaseFirestore.instance
        .collection("bills")
        .where("userId", isEqualTo: userId)
        .where("billNumber", isEqualTo: billNumber.trim())
        .get()
        .then((querySnapshot) async {
      if (querySnapshot.docs.isNotEmpty) {
        final scannedDocument = querySnapshot.docs.first;

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("ยืนยันการลบบิล"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("กรุณาใส่เบอร์โทรศัพท์ของคุณเพื่อยืนยันการลบ"),
                  TextFormField(
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: "เบอร์โทรศัพท์",
                    ),
                    onChanged: (value) {
                      _checkPhoneNumber(value).then((isValid) {
                        if (isValid) {
                          setState(() {
                            _barcodeResult = value;
                          });
                        } else {
                          setState(() {
                            _barcodeResult = '';
                          });
                        }
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("ยกเลิก"),
                ),
                TextButton(
                  onPressed: () {
                    if (_barcodeResult.isNotEmpty) {
                      _deleteBillAndRestoreInventory(scannedDocument);
                      Navigator.of(context).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("กรุณาใส่เบอร์โทรศัพท์ให้ถูกต้อง"),
                        ),
                      );
                    }
                  },
                  child: Text("ยืนยัน"),
                ),
              ],
            );
          },
        );
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("ไม่พบบิล"),
              content: Text("ไม่พบบิลที่มีเลขที่นี้"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("ปิด"),
                ),
              ],
            );
          },
        );
      }
    });
  }

  void initState() {
    super.initState();
    searchController = TextEditingController();
    searchController.addListener(_searchBills);
  }

  void _searchBills() {
    final searchText = searchController.text;
    final user = FirebaseAuth.instance.currentUser;
    final userId = user!.uid;

    FirebaseFirestore.instance
        .collection("bills")
        .where("userId", isEqualTo: userId)
        .where("billNumber", isGreaterThanOrEqualTo: searchText ?? "")
        .where("billNumber", isLessThanOrEqualTo: searchText + '\uf8ff' ?? "")
        .get()
        .then((querySnapshot) {
      List<DocumentSnapshot> matchingBills = querySnapshot.docs;

      setState(() {
        _scannedDocument = null;
      });

      if (matchingBills.isNotEmpty) {
        setState(() {
          _scannedDocument = matchingBills.first;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    initializeDateFormatting('th');
    final user = FirebaseAuth.instance.currentUser;
    final userId = user!.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text("รายการบิล"),
        actions: [],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("bills")
            .where("userId", isEqualTo: userId)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          return ListView(
            children: snapshot.data!.docs.map((document) {
              Timestamp firebaseTimestamp = document["billTime"];
              DateTime billTime = firebaseTimestamp.toDate();

              billTime = DateTime(
                  billTime.year + 543,
                  billTime.month,
                  billTime.day,
                  billTime.hour,
                  billTime.minute,
                  billTime.second);
              return Card(
                margin: EdgeInsets.symmetric(vertical: 7, horizontal: 10),
                elevation: 12,
                color: document == _scannedDocument ? Colors.yellow : null,
                child: ListTile(
                  title: Text(
                    "เลขที่บิล:  ${document["billNumber"]}   ยอดรวม: ${document["total"]}",
                    style: TextStyle(fontSize: 15),
                  ),
                  subtitle: Text(
                    "เวลา: ${DateFormat.yMMMMd('th').add_jms().format(billTime)}  ประเภท: ${document["paymentMethod"]}",
                    style: TextStyle(fontSize: 15),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () {
                          _showBillDetailsDialog(context, document);
                        },
                        child: Icon(
                          Icons.info,
                          color: Colors.blue,
                        ),
                      ),
                      SizedBox(width: 16),
                      GestureDetector(
                        onTap: () {
                          _searchBillByNumber(document["billNumber"]);
                        },
                        child: Icon(
                          Icons.delete,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("ค้นหาบิล"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: searchController,
                decoration: InputDecoration(labelText: "เลขที่บิล"),
              ),
              ElevatedButton(
                onPressed: () {
                  final searchText = searchController.text;
                  if (searchText.isNotEmpty) {
                    _searchBillByNumber(searchText);
                    Navigator.of(context).pop();
                  }
                },
                child: Text("ค้นหา"),
              ),
            ],
          ),
        );
      },
    );
  }

  void _searchBillsByNumber(String billNumber) {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user!.uid;

    FirebaseFirestore.instance
        .collection("bills")
        .where("userId", isEqualTo: userId)
        .where("billNumber", isEqualTo: billNumber.trim() ?? "")
        .get()
        .then((querySnapshot) {
      if (querySnapshot.docs.isNotEmpty) {
        final scannedDocument = querySnapshot.docs.first;

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("ข้อมูลบิล"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("เลขที่บิล: ${scannedDocument["billNumber"]}"),
                  Text("ราคา: ${scannedDocument["price"]}"),
                  Text("จำนวน: ${scannedDocument["total"]}"),
                  Text("ประเภท: ${scannedDocument["type"]}"),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("ปิด"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return EditProduct(document: scannedDocument);
                        },
                      ),
                    );
                  },
                  child: Text("แก้ไข"),
                ),
              ],
            );
          },
        );
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("ไม่พบบิล"),
              content: Text("ไม่พบบิลที่มีเลขที่นี้"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("ปิด"),
                ),
              ],
            );
          },
        );
      }
    });
  }
}
