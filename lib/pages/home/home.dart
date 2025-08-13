import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_windows_android_app/component/RealTimeClock.dart';
import 'component/header/header.dart';
import 'package:provider/provider.dart';
import 'dart:async';
// import '../productionOrder/index.dart';
// import '../demo/index.dart';
// import '../manualMachining/index.dart';
// import '../processInquiry/index.dart';
// import '../technicalNotices/index.dart';
// import '../unqualified/index.dart';
// import '../review/index.dart';
// import '../call/index.dart';
// import '../response/index.dart';
// import '../maintenance/index.dart';
// import '../leftCard/index.dart';
// import '../log/index.dart';
import 'package:flutter_windows_android_app/utils/init.dart';
import '../../common/login_prefs.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../component/webview_component.dart';
import './constants.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final GlobalKey<WebViewComponentState> _webViewKey = GlobalKey();
  String userName = '';
  String versionNum = '';

  Future<String> getVersionFromPubspec() async {
    try {
      final version = await InitUtilData.getVersionFromPubspec();
      setState(() {
        versionNum = version;
      });
      return version;
    } catch (e) {
      print('Error reading version from pubspec.yaml: $e');
      return '';
    }
  }

  @override
  void initState() {
    super.initState();
    getVersionFromPubspec();
    // 初始化数据
    print('登录名${LoginPrefs.getUserInfo()}');
    // userName = LoginPrefs.getUserInfo()['username'];
  }

  void _refreshPage() {
    final userModel = Provider.of<UserModel>(context, listen: false);
    final isH5 = tabData[userModel.activeIndex]['type'] == PageType.h5;
    if (isH5) {
      _webViewKey.currentState?.reloadWebView();
    } else {
      setState(() {});
    }
  }
  @override
  Widget build(BuildContext context) {
    TextEditingController username = TextEditingController();
    final userinfo = jsonDecode(LoginPrefs.getUserInfo() ?? '');
    final userModel = Provider.of<UserModel>(context);
  print('userModel${userModel.info}');
    return Stack(
        children: [
          Container(width: 1.sw, height: 1.sh, color: const Color(0xff001030)),
          // 顶部
          HeaderMenu(),
          Container(
            // width: 1340,
            height: MediaQuery.of(context).size.height,
            margin: EdgeInsets.only(top: 80.h),
            // decoration: const BoxDecoration(
            //   image: DecorationImage(
            //     image: AssetImage('images/table-card-bgc.png'),
            //     fit: BoxFit.fill,
            //   ),
            // ),
            child: Pages(webViewKey: _webViewKey),
          ),
          // 底部
          Container(
            height: 20.h,
            width: 1860.w,
            // color: Colors.red,
            margin: EdgeInsets.only(left: 20.w, top: 1.sh - 20.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // TimeWidget(), // TODO 每秒更新时间
                RealTimeClock(),
                Text(
                  ' |   登录人：${userinfo['username']}   |   产线：${userinfo['lineName']??'-'}   工位：${userModel.info['stationId']?['name']??'-'}',
                  style: TextStyle(color: Color(0xFF3A6FCE), fontSize: 14.sp),
                ),
                Spacer(),
                InkWell(
                  onTap: _refreshPage,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Icon(
                        Icons.refresh,
                        size: 14.sp,
                        color: Color(0xFF3A6FCE),
                      ),
                      Text(
                        '刷新',
                        style: TextStyle(
                          color: Color(0xFF3A6FCE),
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                // Text(
                //   '当前版本：${versionNum}',
                //   style: TextStyle(color: Color(0xFFF3a6fce), fontSize: 14.sp),
                // ),
              ],
            ),
          ),
        ],
      );
  }
}

class Pages extends StatefulWidget {
  final GlobalKey<WebViewComponentState> webViewKey;
  const Pages({super.key, required this.webViewKey});

  @override
  State<Pages> createState() => _PagesState();
}

class _PagesState extends State<Pages> {
  WebViewComponent? _webViewInstance;
  int? _lastH5Index;

  @override
  Widget build(BuildContext context) {
    final userModel = Provider.of<UserModel>(context);
    final int activeIndex = userModel.activeIndex;
    final isH5 = tabData[activeIndex]['type'] == PageType.h5;

    // 只在切到h5页面时创建WebViewComponent
    if (isH5) {
      // 如果切换了h5页面，可以根据需要重建WebViewComponent或处理url
      if (_webViewInstance == null || _lastH5Index != activeIndex) {
        _lastH5Index = activeIndex;
        final userinfo = LoginPrefs.getUserInfo();
        _webViewInstance = WebViewComponent(
          key: widget.webViewKey,
          initialUrl: tabData[activeIndex]['url'] ?? '',
          localStorageData: userinfo,
        );
      }
    }

    return Column(
      children: [
        Container(
          width: 1.sw,
          height: 55.h,
          padding: EdgeInsets.only(top: 8.h, left: 68.w),
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('images/table-card-title.png'),
              fit: BoxFit.fill,
            ),
          ),
          child: Text(
            '${tabData[activeIndex]['title']}',
            style: TextStyle(
              fontSize: 28.sp,
              color: Color(0xffffffff),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              // WebViewComponent 只创建一次，切换到flutter页面时隐藏
              if (_webViewInstance != null)
                Offstage(offstage: !isH5, child: _webViewInstance!),
              // 非h5页面时渲染flutter widget
              if (!isH5) tabData[activeIndex]['widget'] ?? SizedBox.shrink(),
            ],
          ),
        ),
      ],
    );
  }
}

class UserModel extends ChangeNotifier {
  String token = '';
  String childToken = '';
  int activeIndex = 0;
  int andonCount = 0;

  Map info = {'lineId': '', 'stationId': ''};
  Map barcodeinfo = {};
  Map childInfo = {'name': ''};

  void setInfo(Map info) {
    this.info = info;
    notifyListeners();
  }

  void setBarcodeinfo(Map info) {
    barcodeinfo = info;
    notifyListeners();
  }

  void setChildInfo(Map childInfo) {
    this.childInfo = childInfo;
    notifyListeners();
  }

  void setToken(String token) {
    this.token = token;
    notifyListeners();
  }

  void setChildToken(String token) {
    childToken = token;
    notifyListeners();
  }
  //存储跨组件调用方法

  var fun;
  var begin;
  var focusFn;
  var getTecnoticeCountFn;
  var exportImageFn;
  //储存编辑图片函数
  void saveExportImageFn(fn) {
    exportImageFn = fn;

    // notifyListeners();
  }

  getExportImageFn() async {
    return await exportImageFn();

    // notifyListeners();
  }

  void saveTecnoticeCountFn(fn) {
    getTecnoticeCountFn = fn;

    // notifyListeners();
  }

  void getTecnoticeCount() {
    getTecnoticeCountFn();

    // notifyListeners();
  }

  void savefocusFn(fn) {
    focusFn = fn;

    // notifyListeners();
  }

  void saveRefreshFn(fn) {
    fun = fn;

    // notifyListeners();
  }

  void saveBeginFn(fn) {
    begin = fn;

    // notifyListeners();
  }

  void refreshfocus() {
    focusFn();

    // notifyListeners();
  }

  void refreshWeight() {
    fun();

    // notifyListeners();
  }

  void autoBegin() {
    print('999999${begin}');
    begin();

    // notifyListeners();
  }

  void setAndonCount(int index) {
    andonCount = index;
    notifyListeners();
  }

  void setActiveIndex(int index) {
    if (index != activeIndex) {
      childToken = '';
      childInfo = {'name': ''};
    }
    activeIndex = index;
    notifyListeners();
    print(index); // 当状态改变时，通知所有监听者
  }

  void clear() {
    print('clear');
    childToken = '';
    activeIndex = 0;
    token = '';
    info = {'processId': '', 'positionId': ''};
    childInfo = {'name': ''};
    barcodeinfo = {};
    notifyListeners();
  }
}
