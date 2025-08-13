import '../log/index.dart';
import '../demo/index.dart';
import '../productionOrder/index.dart';

// 页面类型枚举
enum PageType { h5, flutter }

List<Map<String, dynamic>> tabData = [
  {'title': '工单', 'icon': 'images/btn-gongdan', 'type': PageType.h5, 'url': 'https://mes-pda-hf-dev.local.360humi.com/productionOrder'},
  {'title': '巡检', 'icon': 'images/btn-xunjian', 'type': PageType.h5, 'url': 'https://mes-pda-hf-dev.local.360humi.com/patrol'},
  {'title': '成品检验', 'icon': 'images/btn-chengpinjianyan', 'type': PageType.h5, 'url': 'https://mes-pda-hf-dev.local.360humi.com/inspection'},
  {'title': '作业文件', 'icon': 'images/btn-zuoye', 'type': PageType.h5, 'url': 'https://mes-pda-hf-dev.local.360humi.com/personnelRewardPunishment'},
  {'title': '返修', 'icon': 'images/btn-fanxiu', 'type': PageType.h5, 'url': 'https://mes-pda-hf-dev.local.360humi.com/repair'},
  {'title': '呼叫', 'icon': 'images/btn-hujiao', 'widget': ProductionOrder()},
  {'title': '响应', 'icon': 'images/btn-xiangying', 'widget': ProductionOrder()},
  {'title': '设备', 'icon': 'images/btn-shebei', 'type': PageType.h5, 'url': 'https://mes-pda-hf-dev.local.360humi.com/device'},
  {'title': '工具箱', 'icon': 'images/btn-gongjuxiang', 'type': PageType.h5, 'url': 'https://mes-pda-hf-dev.local.360humi.com/toolBox'},
  {'title': '人员奖惩', 'icon': 'images/btn-jiangcheng', 'type': PageType.h5, 'url': 'https://mes-pda-hf-dev.local.360humi.com/personnelRewardPunishment'},
  {'title': '日志', 'icon': 'images/btn-rizhi', 'type': PageType.h5, 'url': 'https://mes-pda-hf-dev.local.360humi.com/logPage'},
  {'title': '开发', 'icon': 'images/btn-rizhi', 'type': PageType.h5, 'url': 'http://localhost:8000/inspection'},

];

// 页面配置数组old暂无用
List arr = [
  {
    'title': '工单',
    'widget': ProductionOrder(),
  },
    // 'url': 'http://localhost:8000/UtilsModule',
  {'title': '巡检', 'type': PageType.h5, 'url': 'http://localhost:8000/MyTable'},
  {'title': '成品检验', 'type': PageType.h5, 'url': 'http://localhost:8000/Home'},
  {'title': '作业文件', 'type': PageType.h5, 'url': 'http://localhost:8000/MyTableVirsual'},
  {'title': '返修', 'type': PageType.h5, 'url': 'http://190.75.16.210:30004/hm-mes-product/wms/MaintainPlan?pageView=plan_edit&ID=1934897165790470145&tableCode=EAM_PLAN&CATEGORY=CHECK'},
  {'title': '呼叫', 'type': PageType.h5, 'url': 'http://190.75.16.210:30004/hm-mes-product/mes/qaApprove?tableCode=MES_PROD_QA&STATUS=A'},
  {'title': '响应', 'type': PageType.h5, 'url': 'https://console-private-hc-mes-dev.local.360humi.com/hc-mes/andonResponseRecord'},
  {'title': '设备', 'type': PageType.h5, 'url': 'https://console-private-hc-mes-dev.local.360humi.com/hc-eam/devicemanages'},
  // {'title': '工具箱', 'type': PageType.h5, 'url': 'http://localhost:8000/home'},
  // {'title': '人工机加', 'widget': ManualMachining()},
  // {'title': '工艺查询', 'widget': ProcessInquiry()},
  // {'title': '技术通知', 'widget': TechnicalNotices()},
  // {'title': '返工返修入库', 'widget': Unqualified()},
  // {'title': '不合格评审', 'widget': Review()},
  // {'title': '安灯呼叫', 'widget': Call()},
  // {'title': '安灯响应', 'widget': Response()},
  // {'title': '设备维保', 'widget': Maintenance()},
  {'title': '日志清单', 'widget': Log()},
  {'title': 'demo', 'widget': Demo()},
]; 


