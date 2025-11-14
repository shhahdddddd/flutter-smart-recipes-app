import 'package:flutter/material.dart';

class WeeklyMealPlannerPage extends StatelessWidget {
  const WeeklyMealPlannerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Meal Planner'),
      ),
      body: const Center(
        child: Text('Plan your meals for the week here.'),
      ),
    );
  }
}
