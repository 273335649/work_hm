import 'package:flutter/material.dart';
import '../../common/constant.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LoginModal extends StatefulWidget {
  const LoginModal({super.key});

  @override
  State<LoginModal> createState() => _LoginModalState();
}

class _LoginModalState extends State<LoginModal> {
  final GlobalKey<FormState> form = GlobalKey<FormState>();
  TextEditingController username = TextEditingController();
  TextEditingController password = TextEditingController();
  TextEditingController scancode = TextEditingController();
  FocusNode usernamefocusNode = FocusNode();
  FocusNode passwordfocusNode = FocusNode();
  FocusNode scancodefocusNode = FocusNode();
  var selectedInput;
  var selectedInputNode;
  bool showKeyboard = true;
  String versionNum = '';
  String ipAddress = '';

  @override
  void initState() {
    usernamefocusNode.addListener(_handleFocusChanged);
    passwordfocusNode.addListener(_handleFocusChanged);
    scancodefocusNode.addListener(_handleFocusChanged);
    if (Constant.isDev) {
      username.text = '17366953616';
      password.text = '1234567';
    }
    super.initState();
  }

  void _handleFocusChanged() {
    if (usernamefocusNode.hasFocus) {
      selectedInput = username;
      selectedInputNode = usernamefocusNode;
    }
    if (passwordfocusNode.hasFocus) {
      selectedInput = password;
      selectedInputNode = passwordfocusNode;
    }
    if (scancodefocusNode.hasFocus) {
      selectedInput = scancode;
      selectedInputNode = scancodefocusNode;
    }
  }

  void handleKey(value) {
    if (selectedInput != null) {
      var newvalue = selectedInput.text + value;
      selectedInput.value = selectedInput.value.copyWith(
        text: newvalue,
        selection: TextSelection.fromPosition(
          TextPosition(offset: newvalue.length),
        ),
      );
      FocusScope.of(context).requestFocus(selectedInputNode);
    }
  }

  void delKey() {
    if (selectedInput != null && selectedInput.text != '') {
      var newvalue = selectedInput.text.substring(0, selectedInput.text.length - 1);
      selectedInput.value = selectedInput.value.copyWith(
        text: newvalue,
        selection: TextSelection.fromPosition(
          TextPosition(offset: newvalue.length),
        ),
      );
      FocusScope.of(context).requestFocus(selectedInputNode);
    }
  }

  void toggleKeyboard() {
    setState(() {
      showKeyboard = !showKeyboard;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 600.w,
        height: 400.h,
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.blue[900],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              '登录',
              style: TextStyle(
                fontSize: 20.sp,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 20.h),
            Form(
              key: form,
              child: Column(
                children: [
                  usernameInput(username, usernamefocusNode),
                  SizedBox(height: 15.h),
                  passwordInput(password, passwordfocusNode),
                  SizedBox(height: 15.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('取消'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // 登录逻辑
                          Navigator.pop(context);
                        },
                        child: Text('登录'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget usernameInput(TextEditingController username, focusNode) {
    return SizedBox(
      width: 300.w,
      child: TextFormField(
        controller: username,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.person, color: Colors.white),
          hintText: '请输入账号',
          hintStyle: TextStyle(color: Color(0xffC1D3FF)),
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xff4b74dc)),
          ),
          filled: true,
          fillColor: Color(0xFF050A32),
        ),
        focusNode: focusNode,
      ),
    );
  }

  Widget passwordInput(TextEditingController password, focusNode) {
    return SizedBox(
      width: 300.w,
      child: TextFormField(
        obscureText: true,
        controller: password,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.lock, color: Colors.white),
          hintText: '请输入密码',
          hintStyle: TextStyle(color: Color(0xffC1D3FF)),
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xff4b74dc)),
          ),
          filled: true,
          fillColor: Color(0xFF050A32),
        ),
        focusNode: focusNode,
      ),
    );
  }
}