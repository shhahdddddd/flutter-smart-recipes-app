import 'package:get/get.dart';

import '../../../../injection_container.dart' as di;
import '../controllers/home_controller.dart';
import '../controllers/smart_meal_suggestions_controller.dart';
import '../controllers/recipes_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => HomeController());
    Get.lazyPut(() => RecipesController());
    Get.lazyPut(() => SmartMealSuggestionsController());
  }
}
