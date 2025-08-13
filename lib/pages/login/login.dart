import 'package:flutter/material.dart';
// import 'package:flutter_windows_android_app/pages/login/loginModal.dart';
import 'package:flutter_windows_android_app/pages/home/home.dart';
import '../../common/login_prefs.dart';
import '../../common//dio_request.dart';
import 'package:flutter_windows_android_app/utils/init.dart';
import 'package:sm_crypto/sm_crypto.dart';
import 'dart:convert';
import '../../common/constant.dart';
import 'package:provider/provider.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:io';
import 'package:flutter/services.dart';
// import 'package:auto_updater/auto_updater.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final GlobalKey<FormState> form = GlobalKey<FormState>();
  TextEditingController username = TextEditingController();
  TextEditingController password = TextEditingController();
  TextEditingController scancode = TextEditingController();
  FocusNode usernamefocusNode = FocusNode();
  FocusNode passwordfocusNode = FocusNode();
  FocusNode scancodefocusNode = FocusNode();
  var selectedInput;
  var selectedInputNode;
  bool showKeyboard = true; // 控制小键盘显示/隐藏
  String versionNum = '';
  String ipAddress = '';

  Future<void> getVersionFromPubspec() async {
    String version = await InitUtilData.getVersionFromPubspec();
    setState(() {
      versionNum = version;
    });
  }

  Future<void> getIpAddress() async {
    String ip = await InitUtilData.getLocalIpAddress();
    setState(() {
      ipAddress = ip;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    usernamefocusNode.addListener(_handleFocusChanged);
    passwordfocusNode.addListener(_handleFocusChanged);
    scancodefocusNode.addListener(_handleFocusChanged);
    // 本地默认
    if (Constant.isDev) {
      username.text = 'humi_admin';
      password.text = '1234567';
    }
    super.initState();
    _checkAutoLogin();
    getVersionFromPubspec();
    getIpAddress();
  }

  void _checkAutoLogin() async {
    String? token = LoginPrefs.getToken();
    int? loginTime = LoginPrefs.getLoginTime();
    if (token != null && loginTime != null) {
      int now = DateTime.now().millisecondsSinceEpoch;
      // 30分钟 = 30 * 60 * 1000 毫秒
      if (now - loginTime < 30 * 60 * 1000) {
        // 免登录，跳转到主页面
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (context) => Home()));
      } else {
        // 超时，清除token
        LoginPrefs.saveToken('');
        LoginPrefs.saveLoginTime(0);
      }
    }
  }

  @override
  void dispose() {
    usernamefocusNode.removeListener(_handleFocusChanged);
    passwordfocusNode.removeListener(_handleFocusChanged);
    scancodefocusNode.removeListener(_handleFocusChanged);
    usernamefocusNode.dispose();
    passwordfocusNode.dispose();
    scancodefocusNode.dispose();
    super.dispose();
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
          TextPosition(
            affinity: TextAffinity.downstream,
            offset: newvalue.length,
          ),
        ),
      );
      FocusScope.of(context).requestFocus(selectedInputNode);
    }
  }

  void delKey() {
    if (selectedInput != null && selectedInput.text != '') {
      var newvalue = selectedInput.text.substring(
        0,
        selectedInput.text.length - 1,
      );

      selectedInput.value = selectedInput.value.copyWith(
        text: newvalue,
        selection: TextSelection.fromPosition(
          TextPosition(
            affinity: TextAffinity.downstream,
            offset: newvalue.length,
          ),
        ),
      );
      FocusScope.of(context).requestFocus(selectedInputNode);
    }
  }

  void clearKey() {
    if (selectedInput != null) {
      selectedInput.clear();
    }
  }

  void toggleKeyboard() {
    setState(() {
      showKeyboard = !showKeyboard;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        alignment: Alignment.topCenter,
        width: 1.sw,
        height: 1.sh,
        padding: EdgeInsets.only(left: 57.w, right: 57.w),
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/login-bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 1806.w,
              height: 108.h,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('images/login-title.png'),
                ),
              ),
            ),
            Center(
              child: Container(
                width: 892.w,
                height: 506.h,
                margin: EdgeInsets.only(top: 154.h),
                padding: EdgeInsets.only(top: 46.h, left: 92.w, right: 92.w),
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('images/login-form-bg.png'),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '欢迎使用MES作业端',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w400,
                        color: Color(0xffC1D3FF),
                      ),
                    ),
                    // 新增的按钮，用于弹出LoginModal
                    // ElevatedButton(
                    //   onPressed: () {
                    //     showDialog(
                    //       context: context,
                    //       builder: (BuildContext context) {
                    //         return LoginModal();
                    //       },
                    //     );
                    //   },
                    //   child: Text('打开登录弹窗'),
                    // ),
                    Form(
                      key: form,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(
                            width: 370.w,
                            child: Container(
                              // margin: EdgeInsets.only(right: 18.w, left: 18.w),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start, // 左对齐
                                children: [
                                  SizedBox(height: 36.h),
                                  usernameInput(username, usernamefocusNode),
                                  SizedBox(height: 24.h),
                                  passwordInput(password, passwordfocusNode),
                                  SizedBox(height: 24.h),
                                  scancodeInput(scancode, scancodefocusNode),
                                  SizedBox(height: 22.h),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // 退出按钮
                                      SizedBox(
                                        width: 175.w,
                                        height: 56.h,
                                        child: ExitBtn(),
                                      ),
                                      // 登录按钮
                                      SizedBox(
                                        width: 195.w,
                                        height: 76.h,
                                        child: LoginBtn(
                                          username: username,
                                          password: password,
                                          scancode: scancode,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 338.w,
                            child: Container(
                              // alignment: Alignment.topLeft,
                              margin: EdgeInsets.only(left: 14.w),
                              padding: EdgeInsets.only(top: 30.h),
                              child: showKeyboard
                                  ? Wrap(
                                      children: [
                                        // 用循环生成小键盘按钮
                                        ...[
                                          {
                                            'label': '7',
                                            'onTap': () => handleKey('7'),
                                          },
                                          {
                                            'label': '8',
                                            'onTap': () => handleKey('8'),
                                          },
                                          {
                                            'label': '9',
                                            'onTap': () => handleKey('9'),
                                          },
                                          {
                                            'label': '4',
                                            'onTap': () => handleKey('4'),
                                          },
                                          {
                                            'label': '5',
                                            'onTap': () => handleKey('5'),
                                          },
                                          {
                                            'label': '6',
                                            'onTap': () => handleKey('6'),
                                          },
                                          {
                                            'label': '1',
                                            'onTap': () => handleKey('1'),
                                          },
                                          {
                                            'label': '2',
                                            'onTap': () => handleKey('2'),
                                          },
                                          {
                                            'label': '3',
                                            'onTap': () => handleKey('3'),
                                          },
                                          {
                                            'label': '0',
                                            'onTap': () => handleKey('0'),
                                          },
                                          {
                                            'label': '删除',
                                            'onTap': () => delKey(),
                                            'fontSize': 20.0,
                                          },
                                          {
                                            'label': '小键盘',
                                            'onTap': () => toggleKeyboard(),
                                            'fontSize': 20.0,
                                          },
                                        ].map(
                                          (btn) => KeyButton(
                                            label: btn['label'] as String,
                                            onTap: btn['onTap'] as VoidCallback,
                                            fontSize: btn['fontSize'] != null
                                                ? btn['fontSize'] as double
                                                : 24.0,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Container(), // 当showKeyboard为false时显示空容器
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Center(
              child: SizedBox(
                width: 892.w,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                      "当前版本：${versionNum}",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF3A6FCE),
                      ),
                    ),
                    Text(
                      "有效IP地址：${ipAddress}",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF3A6FCE),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginBtn extends StatefulWidget {
  final username;
  final password;
  final scancode;

  const LoginBtn({super.key, this.username, this.password, this.scancode});
  // const LoginBtn({super.key});

  @override
  State<LoginBtn> createState() => _LoginBtnState();
}

class _LoginBtnState extends State<LoginBtn> {
  var loginBtnImg = 'images/login-btn.png';

  //获取用户详情
  Future<void> getUserInfo() async {
    var response = await Request.get(
      "/mes-biz/api/mes/client/user/getBaseInfo",
    );

    if (response["success"]) {
      print('response${response}');
      var resData = response["data"] ?? {};
      var finalData = jsonDecode(LoginPrefs.getUserInfo() ?? '');
      finalData['employeeNo'] = resData['employeeNo'];
      finalData['employeeId'] = resData['id'];
      finalData['employeeName'] = resData['name'];
      finalData['orgId'] = resData['orgId'];

      LoginPrefs.saveUserInfo(jsonEncode(finalData));
      // LoginPrefs.saveChildUserInfo(jsonEncode(resData));
    } else {
      EasyLoading.showError(response["message"]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userModel = Provider.of<UserModel>(context);

    Future<void> loginBtnClick() async {
      // String feedURL = 'http://10.1.200.31:18090/mes/app/version';
      // await autoUpdater.setFeedURL(feedURL);
      // await autoUpdater.checkForUpdates();
      // await autoUpdater.setScheduledCheckInterval(3600);
      var scanCode = widget.scancode.text;
      var scanusername;
      var scanpassword;
      if (scanCode.toString().contains('|')) {
        var usernamearr = scanCode.toString().split("|");
        scanusername = usernamearr[0];
        scanpassword = usernamearr[1];
      }
      //获取设备信息uuid
      var identifyUuid = await InitUtilData.identityUUID();
      var sm4Resp = await InitUtilData.getInitUuid();
      var data = json.encode({
        "clientIdentity": identifyUuid,
        "platform": 'APP',
        'username': scanusername ?? widget.username.text,
        "password": scanpassword ?? widget.password.text,
      });
      final sm4Encrypt = SM4.encryptOutArray(
        data: data,
        key: sm4Resp["sm4key"],
        mode: SM4CryptoMode.ECB,
        padding: SM4PaddingMode.PKCS5,
      );
      final result = base64.encode(sm4Encrypt);

      loginThen(res) async {
        if (res == "40114" || res == "40111") {
          print(res);
        } else if (res['success']) {
          // print(jsonEncode(res)),
          // print('dengluxinxi'),
          EasyLoading.showSuccess("登录成功");
          LoginPrefs.saveToken(res["data"]["loginToken"]["access_token"]);
          LoginPrefs.saveUserInfo(jsonEncode(res["data"]["loginUser"]));
          // 新增：保存当前时间戳
          LoginPrefs.saveLoginTime(DateTime.now().millisecondsSinceEpoch);
          await getUserInfo();
          userModel.setToken('123');
        } else {
          print(res['message']);
          EasyLoading.showError("登录失败:${res["message"]}");
        };
      }

      // if (Constant.isDev) {
      //   final loginFetch1 = await rootBundle.loadString('assets/login.json');
      //   loginThen(loginFetch1);
      // } else {
        // https://privatization-gateway-hf-dev.local.360humi.com/user-center/authentication/form
        final loginFetch2 = Request.post(
          "/dev/user-center/authentication/form",
          // data: result,
          data: data,
          headers:{
            'noConfer': 'true',
          }
        );
        loginFetch2.then((res) async => {
          loginThen(res)
        });
      // }
      // widget.changeToken();
    }

    ;

    return InkWell(
      onTap: () async {
        await loginBtnClick();
      },
      onHover: (value) {
        setState(() {
          loginBtnImg = value
              ? 'images/login-btn-hover.png'
              : "images/login-btn.png";
        });
      },
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(loginBtnImg),
            fit: BoxFit.fill,
          ),
        ),
        // child: Image(image: AssetImage(loginBtnImg), fit: BoxFit.fill),
      ),
    );
  }
}

OutlineInputBorder _outlineInputBorder = OutlineInputBorder(
  gapPadding: 0,
  borderSide: BorderSide(color: Color(0xff4b74dc)),
);

Widget usernameInput(TextEditingController username, focusNode) {
  return SizedBox(
    width: 360.w,
    child: TextFormField(
      controller: username,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Image(image: AssetImage('images/username-icon.png')),
        hintText: '请输入账号',
        hintStyle: TextStyle(color: Color(0xffC1D3FF)),
        border: _outlineInputBorder,
        focusedBorder: _outlineInputBorder,
        enabledBorder: _outlineInputBorder,
        disabledBorder: _outlineInputBorder,
        focusedErrorBorder: _outlineInputBorder,
        errorBorder: _outlineInputBorder,
        filled: true,
        fillColor: Color(0xFF050A32),
      ),

      // validator: (value) {
      //   if (value!.isEmpty) {
      //     return '用户名不能为空';
      //   }
      //   return null;
      // },
      focusNode: focusNode,
      onSaved: (v) => username.text = v!,
    ),
  );
}

Widget scancodeInput(TextEditingController password, focusNode) {
  return SizedBox(
    width: 360.w,
    child: TextFormField(
      obscureText: true,
      controller: password,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Image(image: AssetImage('images/scan-icon.png')),
        hintText: '扫码登录',
        hintStyle: TextStyle(color: Color(0xffC1D3FF)),
        border: _outlineInputBorder,
        focusedBorder: _outlineInputBorder,
        enabledBorder: _outlineInputBorder,
        disabledBorder: _outlineInputBorder,
        focusedErrorBorder: _outlineInputBorder,
        errorBorder: _outlineInputBorder,
        filled: true,
        fillColor: Color(0xFF050A32),
      ),

      // onSaved: (v) => _email = v!,
      focusNode: focusNode,
    ),
  );
}

Widget passwordInput(TextEditingController password, focusNode) {
  return SizedBox(
    width: 360.w,
    child: TextFormField(
      obscureText: true,
      controller: password,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Image(image: AssetImage('images/password-icon.png')),
        hintText: '请输入登录密码',
        hintStyle: TextStyle(color: Color(0xffC1D3FF)),
        border: _outlineInputBorder,
        focusedBorder: _outlineInputBorder,
        enabledBorder: _outlineInputBorder,
        disabledBorder: _outlineInputBorder,
        focusedErrorBorder: _outlineInputBorder,
        errorBorder: _outlineInputBorder,
        filled: true,
        fillColor: Color(0xFF050A32),
      ),
      focusNode: focusNode,
      // onSaved: (v) => _email = v!,
    ),
  );
}

class ExitBtn extends StatefulWidget {
  const ExitBtn({super.key});

  @override
  State<ExitBtn> createState() => _ExitBtnState();
}

class _ExitBtnState extends State<ExitBtn> {
  var exitBtnImg = 'images/login-exit.png';

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // 退出应用程序
        // SystemNavigator.pop();
        exit(0);
      },
      onHover: (value) {
        setState(() {
          // 如果有hover状态的图片，可以在这里切换
          // exitBtnImg = value ? 'images/btn-tuichu-active.png' : 'images/btn-tuichu.png';
        });
      },
      child: Container(
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/login-exit.png'),
            fit: BoxFit.fill,
          ),
        ),
      ),
    );
  }
}

// 小键盘按钮组件
class KeyButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final double fontSize;

  const KeyButton({
    Key? key,
    required this.label,
    required this.onTap,
    this.fontSize = 24,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: EdgeInsets.only(bottom: 10.h),
        width: 108.w,
        height: 76.h,
        child: Text(
          label,
          style: TextStyle(
            color: Color(0xFFC1D3FF),
            fontSize: fontSize.sp,
            fontWeight: FontWeight.w400,
          ),
        ),
        decoration: const BoxDecoration(
          image: DecorationImage(image: AssetImage('images/key-card.png')),
        ),
      ),
    );
  }
}
