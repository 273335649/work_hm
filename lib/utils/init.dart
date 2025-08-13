import 'package:uuid/uuid.dart';
import '../common/dio_request.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:sp_util/sp_util.dart';
import '../common/constant.dart';
import '../common/login_prefs.dart';
import 'package:yaml/yaml.dart';
import 'dart:io';

class InitUtilData {
  static Future<dynamic> getInitUuid() async {
    final String clientIdentity = await identityUUID();
    // String publicKey = await generateUUID(clientIdentity);
    // print("公钥：$clientIdentity || $publicKey");
    String sm4key = Key.fromSecureRandom(16).base16;
    // String secretKey = await rsaEncrypt(publicKey, sm4key);
    // print("sm4秘钥加密:$secretKey || $sm4key");
    // bool uploadResult = await uploadSecretApi(clientIdentity, secretKey);
    // print("uploadResult:$uploadResult");
    LoginPrefs.saveClientId(clientIdentity);
    LoginPrefs.saveSm4key(sm4key);

    return {
      "sm4key": sm4key,
      "clientId": clientIdentity,
    };
  }

  static generateUUID(String clientIdentity) async {
    // Request.post("/user/code",data: data,);
    var response = await Request.get(
        "/user-center/secretkey/init?clientIdentity=$clientIdentity");
    if (response["success"] == true) {
      return response["data"];
    } else {
      EasyLoading.showError("请求失败:${response["message"]}");
    }
    return "";
  }

  static uploadSecretApi(String clientIdentity, String secretKey) async {
    var response = await Request.post("/user-center/secretkey/confer",
        data: {"clientIdentity": clientIdentity, "secretKey": secretKey});
    if (response["success"] == true) {
      return true;
    } else {
      EasyLoading.showError("请求失败:${response["message"]}");
    }
    return false;
  }

  static rsaEncrypt(String publicKeyStr, String sm4key) async {
    String publicKey = formatPublicKey(publicKeyStr);
    dynamic publicKeys = RSAKeyParser().parse(publicKey);
    final encrypter = Encrypter(RSA(publicKey: publicKeys));
    return encrypter.encrypt(sm4key).base64;
  }

  //公钥字符串格式化
  static String formatPublicKey(String publicKey) {
    String formattedPublicKeyPEM =
        "-----BEGIN PUBLIC KEY-----\n$publicKey\n-----END PUBLIC KEY-----";
    return formattedPublicKeyPEM;
  }

  /// 生成一个UUID，用以应用内标识设备身份
  static Future<String> identityUUID() async {
    //先从本地获取UUID
    String? uuid = SpUtil.getString(Constant.uuid);
    if (uuid == null || uuid.isEmpty) {
      //本地没有UUID，生成一个UUID
      uuid = Uuid().v4();
      //将生成的UUID保存到本地
      SpUtil.putString(Constant.uuid, uuid);
    }
    return uuid;
  }

  static Future<String> getVersionFromPubspec() async {
    try {
      final file = File('pubspec.yaml');
      final content = await file.readAsString();
      final pubspec = loadYaml(content);
      final version = pubspec['version'] as String;
      return version;
    } catch (e) {
      print('读取pubspec.yaml版本号失败: $e');
      return '';
    }
  }

  static Future<String> getLocalIpAddress() async {
    try {
      String ipAddress = '未知';
      if (Platform.isWindows) {
        try {
          ProcessResult process = Process.runSync('ipconfig', ['/all']);
          String output = process.stdout;
          List<String> lines = output.split('\r\n');
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
        } catch (e) {
          print('Windows ipconfig命令执行失败: $e');
        }
      } else if (Platform.isAndroid) {
        try {
          ProcessResult process = Process.runSync('ip', [
            'route',
            'get',
            '8.8.8.8',
          ]);
          if (process.exitCode == 0) {
            String output = process.stdout.toString();
            RegExp regex = RegExp(r'src\s+(\d+\.\d+\.\d+\.\d+)');
            Match? match = regex.firstMatch(output);
            if (match != null) {
              ipAddress = match.group(1) ?? '未知';
            }
          }
        } catch (e) {
          print('Android获取IP地址失败: $e');
        }
      } else if (Platform.isIOS) {
        ipAddress = '127.0.0.1';
      } else {
        print('不支持的平台: \\${Platform.operatingSystem}');
      }
      return ipAddress;
    } catch (e) {
      print('获取IP地址时发生错误: $e');
      return '未知';
    }
  }

}

// 加密 Future代表异步操作
Future<String> encodeString(String content) async {
  const publicPem =
      "-----BEGIN PUBLIC KEY-----\nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAhIcq1BLO0UYnQ2Z/w1oiW65K8ktIRit8BvkDdOwQQ3wG4FmNPa2rHCRkfHe+0/wllYrLeYHn4DLn3rjT/6Cds++9UlpE8BP+3pxmJ2OB472fHpPwO3GxdQUi5T1JIBSEJdPQOv71oTJI2/R2IuKPk3lFEcIUgiQXlQX91+ODtG5XRVO+mmgBxZIf26JYEUAEfJ7OV1Df/f8/daSF9UD+m6AxywJ9AKAEB+41PYMwnVd0/492ODtQGAxplER2HTyAFJd1HBDZOvU+uUh285dSNMayVGLpipO2/pGm1VrW9bdGw1yeRP7Z6ObJoNbrxJm+1zd1Du37wpQbu97A6qT/qQIDAQAB\n-----END PUBLIC KEY-----";

  dynamic publicKey = RSAKeyParser().parse(publicPem);

  final encrypter = Encrypter(RSA(publicKey: publicKey)); //加密使用公钥

  return encrypter.encrypt(content).base64; //返回加密后的base64格式文件
}
