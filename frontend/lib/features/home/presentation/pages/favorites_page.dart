import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../core/utils/constants.dart';
import '../../../../injection_container.dart' as di;
import '../../../auth/domain/repositories/auth_repository.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final favorites = [
      ('Grilled Salmon Bowl', 'Updated 2 days ago'),
      ('Mediterranean Wrap', 'Updated 5 days ago'),
      ('Avocado Power Toast', 'Updated 1 week ago'),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4FB),
      appBar: AppBar(
        title: const Text('Favorites & Saved Recipes'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Builder(
        builder: (context) {
          final client = di.sl<http.Client>();
          final authRepo = di.sl<AuthRepository>();
          final session = authRepo.getCachedSession();
          if (session == null) {
            return const _EmptyState();
          }
          return FutureBuilder<http.Response>(
            future: client.get(
              Uri.parse('${AppConstants.baseUrl}/users/favorites'),
              headers: {'Authorization': 'Bearer ${session.token}'},
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              final resp = snapshot.data;
              if (resp == null || resp.statusCode != 200) {
                return const _EmptyState();
              }
              final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
              final List<dynamic> data = decoded['data'] as List<dynamic>? ?? [];
              if (data.isEmpty) {
                return const _EmptyState();
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: data.length,
                itemBuilder: (context, index) {
                  final map = data[index] as Map<String, dynamic>;
                  final title = (map['title'] ?? '').toString();
                  final subtitle = (map['difficulty'] ?? '').toString();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 18,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          height: 48,
                          width: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF8A65).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.favorite, color: Color(0xFFFF7043)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subtitle.isEmpty ? 'Saved' : subtitle,
                                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Icon(Icons.favorite_border, size: 54, color: Color(0xFFFF7043)),
            ),
            const SizedBox(height: 24),
            Text(
              'No saved recipes yet',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Heart the recipes you love to build your personal cookbook.',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
