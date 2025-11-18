import 'dart:convert';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/utils/constants.dart';
import '../../../../injection_container.dart' as di;
import '../../../auth/domain/repositories/auth_repository.dart';

class SmartMealSuggestionsController extends GetxController {
  SmartMealSuggestionsController()
      : _client = di.sl<http.Client>(),
        _authRepository = di.sl<AuthRepository>(),
        _storage = di.sl<GetStorage>(),
        _picker = ImagePicker();

  final http.Client _client;
  final AuthRepository _authRepository;
  final GetStorage _storage;
  final ImagePicker _picker;

  static const String _cachedRecognizedKey = 'cached_recognized_ingredients';
  static const String _cachedMenuKey = 'cached_menu';
  static const String _cachedShoppingListKey = 'cached_shopping_list';
  static const String _cachedUserShoppingListKey = 'cached_user_shopping_list';

  String _userScopedKey(String baseKey) {
    final session = _authRepository.getCachedSession();
    final userId = session?.user.id ?? 'guest';
    return '${baseKey}_$userId';
  }

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  final RxList<String> recognizedIngredients = <String>[].obs;
  final Rxn<Map<String, dynamic>> menu = Rxn<Map<String, dynamic>>();
  final RxList<Map<String, dynamic>> shoppingList = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> userShoppingList = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    final cachedRecognized = _storage.read<List>(_cachedRecognizedKey);
    if (cachedRecognized is List) {
      recognizedIngredients.assignAll(
        cachedRecognized.map((e) => e.toString()).toList(),
      );
    }

    final cachedMenu = _storage.read<Map>(_cachedMenuKey);
    if (cachedMenu is Map) {
      menu.value = Map<String, dynamic>.from(cachedMenu);
    }

    final cachedShopping = _storage.read<List>(_cachedShoppingListKey);
    if (cachedShopping is List) {
      final list = cachedShopping
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
      shoppingList.assignAll(list);
    }

    final cachedUserShopping = _storage.read<List>(_userScopedKey(_cachedUserShoppingListKey));
    if (cachedUserShopping is List) {
      final list = cachedUserShopping
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
      userShoppingList.assignAll(list);
    }

    super.onInit();
  }

  Future<void> scanAndSuggest() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 75,
    );

    if (picked == null) {
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final uri = Uri.parse('${AppConstants.baseUrl}/ai/detect-ingredients');
      final request = http.MultipartRequest('POST', uri);

      final bytes = await picked.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: picked.name,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final data = decoded['data'] as Map<String, dynamic>;

        final detected = (data['detectedIngredients'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            <String>[];

        if (detected.isEmpty) {
          recognizedIngredients.clear();
          errorMessage.value = 'No ingredients were detected in the photo.';
        } else {
          recognizedIngredients.assignAll(detected);
          await fetchSmartSuggestions(detected);
        }
      } else {
        errorMessage.value = _parseErrorMessage(response.body);
      }
    } catch (_) {
      errorMessage.value = 'Failed to scan food image. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchSmartSuggestions(List<String> ingredients) async {
    if (ingredients.isEmpty) {
      errorMessage.value = 'Please provide at least one ingredient.';
      return;
    }

    final session = _authRepository.getCachedSession();
    if (session == null) {
      errorMessage.value = 'Your session has expired. Please log in again.';
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final response = await _client.post(
        Uri.parse('${AppConstants.baseUrl}/ai/smart-suggestions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${session.token}',
        },
        body: jsonEncode({
          'ingredients': ingredients,
          'duration': 'day',
        }),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final data = decoded['data'] as Map<String, dynamic>;

        final recognized = (data['recognizedIngredients'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            <String>[];
        recognizedIngredients.assignAll(recognized);

        final menuData = data['menu'];
        if (menuData is Map<String, dynamic>) {
          menu.value = menuData;
        } else {
          menu.value = null;
        }

        final list = (data['shoppingList'] as List<dynamic>?)
                ?.whereType<Map<String, dynamic>>()
                .toList() ??
            <Map<String, dynamic>>[];
        shoppingList.assignAll(list);

        _storage.write(_cachedRecognizedKey, recognizedIngredients.toList());
        if (menu.value != null) {
          _storage.write(_cachedMenuKey, menu.value);
        }
        _storage.write(_cachedShoppingListKey, shoppingList.toList());
      } else {
        errorMessage.value = _parseErrorMessage(response.body);
      }
    } catch (_) {
      errorMessage.value = 'Failed to load smart suggestions. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  String _parseErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded['error']?.toString() ?? 'Une erreur est survenue';
      }
      return 'Une erreur est survenue';
    } catch (_) {
      return 'Une erreur est survenue';
    }
  }

  void reloadUserShoppingList() {
    final cached = _storage.read<List>(_userScopedKey(_cachedUserShoppingListKey));
    if (cached is List) {
      final list = cached
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
      userShoppingList.assignAll(list);
    }
  }

  void addMissingItemsToShoppingList() {
    final items = shoppingList.map((item) {
      final name = item['ingredient']?.toString() ?? '';
      final quantity = item['quantity']?.toString() ?? '';
      return {
        'ingredient': name,
        'quantity': quantity,
        'purchased': false,
      };
    }).where((i) => (i['ingredient'] as String).trim().isNotEmpty).toList();

    for (final i in items) {
      final exists = userShoppingList.any(
        (e) => (e['ingredient']?.toString().toLowerCase() ?? '') ==
                (i['ingredient'] as String).toLowerCase(),
      );
      if (!exists) userShoppingList.add(i);
    }

    _storage.write(_userScopedKey(_cachedUserShoppingListKey), userShoppingList.toList());
  }

  void addItemToShoppingList(String name, String quantity) {
    final normalized = name.trim();
    if (normalized.isEmpty) return;
    final exists = userShoppingList.any(
      (e) => (e['ingredient']?.toString().toLowerCase() ?? '') == normalized.toLowerCase(),
    );
    if (!exists) {
      userShoppingList.add({
        'ingredient': normalized,
        'quantity': quantity,
        'purchased': false,
      });
    }
    _storage.write(_userScopedKey(_cachedUserShoppingListKey), userShoppingList.toList());
  }

  void addIngredientsToShoppingList(List<String> ingredients) {
    for (final raw in ingredients) {
      final name = raw.toString();
      addItemToShoppingList(name, '');
    }
    Get.snackbar('Saved', 'Ingredients added to Shopping List', snackPosition: SnackPosition.BOTTOM);
  }

  void togglePurchased(String name) {
    final idx = userShoppingList.indexWhere(
      (e) => (e['ingredient']?.toString().toLowerCase() ?? '') == name.toLowerCase(),
    );
    if (idx >= 0) {
      final item = Map<String, dynamic>.from(userShoppingList[idx]);
      item['purchased'] = !(item['purchased'] == true);
      userShoppingList[idx] = item;
    }

    _storage.write(_userScopedKey(_cachedUserShoppingListKey), userShoppingList.toList());
  }

  void removeFromShoppingListAt(int index) {
    if (index < 0 || index >= userShoppingList.length) return;
    userShoppingList.removeAt(index);
    _storage.write(_userScopedKey(_cachedUserShoppingListKey), userShoppingList.toList());
  }

  Future<void> saveSuggestedRecipe(Map<String, dynamic> recipe) async {
    final session = _authRepository.getCachedSession();
    if (session == null) {
      Get.snackbar('Session expired', 'Please log in again', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    try {
      String? recipeId = (recipe['_id']?.toString().isNotEmpty ?? false) ? recipe['_id'].toString() : null;

      if (recipeId == null) {
        final payload = {
          'title': recipe['title']?.toString() ?? 'Recipe',
          'description': recipe['description']?.toString() ?? '',
          'ingredients': (recipe['ingredients'] as List<dynamic>? ?? [])
              .map((i) => {
                    'name': (i is Map && i['name'] != null) ? i['name'].toString() : i.toString(),
                    'quantity': (i is Map && i['quantity'] != null) ? i['quantity'].toString() : '',
                  })
              .toList(),
          'instructions': (recipe['instructions'] as List<dynamic>? ?? [])
              .map((s) => {
                    'step': (s is Map && s['step'] != null) ? s['step'] : 1,
                    'description': (s is Map && s['description'] != null) ? s['description'].toString() : s.toString(),
                  })
              .toList(),
          'cookingTime': int.tryParse('${recipe['cookingTime'] ?? 20}') ?? 20,
          'difficulty': (recipe['difficulty']?.toString().toLowerCase() ?? 'easy'),
          'category': (recipe['category']?.toString().toLowerCase() ?? 'dinner'),
          'tags': (recipe['tags'] as List<dynamic>? ?? []).map((t) => t.toString()).toList(),
          'isAIGenerated': true,
        };

        final createResp = await _client.post(
          Uri.parse('${AppConstants.baseUrl}/recipes'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${session.token}',
          },
          body: jsonEncode(payload),
        );

        if (createResp.statusCode == 201) {
          final decoded = jsonDecode(createResp.body) as Map<String, dynamic>;
          final data = decoded['data'] as Map<String, dynamic>;
          recipeId = data['_id']?.toString();
        } else {
          Get.snackbar('Save failed', 'Could not create recipe', snackPosition: SnackPosition.BOTTOM);
          return;
        }
      }

      if (recipeId != null) {
        final favResp = await _client.post(
          Uri.parse('${AppConstants.baseUrl}/users/favorites/$recipeId'),
          headers: {
            'Authorization': 'Bearer ${session.token}',
          },
        );
        if (favResp.statusCode == 200) {
          Get.snackbar('Saved', 'Recipe added to favorites', snackPosition: SnackPosition.BOTTOM);
        } else {
          Get.snackbar('Save failed', 'Could not add to favorites', snackPosition: SnackPosition.BOTTOM);
        }
      }
    } catch (_) {
      Get.snackbar('Save failed', 'Unexpected error while saving recipe', snackPosition: SnackPosition.BOTTOM);
    }
  }
}
