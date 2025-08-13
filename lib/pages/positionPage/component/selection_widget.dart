import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SelectionWidget extends StatelessWidget {
  final String title;
  final List<dynamic> dataList;
  final int activeIndex;
  final Function(MapEntry<int, dynamic>entry) onTap;
  final String displayKey;

  const SelectionWidget({
    super.key,
    required this.title,
    required this.dataList,
    required this.activeIndex,
    required this.onTap,
    required this.displayKey,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          alignment: Alignment.topLeft,
          child: Row(
            children: [
              Container(
                width: 6.w,
                height: 24.h,
                color: Color(0xFF2FF2FF),
                margin: EdgeInsets.only(right: 8.w),
              ),
              Text(title, style: TextStyle(color: Colors.white, fontSize: 24.sp)),
            ],
          ),
        ),
        SizedBox(height: 20.h),
        SizedBox(
            height: 120.h, // Adjust height as needed
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8.0, // 主轴(水平)方向间距
                runSpacing: 20.0, // 纵轴（垂直）方向间距
                children: dataList
                    .asMap()
                    .entries
                    .map(
                      (entry) => InkWell(
                        onTap: () {
                          onTap(entry);
                        },
                        highlightColor: Colors.transparent, // 透明色
                        splashColor: Colors.transparent,
                        child: Container(
                          height: 48.h,
                          width: 240.w,
                          alignment: Alignment.center,
                          padding: EdgeInsets.only(left: 12.w, right: 12.w),
                          decoration: BoxDecoration(
                            color: activeIndex == entry.key
                                ? Color(0xff004dc5)
                                : Color.fromARGB(23, 31, 94, 255),
                            border: Border.all(
                              color: Color(0xff0057d9),
                              width: 1.w,
                            ),
                          ),
                          child: (Text(
                            entry.value[displayKey].toString(),
                            style: TextStyle(fontSize: 16.sp, color: Colors.white),
                          )),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
        ),
        SizedBox(height: 20.h),
      ],
    );
  }
}
