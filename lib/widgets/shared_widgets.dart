import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';
import '../core/common/entities/entities.dart';

// ─── Gradient Background ──────────────────────────────────────────────────────

class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints.expand(),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.gradientStart, AppColors.gradientEnd],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: child,
    );
  }
}

// ─── Header with gradient ─────────────────────────────────────────────────────

class AppHeader extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? bottom;
  final double bottomHeight;

  const AppHeader({
    super.key,
    required this.title,
    this.actions,
    this.bottom,
    this.bottomHeight = 0,
  });

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
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
      padding:
          EdgeInsets.only(top: topPad + 12, bottom: bottom != null ? 0 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (actions != null) ...actions!,
              ],
            ),
          ),
          if (bottom != null) bottom!,
          if (bottom != null) const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─── Status Badge ─────────────────────────────────────────────────────────────

class StatusBadge extends StatelessWidget {
  final ItemStatus status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: status.color,
        ),
      ),
    );
  }
}

// ─── Expiry Chip ──────────────────────────────────────────────────────────────

class ExpiryChip extends StatelessWidget {
  final int daysLeft;
  const ExpiryChip({super.key, required this.daysLeft});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    if (daysLeft < 0) {
      bg = AppColors.expiredBg;
      fg = AppColors.expired;
      label = 'Expired';
    } else if (daysLeft == 0) {
      bg = AppColors.expiredBg;
      fg = AppColors.expired;
      label = 'Today';
    } else if (daysLeft <= 3) {
      bg = AppColors.expiringBg;
      fg = AppColors.expiring;
      label = '${daysLeft}d left';
    } else {
      bg = AppColors.freshBg;
      fg = AppColors.fresh;
      label = '${daysLeft}d left';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: GoogleFonts.poppins(
              fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}

// ─── Food Item Card ───────────────────────────────────────────────────────────

class FoodItemCard extends StatelessWidget {
  final FoodItem item;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const FoodItemCard({
    super.key,
    required this.item,
    this.onEdit,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Thumbnail
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: item.category.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(AppSizes.radiusS),
                    ),
                    child: Icon(
                      item.category.icon,
                      color: item.category.color,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${item.category.label} • ${item.quantity} ${item.weight != null ? "${item.weight} ${item.weightUnit}" : "pcs"}',
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  ExpiryChip(daysLeft: item.daysUntilExpiry),
                ],
              ),
            ),
            // Action row
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: Text('Edit',
                          style: GoogleFonts.poppins(fontSize: 13)),
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.mediumBlue),
                    ),
                  ),
                  Container(width: 1, height: 36, color: AppColors.divider),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: Text('Delete',
                          style: GoogleFonts.poppins(fontSize: 13)),
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.expired),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Category Chip Tabs ───────────────────────────────────────────────────────

class CategoryTabs extends StatelessWidget {
  final String selected;
  final List<String> categories;
  final ValueChanged<String> onChanged;

  const CategoryTabs({
    super.key,
    required this.selected,
    required this.categories,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final cat = categories[i];
          final isSelected = cat == selected;
          return GestureDetector(
            onTap: () => onChanged(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.mediumBlue : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.mediumBlue : AppColors.divider,
                ),
              ),
              child: Text(
                cat,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final Color? textColor;

  const SectionHeader(
      {super.key, required this.title, this.trailing, this.textColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textColor ?? AppColors.textPrimary,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ─── Delete Confirmation Modal ────────────────────────────────────────────────

Future<bool?> showDeleteConfirmation(BuildContext context,String itemName,[bool? isExpired]) {
  final expired = isExpired ?? false;

  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          AppSizes.radiusXL,
        ),
      ),

      title: Text(
        expired
            ? 'Discard Expired Item'
            : 'Delete Item',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w700,
        ),
      ),

      content: Text(
        expired
            ? 'Are you sure you want to discard "$itemName"? This item will be recorded as food waste and included in analytics.'
            : 'Are you sure you want to delete "$itemName"? This action cannot be undone.',
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
      ),

      actions: [
        TextButton(
          onPressed: () => Navigator.pop(
            ctx,
            false,
          ),
          child: Text(
            'Cancel',
            style: GoogleFonts.poppins(
              color: AppColors.textSecondary,
            ),
          ),
        ),

        ElevatedButton(
          onPressed: () => Navigator.pop(
            ctx,
            true,
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.expired,
          ),
          child: Text(
            expired
                ? 'Discard'
                : 'Delete',
            style: GoogleFonts.poppins(
              color: Colors.white,
            ),
          ),
        ),
      ],
    ),
  );
}

// ─── Blue Primary Button ──────────────────────────────────────────────────────

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18),
                    const SizedBox(width: 8)
                  ],
                  Text(label),
                ],
              ),
      ),
    );
  }
}

// ─── White Outlined Button ────────────────────────────────────────────────────

class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const SecondaryButton(
      {super.key, required this.label, this.onPressed, this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18),
              const SizedBox(width: 8)
            ],
            Text(label),
          ],
        ),
      ),
    );
  }
}

// ─── Profile Avatar ───────────────────────────────────────────────────────────

class ProfileAvatar extends StatelessWidget {
  final String name;          // ← raw name, not pre-computed initials
  final double size;
  final String? avatarPath;
  final VoidCallback? onTap;
  final bool showEditBadge;

  const ProfileAvatar({
    super.key,
    required this.name,
    this.size = 48,
    this.avatarPath,
    this.onTap,
    this.showEditBadge = false,
  });

  // Single source of truth for initials logic
  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    final avatar = Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.blueAccent.withOpacity(0.5),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.darkBlue.withOpacity(0.5), width: 2),
          ),
          alignment: Alignment.center,
          child: avatarPath != null
              ? ClipOval(
            child: Image.asset(
              avatarPath!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _initialsText(),
            ),
          )
              : _initialsText(),
        ),
        if (showEditBadge)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.3,
              height: size * 0.3,
              decoration: const BoxDecoration(
                color: AppColors.mediumBlue,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.camera_alt,
                  color: Colors.white, size: size * 0.16),
            ),
          ),
      ],
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: avatar);
    }
    return avatar;
  }

  Widget _initialsText() => Text(
    _initials,
    style: GoogleFonts.poppins(
      color: Colors.white,
      fontWeight: FontWeight.w700,
      fontSize: size * 0.35,
    ),
  );
}


// ─── Search Bar ───────────────────────────────────────────────────────────────

class AppSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final VoidCallback? onFilterTap;

  const AppSearchBar(
      {super.key,
      required this.controller,
      this.hint = 'Search...',
      this.onFilterTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        border: Border.all(color: AppColors.lightBlue),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              style: GoogleFonts.poppins(fontSize: 14),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.poppins(
                    fontSize: 14, color: AppColors.textSecondary),
                border: InputBorder.none,
                enabledBorder: InputBorder.none, // ← ADD
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                fillColor: Colors.transparent,
                filled: false,
              ),
            ),
          ),
          if (onFilterTap != null)
            IconButton(
              onPressed: onFilterTap,
              icon:
                  const Icon(Icons.tune, color: AppColors.mediumBlue, size: 20),
            ),
        ],
      ),
    );
  }
}

// ─── Settings List Tile ───────────────────────────────────────────────────────

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isBold;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.mediumBlue, size: 22),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: GoogleFonts.poppins(
                  fontSize: 12, color: AppColors.textSecondary))
          : null,
      trailing: trailing ??
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    );
  }
}
/// Reusable product name + category pair.
/// Used by both AddItemPage and RegisterProductPage.
/// This avoids duplicating the field styling and dropdown items.
class ProductBasicFields extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController barcodeCtrl;
  final String selectedCategory;
  final ValueChanged<String?> onCategoryChanged;
  final String? nameLabelOverride;
  final bool isLocked;

  const ProductBasicFields({
    super.key,
    required this.nameCtrl,
    required this.barcodeCtrl,
    required this.selectedCategory,
    required this.onCategoryChanged,
    this.nameLabelOverride,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: nameCtrl,
          onTapOutside: (_) {
            FocusManager.instance.primaryFocus?.unfocus();
          },
          readOnly: isLocked,
          onTap: isLocked
              ? () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Registered product information cannot be edited.',
                ),
              ),
            );
          }
              : null,// Lock field
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: nameLabelOverride ?? 'Product Name',
            hintText: 'e.g. Milk, Bread, Yogurt',
            prefixIcon: const Icon(Icons.label_outline, size: 18),
            filled: true,
            fillColor: AppColors.inputBg,
          ),
          validator: (v) => (v == null || v.trim().isEmpty)
              ? 'Product name is required'
              : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: barcodeCtrl,
          onTapOutside: (_) {
            FocusManager.instance.primaryFocus?.unfocus();
          },
          readOnly: isLocked,
          onTap: isLocked
              ? () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Registered product information cannot be edited.',
                ),
              ),
            );
          }
              : null,
          decoration: const InputDecoration(
            labelText: 'Barcode (optional)',
            prefixIcon: Icon(Icons.qr_code, size: 18),
            hintText: 'Scan barcode to auto-fill',
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: selectedCategory,

          decoration: InputDecoration(
            labelText: 'Category',
            filled: true,
            fillColor: AppColors.inputBg,
          ),
          items: AppStrings.categoriesNoAll
              .map((c) => DropdownMenuItem(
            value: c,
            child: Row(
              children: [
                Icon(
                  ItemCategory.values
                      .firstWhere((e) => e.label == c,
                      orElse: () => ItemCategory.others)
                      .icon,
                  size: 18,
                  color: ItemCategory.values
                      .firstWhere((e) => e.label == c,
                      orElse: () => ItemCategory.others)
                      .color,
                ),
                const SizedBox(width: 8),
                Text(c, style: GoogleFonts.poppins(fontSize: 14)),
              ],
            ),
          )).toList(),
          onChanged: isLocked ? null : onCategoryChanged, // Disable if locked
          validator: (v) => v == null ? 'Required' : null,
        ),
      ],
    );
  }
}