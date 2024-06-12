import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:pstock/model/profile.dart';
import 'package:pstock/screen/home.dart';

class RegisterScreen extends StatefulWidget {
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final formKey = GlobalKey<FormState>();
  Profile profile = Profile(username: '', email: '', password: '');
  final Future<FirebaseApp> firebase = Firebase.initializeApp();
  String? userUid;
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: firebase,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: Text("Loading..."),
            ),
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: Text("Error"),
            ),
            body: Center(
              child: Text("${snapshot.error}"),
            ),
          );
        } else {
          return Scaffold(
            appBar: AppBar(
              title: Text("สร้างบัญชีผู้ใช้"),
            ),
            body: Padding(
              padding: const EdgeInsets.all(30.0),
              child: Container(
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("อีเมล", style: TextStyle(fontSize: 20)),
                        TextFormField(
                          validator: MultiValidator([
                            RequiredValidator(
                                errorText: "กรุณาป้อนข้อมูลอีเมล"),
                            EmailValidator(
                                errorText: "รูปแบบอีเมลล์ไม่ถูกต้อง"),
                          ]),
                          keyboardType: TextInputType.emailAddress,
                          onSaved: (String? email) {
                            profile.email = email!;
                          },
                        ),
                        SizedBox(
                          height: 15,
                        ),
                        Text("รหัสผ่าน", style: TextStyle(fontSize: 20)),
                        TextFormField(
                          validator: RequiredValidator(
                              errorText: "กรุณาป้อนข้อมูลรหัสผ่าน"),
                          obscureText: !_isPasswordVisible,
                          onSaved: (String? password) {
                            profile.password = password!;
                          },
                          decoration: InputDecoration(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            child: Text("ลงทะเบียน",
                                style: TextStyle(fontSize: 20)),
                            onPressed: () async {
                              if (formKey.currentState!.validate()) {
                                formKey.currentState!.save();
                                try {
                                  UserCredential userCredential =
                                      await FirebaseAuth.instance
                                          .createUserWithEmailAndPassword(
                                    email: profile.email,
                                    password: profile.password,
                                  );

                                  userUid = userCredential.user?.uid;

                                  print("User UID: $userUid");
                                  formKey.currentState!.reset();
                                  Navigator.pushReplacement(context,
                                      MaterialPageRoute(builder: (context) {
                                    return HomeScreen();
                                  }));
                                } on FirebaseAuthException catch (e) {
                                  String message = '';
                                  if (e.code == 'email-already-in-use') {
                                    message =
                                        "ที่อยู่อีเมลนี้มีการใช้งานในระบบแล้ว";
                                  } else if (e.code == 'weak-password') {
                                    message = "รหัสผ่านที่อ่อนแอ"
                                        "รหัสผ่านต้องมีความยาว 6 ตัวอักษรขึ้นไป";
                                  } else {
                                    message = e.message!;
                                  }
                                  Fluttertoast.showToast(
                                    msg: message,
                                    gravity: ToastGravity.CENTER,
                                  );
                                }
                              }
                            },
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.add),
                            label: Text("ย้อนกลับ",
                                style: TextStyle(fontSize: 20)),
                            onPressed: () {
                              Navigator.pushReplacement(context,
                                  MaterialPageRoute(builder: (cntext) {
                                return HomeScreen();
                              }));
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }
      },
    );
  }
}
