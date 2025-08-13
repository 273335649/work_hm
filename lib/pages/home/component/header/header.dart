import 'package:flutter/material.dart';
import '../../../../../common/login_prefs.dart';
import 'package:flutter_windows_android_app/pages/home/home.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../../../../common/dio_request.dart';
import 'dart:async';
import "package:dart_amqp/dart_amqp.dart";
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../component/global_dialog.dart';
import 'dart:io';
import '../../constants.dart';

// int activeIndex = 0;

//头部导航
class HeaderMenu extends StatefulWidget {
  const HeaderMenu({super.key});

  @override
  State<HeaderMenu> createState() => _HeaderMenuState();
}

class _HeaderMenuState extends State<HeaderMenu> {
  int activeIndex = 0;
  String tecnoticeCount = '0';
  late final UserModel _userModel;
  late Client client;
  late Client client2;
  var logString = '';
  var warnString = '';

  @override
  void initState() {
    _userModel = Provider.of<UserModel>(context, listen: false);
    super.initState();
    _userModel.saveTecnoticeCountFn(() => {getTecnoticeCount()});
    getTecnoticeCount();
    getWarnInfo();
    startTimer();
    initmq();
  }

  @override
  void dispose() {
    // 移除监听器

    stopTimer();
    client.close();
    client2.close();
    super.dispose();
  }

  var myTimer;
  var myTimer2;
  void startTimer() {
    // 创建周期性定时器，每500毫秒执行一次
    myTimer = Timer.periodic(Duration(milliseconds: 60000), (timer) async {
      await getTecnoticeCount();
    });
    myTimer2 = Timer.periodic(Duration(milliseconds: 10000), (timer) async {
      await getWarnInfo();
    });
  }

  void stopTimer() {
    // 取消定时器
    if (myTimer != null) {
      myTimer.cancel();
      myTimer = null;
    }
    if (myTimer2 != null) {
      myTimer2.cancel();
      myTimer2 = null;
    }
  }

  Future initmq() async {
    var infoData = jsonDecode(LoginPrefs.getUserInfo() ?? '');
    print('infoData${infoData}');
    // var autoinfoData = jsonDecode(LoginPrefs.getAutoUserInfo() ?? '');
    print('链接mq！！！！！and');
    print("qu_linecode_${infoData['employeeId']}_${infoData['lineId']}");
    ConnectionSettings settings = ConnectionSettings(
      // host: "172.16.201.62", //生产
      host: "192.168.10.112", //测试
      virtualHost: '/humi-mes-v1',
      // authProvider:
      //     PlainAuthenticator("hmmquser", "PJexCWZ8PjxG2kMax2NM")); //生产
      authProvider: PlainAuthenticator("humi-mes-v1", "humi-mes-v1"),
    ); //测试
    client = Client(settings: settings);
    Channel channel = await client.channel();

    Exchange exchange = await channel.exchange(
      "EX_MES_ANDON",
      durable: true,
      ExchangeType.FANOUT,
    );

    var consumer = await exchange.bindQueueConsumer(
      "qu_${infoData['lineId']}_${infoData['mac']}_andon",
      [''],
      autoDelete: true,
    );
    // Queue queue = await channel.queue(
    //     "qu_${infoData['lineId']}_${infoData['mac']}_andon",
    //     autoDelete: true);
    // var consumer = await queue.consume();
    print('consumer:${consumer.tag}');
    consumer.listen((AmqpMessage message) async {
      print(" [x] Received string: ${message.payloadAsString}");
      print("scx:${infoData['lineCode']} gwh:${infoData['stationCode']}");
      var response = message.payloadAsString;
      print('mq接受：${response}');
      if (response.contains(infoData['employeeId'])) {
        print('加1加1${_userModel.andonCount}');
        _userModel.setAndonCount(_userModel.andonCount + 1);
      } else {
        print('不归我管');
      }

      // Or unserialize to json
      // print(" [x] Received json: ${message.payloadAsJson}");

      // Or just get the raw data as a Uint8List
      // print(" [x] Received raw: ${message.payload}");
    });

    client2 = Client(settings: settings);
    Channel channel2 = await client2.channel();
    Exchange exchange2 = await channel2.exchange(
      "EX_OP_LOG",
      durable: true,
      ExchangeType.FANOUT,
    );

    var consumer2 = await exchange2.bindQueueConsumer(
      "qu_${infoData['lineId']}_${infoData['mac']}_log",
      [''],
      autoDelete: true,
    );
    // Queue queue2 = await channel2
    //     .queue("qu_${infoData['lineId']}_${infoData['mac']}", autoDelete: true);
    // var consumer2 = await queue2.consume();
    // print('consumer2:${consumer2.tag}');
    consumer2.listen((AmqpMessage message2) async {
      print(" [x] Received string12222: ${message2.payloadAsString}");
      var response2 = message2.payloadAsJson;

      print('mq2接受：${response2}');
      setState(() {
        logString = response2['description'];
      });
      // if (response.contains(infoData['employeeId'])) {
      //   print('加1加1${_userModel.andonCount}');
      //   _userModel.setAndonCount(_userModel.andonCount + 1);
      // } else {
      //   print('不归我管');
      // }
    });
  }

  Future<void> getTecnoticeCount() async {
    var infoData = jsonDecode(LoginPrefs.getUserInfo() ?? '');
    // print(infoData);
    var params = {'staticId': infoData['stationId'], 'status': 0};
    // print('技术通知数量请求参数${params}');
    var response = await Request.get(
      '/mes-biz/api/tecnotice/countByStationStatus',
      params: params,
      isShow: false,
    );
    // print('数量${response}');
    if (response['success']) {
      setState(() {
        tecnoticeCount = response['data'].toString();
      });
    }
  }

  Future<void> getWarnInfo() async {
    var infoData = jsonDecode(LoginPrefs.getUserInfo() ?? '');
    // print(infoData);
    var params = {'lineId': infoData['lineId']};
    // print('${params}133333');
    // print('技术通知数量请求参数${params}');
    var response = await Request.get(
      '/mes-biz/api/cuttingtool/warning',
      params: params,
      isShow: false,
    );

    // print('数量${response}');
    if (response['success']) {
      setState(() {
        warnString = response['data']??[]
            .map(
              (item) =>
                  '${item['orgName']}产线,${item['fmachineCode']}设备,${item['fdronlyCode']}刀具寿命预警,请及时处理',
              // {
              //     'orgName': item['orgName'],
              //     'fmachineCode': item['fmachineCode'],
              //     'fdronlyCode': item['fdronlyCode']
              //   }
            )
            .join(' , ');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userModel = Provider.of<UserModel>(context);
    var userInfo = jsonDecode(LoginPrefs.getUserInfo() ?? '');

    List<Widget> _buildTabItems() {
      return tabData.asMap().entries.map((entry) {
        int index = entry.key;
        var item = entry.value;
        return Padding(
          padding: EdgeInsets.only(right: 30.w),
          child: InkWell(
            onTap: () {
              setState(() {
                userModel.setActiveIndex(index);
                activeIndex = index;
              });
            },
            highlightColor: Colors.transparent, // 透明色
            splashColor: Colors.transparent,
            child: Image(
              width: 72.w,
              height: 80.h,
              image: AssetImage(
                '${item['icon']}${activeIndex == index ? '-active' : ''}.png',
              ),
              fit: BoxFit.cover,
            ),
          ),
        );
      }).toList();
    }

    return Column(
      children: [
        Container(
          width: 1.sw,
          height: 80.h,
          padding: EdgeInsets.only(left: 490.w),
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('images/home-header.png'),
              fit: BoxFit.fill,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  ..._buildTabItems(),
                  const Spacer(), // 添加Spacer将后续元素推到右侧
                  Padding(
                    padding: EdgeInsets.only(right: 30.w),
                    child: InkWell(
                      onTap: () {
                        // 最小化逻辑
                        // SystemNavigator.pop();
                        GlobalDialog.show(context, '提示', '是否最小化');
                      },
                      highlightColor: Colors.transparent,
                      splashColor: Colors.transparent,
                      child: Image(
                        width: 72.w,
                        height: 80.h,
                        image: AssetImage('images/btn-zuixiaohua.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(right: 30.w),
                    child: InkWell(
                      onTap: () {
                        // 退出逻辑
                        print('退出逻辑');
                        exit(0);
                      },
                      highlightColor: Colors.transparent,
                      splashColor: Colors.transparent,
                      child: Image(
                        width: 72.w,
                        height: 80.h,
                        image: AssetImage('images/btn-tuichu.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Row(
          children: [
            Container(
              width: 1850.w,
              margin: EdgeInsets.only(left: 30.w, top: 2.h),
              child: Text(
                overflow: TextOverflow.ellipsis,
                // logString,
                warnString,
                style: TextStyle(color: Colors.white, fontSize: 20.sp),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Container(
              width: 1850.w,
              margin: EdgeInsets.only(left: 30.w, top: 2.h),
              child: Text(
                overflow: TextOverflow.ellipsis,
                logString,
                style: TextStyle(color: Colors.white, fontSize: 20.sp),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
