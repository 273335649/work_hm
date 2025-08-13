import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'common/login_prefs.dart';
import '../../common/constant.dart';
import './pages/login/login.dart';
import './pages/home/home.dart';
import './pages/positionPage/index.dart';

void configLoading() {
  EasyLoading.instance
    ..indicatorSize = 50
    ..fontSize = 30
    ..displayDuration = const Duration(milliseconds: 5000);
}

Future<Map> getLocalMacAddress() async {
  try {
    List<String> macAddresses = [];
    String ipAddress = '未知';

    if (Platform.isWindows) {
      // Windows平台使用ipconfig命令
      try {
        ProcessResult process = Process.runSync('ipconfig', ['/all']);
        String output = process.stdout;
        List<String> lines = output.split('\r\n');

        var windowsMacAddresses = lines
            .where((element) => element.contains('物理地址'))
            .toList()
            .map((item) => item.split(':').last.trim())
            .toList();

        if (windowsMacAddresses.isNotEmpty) {
          macAddresses.addAll(windowsMacAddresses);
        }

        var windowsIP = lines
            .where((element) => element.contains('IPv4'))
            .toList()
            .last
            .split(':')
            .last
            .split('(')
            .first
            .trim();

        ipAddress = windowsIP;

        print('Windows物理地址：$windowsMacAddresses');
        print('Windows IP地址：$windowsIP');
      } catch (e) {
        print('Windows ipconfig命令执行失败: $e');
      }
    } else if (Platform.isAndroid) {
      // Android平台使用系统命令
      try {
        // 尝试获取网络接口信息
        ProcessResult process = Process.runSync('cat', [
          '/sys/class/net/wlan0/address',
        ]);
        if (process.exitCode == 0) {
          String mac = process.stdout.toString().trim();
          if (mac.isNotEmpty) {
            macAddresses.add(mac);
            print('Android WiFi MAC地址: $mac');
          }
        }
      } catch (e) {
        print('Android获取MAC地址失败: $e');
      }

      try {
        // 尝试获取IP地址
        ProcessResult process = Process.runSync('ip', [
          'route',
          'get',
          '8.8.8.8',
        ]);
        if (process.exitCode == 0) {
          String output = process.stdout.toString();
          // 解析输出获取源IP地址
          RegExp regex = RegExp(r'src\s+(\d+\.\d+\.\d+\.\d+)');
          Match? match = regex.firstMatch(output);
          if (match != null) {
            ipAddress = match.group(1) ?? '未知';
            print('Android IP地址: $ipAddress');
          }
        }
      } catch (e) {
        print('Android获取IP地址失败: $e');
      }

      // 如果上面的方法失败，尝试其他网络接口
      if (macAddresses.isEmpty) {
        try {
          List<String> interfaces = ['wlan0', 'wlan1', 'eth0', 'usb0'];
          for (String interface in interfaces) {
            try {
              ProcessResult process = Process.runSync('cat', [
                '/sys/class/net/$interface/address',
              ]);
              if (process.exitCode == 0) {
                String mac = process.stdout.toString().trim();
                if (mac.isNotEmpty) {
                  macAddresses.add(mac);
                  print('Android $interface MAC地址: $mac');
                  break;
                }
              }
            } catch (e) {
              continue;
            }
          }
        } catch (e) {
          print('Android获取网络接口MAC地址失败: $e');
        }
      }
    } else if (Platform.isIOS) {
      // iOS平台 - 由于权限限制，通常无法获取真实MAC地址
      print('iOS平台无法获取MAC地址（权限限制）');
      ipAddress = '127.0.0.1'; // 使用本地回环地址
    } else {
      // 其他平台
      print('不支持的平台: ${Platform.operatingSystem}');
    }

    print('最终MAC地址列表：$macAddresses');
    print('最终IP地址：$ipAddress');

    if (Constant.isDev) {
      print('最终MAC地址列表2：$macAddresses');
      return {
        'mac': ['A0-36-BC-22-8D-5C', '00-50-56-C0-00-01', '00-50-56-C0-00-08'],
        'ip': ipAddress,
      };
    } else {
      return {'mac': macAddresses, 'ip': ipAddress};
    }
  } catch (e) {
    print('获取网络信息时发生错误: $e');
    return {'mac': [], 'ip': '未知'};
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isAndroid) {
    await InAppWebViewController.setWebContentsDebuggingEnabled(
      true,
    ); // 启用调试模式（可选）
  }

  //热更新 TODO
  // String feedURL = '${Constant.baseUrlDev}/mes-biz/api/common/appVersion';
  //初始化尺寸 TODO

  await LoginPrefs.init();

  LoginPrefs.clearLogin();
  configLoading();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  var token;

  // void changeToken() {
  //   token = LoginPrefs.getToken();
  //   print('运行了change函数${token}');
  //   setState(() {});
  // }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(1920, 1080),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiProvider(
          providers: [ChangeNotifierProvider(create: (_) => UserModel())],
          child: MaterialApp(
            title: 'hf_mes_app',
            theme: ThemeData(
              // fontFamily: 'Schyler',
              scrollbarTheme: ScrollbarThemeData(
                thumbColor: MaterialStateProperty.resolveWith<Color>((
                  Set<MaterialState> states,
                ) {
                  if (states.contains(MaterialState.pressed)) {
                    return Color(0x472667FF);
                  }
                  if (states.contains(MaterialState.hovered)) {
                    return Color(0x472667FF);
                  }
                  return Color(0x472667FF);
                }),
                trackColor: MaterialStateProperty.all(
                  Colors.transparent,
                ), // 轨道颜色
              ),
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xffC1D3FF),
              ),
              useMaterial3: true,
            ),
            home: Builder(
              builder: (context) {
                final userModel = context.read<UserModel>();
                return Consumer<UserModel>(
                  builder: (context, counter, child) => (userModel.token != ''
                      ? userModel.info['lineId'].isNotEmpty &&
                                userModel.info['stationId'].isNotEmpty
                            ? Home()
                            : PositionPage()
                      // : Home(changeToken: changeToken)
                      : Login()),
                );
              },
            ),
            // home: WebViewComponent(initialUrl: "https://docs.flutter.dev/get-started/install/"),
            builder: EasyLoading.init(),
          ),
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
