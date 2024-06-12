//import 'package:app2/screen/pos.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pstock/screen/accountscreen.dart';
import 'package:pstock/screen/homeproduct.dart';
import 'package:pstock/screen/pos.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  final auth = FirebaseAuth.instanceFor;
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: TabBarView(children: [HomeProduct(), PosPage(), AccountScreen()]),
        backgroundColor: Colors.blue,
        bottomNavigationBar: TabBar(tabs: [
          Tab(
            text: "คลังสินค้า",
          ),
          Tab(
            text: "ระบบคิดเงิน",
          ),
          Tab(
            text: "โปรไฟล์",
          ),
        ]),
      ),
    );
  }
}
