import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_windows_android_app/main.dart';
import 'package:flutter_windows_android_app/pages/home/home.dart';
import 'package:sp_util/sp_util.dart';
import './constant.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'login_prefs.dart';
import 'package:common_utils/common_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/cupertino.dart';

import 'package:flutter/services.dart' show rootBundle;

class Request {
  static String currentEnv = "pro";
  static final BaseOptions _options = BaseOptions(
    ///Api地址
    // baseUrl: Constant.baseUrlPro, // 正式环境
    baseUrl: Constant.ENV == "dev"
        ? Constant.baseUrlDev
        : Constant.hfBaseUrl[Constant.ENV] ?? Constant.baseUrlDev, // 开发环境
    // baseUrl: Constant.baseUrlFat, // 测试环境

    ///打开超时时间
    connectTimeout: Duration(seconds: 50),

    ///接收超时时间
    receiveTimeout: Duration(seconds: 60),
    headers: {
      "Accept": "application/json",
      "Content-Type": Headers.jsonContentType,
      "X-Requested-With": "XMLHttpRequest",
    },
  );
  // 创建 Dio 实例

  static final Dio _dio = Dio(_options);

  // 初始化dio实例并配置代理

  // 初始化dio实例并配置代理
  static Future<void> init() async {
    // 配置代理

    _dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        // Don't trust any certificate just because their root cert is trusted.
        final HttpClient client = HttpClient(
          context: SecurityContext(withTrustedRoots: false),
        );
        // You can test the intermediate / root cert here. We just ignore it.
        client.badCertificateCallback = (cert, host, port) => true;
        client.findProxy = (Uri uri) {
          // 设置代理服务器地址和端口
          return "PROXY 10.1.204.2:8888"; //z
          // return "PROXY 10.1.204.60:8888"; //c
        };
        return client;
      },
      validateCertificate: (cert, host, port) {
        // Check that the cert fingerprint matches the one we expect.
        // We definitely require _some_ certificate.
        if (cert == null) {
          return false;
        }
        // Validate it any way you want. Here we only check that
        // the fingerprint matches the OpenSSL SHA256.
        // return fingerprint == sha256.convert(cert.der).toString();
        return true;
      },
    );
  }

  // static ChangeLogin loginStatus = ChangeLogin();
  static Future _request(
    String path, {
    String? method,
    String? baseUrl,
    Map<String, dynamic>? params,
    data,
    bool isShow = true,
    bool isChildToken = false,
    bool isZDToken = false,
    onBadResponse,
    headers,
  }) async {
    await LoginPrefs.init();
    // await Request.init();
    try {
      if (isShow) {
        EasyLoading.show();
        // print('加载中');
      }
      String clientId = LoginPrefs.getclientId() ?? '';
      String accessToken = isZDToken
          ? LoginPrefs.getIdentitytoken() ?? ''
          : isChildToken
          ? LoginPrefs.getChildToken() ?? ''
          : LoginPrefs.getToken() ?? '';
      // String clientId = SpUtil.getString(Constant.clientId) ?? "";
      // print('查看存储token：${LoginPrefs.getIdentitytoken()}');
      // print('accessToken:${LoginPrefs.getIdentitytoken()}');
      String requestPath = path;
      if (path.startsWith('/dev')) { // 本地代理到hf开发
        _dio.options.baseUrl = Constant.hfBaseUrl[Constant.ENV] ?? Constant.baseUrlDev;
        requestPath = path.substring(4); // 去掉/dev前缀
      } else {
        _dio.options.baseUrl = baseUrl ?? Constant.baseUrlDev; //如果切换环境请改非空地址
      }
      // print('_dio.options.baseUrl${_options.baseUrl}');

      Response response = await _dio.request(
        requestPath,
        data: data,
        queryParameters: params,
        options: Options(
          method: method,
          headers: {
            "Accept": "application/json",
            "Content-Type": Headers.jsonContentType,
            "X-Requested-With": "XMLHttpRequest",
            "Authorization": accessToken,
            "Client-Identity": clientId,
            'Cookie': 'identitytoken=${accessToken}',
            ...headers??{},
          },
        ),
      );

      // //从响应header中获取Renewal-Authorization
      // String renewalAuthorization =
      //     response.headers.value("Renewal-Authorization") ?? "";

      // if (renewalAuthorization.isNotEmpty) {
      //   // SpUtil.putString(Constant.accessToken, renewalAuthorization);
      //   //todo:存储token
      // }

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (isShow) {
          EasyLoading.dismiss();
        }
        var data = response.data;
        try {
          // return data;
          LogUtil.v(path, tag: 'path');
          LogUtil.v(data, tag: '响应的数据data为：');
          if (data['code'] == 200) {
            return data;
          } else if (data['code'] == "40107") {
            /// 如果状态丢失了，将用户token数据清空，让引导页可以直接登录
            EasyLoading.showError(data["message"] ?? "当前数据状态丢失，请重新登录");
            print('失去登录状态');
            return Future.error(data['message']);
          } else {
            ///其他状态说明正常
            // LogUtil.v(data, tag: '响应的数据为：');
            return data;
          }
        } catch (e) {
          LogUtil.v(e, tag: '解析响应数据异常1');
          return Future.error('解析响应数据异常2');
        }
      } else {
        LogUtil.v(response.statusCode, tag: 'response.statusCode');
        EasyLoading.showInfo('response.statusCode，状态码为：${response.statusCode}');
        _handleHttpError(response.statusCode!);
        return Future.error('HTTP错误');
      }
    } on DioException catch (e) {
      LogUtil.v(e.response, tag: 'DioException_catch');
      Response? errorCode = e.response;

      var dataObjec = e.response?.data ?? {};
      var dataCode = dataObjec['code'] ?? "";
      if (errorCode?.statusCode == 401) {
        List logintCode = ["400", "40105", "40104", "40100", "40111", "40114"];
        print('错误401 接口：${e.requestOptions.uri.toString()} 状态：${logintCode.contains(dataCode)} 数据代码：$dataCode headers: ${e.requestOptions.headers ?? 'null'} noConfer: ${e.requestOptions.headers?['noConfer'] ?? 'null'} 参数: ${e.requestOptions.data ?? 'null'}');
        // SpUtil.remove(Constant.accessToken);
        // SpUtil.remove(Constant.userBasicInfo);
        if (dataCode.isNotEmpty && logintCode.contains(dataCode)) {
          EasyLoading.dismiss();
          EasyLoading.showError(dataObjec["message"]);
          // loginStatus.setLoginStatus(true);
          return dataCode;
        } else {
          EasyLoading.dismiss();
          print('回到登录页面');

          onBadResponse != null && onBadResponse();

          // return e.response;
          // loginOut();
        }
        return Future.error(_dioError(e));
      }
      EasyLoading.showInfo(dataObjec["message"] ?? _dioError(e));
      return Future.error(_dioError(e));
    }
  }

  // 处理 Dio 异常
  static String _dioError(DioException error) {
    print('DioException error${error}');
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return '网络连接超时，请检查网络设置';
      case DioExceptionType.sendTimeout:
        return '请求发送超时，请检查网络设置';
      case DioExceptionType.receiveTimeout:
        return '请求接收超时，请稍后重试';
      case DioExceptionType.badCertificate:
        return 'bad certificate';
      case DioExceptionType.badResponse:
        return 'bad response';
      case DioExceptionType.cancel:
        return '请求已被取消，请重新请求';
      case DioExceptionType.connectionError:
        return '网络连接错误，请稍后重试！';
      case DioExceptionType.unknown:
        return '网络异常，请稍后重试！';
      default:
        return "Dio异常";
    }
  }

  // 处理 Http 错误码
  static void _handleHttpError(int errorCode) {
    String message;
    switch (errorCode) {
      case 400:
        message = '请求语法错误';
        break;
      case 401:
        message = '未授权，请登录';
        break;
      case 403:
        message = '拒绝访问';
        break;
      case 404:
        message = '请求出错';
        break;
      case 408:
        message = '请求超时';
        break;
      case 500:
        message = '服务器异常';
        break;
      case 501:
        message = '服务未实现';
        break;
      case 502:
        message = '网关错误';
        break;
      case 503:
        message = '服务不可用';
        break;
      case 504:
        message = '网关超时';
        break;
      case 505:
        message = 'HTTP版本不受支持';
        break;
      case 40114:
        message = '已向您发送验证码，请查收';
        break;
      case 40111:
        message = '登录验证码错误';
        break;
      default:
        message = '请求失败，错误码：$errorCode';
    }
    EasyLoading.showError(message);
  }

  static Future get<T>(
    String path, {
    Map<String, dynamic>? params,
    bool? isShow,
    bool? isChildToken,
    bool? isZDToken,
    String? baseUrl,
  }) {
    return _request(
      path,
      method: 'get',
      params: params,
      isShow: isShow ?? true,
      isChildToken: isChildToken ?? false,
      isZDToken: isZDToken ?? false,
      baseUrl: baseUrl,
    );
  }

  static Future post<T>(
    String path, {
    Map<String, dynamic>? params,
    data,
    headers,
    bool? isShow,
    bool? isChildToken,
    bool? isZDToken,
    String? baseUrl,
    onBadResponse,
  }) {
    return _request(
      path,
      method: 'post',
      params: params,
      data: data,
      isShow: isShow ?? true,
      isChildToken: isChildToken ?? false,
      isZDToken: isZDToken ?? false,
      baseUrl: baseUrl,
      onBadResponse: onBadResponse,
      headers: headers?? {},
    );
  }

  // 这里只写了 get 和 post，其他的别名大家自己手动加上去就行
}
