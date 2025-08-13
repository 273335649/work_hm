import 'package:flutter/material.dart';
import '../../common//dio_request.dart';
import 'package:provider/provider.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../../common/login_prefs.dart';
import 'dart:convert';

const tableTextStyle = TextStyle(
  color: Colors.white,
  fontSize: 22,
);

class Log extends StatefulWidget {
  const Log({super.key});

  @override
  State<Log> createState() => _LogState();
}

class _LogState extends State<Log> {
  // late final ScrollController _scrollController;
  @override
  Widget build(BuildContext context) {
    return Container(
        width: 1340,
        height: 780,
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
        ),
        child: MyTable());
  }
}

class MyTable extends StatefulWidget {
  const MyTable({super.key});

  @override
  State<MyTable> createState() => _MyTableState();
}

class _MyTableState extends State<MyTable> {
  var current = 1;
  var total = 0;
  var submitItems;
  var detailData;
  List<DataRow> dataSource = [];

  void changeItems(items) {
    submitItems = items;
    print('外部打印${items}');
  }

  void closeModal() {
    // Navigator.of(context).pop();
    Navigator.of(context).pop();
  }

  Future<void> getTableData() async {
    var finalData = jsonDecode(LoginPrefs.getUserInfo() ?? '');

    print(finalData['lineId']);
    var response = await Request.get(
        "/mes-biz/api/operationLog/page/${current}/10",
        isShow: false,
        params: {
          "size": 10,
          'page': current,
          'lineName': finalData['lineName'],
          'lineId': finalData['lineId']
        });

    if (response["success"]) {
      List resData = response["data"]['records'] ?? [];
      total = response["data"]['total'];
      current = response["data"]['current'];
      print('查看接口数据 ${response}');
      dataSource = resData
          .map((rowdata) => DataRow.byIndex(
                  index: int.tryParse(rowdata['id']),
                  // onSelectChanged: (value) async {
                  //   print('点击${rowdata['items']}');
                  //   var items = await getDetail(rowdata['id']);
                  //   showDialogFunction(context, {
                  //     'width': 1144.0,
                  //     'height': 500.0,
                  //     'title': '执行维保',
                  //     'okText': '确定',
                  //     'content': ModalContent(
                  //         rowdata: items, changeItems: changeItems),
                  //     'onSubmit': () {
                  //       return submitDetail(rowdata, 1);
                  //     },
                  //     'expentBtn': OutlinedButton(
                  //         onPressed: () {
                  //           closeModal();
                  //           print('维保异常');
                  //           showDialogFunction(context, {
                  //             'width': 1144.0,
                  //             'height': 500.0,
                  //             'title': '设备异常呼叫',
                  //             'okText': '确定',
                  //             'content': MaintenanceModal(),
                  //             'onSubmit': () {
                  //               return submitDetail(rowdata, 2);
                  //             },
                  //           });
                  //         },
                  //         style: OutlinedButton.styleFrom(
                  //             fixedSize: Size(152, 54),
                  //             shape: RoundedRectangleBorder(
                  //               borderRadius: BorderRadius.circular(3),
                  //             ),
                  //             side: const BorderSide(
                  //                 width: 1, color: Color(0xffb52929)),
                  //             // shadowColor: Color.fromARGB(135, 0, 133, 255),
                  //             // elevation: 5.0,
                  //             backgroundColor:
                  //                 const Color.fromARGB(40, 245, 46, 46)),
                  //         child: Text(
                  //           '维保异常',
                  //           style: TextStyle(
                  //               color: Colors.white,
                  //               fontSize: 24,
                  //               fontWeight: FontWeight.w700),
                  //         )),
                  //   });
                  // },
                  cells: [
                    DataCell(Text(
                        rowdata['createTime'].toString() != 'null'
                            ? rowdata['createTime'].toString()
                            : '-',
                        style: tableTextStyle)),
                    DataCell(Text(
                        rowdata['title'].toString() != 'null'
                            ? rowdata['title'].toString()
                            : '-',
                        style: tableTextStyle)),
                    DataCell(Text(
                        rowdata['description'].toString() != 'null'
                            ? rowdata['description'].toString()
                            : '-',
                        style: tableTextStyle)),
                  ]))
          .toList();

      // setState(() {});
    } else {
      EasyLoading.showError('${response['message']}');
    }
  }

  Future getDetail(id) async {
    var infoData = jsonDecode(LoginPrefs.getUserInfo() ?? '');
    print('用户信息：${infoData}');
    // print('列表详情：${rowdata}');

    var params = {
      "id": id,
    };
    print('接口提交信息${params}');

    var response =
        await Request.get("/mes-eam/maintain/task/detail", params: params);
    if (response["success"]) {
      // var resData = response["data"] ?? {};

      print(response);
      detailData = response['data'];

      return response['data'];
    } else {
      EasyLoading.showError(response["message"]);
      return {};
    }
  }

  Future submitDetail(rowdata, maintainStatus) async {
    var infoData = jsonDecode(LoginPrefs.getUserInfo() ?? '');
    print('用户信息：${infoData}');
    print('列表详情：${submitItems}');
    var newitems = submitItems
        .map((item) => {
              "description": item['description'],
              "name": item['description'],
              "remark": item['remark'],
              "result": item['submit'] == true ? '已保养' : '未保养'
            })
        .toList();
    var params = {
      "attachment": detailData['attachment'],
      "id": rowdata['id'],
      "items": newitems,
      "maintainStatus": maintainStatus
    };
    print('接口提交信息${params}');

    var response =
        await Request.post("/mes-eam/maintain/task/maintain", data: params);
    if (response["success"]) {
      // var resData = response["data"] ?? {};

      EasyLoading.showSuccess(response["message"]);
      print(response);

      getTableData();
      return true;
    } else {
      EasyLoading.showError(response["message"]);
      return false;
    }
  }

  ScrollController _scrollController = ScrollController();
  @override
  void initState() {
    // TODO: implement initState
    getTableData();
    super.initState();
    _scrollController.addListener(() {
      // 当滚动位置改变时，这个回调会被触发
      double offset = _scrollController.offset;
      // 使用offset做你需要的操作
    });
  }

  @override
  void dispose() {
    _scrollController.dispose(); // 释放资源
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Flex(
        direction: Axis.vertical,
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
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
            trackVisibility: true,
            child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: 20),
                // primary: true,
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                child: DataTable(
                    showCheckboxColumn: false,
                    headingRowHeight: 62,
                    dataRowMinHeight: 62,
                    dataRowMaxHeight: 62,
                    border: TableBorder.all(color: Color(0xff001b44), width: 2),
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
                          label: SizedBox(
                        width: 200,
                        child: Text(
                          '时间',
                        ),
                      )),
                      DataColumn(
                          label: SizedBox(
                        width: 200,
                        child: Text(
                          '日志类型',
                        ),
                      )),
                      DataColumn(
                          label: SizedBox(
                        width: 800,
                        child: Text(
                          '日志内容',
                        ),
                      )),
                    ],
                    rows: dataSource)),
          )),
          Container(
            width: 1340,
            height: 56,
            padding: EdgeInsets.only(left: 24, right: 24, top: 12, bottom: 12),
            color: Color.fromARGB(45, 31, 94, 255),
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
                    Text('${current}',
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
                      color: Color(0xffc54a1ff),
                      icon: Icon(Icons.chevron_right),
                      onPressed: () {
                        print('下一页');
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
