import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pstock/model/productitem.dart';
import 'package:pstock/screen/WelcomeScreen.dart';

class Addproduct extends StatefulWidget {
  const Addproduct({Key? key}) : super(key: key);

  @override
  _AddproductState createState() => _AddproductState();
}

class _AddproductState extends State<Addproduct> {
  final formKey = GlobalKey<FormState>();

  Product product = Product(
    nameitem: '',
    price: 0,
    total: 0,
    type: '',
    description: '',
    barcodenumber: '',
  );

  final User? user = FirebaseAuth.instance.currentUser;
  final CollectionReference productCollection =
      FirebaseFirestore.instance.collection("product");
  XFile? imageFile; // Stores the selected image file
  String? imageUrl;
  String _barcodeResult = ''; // Stores the URL of the uploaded image
  String _textEditingControllerValue = '';

  Future<void> selectImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? selectedImage =
        await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      imageFile = selectedImage;
    });
  }

  Future<String?> uploadImageToFirebaseStorage() async {
    if (imageFile == null) {
      return null;
    }

    try {
      final Reference storageReference =
          FirebaseStorage.instance.ref().child('product_images');

      final UploadTask uploadTask = storageReference
          .child('${DateTime.now()}.jpg')
          .putFile(File(imageFile!.path));

      final TaskSnapshot storageTaskSnapshot =
          await uploadTask.whenComplete(() {});

      final String downloadUrl = await storageTaskSnapshot.ref.getDownloadURL();
      setState(() {
        imageUrl = downloadUrl;
      });
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
    return null;
  }

  Future<void> _takePicture() async {
    final XFile? picture = await ImagePicker().pickImage(
      source: ImageSource.camera,
    );

    if (picture != null) {
      setState(() {
        imageFile = picture;
      });
    }
  }

  void _showImageSourceOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.photo),
              title: Text('เลือกรูปจากแกลอรี'),
              onTap: () {
                Navigator.pop(context);
                selectImage();
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('ถ่ายภาพ'),
              onTap: () {
                Navigator.pop(context);
                _takePicture();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _scanBarcode() async {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("เพิ่มรายการสินค้า"),
      ),
      body: Container(
        padding: EdgeInsets.all(15),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        _showImageSourceOptions(context);
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            onPressed: null,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.photo),
                                SizedBox(height: 30),
                                Text("เลือกรูปสินค้า"),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                if (imageFile != null)
                  Center(
                    child: Container(
                      height: 300,
                      width: 300,
                      child: Image.file(
                        File(imageFile!.path),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                SizedBox(height: 20),
                Text("ชื่อสินค้า", style: TextStyle(fontSize: 15)),
                TextFormField(
                  validator: MultiValidator(
                      [RequiredValidator(errorText: "โปรดกรอกชื่อ")]),
                  onSaved: (String? nameitem) {
                    product.nameitem = nameitem!;
                  },
                ),
                Text("จำนวนสินค้า", style: TextStyle(fontSize: 15)),
                TextFormField(
                  keyboardType: TextInputType.number,
                  validator: MultiValidator(
                      [RequiredValidator(errorText: "โปรดกรอกจำนวนสินค้า")]),
                  onSaved: (String? total) {
                    // Convert 'total' to int before saving
                    product.total = int.parse(total!);
                  },
                ),
                Text("ราคาสินค้า", style: TextStyle(fontSize: 15)),
                SizedBox(height: 10),
                TextFormField(
                  keyboardType: TextInputType.number,
                  validator: MultiValidator(
                      [RequiredValidator(errorText: "โปรดกรอกราคาสิค้า")]),
                  onSaved: (String? price) {
                    // Convert 'price' to int before saving
                    product.price = int.parse(price!);
                  },
                ),
                SizedBox(height: 10),
                Text("ประเภท", style: TextStyle(fontSize: 15)),
                TextFormField(
                  validator: MultiValidator(
                      [RequiredValidator(errorText: "โปรดกรอกประเภทสินค้า")]),
                  onSaved: (String? type) {
                    product.type = type!;
                  },
                ),
                SizedBox(height: 10),
                Text("รายละเอียดสิค้า", style: TextStyle(fontSize: 15)),
                TextFormField(
                  onSaved: (String? description) {
                    product.description = description!;
                  },
                ),
                SizedBox(height: 10),
                Text("บาร์โค้ดสินค้า", style: TextStyle(fontSize: 15)),
                TextFormField(
                  controller: TextEditingController(
                    text: _barcodeResult,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _barcodeResult = value;
                    });
                  },
                  onSaved: (String? barcodenumber) {
                    setState(() {
                      product.barcodenumber = barcodenumber!;
                    });
                  },
                  decoration: InputDecoration(
                    suffixIcon: IconButton(
                      icon: Icon(Icons.camera_alt),
                      onPressed: () {
                        _scanBarcode();
                      },
                    ),
                  ),
                ),
                SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    child: Text("บันทึกรายการสินค้า",
                        style: TextStyle(fontSize: 15)),
                    onPressed: () async {
                      String? uploadedImageUrl =
                          await uploadImageToFirebaseStorage();
                      if (formKey.currentState!.validate()) {
                        formKey.currentState!.save();
                        if (user != null) {
                          await productCollection.add({
                            "userId": user!.uid,
                            "nameitem": product.nameitem,
                            "price": product.price,
                            "total": product.total,
                            "type": product.type,
                            "description": product.description,
                            "barcodenumber": product.barcodenumber,
                            "imageUrl": imageUrl,
                          });
                          formKey.currentState!.reset();
                          Fluttertoast.showToast(
                            msg: "เพิ่มรายการสินค้าสำเร็จ",
                            gravity: ToastGravity.CENTER,
                          );
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (context) => WelcomeScreen()),
                            ModalRoute.withName('/'),
                          );
                        } else {}
                      }
                    },
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
