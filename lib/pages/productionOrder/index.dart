import 'dart:async';
import 'package:flutter/material.dart';
import '../../common//dio_request.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../../common/login_prefs.dart';
import 'dart:convert';

import "package:dart_amqp/dart_amqp.dart";

var colorList = {
  '1': 0xFFFC955F,
  '2': 0xFF18FEFE,
  '3': 0xFFE24F42,
  '5': 0x7DFFFFFF,
  '6': 0xFFE43449,
};

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

class ProductionOrder extends StatefulWidget {
  const ProductionOrder({super.key});

  @override
  State<ProductionOrder> createState() => _ProductionOrderState();
}

class _ProductionOrderState extends State<ProductionOrder> {
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
  final ScrollController _scrollController = ScrollController();
  // late VoidCallback _listener;
  // late final UserModel _userModel;
  String positionId = '';
  late Client client;
  late final Debouncer debouncer;

  var myTimer;
  var apiBool = false;

  void startTimer() {
    myTimer = Timer.periodic(Duration(milliseconds: 1000), (timer) async {
      print('${apiBool}定时器api加载了');
      if (!apiBool) {
        apiBool = true;
        await getTableData();
      }
    });

    // 创建周期性定时器，每500毫秒执行一次
  }

  void stopTimer() {
    // 取消定时器
    if (myTimer != null) {
      myTimer.cancel();
      myTimer = null;
    }
  }

  // void _onUserModelChange() {
  //   if (positionId != _userModel.info['positionId']['id']) {
  //     print('监听执行了${_userModel.info}${positionId}');
  //     getTableData();
  //   }
  // }

  @override
  void initState() {
    super.initState();
    // 初始化数据
    getTableData();
    apiBool = true;
    // startTimer();
    // _userModel = Provider.of<UserModel>(context, listen: false);
    // print('123445555${_userModel.info}');
    // positionId = _userModel.info['positionId']['id'];
    // _userModel.addListener(_onUserModelChange);

    //test

    // debouncer = Debouncer(Duration(milliseconds: 500), getTableData);
    // initmq();

    //test
    // myProvider.addListener(() {
    //   // 当值变化时，调用 getTableData
    //   getTableData();
    // });
    _scrollController.addListener(() {
      // 当滚动位置改变时，这个回调会被触发
      // double offset = _scrollController.offset;
      // 使用offset做你需要的操作
    });
  }

  @override
  bool get mounted {
    // _userModel.saveRefreshFn(() => {current = 1, getTableData()});
    return super.mounted;
  }

  @override
  void deactivate() {
    apiBool = false;
    // print('销毁页面………………');
    _scrollController.dispose(); // 释放资源
    // client.close();
    stopTimer();
    // debouncer.dispose();
    // _userModel.saveRefreshFn(() => {print('方法清除')});
    // _userModel.removeListener(_onUserModelChange);

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
      //500ms防抖刷新页面
      // debouncer.call();
      //刷新页面
      // if (response['eventType'] == '8') {
      // await getTableData();
      // }
      // username.text = '123';
      // if (response['scx'] == infoData['lineCode'] &&
      //     response['gwh'] == autoinfoData['stationCode'] &&
      //     response['ishege'] == 'TRUE') {
      //   username.value = username.value.copyWith(
      //     text: response['engineNo'],
      //   );
      //   var res = await autoGetDetails();
      //   print('自动查询结果：${res}');
      //   if (res != null) {
      //     await autoSubmitDetail(1);
      //   }
      // }

      // // Or unserialize to json
      // print(" [x] Received json: ${message.payloadAsJson}");

      // // Or just get the raw data as a Uint8List
      // print(" [x] Received raw: ${message.payload}");
    });
  }

  Future<void> getTableData() async {
    var finalData = jsonDecode(LoginPrefs.getUserInfo() ?? '');
    var statusList = {
      '1': '合格',
      '2': '待定',
      '3': '不合格',
      '5': '评审',
      '6': '报废',
    };
    // print({
    //   'lineId': finalData["processCode"] + '-' + finalData["processName"],
    //   'employeeId': finalData['employeeId'],
    //   'processId': finalData['processId'],
    //   'equipmentId': finalData['equipmentId']
    // });
    print(finalData);
    print(
        'getCurrentTaskRecordPage______${DateTime.now().millisecondsSinceEpoch}___${finalData['equipmentId']}');

    var response = await Request.get(
        "/mes-biz/api/mes/client/task/getCurrentTaskRecordPage/${current}/10",
        params: {
          'lineId': finalData['lineId'],
          'employeeId': finalData['employeeId'],
          'processId': finalData['processId'],
          'equipmentId': finalData['equipmentId']
        },
        isShow: false);
    // print('接口返回：${response}');
    apiBool = false; //接口请求完成
    if (response["success"]) {
      positionId = finalData["stationId"];
      List resData = response["data"]['workLogs']['records'] ?? [];
      dataInfo['shift'] = response["data"]['shift'];
      dataInfo['finishQty'] = response["data"]['finishQty'].toString();
      dataInfo['stationName'] = finalData["stationName"];
      dataInfo['processName'] =
          finalData["processCode"] + '-' + finalData["processName"];
      dataInfo['qualifiedQty'] = response["data"]['qualifiedQty'].toString();
      dataInfo['unqualifiedQty'] =
          response["data"]['unqualifiedQty'].toString();
      dataInfo['reviewQty'] = response["data"]['reviewQty'].toString();
      dataInfo['pendingQty'] = response["data"]['pendingQty'].toString();
      total = response["data"]['workLogs']['total'];
      current = response["data"]['workLogs']['current'];

      for (var i = 0; i < resData.length; i++) {
        resData[i]['key'] = i;

        // arrList.add(resData[i]);
      }

      dataSource = resData
          .map((rowdata) => DataRow.byIndex(
                  index: rowdata['key'],
                  // onSelectChanged: (value) {
                  //   print('点击${rowdata['id']}');
                  // },
                  cells: [
                    DataCell(Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                            rowdata['barcode'].toString() != 'null'
                                ? rowdata['barcode'].toString()
                                : '-',
                            style: tableTextStyle),
                        SizedBox(
                          width: 8.5,
                        ),
                        rowdata['reworkFlag'] == 1
                            ? Container(
                                alignment: Alignment.center,
                                width: 60,
                                height: 30,
                                decoration: BoxDecoration(
                                    color: Color(0x8FDC9E00),
                                    border: Border.all(
                                        color: Color(0x8FDC9E00), width: 1)),
                                child: Text(
                                  '返工',
                                  style: TextStyle(color: Colors.white),
                                ),
                              )
                            : Container(),
                        rowdata['reworkFlag'] == 2
                            ? Container(
                                alignment: Alignment.center,
                                width: 60,
                                height: 30,
                                decoration: BoxDecoration(
                                    color: const Color(0x4DFF0000),
                                    border: Border.all(
                                        color: const Color(0x4DFF0000),
                                        width: 1)),
                                child: const Text(
                                  '浸渗',
                                  style: TextStyle(color: Colors.white),
                                ),
                              )
                            : Container()
                      ],
                    )),
                    DataCell(Text(
                        rowdata['materialCode'].toString() != 'null'
                            ? rowdata['materialCode'].toString()
                            : '-',
                        style: tableTextStyle)),
                    DataCell(Text(
                        rowdata['materialName'].toString() != 'null'
                            ? rowdata['materialName'].toString()
                            : '-',
                        style: tableTextStyle)),
                    DataCell(Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 12.0, // 设置小圆点的宽度
                          height: 12.0, // 设置小圆点的高度
                          decoration: BoxDecoration(
                            shape: BoxShape.circle, // 设置形状为圆形
                            color: Color(colorList[rowdata['status']] ??
                                0xFFFFCC49), // 设置小圆点的颜色
                          ),
                        ),
                        SizedBox(
                          width: 8.5,
                        ),
                        Text(
                            rowdata['status'].toString() != 'null'
                                ? statusList[rowdata['status'].toString()]
                                    .toString()
                                : '-',
                            style: tableTextStyle)
                      ],
                    )),
                    DataCell(Text(
                        rowdata['createTime'].toString() != 'null'
                            ? rowdata['createTime'].toString()
                            : '-',
                        style: tableTextStyle)),
                  ]))
          .toList();
    } else {
      if (response['code'] == '777') {
      } else {
        EasyLoading.showError('${response['message']}');
      }
    }
    if (mounted) {
      setState(() {
        // 更新状态
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // return Consumer<UserModel>(builder: (context, myModel, child) {
    //   // print('1234566${isinit}');

    //   print('_userModel${_userModel?.info['positionId']['id']}');
    //   print('myModel${myModel.info}');
    //   if (_userModel != myModel) {
    //     _userModel = myModel;
    //     // getTableData();
    //   }
    // _userModel = Provider.of<UserModel>(context);
    return Flex(
        direction: Axis.vertical,
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            // height: 100,
            margin: EdgeInsets.all(2),
            // color: Colors.red,
            child: Column(children: [
              Row(
                children: [
                  Expanded(
                      flex: 1,
                      child: Row(
                        children: [
                          Text(
                            '班次:',
                            style: TextStyle(
                              color: Color(0xffC1D3FF),
                              fontSize: 24,
                            ),
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Text(
                            dataInfo['shift'] ?? '',
                            style: TextStyle(
                              color: Color(0xffC1D3FF),
                              fontSize: 24,
                            ),
                          ),
                        ],
                      )),
                  Expanded(
                      flex: 1,
                      child: Row(
                        children: [
                          Text(
                            '工序:',
                            style: TextStyle(
                              color: Color(0xffC1D3FF),
                              fontSize: 24,
                            ),
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Text(
                            dataInfo['processName'] ?? '',
                            style: TextStyle(
                              color: Color(0xffC1D3FF),
                              fontSize: 24,
                            ),
                          ),
                        ],
                      )),
                ],
              ),
              Row(
                children: [
                  Expanded(
                      flex: 1,
                      child: Row(
                        children: [
                          Text(
                            '岗位:',
                            style: TextStyle(
                              color: Color(0xffC1D3FF),
                              fontSize: 24,
                            ),
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Text(
                            dataInfo['stationName'] ?? '',
                            style: TextStyle(
                              color: Color(0xffC1D3FF),
                              fontSize: 24,
                            ),
                          ),
                        ],
                      )),
                  Expanded(
                      flex: 1,
                      child: Row(
                        children: [
                          Text(
                            '完成数量:',
                            style: TextStyle(
                              color: Color(0xffC1D3FF),
                              fontSize: 24,
                            ),
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Text(
                            dataInfo['finishQty'] ?? '',
                            style: TextStyle(
                              color: Color(0xffC1D3FF),
                              fontSize: 24,
                            ),
                          ),
                        ],
                      )),
                ],
              ),
              Row(
                children: [
                  Expanded(
                      flex: 1,
                      child: Row(
                        children: [
                          Text(
                            '合格数量:',
                            style: TextStyle(
                              color: Color(0xffC1D3FF),
                              fontSize: 24,
                            ),
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Text(
                            dataInfo['qualifiedQty'] ?? '',
                            style: TextStyle(
                              color: Color(0xffC1D3FF),
                              fontSize: 24,
                            ),
                          ),
                        ],
                      )),
                  Expanded(
                      flex: 1,
                      child: Row(
                        children: [
                          Text(
                            '不合格数量:',
                            style: TextStyle(
                              color: Color(0xffC1D3FF),
                              fontSize: 24,
                            ),
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Text(
                            dataInfo['unqualifiedQty'] ?? '',
                            style: TextStyle(
                              color: Color(0xffC1D3FF),
                              fontSize: 24,
                            ),
                          ),
                        ],
                      )),
                ],
              ),
              Row(
                children: [
                  Expanded(
                      flex: 1,
                      child: Row(
                        children: [
                          Text(
                            '评审数量:',
                            style: TextStyle(
                              color: Color(0xffC1D3FF),
                              fontSize: 24,
                            ),
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Text(
                            dataInfo['reviewQty'] ?? '',
                            style: TextStyle(
                              color: Color(0xffC1D3FF),
                              fontSize: 24,
                            ),
                          ),
                        ],
                      )),
                  Expanded(
                      flex: 1,
                      child: Row(
                        children: [
                          Text(
                            '待定数量:',
                            style: TextStyle(
                              color: Color(0xffC1D3FF),
                              fontSize: 24,
                            ),
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Text(
                            dataInfo['pendingQty'] ?? '',
                            style: TextStyle(
                              color: Color(0xffC1D3FF),
                              fontSize: 24,
                            ),
                          ),
                        ],
                      )),
                ],
              )
            ]),
          ),
          SizedBox(
            width: 1340,
            height: 500,
            child: Scrollbar(
              controller: _scrollController,
              // showTrackOnHover: true,

              /// 滚动条的宽度
              thickness: 12,

              /// 滚动条两端的圆角半径
              radius: const Radius.circular(11),

              /// 是否显示滚动条滑块
              thumbVisibility: true,

              /// 是否显示滚动条轨道
              trackVisibility: false,
              child: SingleChildScrollView(
                  padding: EdgeInsets.only(right: 20),
                  controller: _scrollController,
                  child: DataTable(
                      showCheckboxColumn: false,
                      headingRowHeight: 62,
                      dataRowMinHeight: 62,
                      dataRowMaxHeight: 62,
                      border: TableBorder.all(
                        color: Color(0xff001b44),
                        width: 2,
                      ),
                      dataRowColor: MaterialStateColor.resolveWith(
                          (states) => const Color.fromARGB(45, 31, 94, 255)),
                      headingRowColor: MaterialStateColor.resolveWith(
                          (states) => const Color.fromARGB(170, 0, 102, 255)),
                      headingTextStyle: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                      ),
                      columns: const [
                        DataColumn(
                            label: Text(
                          '产品件号',
                        )),
                        DataColumn(label: Text('状态编码')),
                        DataColumn(label: Text('产品名称')),
                        DataColumn(label: Text('状态')),
                        DataColumn(label: Text('创建时间')),
                      ],
                      rows: dataSource)),
            ),
          ),
          SizedBox(
            height: 20,
          ),
          Container(
            width: 1340,
            height: 56,
            margin: EdgeInsets.only(left: 2, right: 2),
            padding: EdgeInsets.only(left: 24, right: 24, top: 12, bottom: 12),
            color: Color.fromARGB(25, 31, 94, 255),
            child: Flex(
              direction: Axis.horizontal,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '共${total}条',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      color: Color(0xffc54a1ff),
                      icon: Icon(Icons.chevron_left),
                      onPressed: () {
                        print('上一页');
                        if (current > 1) {
                          current = current - 1;
                          setState(() {
                            getTableData();
                          });
                        }
                      },
                    ),
                    Text('$current',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                        )),
                    Text(
                        '/${(total / 10).ceil() == 0 ? 1 : (total / 10).ceil()}',
                        style: TextStyle(
                          color: Color.fromARGB(90, 255, 255, 255),
                          fontSize: 24,
                        )),
                    IconButton(
                      color: Color.fromRGBO(84, 161, 255, 0.988),
                      icon: Icon(Icons.chevron_right),
                      onPressed: () {
                        if (current < (total / 10).ceil()) {
                          current = current + 1;
                          setState(() {
                            getTableData();
                          });
                        }
                      },
                    ),
                  ],
                )
              ],
            ),
          )
        ]);
  }
}

const tableTextStyle = TextStyle(
  color: Colors.white,
  fontSize: 22,
);

// class MyTable extends StatefulWidget {
//   const MyTable({super.key});

//   @override
//   State<MyTable> createState() => _MyTableState();
// }

// class _MyTableState extends State<MyTable> {
//   TableDataSource datasource = TableDataSource();

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.all(Radius.circular(0.0)), // 设置圆角大小
//           border: Border.all(color: Colors.grey, width: 1.0), // 可选：设置边框
//         ),
//         child: PaginatedDataTable(
//           columns: <DataColumn>[
//             DataColumn(
//                 label: Container(
//               width: 298,
//               height: 64,
//               color: Colors.red,
//               child: Text('名字'),
//             )),
//             DataColumn(
//                 label: Container(
//               width: 298,
//               height: 64,
//               color: Colors.red,
//               child: Text('价格'),
//             )),
//             DataColumn(
//                 label: Container(
//               width: 298,
//               height: 64,
//               color: Colors.red,
//               child: Text('类型'),
//             )),
//             DataColumn(
//                 label: Container(
//               width: 100,
//               height: 64,
//               color: Colors.red,
//               child: Text('类型'),
//             )),
//             // DataColumn(
//             //     label: Container(
//             //   width: 100,
//             //   height: 64,
//             //   color: Colors.red,
//             //   child: Text('类型'),
//             // )),
//           ],
//           source: datasource,
//           // headingRowColor: MaterialStateColor.resolveWith((states) => Colors.blue),
//           rowsPerPage: 9,
//           headingRowHeight: 64,
//           dataRowMaxHeight: 64,
//           dataRowMinHeight: 64,

//           headingRowColor:
//               MaterialStateProperty.resolveWith((states) => Colors.black),
//         ));
//   }
// }

// class Shop {
//   final String name;
//   final int price;
//   final int china;
//   final int english;
//   final String type;

//   // 默认为未选中
//   bool selected = false;
//   Shop(this.name, this.price, this.type, this.china, this.english);
// }

// class TableDataSource extends DataTableSource {
//   final List<Shop> shops = <Shop>[
//     Shop('name', 100, '家电', 33, 44),
//     Shop('name2', 130, '手机', 33, 44),
//     Shop('三星', 130, '手机', 33, 44),
//     Shop('三星', 130, '手机', 33, 44),
//     Shop('三星', 130, '手机', 33, 44),
//     Shop('海信', 100, '家电', 33, 44),
//     Shop('TCL', 100, '家电', 33, 44),
//     Shop('海信', 100, '家电', 33, 44),
//     Shop('TCL', 100, '家电', 33, 44),
//     Shop('海信', 100, '家电', 33, 44),
//     Shop('TCL', 100, '家电', 33, 44),
//     Shop('海信', 100, '家电', 33, 44),
//     Shop('TCL', 100, '家电', 33, 44),
//     Shop('海信', 100, '家电', 33, 44),
//     Shop('TCL', 100, '家电', 33, 44),
//     Shop('海信', 100, '家电', 33, 44),
//   ];
//   int _selectedCount = 0;

//   @override
//   DataRow? getRow(int index) {
//     // TODO: implement getRow
//     Shop shop = shops.elementAt(index);
//     assert(index >= 0);
//     if (index >= shops.length) {
//       return null;
//     }
//     return DataRow.byIndex(
//       cells: <DataCell>[
//         DataCell(
//           Text('${shop.name}'),
//           placeholder: true,
//         ),
//         DataCell(Text('${shop.price}'), showEditIcon: false),
//         DataCell(Text('${shop.type}'), showEditIcon: false),
//         DataCell(Text('${shop.type}'), showEditIcon: false),
//       ],
//       selected: shop.selected,
//       index: index,
//     );
//   }

//   @override
//   // TODO: implement isRowCountApproximate
//   bool get isRowCountApproximate => false;

//   @override
//   // TODO: implement rowCount
//   int get rowCount => shops.length;

//   @override
//   // TODO: implement selectedRowCount
//   int get selectedRowCount => 0;
// }
