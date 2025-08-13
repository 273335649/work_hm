import '../common/dio_request.dart';
import '../common/constant.dart';

class CommonService {
  // 通过用户Id查询关联的产线，岗位和子岗位
  static Future<dynamic> getUserFactoryOrg() async {
    try {
      if (!Constant.isDev) {
        final response = await Request.get(
          '/dev/mes-biz/org/getUserFactoryOrg?id=1',
        );
        return response;
      } else {
        final response = await Request.get('/dev/mes-biz/org/getUserFactoryOrg');
        return response;
      }
    } catch (e) {
      // print('Error fetching user factory organization: $e');
      rethrow;
    }
  }
}