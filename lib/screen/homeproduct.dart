import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pstock/screen/addproduct.dart';
import 'package:pstock/screen/editproduct.dart';

class HomeProduct extends StatefulWidget {
  const HomeProduct({Key? key}) : super(key: key);

  @override
  State<HomeProduct> createState() => _ProductState();
}

class _ProductState extends State<HomeProduct> {
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  late TextEditingController searchController;
  String _barcodeResult = '';
  DocumentSnapshot? _scannedDocument;
  int limit = 6;

  @override
  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
    searchController.addListener(_searchProducts);
  }

  void _searchProducts() {
    final searchText = searchController.text;
    final user = FirebaseAuth.instance.currentUser;
    final userId = user!.uid;

    FirebaseFirestore.instance
        .collection("product")
        .where("userId", isEqualTo: userId)
        .where("nameitem", isGreaterThanOrEqualTo: searchText ?? "")
        .where("nameitem", isLessThanOrEqualTo: searchText + '\uf8ff' ?? "")
        .get()
        .then((querySnapshot) {
      List<DocumentSnapshot> matchingProducts = querySnapshot.docs;

      setState(() {
        _scannedDocument = null;
      });

      if (matchingProducts.isNotEmpty) {
        setState(() {
          _scannedDocument = matchingProducts.first;
        });
      }
    });
  }

  Future<void> _scanBarcode() async {
    String currentUserUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    String barcodeResult = await FlutterBarcodeScanner.scanBarcode(
      '#FF0000',
      'Cancel',
      true,
      ScanMode.BARCODE,
    );

    if (!mounted) return;

    setState(() {
      _barcodeResult = barcodeResult;
    });

    if (barcodeResult != null && barcodeResult != '-1') {
      FirebaseFirestore.instance
          .collection("product")
          .where("barcodenumber", isEqualTo: barcodeResult)
          .where("userId", isEqualTo: currentUserUid)
          .get()
          .then((querySnapshot) {
        if (querySnapshot.docs.isNotEmpty) {
          final scannedDocument = querySnapshot.docs.first;
          // Check if the document contains the "total" field
          if (scannedDocument.data().containsKey("total")) {
            setState(() {
              _scannedDocument = scannedDocument;
            });

            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text("ข้อมูลสินค้า"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("ชื่อสินค้า: ${scannedDocument["nameitem"]}"),
                      Text("ราคา: ${scannedDocument["price"]}"),
                      Text("จำนวน: ${scannedDocument["total"]}"),
                      Text("ประเภท: ${scannedDocument["type"]}"),
                    ],
                  ),
                  actions: [
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
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();

                        if (scannedDocument["total"] == 0) {
                          FirebaseFirestore.instance
                              .collection("product")
                              .doc(scannedDocument.id)
                              .delete()
                              .then((value) {
                            print("ลบเอกสารเรียบร้อยแล้ว");
                          }).catchError((error) {
                            print("Failed to delete document: $error");
                          });
                        }
                      },
                      child: Text("ปิด"),
                    ),
                  ],
                );
              },
            );
          } else {
            print("ไม่มีฟิลด์ผลรวมในเอกสาร");
          }
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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user!.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text("รายการสินค้า"),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (context) {
                  return Addproduct();
                },
              ));
            },
            icon: Icon(Icons.add),
          ),
          IconButton(
            onPressed: () {
              _showSearchDialog(context);
            },
            icon: Icon(Icons.search),
          ),
          IconButton(
            onPressed: () {
              _scanBarcode();
            },
            icon: Icon(Icons.camera),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("product")
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
              return Card(
                margin: EdgeInsets.symmetric(vertical: 7, horizontal: 10),
                elevation: 12,
                color: document == _scannedDocument
                    ? Colors.yellow
                    : null, // Highlight if scanned
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 50,
                    child: CachedNetworkImage(
                      imageUrl: document["imageUrl"] ?? "",
                      placeholder: (context, url) =>
                          CircularProgressIndicator(),
                      errorWidget: (context, url, error) => Icon(Icons.error),
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: Text(
                    ":  ${document["nameitem"]}   จำนวน: ${document["total"]}",
                    style: TextStyle(fontSize: 17),
                  ),
                  subtitle: Text(
                    "ราคา: ${document["price"]} ประเภท: ${document["type"]}",
                    style: TextStyle(fontSize: 15),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) {
                                return EditProduct(document: document);
                              },
                            ),
                          );
                        },
                        child: Icon(
                          Icons.edit,
                          color: Colors.blue,
                        ),
                      ),
                      SizedBox(width: 16),
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text("ลบรายการสินค้า"),
                                content: Text(
                                    "คุณต้องการลบรายการสินค้านี้หรือไม่ ?"),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: Text("ไม่ลบ"),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      FirebaseFirestore.instance
                                          .collection("product")
                                          .doc(document.id)
                                          .delete();
                                      Navigator.of(context).pop();
                                    },
                                    child: Text("ลบ"),
                                  ),
                                ],
                              );
                            },
                          );
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
          title: Text("ค้นหาสินค้า"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: searchController,
                decoration: InputDecoration(labelText: "ชื่อสินค้า"),
              ),
              ElevatedButton(
                onPressed: () {
                  final searchText = searchController.text;
                  if (searchText.isNotEmpty) {
                    _searchProductsByName(searchText);
                    Navigator.of(context).pop(); // Close the search dialog
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

  void _searchProductsByName(String productName) {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user!.uid;

    FirebaseFirestore.instance
        .collection("product")
        .where("userId", isEqualTo: userId)
        .where("nameitem", isEqualTo: productName.trim() ?? "")
        .get()
        .then((querySnapshot) {
      if (querySnapshot.docs.isNotEmpty) {
        final scannedDocument = querySnapshot.docs.first;

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("ข้อมูลสินค้า"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("ชื่อสินค้า: ${scannedDocument["nameitem"]}"),
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
              title: Text("ไม่พบสินค้า"),
              content: Text("ไม่พบสินค้าที่มีชื่อนี้"),
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
