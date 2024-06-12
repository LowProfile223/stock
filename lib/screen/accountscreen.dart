import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pstock/screen/home.dart';
import 'package:pstock/screen/profiles.dart';
import 'package:pstock/screen/salereport.dart';
import 'package:pstock/screen/srcbill.dart';

class AccountScreen extends StatefulWidget {
  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final formKey = GlobalKey<FormState>();
  late String _ownerName = '';
  late String _phoneNumber = '';

  @override
  void initState() {
    super.initState();
    _loadOwnerName();
    _loadPhoneNumber();
  }

  Future<void> _loadOwnerName() async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot profileSnapshot = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(userId)
          .get();

      if (profileSnapshot.exists) {
        setState(() {
          _ownerName = profileSnapshot['owner_name'] ?? 'ไม่พบชื่อเจ้าของ';
        });
      }
    } catch (e) {
      print('เกิดข้อผิดพลาดในการโหลดข้อมูลโปรไฟล์: $e');
    }
  }

  Future<void> _loadPhoneNumber() async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot profileSnapshot = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(userId)
          .get();

      if (profileSnapshot.exists) {
        setState(() {
          _phoneNumber = profileSnapshot['phone'] ?? 'ไม่พบเบอร์โทรศัพท์';
        });
      }
    } catch (e) {
      print('เกิดข้อผิดพลาดในการโหลดข้อมูลเบอร์โทรศัพท์: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('บัญชี'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              try {
                await FirebaseAuth.instance.signOut().then((value) {
                  Fluttertoast.showToast(
                      msg: "ออกจากระบบเรียบร้อย", gravity: ToastGravity.CENTER);
                  formKey.currentState!.reset();
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (context) {
                    return HomeScreen();
                  }));
                });
              } catch (e) {
                print("เกิดข้อผิดพลาดในการออกจากระบบ: $e");
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text("ยินดีต้อนรับเข้าสู่แอปพลิเคชัน"),
              SizedBox(height: 5),
              Text(
                "คุณ : $_ownerName",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 5),
              Text(
                "$_phoneNumber",
                style: TextStyle(
                  fontSize: 17,
                ),
              ),
              SizedBox(height: 20),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (cntext) {
                        return HomeBills();
                      }));
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(200, 50), // กำหนดขนาดของปุ่ม
                    ),
                    child: Text("ประวัติการขาย"),
                  ),
                  SizedBox(height: 10), // เพิ่มระยะห่างระหว่างปุ่ม
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (cntext) {
                        return ProfilePage();
                      }));
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(200, 50), // กำหนดขนาดของปุ่ม
                    ),
                    child: Text("โปรไฟล์"),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (cntext) {
                        return SalesReportPage();
                      }));
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(200, 50), // กำหนดขนาดของปุ่ม
                    ),
                    child: Text("ยอดขาย"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
