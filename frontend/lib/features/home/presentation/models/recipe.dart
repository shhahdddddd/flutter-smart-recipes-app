class Recipe {
  const Recipe({
    required this.id,
    required this.title,
    required this.description,
    required this.duration,
    required this.servings,
    required this.imageUrl,
    required this.tags,
    required this.ingredients,
    required this.steps,
    this.tips = const [],
    this.calories,
    this.protein,
    this.sugar,
    this.carbs,
  });

  final String id;
  final String title;
  final String description;
  final String duration;
  final int servings;
  final String imageUrl;
  final List<String> tags;
  final List<String> ingredients;
  final List<String> steps;
  final List<String> tips;

  final double? calories;
  final double? protein;
  final double? sugar;
  final double? carbs;
}

const recipesCatalog = <Recipe>[
  Recipe(
    id: 'avocado-toast',
    title: 'Avocado Toast with Poached Eggs',
    description: 'A protein-packed breakfast with creamy avocado and perfectly poached eggs.',
    duration: '15 min',
    servings: 2,
    imageUrl: 'https://images.unsplash.com/photo-1528712306091-ed0763094c98?auto=format&fit=crop&w=800&q=80',
    tags: ['Breakfast', 'High Protein'],
    ingredients: [
      '4 slices whole-grain sourdough bread',
      '2 ripe avocados',
      '4 large eggs',
      '1 tablespoon white vinegar',
      '1 tablespoon lemon juice',
      'Salt and freshly ground black pepper to taste',
      '2 tablespoons chopped chives',
      'Optional: chili flakes for serving',
    ],
    steps: [
      'Bring a medium pot of water to a gentle simmer and add the vinegar.',
      'Crack each egg into a small bowl and gently slide into the simmering water. Poach for 3 minutes, then remove with a slotted spoon.',
      'While the eggs cook, toast the bread slices until golden.',
      'Mash the avocados with lemon juice, salt, and pepper, then spread evenly over the toast.',
      'Top each toast with a poached egg, season with more salt and pepper, and garnish with chives and chili flakes.',
    ],
    tips: [
      'Use very fresh eggs for the best poached texture.',
      'Add smoked salmon for an extra protein boost.',
    ],
  ),
  Recipe(
    id: 'quinoa-bowl',
    title: 'Mediterranean Quinoa Bowl',
    description: 'Colorful quinoa bowl with chickpeas, feta, and lemon herb dressing.',
    duration: '25 min',
    servings: 4,
    imageUrl: 'https://images.unsplash.com/photo-1478144592103-25e218a04891?auto=format&fit=crop&w=800&q=80',
    tags: ['Lunch', 'Vegetarian'],
    ingredients: [
      '1 1/2 cups uncooked quinoa, rinsed',
      '3 cups low-sodium vegetable broth',
      '1 can (15 oz) chickpeas, rinsed and drained',
      '1 cup cherry tomatoes, halved',
      '1 cup cucumber, diced',
      '1/2 cup Kalamata olives, sliced',
      '1/2 cup crumbled feta cheese',
      '1/4 cup red onion, finely diced',
      'Fresh parsley and mint for garnish',
    ],
    steps: [
      'Cook quinoa in vegetable broth according to package instructions and let cool slightly.',
      'In a large bowl combine chickpeas, tomatoes, cucumber, olives, feta, and red onion.',
      'Whisk together 3 tablespoons olive oil, juice of 1 lemon, 1 minced garlic clove, 1 teaspoon dried oregano, salt, and pepper.',
      'Add the cooked quinoa to the bowl, drizzle with dressing, and toss gently to combine.',
      'Garnish with chopped parsley and mint before serving.',
    ],
    tips: [
      'Make it vegan by swapping feta for marinated tofu.',
      'Meal prep by storing components separately and combining just before eating.',
    ],
  ),
  Recipe(
    id: 'salmon-teriyaki',
    title: 'Teriyaki Glazed Salmon',
    description: 'Oven-baked salmon with homemade teriyaki glaze and sesame greens.',
    duration: '30 min',
    servings: 2,
    imageUrl: 'https://images.unsplash.com/photo-1612872087720-bb876e01fd95?auto=format&fit=crop&w=800&q=80',
    tags: ['Dinner', 'Omega-3'],
    ingredients: [
      '2 salmon fillets (about 6 oz each)',
      '3 tablespoons low-sodium soy sauce',
      '2 tablespoons maple syrup or honey',
      '1 tablespoon rice vinegar',
      '1 teaspoon grated fresh ginger',
      '1 garlic clove, minced',
      '1 teaspoon toasted sesame oil',
      '1 tablespoon cornstarch mixed with 1 tablespoon water',
      '4 cups baby bok choy or spinach',
      'Sesame seeds and sliced scallions for garnish',
    ],
    steps: [
      'Preheat oven to 400°F (200°C) and line a baking sheet with parchment paper.',
      'Whisk soy sauce, maple syrup, rice vinegar, ginger, garlic, and sesame oil in a small saucepan. Simmer for 2 minutes.',
      'Stir in the cornstarch slurry and cook until the glaze thickens. Reserve 2 tablespoons for serving.',
      'Place salmon on the baking sheet, brush generously with glaze, and bake for 12-14 minutes until flaky.',
      'Sauté bok choy or spinach in a skillet with a splash of glaze until wilted. Serve salmon over greens, drizzle with reserved glaze, and garnish with sesame seeds and scallions.',
    ],
    tips: [
      'Swap salmon for tofu for a plant-based version.',
      'Serve with brown rice for a complete meal.',
    ],
  ),
  Recipe(
    id: 'chia-parfait',
    title: 'Berry Chia Parfait',
    description: 'Layered chia pudding with Greek yogurt, berries, and crunchy granola.',
    duration: '10 min (plus chilling)',
    servings: 2,
    imageUrl: 'https://images.unsplash.com/photo-1506086679525-9f1d5f0de1c0?auto=format&fit=crop&w=800&q=80',
    tags: ['Dessert', 'Heart Healthy'],
    ingredients: [
      '1/2 cup chia seeds',
      '2 cups unsweetened almond milk',
      '2 tablespoons maple syrup or honey',
      '1 teaspoon vanilla extract',
      '1 cup Greek yogurt',
      '1 cup mixed berries (strawberries, blueberries, raspberries)',
      '1/2 cup low-sugar granola',
      'Fresh mint for garnish',
    ],
    steps: [
      'Whisk chia seeds, almond milk, maple syrup, and vanilla in a bowl. Refrigerate for at least 2 hours or overnight.',
      'Stir the chia pudding to break up any clumps before assembling.',
      'Layer the chia pudding, Greek yogurt, and berries in serving glasses.',
      'Top with granola just before serving to keep it crunchy.',
      'Garnish with fresh mint and an extra drizzle of honey if desired.',
    ],
    tips: [
      'Prep chia pudding ahead for quick breakfasts.',
      'Use coconut yogurt to keep the parfait dairy-free.',
    ],
  ),
];
