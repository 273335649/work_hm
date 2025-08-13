import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import './components/image_point_card.dart';
import '../../common//dio_request.dart';
import 'package:provider/provider.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_windows_android_app/common/login_prefs.dart';
import 'dart:convert';

import '../home/home.dart';
import "package:dart_amqp/dart_amqp.dart";

const fetchPoints = [
  {"x": 31.125000000000004, "y": 7.72367873491469},
  {"x": 19.375, "y": 40.21639617145235},
  {"x": 7.124999999999999, "y": 46.87473990844777},
  {"x": 17.125, "y": 72.44277985851019},
  {"x": 91.625, "y": 75.90511860174782},
];

//防抖函数
class Debouncer {
  Timer? _timer;
  Duration _wait;
  final VoidCallback _callback; // 使用 VoidCallback 替代 ValueCallback

  Debouncer(Duration wait, VoidCallback callback)
      : _wait = wait,
        _callback = callback {
    _timer = null;
  }

  void call() {
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
    }
    _timer = Timer(_wait, () => _callback());
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}

class Demo extends StatefulWidget {
  const Demo({super.key});

  @override
  State<Demo> createState() => _ProductionOrderState();
}

class _ProductionOrderState extends State<Demo> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1340,
      height: 780,
      padding: const EdgeInsets.all(20),
      child: MyTable(),
      // color: Colors.red,
    );
  }
}

class MyTable extends StatefulWidget {
  const MyTable({super.key});

  @override
  State<MyTable> createState() => _MyTableState();
}

class _MyTableState extends State<MyTable> {
  var fetchActiveIndex = 0;
  final ScrollController _scrollController = ScrollController();
  // late VoidCallback _listener;
  late final UserModel _userModel;
  String positionId = '';
  late Client client;
  late final Debouncer debouncer;

  var myTimer;
  var apiBool = false;

  @override
  void initState() {
    super.initState();
    // getPoints();
    // 初始化数据
    apiBool = true;
    _userModel = Provider.of<UserModel>(context, listen: false);
    _scrollController.addListener(() {
      // 当滚动位置改变时，这个回调会被触发
      double offset = _scrollController.offset;
      // 使用offset做你需要的操作
    });
  }

  @override
  bool get mounted {
    return super.mounted;
  }

  @override
  void deactivate() {
    apiBool = false;
    // print('销毁页面………………');
    _scrollController.dispose(); // 释放资源
    // client.close();
    super.deactivate();
  }

  var current = 1;
  var total = 0;

  List<DataRow> dataSource = [];
  var dataInfo = {};

  Future initmq() async {
    var infoData = jsonDecode(LoginPrefs.getUserInfo() ?? '');
    print('infoData${infoData}');
    // var autoinfoData = jsonDecode(LoginPrefs.getAutoUserInfo() ?? '');
    print('链接mq！！！！！');
    print("QU_MES2C_${infoData['lineId']}_${infoData['employeeId']}");
    ConnectionSettings settings = ConnectionSettings(
        // host: "172.16.201.62", //生产
        host: "192.168.10.112", //测试
        virtualHost: '/humi-mes-v1',
        // authProvider:PlainAuthenticator("hmmquser", "PJexCWZ8PjxG2kMax2NM")); //生产
        authProvider: PlainAuthenticator("humi-mes-v1", "humi-mes-v1")); //测试
    client = Client(settings: settings);
    Channel channel = await client.channel();

    Exchange exchange = await channel.exchange(
        "EX_MES_CHANGE_POINT", durable: true, ExchangeType.FANOUT);

    var consumer = await exchange.bindQueueConsumer(
        "QU_MES2C_${infoData['lineId']}_${infoData['employeeId']}_product",
        [''],
        autoDelete: true);
    // Queue queue = await channel.queue(
    //     "QU_MES2C_${infoData['lineId']}_${infoData['employeeId']}_productOrder");
    // var consumer = await queue.consume();
    consumer.listen((
      AmqpMessage message,
    ) async {
      print(" [x] Received string: ${message.payloadAsString}");
      print("scx:${infoData['lineCode']} gwh:${infoData['stationCode']}");
      var response = message.payloadAsJson;
      print('mq接受：${response['eventType']}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Flex(
        direction: Axis.vertical,
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(
            width: 1340,
            height: 500,
            child: Scrollbar(
              controller: _scrollController,

              /// 滚动条的宽度
              thickness: 12,

              /// 滚动条两端的圆角半径
              radius: const Radius.circular(11),

              /// 是否显示滚动条滑块
              thumbVisibility: true,

              /// 是否显示滚动条轨道
              trackVisibility: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(right: 20),
                controller: _scrollController,
                child: Column(
                  children: [
                    const Text("data2226",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                        )),
                    ImagePointCard(
                      activeIndex: fetchActiveIndex,
                      fetchPoints: fetchPoints,
                      imagePath: 'images/bg/bgt.jpg',
                      imageWidth: 400,
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          fetchActiveIndex =
                              (fetchActiveIndex + 1) % fetchPoints.length;
                        });
                      },
                      child: const Text("下一步"),
                    )
                  ],
                ),
              ),
            ),
          ),
          SizedBox(
            height: 20,
          ),
        ]);
  }
}

const tableTextStyle = TextStyle(
  color: Colors.white,
  fontSize: 22,
);
