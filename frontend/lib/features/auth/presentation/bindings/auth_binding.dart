import 'package:get/get.dart';

import '../../../../../injection_container.dart' as di;
import '../controllers/auth_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthController>(() => di.sl<AuthController>(), fenix: true);
  }
}
