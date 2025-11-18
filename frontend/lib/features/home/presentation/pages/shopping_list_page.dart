import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/smart_meal_suggestions_controller.dart';

class ShoppingListPage extends StatefulWidget {
  const ShoppingListPage({super.key});

  @override
  State<ShoppingListPage> createState() => _ShoppingListPageState();
}

class _ShoppingListPageState extends State<ShoppingListPage> {
  @override
  void initState() {
    super.initState();
    Get.find<SmartMealSuggestionsController>().reloadUserShoppingList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4FB),
      appBar: AppBar(
        title: const Text('Shopping List'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Share list',
            icon: const Icon(Icons.share_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: Obx(() {
        final controller = Get.find<SmartMealSuggestionsController>();
        final items = controller.userShoppingList;
        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Your shopping list is empty. Add items from Smart Suggestions.',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final name = item['ingredient']?.toString() ?? '';
            final quantity = item['quantity']?.toString() ?? '';
            final purchased = item['purchased'] == true;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: purchased,
                    onChanged: (_) => controller.togglePurchased(name),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            decoration: purchased ? TextDecoration.lineThrough : null,
                            color: purchased ? Colors.grey : null,
                          ),
                        ),
                        if (quantity.isNotEmpty)
                          Text(
                            quantity,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: purchased ? Colors.grey : Colors.grey.shade600,
                              decoration: purchased ? TextDecoration.lineThrough : null,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remove',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      controller.removeFromShoppingListAt(index);
                    },
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }
}
