import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';
import '../app/router.dart';
import '../widgets/shared_widgets.dart';
import '../data/models.dart';
import '../data/mock_data.dart';

class ItemDetailPage extends StatelessWidget {
  final String itemId;
  const ItemDetailPage({super.key, required this.itemId});

  @override
  Widget build(BuildContext context) {
    final item = MockData.items
        .firstWhere((i) => i.id == itemId, orElse: () => MockData.items.first);

    return Scaffold(
      body: AppBackground(
        child: Column(
          children: [
            // Header with photo
            _ItemHeader(item: item),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.paddingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status + days
                    Row(
                      children: [
                        StatusBadge(status: item.status),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.lightBlue,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            item.daysUntilExpiry < 0
                                ? 'Expired ${item.daysUntilExpiry.abs()} days ago'
                                : '${item.daysUntilExpiry} days until expiry',
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.darkBlue),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(),
                    const SizedBox(height: 20),
                    // Info cards
                    _InfoCard(
                      title: 'Basic Info',
                      children: [
                        _InfoRow(label: 'Name', value: item.name),
                        _InfoRow(label: 'Category', value: item.category.label),
                        _InfoRow(label: 'Quantity', value: '${item.quantity}'),
                        if (item.weight != null)
                          _InfoRow(
                              label: 'Weight',
                              value: '${item.weight} ${item.weightUnit}'),
                        _InfoRow(
                            label: 'Date Added',
                            value: DateFormat('MMMM d, yyyy')
                                .format(item.dateAdded)),
                      ],
                    ).animate().fadeIn(delay: 100.ms),
                    const SizedBox(height: 12),
                    _InfoCard(
                      title: 'Expiry Details',
                      children: [
                        _InfoRow(
                            label: 'Expiry Date',
                            value: DateFormat('MMMM d, yyyy')
                                .format(item.expiryDate)),
                        if (item.consumeWithinDays != null)
                          _InfoRow(
                              label: 'Consume Within (After Opening)',
                              value: '${item.consumeWithinDays} days'),
                      ],
                    ).animate().fadeIn(delay: 150.ms),
                    if (item.purchasePrice != null ||
                        item.purchaseDate != null) ...[
                      const SizedBox(height: 12),
                      _InfoCard(
                        title: 'Finance',
                        children: [
                          if (item.purchaseDate != null)
                            _InfoRow(
                                label: 'Purchase Date',
                                value: DateFormat('MMMM d, yyyy')
                                    .format(item.purchaseDate!)),
                          if (item.purchasePrice != null)
                            _InfoRow(
                                label: 'Purchase Price',
                                value:
                                    '₱${item.purchasePrice!.toStringAsFixed(2)}'),
                        ],
                      ).animate().fadeIn(delay: 200.ms),
                    ],
                    if (item.notes != null && item.notes!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _InfoCard(
                        title: 'Notes',
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(item.notes!,
                                style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: AppColors.textSecondary)),
                          ),
                        ],
                      ).animate().fadeIn(delay: 250.ms),
                    ],
                    const SizedBox(height: 24),
                    // Mark as consumed
                    ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Marked as consumed!')),
                        );
                        context.pop();
                      },
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Mark as Consumed'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.fresh,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ).animate().fadeIn(delay: 300.ms),
                    const SizedBox(height: 12),
                    // Delete
                    OutlinedButton.icon(
                      onPressed: () async {
                        final confirmed =
                            await showDeleteConfirmation(context, item.name);
                        if (confirmed == true && context.mounted) context.pop();
                      },
                      icon: const Icon(Icons.delete_outline,
                          color: AppColors.expired),
                      label: const Text('Delete Item',
                          style: TextStyle(color: AppColors.expired)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.expired),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ).animate().fadeIn(delay: 350.ms),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemHeader extends StatelessWidget {
  final FoodItem item;
  const _ItemHeader({required this.item});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      padding:
          EdgeInsets.only(top: topPad + 12, left: 16, right: 16, bottom: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.darkBlue, AppColors.mediumBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.white, size: 20),
              ),
              Expanded(
                  child: Text('Item Detail',
                      style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white))),
              IconButton(
                onPressed: () {
                  context.push(AppRoutes.editItem, extra: item.id);
                },
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  item.imagePath ?? 'assets/images/placeholder.png',
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 72,
                    height: 72,
                    color: Colors.white24,
                    child:
                        Icon(item.category.icon, size: 36, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name,
                        style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(item.category.label,
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _InfoCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        boxShadow: [
          BoxShadow(
              color: AppColors.mediumBlue.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkBlue)),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppColors.textSecondary)),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
