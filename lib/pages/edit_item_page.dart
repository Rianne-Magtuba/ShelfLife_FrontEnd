import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shelllife/core/business/dtos/inventory_dto.dart';
import '../constants/app_constants.dart';
import '../widgets/shared_widgets.dart';
import '../core/common/entities/entities.dart';
import '../core/business/providers/inventory_provider.dart';

class EditItemPage extends ConsumerStatefulWidget {
  final String itemId;
  const EditItemPage({super.key, required this.itemId});

  @override
  ConsumerState<EditItemPage> createState() => _EditItemPageState();
}

class _EditItemPageState extends ConsumerState<EditItemPage> {
  late FoodItem _item;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _quantityCtrl;
  late TextEditingController _weightCtrl; // weight is String? in model
  late TextEditingController _notesCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _consumeWithinCtrl;

  late ItemCategory _selectedCategory; // correct enum: ItemCategory
  late String _selectedWeightUnit; // from AppStrings.weightUnits
  late DateTime _expiryDate;
  DateTime? _purchaseDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final inventory = ref.read(inventoryProvider).value ?? [];
    _item = inventory.firstWhere(
          (i) => i.id == widget.itemId,
      orElse: () => inventory.first, // fallback prevents null
    );

    _nameCtrl = TextEditingController(text: _item.name);
    _quantityCtrl = TextEditingController(text: '${_item.quantity}');
    _weightCtrl = TextEditingController(text: _item.weight ?? '');
    _notesCtrl = TextEditingController(text: _item.notes ?? '');
    _priceCtrl = TextEditingController(
        text: _item.purchasePrice?.toStringAsFixed(2) ?? '');
    _consumeWithinCtrl =
        TextEditingController(text: _item.consumeWithinDays?.toString() ?? '');

    _selectedCategory = _item.category;
    _selectedWeightUnit = _item.weightUnit ?? AppStrings.weightUnits.first;
    _expiryDate = _item.expiryDate;
    _purchaseDate = _item.purchaseDate;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _quantityCtrl.dispose();
    _weightCtrl.dispose();
    _notesCtrl.dispose();
    _priceCtrl.dispose();
    _consumeWithinCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.mediumBlue),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _expiryDate = picked);
  }

  Future<void> _pickPurchaseDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.mediumBlue),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _purchaseDate = picked);
  }

  Future<void> _save() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isSaving = true);

  try {
    final request = AddInventoryItemRequest(
      isCustomItem: true,
      barcodeRef: null,
      customName: _nameCtrl.text.trim(),
      customCategory: _selectedCategory.label,
      customWeightGrams: _weightCtrl.text.trim().isEmpty
          ? null
          : double.tryParse(_weightCtrl.text.trim()),
      customPrice: _priceCtrl.text.trim().isEmpty
          ? null
          : double.tryParse(_priceCtrl.text.trim()),
      quantity: int.parse(_quantityCtrl.text.trim()),
      quality: 'Good',
      notes: _notesCtrl.text.trim(),
      expirationDate: _expiryDate,
    );

    final success = await ref
        .read(inventoryProvider.notifier)
        .updateItem(_item.id, request);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item updated successfully')),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update item')),
      );
    }
  } catch (e) {
    debugPrint('[EditItem] update error: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong')),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isSaving = false);
    }
  }
}

  /*Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    // Build updated FoodItem via copyWith — all types match the model exactly.
    // ignore: unused_local_variable
    final updated = _item.copyWith(
      name: _nameCtrl.text.trim(),
      category: _selectedCategory,
      quantity: int.parse(_quantityCtrl.text.trim()),
      weight: _weightCtrl.text.trim().isEmpty ? null : _weightCtrl.text.trim(),
      weightUnit: _selectedWeightUnit,
      expiryDate: _expiryDate,
      purchaseDate: _purchaseDate,
      purchasePrice: _priceCtrl.text.trim().isEmpty
          ? null
          : double.tryParse(_priceCtrl.text.trim()),
      consumeWithinDays: _consumeWithinCtrl.text.trim().isEmpty
          ? null
          : int.tryParse(_consumeWithinCtrl.text.trim()),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    // TODO: pass `updated` to a repository / Riverpod provider
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Item updated successfully!')),
    );
    context.pop();
  }*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Column(
          children: [
            _EditHeader(item: _item),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSizes.paddingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Basic Info ──────────────────────────────────────
                      _SectionCard(
                        title: 'Basic Info',
                        children: [
                          _field(
                            controller: _nameCtrl,
                            label: 'Name',
                            icon: Icons.label_outline,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Name is required'
                                : null,
                          ),
                          const SizedBox(height: 12),

                          // ItemCategory dropdown with icon + colour from ext
                          DropdownButtonFormField<ItemCategory>(
                            initialValue: _selectedCategory,
                            decoration: _inputDecoration(
                                'Category', Icons.category_outlined),
                            style: GoogleFonts.poppins(
                                fontSize: 14, color: AppColors.textPrimary),
                            items: ItemCategory.values
                                .map((c) => DropdownMenuItem(
                                      value: c,
                                      child: Row(
                                        children: [
                                          Icon(c.icon,
                                              size: 16, color: c.color),
                                          const SizedBox(width: 8),
                                          Text(c.label),
                                        ],
                                      ),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _selectedCategory = v);
                              }
                            },
                          ),
                          const SizedBox(height: 12),

                          _field(
                            controller: _quantityCtrl,
                            label: 'Quantity',
                            icon: Icons.numbers_outlined,
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Quantity is required';
                              }
                              if (int.tryParse(v.trim()) == null) {
                                return 'Must be a whole number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          // Weight (String) + unit (from AppStrings.weightUnits)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: _field(
                                  controller: _weightCtrl,
                                  label: 'Weight (optional)',
                                  icon: Icons.scale_outlined,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: DropdownButtonFormField<String>(
                                  initialValue: _selectedWeightUnit,
                                  decoration: _inputDecoration(
                                      'Unit', Icons.straighten_outlined),
                                  style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: AppColors.textPrimary),
                                  items: AppStrings.weightUnits
                                      .map((u) => DropdownMenuItem(
                                            value: u,
                                            child: Text(u),
                                          ))
                                      .toList(),
                                  onChanged: (v) {
                                    if (v != null) {
                                      setState(() => _selectedWeightUnit = v);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ).animate().fadeIn(),

                      const SizedBox(height: 12),

                      // ── Expiry Details ──────────────────────────────────
                      _SectionCard(
                        title: 'Expiry Details',
                        children: [
                          _DateTile(
                            label: 'Expiry Date',
                            date: _expiryDate,
                            onTap: _pickExpiryDate,
                            icon: Icons.event_outlined,
                          ),
                          const SizedBox(height: 12),
                          _field(
                            controller: _consumeWithinCtrl,
                            label: 'Consume Within (days after opening)',
                            icon: Icons.hourglass_bottom_outlined,
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return null;
                              if (int.tryParse(v.trim()) == null) {
                                return 'Must be a whole number';
                              }
                              return null;
                            },
                          ),
                        ],
                      ).animate().fadeIn(delay: 80.ms),

                      const SizedBox(height: 12),

                      // ── Finance ─────────────────────────────────────────
                      _SectionCard(
                        title: 'Finance',
                        children: [
                          _DateTile(
                            label: 'Purchase Date',
                            date: _purchaseDate,
                            onTap: _pickPurchaseDate,
                            icon: Icons.calendar_today_outlined,
                            optional: true,
                          ),
                          const SizedBox(height: 12),
                          _field(
                            controller: _priceCtrl,
                            label: 'Purchase Price (₱)',
                            icon: Icons.payments_outlined,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return null;
                              if (double.tryParse(v.trim()) == null) {
                                return 'Must be a valid number';
                              }
                              return null;
                            },
                          ),
                        ],
                      ).animate().fadeIn(delay: 160.ms),

                      const SizedBox(height: 12),

                      // ── Notes ───────────────────────────────────────────
                      _SectionCard(
                        title: 'Notes',
                        children: [
                          TextFormField(
                            controller: _notesCtrl,
                            maxLines: 4,
                            style: GoogleFonts.poppins(fontSize: 14),
                            decoration: _inputDecoration(
                                'Additional notes…', Icons.notes_outlined),
                          ),
                        ],
                      ).animate().fadeIn(delay: 240.ms),

                      const SizedBox(height: 24),

                      PrimaryButton(
                        label: 'Save Changes',
                        onPressed: _isSaving ? null : _save,
                        isLoading: _isSaving,
                        icon: Icons.save_outlined,
                      ).animate().fadeIn(delay: 300.ms),

                      const SizedBox(height: 12),

                      SecondaryButton(
                        label: 'Cancel',
                        onPressed: () => context.pop(),
                        icon: Icons.close,
                      ).animate().fadeIn(delay: 350.ms),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle:
          GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary),
      prefixIcon: Icon(icon, size: 20, color: AppColors.mediumBlue),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        borderSide: const BorderSide(color: AppColors.mediumBlue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        borderSide: const BorderSide(color: AppColors.expired),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(fontSize: 14),
      decoration: _inputDecoration(label, icon),
      validator: validator,
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _EditHeader extends StatelessWidget {
  final FoodItem item;
  const _EditHeader({required this.item});

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
                child: Text('Edit Item',
                    style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
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
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _HeaderPill(item.category.label),
                        const SizedBox(width: 6),
                        _HeaderPill(item.status.label,
                            color: item.status.color.withOpacity(0.3)),
                      ],
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

class _HeaderPill extends StatelessWidget {
  final String text;
  final Color color;
  const _HeaderPill(this.text, {this.color = Colors.white24});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.white)),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.children});

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
            offset: const Offset(0, 2),
          ),
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
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final IconData icon;
  final bool optional;
  const _DateTile({
    required this.label,
    required this.date,
    required this.onTap,
    required this.icon,
    this.optional = false,
  });

  @override
  Widget build(BuildContext context) {
    final display = date != null
        ? DateFormat('MMMM d, yyyy').format(date!)
        : optional
            ? 'Tap to set'
            : 'Select date';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusM),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.mediumBlue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(display,
                      style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const Icon(Icons.edit_calendar_outlined,
                size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
