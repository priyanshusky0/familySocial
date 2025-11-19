import 'package:family_socail/app/modules/Alarm/controllers%20/alarm_controller.dart';
import 'package:get/get.dart';



class AlarmBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AlarmController>(() => AlarmController());
  }
}