import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: const Text('Search & Filter'),
        backgroundColor: AppTheme.bgDark,
      ),
      body: const _SearchBody(),
    );
  }
}

class _SearchBody extends StatefulWidget {
  const _SearchBody();

  @override
  State<_SearchBody> createState() => _SearchBodyState();
}

class _SearchBodyState extends State<_SearchBody> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<InventoryProvider>(
      builder: (context, provider, _) {
        final filtered = provider.products;

        return Column(
          children: [
            // Search bar + filters
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              color: AppTheme.bgDark,
              child: Column(
                children: [
                  // Search bar
                  TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    onChanged: provider.setSearchQuery,
                    decoration: InputDecoration(
                      hintText: 'Search by name or category...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded,
                                  color: AppTheme.textMuted),
                              onPressed: () {
                                _searchCtrl.clear();
                                provider.setSearchQuery('');
                              },
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Category filter chips
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: provider.categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final cat = provider.categories[i];
                        final selected = provider.categoryFilter == cat;
                        return FilterChip(
                          label: Text(cat),
                          selected: selected,
                          onSelected: (_) => provider.setCategoryFilter(cat),
                          selectedColor: AppTheme.primary.withOpacity(0.25),
                          checkmarkColor: AppTheme.primary,
                          backgroundColor: AppTheme.surfaceColor,
                          labelStyle: TextStyle(
                            color: selected
                                ? AppTheme.primary
                                : AppTheme.textSecondary,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            fontSize: 13,
                          ),
                          side: BorderSide(
                            color: selected
                                ? AppTheme.primary.withOpacity(0.5)
                                : Colors.white.withOpacity(0.08),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Status filter chips
                  Row(
                    children: [
                      const Text('Status:',
                          style: TextStyle(
                              color: AppTheme.textMuted, fontSize: 12)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: ['All', 'Normal', 'Low', 'Out of Stock']
                                .map((s) {
                              final selected = provider.statusFilter == s;
                              final color = s == 'Normal'
                                  ? AppTheme.stockNormal
                                  : s == 'Low'
                                      ? AppTheme.stockLow
                                      : s == 'Out of Stock'
                                          ? AppTheme.stockOut
                                          : AppTheme.primary;

                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(s),
                                  selected: selected,
                                  onSelected: (_) =>
                                      provider.setStatusFilter(s),
                                  selectedColor: color.withOpacity(0.25),
                                  checkmarkColor: color,
                                  backgroundColor: AppTheme.surfaceColor,
                                  labelStyle: TextStyle(
                                    color: selected
                                        ? color
                                        : AppTheme.textSecondary,
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    fontSize: 12,
                                  ),
                                  side: BorderSide(
                                    color: selected
                                        ? color.withOpacity(0.5)
                                        : Colors.white.withOpacity(0.08),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Results header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${filtered.length} result${filtered.length != 1 ? 's' : ''}',
                    style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                  ),
                  if (provider.searchQuery.isNotEmpty ||
                      provider.categoryFilter != 'All' ||
                      provider.statusFilter != 'All')
                    TextButton.icon(
                      onPressed: () {
                        _searchCtrl.clear();
                        provider.clearFilters();
                      },
                      icon: const Icon(Icons.filter_alt_off_rounded,
                          size: 16, color: AppTheme.error),
                      label: const Text('Clear',
                          style:
                              TextStyle(color: AppTheme.error, fontSize: 13)),
                    ),
                ],
              ),
            ),
            // Results
            Expanded(
              child: filtered.isEmpty
                  ? _buildNoResults()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _SearchResultCard(product: filtered[i]),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNoResults() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 56, color: AppTheme.textMuted),
          SizedBox(height: 16),
          Text('No results found',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
          SizedBox(height: 8),
          Text('Try a different search or filter',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final Product product;
  const _SearchResultCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final statusColor = AppTheme.stockColor(product.stockStatus);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(AppTheme.stockIcon(product.stockStatus),
                color: statusColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(product.category,
                          style: const TextStyle(
                              color: AppTheme.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 6),
                    Text('Min: ${product.minimumThreshold}',
                        style: const TextStyle(
                            color: AppTheme.textMuted, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${product.quantity}',
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 24,
                      fontWeight: FontWeight.w800)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(product.stockStatus,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
