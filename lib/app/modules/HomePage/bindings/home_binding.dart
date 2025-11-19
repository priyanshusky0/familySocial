import 'package:family_socail/app/modules/HomePage/controller/home_controller.dart';
import 'package:get/get.dart';

/// Home Binding
/// Initializes HomeController when home screen is accessed
class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(() => HomeController());
  }
}