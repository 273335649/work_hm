import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPrefs {
  static const String USER_INFO = "USER_INFO"; //用户名
  static const String USER_CHILD_INFO = ""; //用户名
  static const String AUTO_USER_CHILD_INFO = "AUTO_USER_CHILD_INFO"; //用户名
  static const String MATERIAL_INFO = "MATERIAL_INFO"; //物料信息
  static const String TOKEN = "TOKEN"; //token
  static const String CHILDTOKEN = "CHILDTOKEN"; //token
  static const String clientId = "clientId";
  static const String sm4key = "sm4key";
  static const String IDENTITY_TOKEN = "identitytoken";

  static late SharedPreferences _prefs; //延迟初始化
  static Future init() async {
    WidgetsFlutterBinding.ensureInitialized();
    _prefs = await SharedPreferences.getInstance();
  }

  static void saveUserInfo(String userInfo) {
    _prefs.setString(USER_INFO, userInfo);
  }

  static String? getUserInfo() {
    return _prefs.getString(USER_INFO);
  }

  static void saveMaterialInfo(String userInfo) {
    _prefs.setString(MATERIAL_INFO, userInfo);
  }

  static String? getMaterialInfo() {
    return _prefs.getString(MATERIAL_INFO);
  }

  static void saveAutoUserInfo(String userInfo) {
    _prefs.setString(AUTO_USER_CHILD_INFO, userInfo);
  }

  static String? getAutoUserInfo() {
    return _prefs.getString(AUTO_USER_CHILD_INFO);
  }

  static void saveChildUserInfo(String userInfo) {
    _prefs.setString(USER_CHILD_INFO, userInfo);
  }

  static String? getChildUserInfo() {
    return _prefs.getString(USER_CHILD_INFO);
  }

  static void saveIdentitytoken(String identitytoken) {
    print('传进来的token：${identitytoken}');
    _prefs.setString(IDENTITY_TOKEN, identitytoken);
  }

  static String? getIdentitytoken() {
    return _prefs.getString(IDENTITY_TOKEN);
  }

  static void saveToken(String token) {
    _prefs.setString(TOKEN, token);
  }

  static String? getToken() {
    return _prefs.getString(TOKEN);
  }

  static void saveClientId(String token) {
    _prefs.setString(clientId, token);
  }

  static String? getclientId() {
    return _prefs.getString(clientId);
  }

  static void saveSm4key(String token) {
    _prefs.setString(sm4key, token);
  }

  static String? getSm4key() {
    return _prefs.getString(sm4key);
  }

  static void saveChildToken(String token) {
    _prefs.setString(CHILDTOKEN, token);
  }

  static String? getChildToken() {
    return _prefs.getString(CHILDTOKEN);
  }

  static void removeUserName() {
    _prefs.remove(USER_INFO);
  }

  static void removeChildUserInfo() {
    _prefs.remove(USER_CHILD_INFO);
  }

  static void removeToken() {
    _prefs.remove(TOKEN);
  }

  static void removeChildToken() {
    _prefs.remove(CHILDTOKEN);
  }

  static void clearLogin() {
    _prefs.clear();
  }

  // 保存登录时间
  static Future<void> saveLoginTime(int timestamp) async {
    await _prefs.setInt('login_time', timestamp);
  }

  // 获取登录时间
  static int? getLoginTime() {
    return _prefs.getInt('login_time');
  }
}
