class Constant {
  /// App运行在Release环境时，inProduction为true；当App运行在Debug和Profile环境时，inProduction为false
  // static const bool inProduction = kReleaseMode;
  static const String ENV = String.fromEnvironment('ENV', defaultValue: 'dev');
  static const bool isDev =
      String.fromEnvironment('ENV', defaultValue: 'dev') == 'dev';
  // flutter build --release --dart-define=ENV=prod 生成release包

  static const Map<String, String> baseUrl = {
    'dev': "https://privatization-gateway-ckd-dev.local.360humi.com",
    'fat': "https://privatization-gateway-ckd-fat.local.360humi.com",
    'prod': "http://172.16.201.59:31817",
    'pre': "http://172.22.1.38:9001",
  };
  static const String baseUrlDev =
      "https://gateway-mes-dev-v1.local.360humi.com";
  static const String baseUrlFat =
      "https://privatization-gateway-hf-fat.local.360humi.com";

  static const Map<String, String> hfBaseUrl = {
    'dev': "https://privatization-gateway-hf-dev.local.360humi.com",
    'fat': "https://privatization-gateway-hf-fat.local.360humi.com",
    'prod': "https://privatization-gateway-hf-fat.local.360humi.com",
    'pre': "http://172.22.1.38:9001",
  };


  // "http://10.1.200.31:8080";
  // static const String baseUrlFat = "https://privatization-gateway-fat.local.360humi.com";
  static const String baseUrlPro = "http://172.16.201.59:31817";
  static const String zdUrl = "http://apims-gw.zsdl.cn/gw"; //生产
  // static const String zdUrl = "http://190.75.16.113:8080/restcloud"; //测试
  // static const String zdUrl = "http://apims-fat.zsdl.cn/restcloud";

  static const String data = 'data';
  static const String message = 'message';
  static const String code = 'code';

  static const String accessToken = 'accessToken';
  static const String sm4key = 'sm4key';
  static const String clientId = 'clientId';
  static const String userBasicInfo = 'userBasicInfo';
  static const String userLoginInfo = 'userLoginInfo';

  static const String uuid = 'uuid';
}
