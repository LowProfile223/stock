import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pstock/screen/welcomescreen.dart';

class EditProduct extends StatefulWidget {
  final QueryDocumentSnapshot document;

  EditProduct({required this.document});

  @override
  State<EditProduct> createState() => _EditProductState();
}

class _EditProductState extends State<EditProduct> {
  TextEditingController nameController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  TextEditingController typeController = TextEditingController();
  TextEditingController totalController = TextEditingController();
  TextEditingController barcodenumberController = TextEditingController();
  File? _image;

  @override
  void initState() {
    super.initState();

    nameController.text = widget.document["nameitem"];
    priceController.text = widget.document["price"].toString();
    typeController.text = widget.document["type"];
    totalController.text = widget.document["total"].toString();
    barcodenumberController.text = widget.document["barcodenumber"];
  }

  Future<void> _getImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      }
    });
  }

  Future<void> _uploadImage(int price, int total) async {
    try {
      if (_image != null) {
        final storage = FirebaseStorage.instance;
        final imageName = DateTime.now().millisecondsSinceEpoch.toString();
        final Reference storageReference =
            storage.ref().child('product_images/$imageName.jpg');
        await storageReference.putFile(_image!);
        final String imageUrl = await storageReference.getDownloadURL();

        if (imageUrl.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection("product")
              .doc(widget.document.id)
              .update({
            "nameitem": nameController.text,
            "price": price,
            "total": total,
            "type": typeController.text,
            "imageUrl": imageUrl,
          });
          Fluttertoast.showToast(
            msg: "บันทึกรายการเรียบร้อยแล้ว",
            gravity: ToastGravity.CENTER,
          );
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => WelcomeScreen()),
            ModalRoute.withName('/'),
          );
        } else {
          print("Image upload failed. Empty imageUrl.");
        }
      } else {
        await FirebaseFirestore.instance
            .collection("product")
            .doc(widget.document.id)
            .update({
          "nameitem": nameController.text,
          "price": price,
          "total": total,
          "type": typeController.text,
        });
        Fluttertoast.showToast(
          msg: "บันทึกรายการเรียบร้อยแล้ว",
          gravity: ToastGravity.CENTER,
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => WelcomeScreen()),
          ModalRoute.withName('/'),
        );
      }
    } catch (e) {
      print("Error uploading image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("แก้ไขรายการสินค้า"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildImageSelectionButton(),
              SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: "ชื่อสินค้า"),
              ),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                ],
                decoration: InputDecoration(labelText: "ราคา"),
              ),
              SizedBox(height: 10),
              TextField(
                controller: totalController,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                ],
                decoration: InputDecoration(labelText: "จำนวน"),
              ),
              SizedBox(height: 10),
              TextField(
                controller: typeController,
                decoration: InputDecoration(labelText: "ประเภท"),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  if (_isValidData()) {
                    int price = int.parse(priceController.text);
                    int total = int.parse(totalController.text);
                    _uploadImage(price, total);
                  }
                },
                child: Text("บันทักการเปลี่ยนแปลง"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSelectionButton() {
    return TextButton(
      onPressed: () {
        _getImage();
      },
      child: _image == null
          ? CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[300],
              child: Icon(
                Icons.add_photo_alternate,
                size: 40,
                color: Colors.grey[600],
              ),
            )
          : CircleAvatar(
              radius: 50,
              backgroundImage: FileImage(_image!),
            ),
    );
  }

  bool _isValidData() {
    if (nameController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: "กรุณากรอกชื่อสินค้า",
        gravity: ToastGravity.CENTER,
      );
      return false;
    }

    if (priceController.text.isEmpty ||
        int.tryParse(priceController.text) == null) {
      Fluttertoast.showToast(
        msg: "กรุณากรอกราคาให้ถูกต้อง",
        gravity: ToastGravity.CENTER,
      );
      return false;
    }

    if (priceController.text.isEmpty ||
        int.tryParse(priceController.text) == null) {
      Fluttertoast.showToast(
        msg: "กรุณากรอกจำนวนให้ถูกต้อง",
        gravity: ToastGravity.CENTER,
      );
      return false;
    }

    if (typeController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: "กรุณากรอกประเภท",
        gravity: ToastGravity.CENTER,
      );
      return false;
    }

    return true;
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    typeController.dispose();
    totalController.dispose();
    barcodenumberController.dispose();
    super.dispose();
  }
}
