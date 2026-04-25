import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';
import '../widgets/shared_widgets.dart';
import '../data/models.dart';
import '../data/mock_data.dart';
import '../app/router.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final _searchCtrl = TextEditingController();
  String _selectedCategory = 'All';
  String _selectedSort = 'Expiry (Soonest)';
  bool _expiredExpanded = true;
  List<FoodItem> _allItems = [];

  @override
  void initState() {
    super.initState();
    _allItems = List.from(MockData.items);
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<FoodItem> get _filtered {
    var list = _allItems.where((item) {
      final q = _searchCtrl.text.toLowerCase();
      final matchName = item.name.toLowerCase().contains(q);
      final matchCat = _selectedCategory == 'All' ||
          item.category.label == _selectedCategory;
      return matchName && matchCat;
    }).toList();

    switch (_selectedSort) {
      case 'Expiry (Soonest)':
        list.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
        break;
      case 'Expiry (Latest)':
        list.sort((a, b) => b.expiryDate.compareTo(a.expiryDate));
        break;
      case 'Name A–Z':
        list.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'Name Z–A':
        list.sort((a, b) => b.name.compareTo(a.name));
        break;
      case 'Date Added':
        list.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
        break;
    }
    return list;
  }

  void _deleteItem(FoodItem item) async {
    final confirmed = await showDeleteConfirmation(context, item.name);
    if (confirmed == true) {
      setState(() => _allItems.removeWhere((i) => i.id == item.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item.name} deleted')),
        );
      }
    }
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _SortSheet(
        selected: _selectedSort,
        onSelected: (v) {
          setState(() => _selectedSort = v);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final expired =
        filtered.where((i) => i.status == ItemStatus.expired).toList();
    final active =
        filtered.where((i) => i.status != ItemStatus.expired).toList();

    return AppBackground(
      child: Column(
        children: [
          AppHeader(
            title: 'Inventory',
            bottom: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: AppSearchBar(
                controller: _searchCtrl,
                hint: 'Search items...',
                onFilterTap: _showSortSheet,
              ),
            ),
          ),
          const SizedBox(height: 12),
          CategoryTabs(
            selected: _selectedCategory,
            categories: AppStrings.categories,
            onChanged: (c) => setState(() => _selectedCategory = c),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: filtered.isEmpty
                ? _EmptyState()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    children: [
                      // Expired section
                      if (expired.isNotEmpty) ...[
                        GestureDetector(
                          onTap: () => setState(
                              () => _expiredExpanded = !_expiredExpanded),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Expired Items',
                                  style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.expired),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                    color: AppColors.expiredBg,
                                    borderRadius: BorderRadius.circular(12)),
                                child: Text('${expired.length}',
                                    style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.expired)),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                  _expiredExpanded
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  color: AppColors.expired),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (_expiredExpanded)
                          ...expired.map((item) => FoodItemCard(
                                item: item,
                                onEdit: () => context.push(AppRoutes.editItem,
                                    extra: item.id), // ← fix this
                                onDelete: () => _deleteItem(item),
                                onTap: () => context.push(AppRoutes.itemDetail,
                                    extra: item.id),
                              ).animate().fadeIn()),
                        const SizedBox(height: 16),
                      ],
                      // Active section
                      if (active.isNotEmpty) ...[
                        const SectionHeader(title: 'Active Items'),
                        ...active.map((item) => FoodItemCard(
                              item: item,
                              onEdit: () => context.push(AppRoutes.editItem,
                                  extra: item.id), // ← fix this
                              onDelete: () => _deleteItem(item),
                              onTap: () => context.push(AppRoutes.itemDetail,
                                  extra: item.id),
                            ).animate().fadeIn()),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inventory_2_outlined,
              size: 72, color: AppColors.lightBlue),
          const SizedBox(height: 16),
          Text('No items found',
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text('Add your first item using the + button',
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppColors.textSecondary)),
        ],
      ).animate().fadeIn().scale(begin: const Offset(0.8, 0.8)),
    );
  }
}

class _SortSheet extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const _SortSheet({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sort by',
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...AppStrings.sortOptions.map((opt) => ListTile(
                title: Text(opt, style: GoogleFonts.poppins(fontSize: 14)),
                trailing: opt == selected
                    ? const Icon(Icons.check, color: AppColors.mediumBlue)
                    : null,
                onTap: () => onSelected(opt),
                contentPadding: EdgeInsets.zero,
              )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
