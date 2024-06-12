import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

void main() {
  runApp(ProfilePage());
}

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  TextEditingController _storeNameController = TextEditingController();
  TextEditingController _ownerNameController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();

  bool _isEditMode = false;
  bool _allFieldsEntered = false;
  late String _userId;

  @override
  void initState() {
    super.initState();

    _userId = FirebaseAuth.instance.currentUser!.uid;
    loadProfileData(_userId);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('โปรไฟล์'),
          actions: [
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditMode = true;
                });
              },
            ),
          ],
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _ownerNameController,
                decoration: InputDecoration(labelText: 'ชื่อเจ้าของร้านค้า'),
                enabled: _isEditMode,
                onChanged: (value) {
                  checkAllFieldsEntered();
                },
              ),
              SizedBox(height: 20),
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(labelText: 'เบอร์โทรศัพท์'),
                enabled: _isEditMode,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                onChanged: (value) {
                  checkAllFieldsEntered();
                },
              ),
              SizedBox(height: 20),
              if (_isEditMode && _allFieldsEntered)
                ElevatedButton(
                  onPressed: () async {
                    await saveProfileData(_userId);
                    setState(() {
                      _isEditMode = false;
                    });
                    Fluttertoast.showToast(
                      msg: "บันทึกข้อมูลโปรไฟล์สำเร็จ!",
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.BOTTOM,
                    );
                  },
                  child: Text('บันทึก'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void checkAllFieldsEntered() {
    setState(() {
      _allFieldsEntered = _ownerNameController.text.isNotEmpty &&
          _phoneController.text.isNotEmpty;
    });
  }

  Future<void> saveProfileData(String userId) async {
    try {
      await FirebaseFirestore.instance.collection('profiles').doc(userId).set({
        'owner_name': _ownerNameController.text,
        'phone': _phoneController.text,
        'user_id': userId,
      });
      print('บันทึกข้อมูลโปรไฟล์สำเร็จ!');
    } catch (e) {
      print('เกิดข้อผิดพลาดในการบันทึกข้อมูลโปรไฟล์: $e');
    }
  }

  Future<void> loadProfileData(String userId) async {
    try {
      DocumentSnapshot profileSnapshot = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(userId)
          .get();

      if (profileSnapshot.exists) {
        setState(() {
          _ownerNameController.text = profileSnapshot['owner_name'] ?? '';
          _phoneController.text = profileSnapshot['phone'] ?? '';
        });
      }
    } catch (e) {
      print('เกิดข้อผิดพลาดในการโหลดข้อมูลโปรไฟล์: $e');
    }
  }
}
