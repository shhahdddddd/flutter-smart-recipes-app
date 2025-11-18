import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../../../injection_container.dart' as di;
import '../../../../routes/app_routes.dart';
import '../controllers/home_controller.dart';
import '../controllers/recipes_controller.dart';
import '../controllers/smart_meal_suggestions_controller.dart';
import '../models/recipe.dart';

String _difficultyFor(Recipe r) {
  final m = RegExp(r'(\d+)').firstMatch(r.duration);
  final minutes = int.tryParse(m?.group(1) ?? '0') ?? 0;
  if (minutes == 0) return 'medium';
  if (minutes <= 15) return 'easy';
  if (minutes <= 30) return 'medium';
  return 'hard';
}

int _healthScoreFor(Recipe r) {
  int score = 50;
  final tags = r.tags.map((t) => t.toLowerCase()).toList();
  if (tags.any((t) => t.contains('healthy') || t.contains('heart') || t.contains('omega') || t.contains('high protein'))) score += 20;
  if (tags.any((t) => t.contains('dessert') || t.contains('sugar'))) score -= 10;
  return score.clamp(0, 100);
}

class WeeklyMealPlannerPage extends StatefulWidget {
  const WeeklyMealPlannerPage({super.key});

  @override
  State<WeeklyMealPlannerPage> createState() => _WeeklyMealPlannerPageState();
}

class _WeeklyMealPlannerPageState extends State<WeeklyMealPlannerPage> {
  final _days = const ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
  final _slots = const ['Breakfast','Lunch','Dinner'];
  late final RecipesController _recipes;
  late final HomeController _home;
  late final SmartMealSuggestionsController _smart;
  late final GetStorage _storage;

  final Map<String, Map<String, Recipe?>> _plan = {};
  bool _zeroWaste = false;
  bool _quickMode = false;
  bool _budgetMode = false;
  int _weekOffset = 0;

  @override
  void initState() {
    super.initState();
    _recipes = Get.find<RecipesController>();
    _home = Get.find<HomeController>();
    _smart = Get.find<SmartMealSuggestionsController>();
    _storage = di.sl<GetStorage>();
    for (final d in _days) {
      _plan[d] = {for (final s in _slots) s: null};
    }
    _loadCurrentWeekIfExists();
  }

  String _userId() => _home.user.value?.id ?? 'guest';
  String _weekKey(int offset) => 'planner_week_${_userId()}_$offset';
  String _lastKeyName() => 'last_planner_key_${_userId()}';

  void _saveCurrentWeek() {
    final payload = {
      'weekOffset': _weekOffset,
      'plan': {
        for (final d in _days)
          d: {
            for (final s in _slots)
              s: _plan[d]![s]?.id
          }
      }
    };
    final key = _weekKey(_weekOffset);
    _storage.write(key, payload);
    _storage.write(_lastKeyName(), key);
  }

  void _loadCurrentWeekIfExists() {
    final key = _weekKey(_weekOffset);
    final saved = _storage.read<Map>(key);
    if (saved is Map && saved['plan'] is Map) {
      _rehydrateFromMap(Map<String, dynamic>.from(saved['plan'] as Map));
      setState((){});
    } else {
      _autoFill();
    }
  }

  void _loadLastWeek() {
    final lastKey = _storage.read<String>(_lastKeyName());
    if (lastKey is String) {
      final saved = _storage.read<Map>(lastKey);
      if (saved is Map && saved['plan'] is Map) {
        _rehydrateFromMap(Map<String, dynamic>.from(saved['plan'] as Map));
        setState((){});
      }
    }
  }

  Recipe? _findRecipeById(String? id) {
    if (id==null || id.isEmpty) return null;
    final all = <Recipe>[]
      ..addAll(_recipes.recipes)
      ..addAll(_home.recommendedRecipes)
      ..addAll(recipesCatalog);
    try {
      return all.firstWhere((r) => r.id == id);
    } catch (_) { return null; }
  }

  void _rehydrateFromMap(Map<String, dynamic> map) {
    for (final d in _days) {
      final dayMap = Map<String, dynamic>.from(map[d] ?? {});
      for (final s in _slots) {
        _plan[d]![s] = _findRecipeById(dayMap[s]?.toString());
      }
    }
  }

  Map<String, String> _dayTotals(String day) {
    double calories = 0, protein = 0, sugar = 0, carbs = 0;
    bool any = false;
    for (final s in _slots) {
      final r = _plan[day]![s];
      if (r?.calories != null) { calories += r!.calories!; any = true; }
      if (r?.protein != null) { protein += r!.protein!; any = true; }
      if (r?.sugar != null) { sugar += r!.sugar!; any = true; }
      if (r?.carbs != null) { carbs += r!.carbs!; any = true; }
    }
    if (!any) return {};
    String fmt(double v) => v.round().toString();
    return {
      if (calories>0) 'calories': fmt(calories),
      if (protein>0) 'protein': fmt(protein),
      if (carbs>0) 'carbs': fmt(carbs),
      if (sugar>0) 'sugar': fmt(sugar),
    };
  }

  List<Recipe> _dedupe(List<Recipe> src) {
    final seen = <String, Recipe>{};
    for (final r in src) {
      final k = r.title.trim().toLowerCase();
      if (k.isEmpty) continue;
      seen.putIfAbsent(k, () => r);
    }
    return seen.values.toList();
  }

  void _autoFill() async {
    final combined = <Recipe>[]
      ..addAll(_home.recommendedRecipes)
      ..addAll(_recipes.recipes);
    var pool = _dedupe(combined);
    if (pool.length < 15) {
      await _recipes.ensureMinimumForCategory('all', min: 15);
      pool = _dedupe(<Recipe>[]..addAll(_home.recommendedRecipes)..addAll(_recipes.recipes));
    }

    final have = _smart.userShoppingList
        .map((e) => (e['ingredient']?.toString() ?? '').toLowerCase())
        .where((s) => s.isNotEmpty)
        .toSet();

    pool.sort((a,b){
      int sa = a.ingredients.where((i)=>have.contains(i.toLowerCase())).length;
      int sb = b.ingredients.where((i)=>have.contains(i.toLowerCase())).length;
      if (_zeroWaste && sa!=sb) return sb.compareTo(sa);
      final ma = int.tryParse(RegExp(r'(\d+)').firstMatch(a.duration)?.group(1)??'0')??0;
      final mb = int.tryParse(RegExp(r'(\d+)').firstMatch(b.duration)?.group(1)??'0')??0;
      if (_quickMode && ma!=mb) return ma.compareTo(mb);
      final ta = a.tags.map((t)=>t.toLowerCase()).toList();
      final tb = b.tags.map((t)=>t.toLowerCase()).toList();
      final ba = ta.any((t)=>t.contains('cheap')||t.contains('budget'))?1:0;
      final bb = tb.any((t)=>t.contains('cheap')||t.contains('budget'))?1:0;
      if (_budgetMode && ba!=bb) return bb.compareTo(ba);
      return 0;
    });

    int idx = 0;
    for (final d in _days) {
      for (final s in _slots) {
        if (idx < pool.length) {
          _plan[d]![s] = pool[idx++];
        }
      }
    }
    setState((){});
  }

  void _addWeekToShopping() {
    for (final d in _days) {
      for (final s in _slots) {
        final r = _plan[d]![s];
        if (r!=null) _smart.addIngredientsToShoppingList(r.ingredients);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Meal Planner'),
        actions: [
          IconButton(
            tooltip: 'Zero-Waste',
            icon: Icon(_zeroWaste?Icons.recycling:Icons.recycling_outlined),
            onPressed: (){ setState(()=>_zeroWaste=!_zeroWaste); _autoFill(); },
          ),
          IconButton(
            tooltip: 'Quick Mode',
            icon: Icon(_quickMode?Icons.flash_on:Icons.flash_on_outlined),
            onPressed: (){ setState(()=>_quickMode=!_quickMode); _autoFill(); },
          ),
          IconButton(
            tooltip: 'Budget Mode',
            icon: Icon(_budgetMode?Icons.savings:Icons.savings_outlined),
            onPressed: (){ setState(()=>_budgetMode=!_budgetMode); _autoFill(); },
          ),
          IconButton(
            tooltip: 'Save Week',
            icon: const Icon(Icons.save_outlined),
            onPressed: _saveCurrentWeek,
          ),
          IconButton(
            tooltip: 'Load Last Week',
            icon: const Icon(Icons.restore_outlined),
            onPressed: _loadLastWeek,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addWeekToShopping,
        icon: const Icon(Icons.playlist_add),
        label: const Text('Add Week to Shopping'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: _days.length,
        itemBuilder: (context, di){
          final day = _days[di];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(day, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _slots.map((slot){
                      final r = _plan[day]![slot];
                      return _MealSlot(
                        slot: slot,
                        recipe: r,
                        onAccept: (incoming){ setState(()=>_plan[day]![slot]=incoming); _saveCurrentWeek(); },
                        onEdit: () => r!=null? _openAlternatives(day, slot, r!):null,
                        onSave: () => r!=null? _recipes.addToFavorites(r):null,
                        onAddShopping: () => r!=null? _smart.addIngredientsToShoppingList(r.ingredients):null,
                      );
                    }).toList(),
                  ),
                  Builder(builder: (context){
                    final totals = _dayTotals(day);
                    if (totals.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (totals['calories']!=null) _StatChip(icon: Icons.local_fire_department, label: '${totals['calories']} kcal'),
                          if (totals['protein']!=null) _StatChip(icon: Icons.fitness_center, label: '${totals['protein']} g protein'),
                          if (totals['carbs']!=null) _StatChip(icon: Icons.grid_view, label: '${totals['carbs']} g carbs'),
                          if (totals['sugar']!=null) _StatChip(icon: Icons.cake_outlined, label: '${totals['sugar']} g sugar'),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openAlternatives(String day, String slot, Recipe current) async {
    await _recipes.generateSimilar(current);
    final all = _recipes.recipes.toList();
    final tags = current.tags.map((t)=>t.toLowerCase()).toSet();
    final ingredients = current.ingredients.map((i)=>i.toLowerCase()).toSet();
    final candidates = all.where((r){
      if (r.title==current.title) return false;
      final rt = r.tags.map((t)=>t.toLowerCase()).toSet();
      final ri = r.ingredients.map((i)=>i.toLowerCase()).toSet();
      final overlap = rt.intersection(tags).isNotEmpty || ri.intersection(ingredients).isNotEmpty;
      return overlap;
    }).take(20).toList();

    if (candidates.isEmpty) return;

    await showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      builder: (ctx){
        final theme = Theme.of(ctx);
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: candidates.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i){
            final r = candidates[i];
            return ListTile(
              title: Text(r.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Row(children:[
                const Icon(Icons.timer_outlined, size: 16), const SizedBox(width:4), Text(r.duration, style: theme.textTheme.bodySmall),
                const SizedBox(width: 12), const Icon(Icons.health_and_safety_outlined, size:16), const SizedBox(width:4), Text('Health ${_healthScoreFor(r)}', style: theme.textTheme.bodySmall),
              ]),
              onTap: (){ setState(()=>_plan[day]![slot]=r); _saveCurrentWeek(); Navigator.pop(ctx); },
            );
          },
        );
      }
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});
  final IconData icon; final String label;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0,4))],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children:[Icon(icon, size:16), const SizedBox(width:6), Text(label, style: theme.textTheme.bodySmall)])
    );
  }
}

class _MealSlot extends StatelessWidget {
  const _MealSlot({
    required this.slot,
    required this.recipe,
    required this.onAccept,
    required this.onEdit,
    required this.onSave,
    required this.onAddShopping,
  });

  final String slot;
  final Recipe? recipe;
  final void Function(Recipe) onAccept;
  final VoidCallback? onEdit;
  final VoidCallback? onSave;
  final VoidCallback? onAddShopping;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final child = Container(
      width: 300,
      constraints: const BoxConstraints(minHeight: 120),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0,8))],
      ),
      child: recipe==null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(slot, style: theme.textTheme.labelLarge?.copyWith(color: Colors.grey.shade700)),
                const SizedBox(height: 8),
                const Text('Tap Edit to suggest a meal'),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$slot • ${recipe!.title}', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Row(children:[
                  const Icon(Icons.timer_outlined, size: 16), const SizedBox(width:4), Text(recipe!.duration, style: theme.textTheme.bodySmall),
                  const SizedBox(width: 12), const Icon(Icons.speed_outlined, size:16), const SizedBox(width:4), Text(_difficultyFor(recipe!), style: theme.textTheme.bodySmall),
                  const SizedBox(width: 12), const Icon(Icons.health_and_safety_outlined, size:16), const SizedBox(width:4), Text('Health ${_healthScoreFor(recipe!)}', style: theme.textTheme.bodySmall),
                ]),
                const SizedBox(height: 8),
                Row(children:[
                  IconButton(tooltip:'Edit', icon: const Icon(Icons.edit_outlined), onPressed: onEdit),
                  IconButton(tooltip:'Save', icon: const Icon(Icons.favorite_border), onPressed: onSave),
                  IconButton(tooltip:'Add Shopping', icon: const Icon(Icons.add_shopping_cart_outlined), onPressed: onAddShopping),
                ]),
              ],
            ),
    );

    final tappable = InkWell(
      onTap: recipe != null
          ? () => Get.toNamed(AppRoutes.recipeDetail, arguments: recipe)
          : null,
      borderRadius: BorderRadius.circular(14),
      child: child,
    );

    return DragTarget<Recipe>(
      onWillAccept: (incoming) => incoming != null,
      onAccept: onAccept,
      builder: (context, _, __) {
        if (recipe == null) {
          return tappable;
        }
        return Draggable<Recipe>(
          data: recipe!,
          feedback: Material(color: Colors.transparent, child: tappable),
          childWhenDragging: Opacity(opacity: 0.5, child: tappable),
          child: tappable,
        );
      },
    );
  }
}
