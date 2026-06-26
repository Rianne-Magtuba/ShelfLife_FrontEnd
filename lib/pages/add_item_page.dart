import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import '../constants/app_constants.dart';
import '../core/business/services/inventory_service.dart';
import '../widgets/shared_widgets.dart';
import '../core/common/entities/entities.dart';
import '../core/business/dtos/inventory_dto.dart';
import '../core/business/dtos/product_dto.dart';
import '../core/business/services/product_service.dart';
import '../core/business/providers/inventory_provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../constants/responsive_extensions.dart';
import '../core/common/utils/weight_converter.dart';



class AddItemPage extends ConsumerStatefulWidget {
  const AddItemPage({super.key});

  @override
  ConsumerState<AddItemPage> createState() => _AddItemPageState();
}


class _AddItemPageState extends ConsumerState<AddItemPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Form state
  final _barcodeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  ItemCategory _category = ItemCategory.fridge;
  int _quantity = 1;
  final _weightCtrl = TextEditingController();
  String _weightUnit = 'g';
  DateTime? _expiryDate;
  DateTime? _mfgDate;
  final _shelfLifeCtrl = TextEditingController();
  bool _useExactDate = true;
  final _consumeWithinCtrl = TextEditingController();
  DateTime? _purchaseDate;
  final _priceCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _saving = false;

  // New State Variables for Barcode Flow
  bool _isProductLocked = false;
  bool _isScannedNotRegistered = false;
  bool _isLookingUp = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _barcodeCtrl.dispose();
    _tabController.dispose();
    _nameCtrl.dispose();
    _weightCtrl.dispose();
    _shelfLifeCtrl.dispose();
    _consumeWithinCtrl.dispose();
    _priceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isExpiry) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime(2000),
      lastDate: DateTime(2035),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.mediumBlue),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => isExpiry ? _expiryDate = picked : _mfgDate = picked);
    }
  }

  Future<void> _pickPurchaseDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
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

  Future<void> _showRequestDialog() async {

    if (!_isProductLocked ||
        _barcodeCtrl.text.trim().isEmpty) {

      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: context.w(0.06),
            vertical: context.h(0.03),
          ),
          title: const Text('Request Unavailable'),
          content: const Text(
            'This product is not yet registered in the system.\n\n'
                'Correction requests can only be submitted for existing registered products.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      return;
    }

    final changeCtrl = TextEditingController();
    final proposedNameCtrl = TextEditingController(text: _nameCtrl.text);
    final proposedWeightCtrl = TextEditingController(text: _weightCtrl.text);

    String selectedReason = 'Incorrect Product Name';

    final reasons = [
      'Incorrect Product Name',
      'Incorrect Category',
      'Incorrect Weight',
      'Typographical Error',
      'Wrong Product Information',
      'Other',
    ];
    final dropdownWidth = context.w(0.65);
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {

            return AlertDialog(
              title: Text(
                'Request Product Correction',
                style: GoogleFonts.poppins(
                  fontSize: context.sp(20),
                ),
              ),
                content: SizedBox(
                  width: context.w(0.80),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    TextFormField(
                      initialValue: _barcodeCtrl.text,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Barcode',
                      ),
                    ),

                    SizedBox(height: context.h(0.015)),

                    TextFormField(
                      controller: proposedNameCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Proposed Name',
                      ),
                    ),

                    SizedBox(height: context.h(0.015)),

                    TextFormField(
                      controller: proposedWeightCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Proposed Weight ($_weightUnit)',
                      ),
                    ),
                    SizedBox(height: context.h(0.015)),



                  DropdownMenu<String>(

                  width: dropdownWidth,

                  label: const Text('Reason'),

                  initialSelection: selectedReason,

                  inputDecorationTheme: InputDecorationTheme(
                    filled: true,
                    fillColor: AppColors.inputBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),

                  menuStyle: MenuStyle(
                    backgroundColor: const WidgetStatePropertyAll(
                      Colors.white,
                    ),

                    minimumSize: WidgetStatePropertyAll(
                      Size(dropdownWidth, 0),
                    ),

                    maximumSize: WidgetStatePropertyAll(
                      Size(
                        dropdownWidth,
                        context.h(0.25),
                      ),
                    ),
                  ),

                  dropdownMenuEntries: reasons
                      .map(
                        (e) => DropdownMenuEntry(
                      value: e,
                      label: e,
                    ),
                  )
                      .toList(),

                  onSelected: (value) {
                    if (value == null) return;

                    setState(() {
                      selectedReason = value;
                    });
                  },
                ),

                    SizedBox(height: context.h(0.015)),

                    TextFormField(
                      controller: changeCtrl,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Requested Correction',
                        hintText:
                        'Describe what should be changed',
                      ),
                    ),
                  ],
                ),
              ),
                ),

              actions: [

                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),

                ElevatedButton(
                  onPressed: () async {
                    try {
                      await InventoryService().sendCorrectionRequest(
                        barcode:             _barcodeCtrl.text,
                        proposedName:        proposedNameCtrl.text.trim(),
                        proposedCategory:    _category.label,
                        proposedWeightGrams: WeightConverter.toGrams(proposedWeightCtrl.text.trim(), _weightUnit)?.toStringAsFixed(2) ?? proposedWeightCtrl.text.trim(),
                        proposedPrice:       _priceCtrl.text,
                      );

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Correction request submitted successfully!'),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(e.toString().replaceFirst('Exception: ', '')),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _save() async {
    // Only validate unlocked fields
    final nameEmpty = _nameCtrl.text.trim().isEmpty;
    final expiryMissing = _useExactDate && _expiryDate == null;

    if (!_isProductLocked && nameEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a product name')),
      );
      return;
    }
    if (expiryMissing) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an expiry date')),
      );
      return;
    }

    // ── Resolve expiry date ────────────────────────────────────────────────
    DateTime? resolvedExpiry;

    if (_useExactDate) {
      if (_expiryDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an expiry date')),
        );
        return;
      }
      resolvedExpiry = _expiryDate;
    } else {
      if (_mfgDate == null || _shelfLifeCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter manufacturing date and shelf life')),
        );
        return;
      }
      final shelfDays = int.tryParse(_shelfLifeCtrl.text.trim());
      if (shelfDays == null || shelfDays <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shelf life must be a positive number')),
        );
        return;
      }
      resolvedExpiry = _mfgDate!.add(Duration(days: shelfDays));
    }

    // ── Build request ──────────────────────────────────────────────────────
    final hasBarcode = _barcodeCtrl.text.trim().isNotEmpty;
    
    // CRITICAL: Force custom fields to be sent if the product doesn't exist yet, 
    // otherwise the backend will create a blank item.
    final sendCustomDetails = !hasBarcode || _isScannedNotRegistered;

    final request = AddInventoryItemRequest(
      isCustomItem:      sendCustomDetails,
      barcodeRef:        _barcodeCtrl.text.trim(),
      customName:        _nameCtrl.text.trim(),
      customCategory:    _category.label ,
      customWeightGrams: WeightConverter.toGrams(_weightCtrl.text.trim(), _weightUnit),
      customPrice:       double.tryParse(_priceCtrl.text.trim()),
      quantity:        _quantity,
      quality:         'Good',
      notes: WeightConverter.encodeUnitInNotes(_notesCtrl.text.trim(), _weightUnit),
      expirationDate:  resolvedExpiry!,
    );

    // ── Call backend via provider ──────────────────────────────────────────
    setState(() => _saving = true);

    final success = await ref.read(inventoryProvider.notifier).addItem(request);

    if (!mounted) return;

    if (success) {
      bool productRegistered = false;

      // Register the product if it was scanned but didn't exist
      if (_isScannedNotRegistered && hasBarcode) {
        try {
          await ProductService().createProduct(
            ProductRequest(
              barcode: _barcodeCtrl.text.trim(),
              name: _nameCtrl.text.trim(),
              category: _category.label,
              weightGrams: WeightConverter.toGrams(_weightCtrl.text.trim(), _weightUnit),
              price: double.tryParse(_priceCtrl.text.trim()),
            )
          );
          productRegistered = true;
        } catch (e) {
          debugPrint('[AddItemPage] Failed to register product: $e');
        }
      }

      setState(() => _saving = false);
      context.pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(productRegistered 
            ? '${_nameCtrl.text.trim()} added to inventory and registered product!'
            : '${_nameCtrl.text.trim()} added to inventory!'),
        ),
      );
    } else {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save item. Please try again.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
 @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          AppBackground(
            child: Column(
              children: [
            // ── Header ──────────────────────────────────────────────────────
            Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + context.h(0.015),
                left: context.w(0.04),
                right: context.w(0.04),
                bottom: context.w(0.04),
              ),
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
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.white, size: 20),
                      ),
                      Expanded(
                        child: Text(
                          'Add New Item',
                          style: GoogleFonts.poppins(
                              fontSize: context.sp(20),
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.message_rounded,
                          color: _isProductLocked
                              ? Colors.white
                              : Colors.white54,
                        ),
                        onPressed: _isProductLocked
                            ? _showRequestDialog
                            : () async {
                          await showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text(
                                'Request Unavailable',
                              ),
                              content: const Text(
                                'Only registered products can receive correction requests.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                   SizedBox(height: context.h(0.015)),
                  // Tab toggle
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(5),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      indicatorPadding: const EdgeInsets.symmetric(vertical: 1, horizontal: -10),
                      labelColor: AppColors.darkBlue,
                      unselectedLabelColor: Colors.white,
                      labelStyle: GoogleFonts.poppins(
                          fontSize: context.sp(13), fontWeight: FontWeight.w600),
                      unselectedLabelStyle: GoogleFonts.poppins(fontSize: context.sp(13)),
                      tabs: const [
                        Tab(text: 'Manual Entry'),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.qr_code_scanner_outlined, size: 15),
                              SizedBox(width: 4),
                              Text('Scan Product '),
                            ],
                          ),
                        ),
                      ],
                      dividerColor: Colors.transparent,
                    ),
                  ),
                ],
              ),
            ),

            // ── Tab views ───────────────────────────────────────────────────
        Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Manual tab
                      _ManualForm(
                        barcodeCtrl: _barcodeCtrl,
                        formKey: _formKey,
                        nameCtrl: _nameCtrl,
                        category: _category,
                        isProductLocked: _isProductLocked, // Pass the lock state
                        onCategoryChanged: (c) {
                          if (c != null && !_isProductLocked) setState(() => _category = c);
                        },
                        quantity: _quantity,
                        onQtyChanged: (v) => setState(() => _quantity = v),
                        weightCtrl: _weightCtrl,
                        weightUnit: _weightUnit,
                        onWeightUnitChanged: (u) {
                          if (u != null) setState(() => _weightUnit = u);
                        },
                        useExactDate: _useExactDate,
                        onExpiryModeChanged: (v) => setState(() => _useExactDate = v),
                        expiryDate: _expiryDate,
                        onPickExpiry: () => _pickDate(true),
                        mfgDate: _mfgDate,
                        onPickMfg: () => _pickDate(false),
                        shelfLifeCtrl: _shelfLifeCtrl,
                        consumeWithinCtrl: _consumeWithinCtrl,
                        purchaseDate: _purchaseDate,
                        onPickPurchase: _pickPurchaseDate,
                        priceCtrl: _priceCtrl,
                        notesCtrl: _notesCtrl,
                        saving: _saving,
                        onSave: _save,
                      ),
                      // Scan tab
                      _ScanTab(
                        onManualEntry: () => _tabController.animateTo(0),
                        onBarcodeScanned: (barcode) async {
                          _tabController.animateTo(0);
                          setState(() {
                            _barcodeCtrl.text = barcode;
                            _isLookingUp = true;
                            // Clear fields before lookup
                            _nameCtrl.clear();
                            _weightCtrl.clear();
                            _priceCtrl.clear();
                          });

                          try {
                            final product = await ProductService().fetchProduct(barcode);
                            if (!mounted) return;

                            if (product != null) {
                              setState(() {
                                _nameCtrl.text = product.name;
                                _category = ItemCategory.values.firstWhere(
                                  (c) => c.label == product.category,
                                  orElse: () => ItemCategory.fridge,
                                );
                                if (product.weightGrams != null) {
                                  _weightCtrl.text = product.weightGrams.toString();
                                }
                                if (product.price != null) {
                                  _priceCtrl.text = product.price.toString();
                                }
                                _isProductLocked = true;
                                _isScannedNotRegistered = false;
                                _isLookingUp = false;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('${product.name} found — fill in expiry date')),
                              );
                            } else {
                              setState(() {
                                _isProductLocked = false;
                                _isScannedNotRegistered = true;
                                _isLookingUp = false;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('New product scanned — please fill in details to register')),
                              );
                            }
                          } catch (e) {
                            if (!mounted) return;
                            setState(() {
                              _isProductLocked = false;
                              _isScannedNotRegistered = true;
                              _isLookingUp = false;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Loading Overlay ──────────────────────────────────────────────────
          if (_isLookingUp)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.mediumBlue),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Manual Form ─────────────────────────────────────────────────────────────
// Must be StatefulWidget so dropdowns and toggles render correctly

class _ManualForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl, weightCtrl, barcodeCtrl, shelfLifeCtrl, consumeWithinCtrl, priceCtrl, notesCtrl;
  final ItemCategory category;
  final ValueChanged<ItemCategory?> onCategoryChanged;
  final int quantity;
  final ValueChanged<int> onQtyChanged;
  final String weightUnit;
  final ValueChanged<String?> onWeightUnitChanged;
  final bool useExactDate;
  final ValueChanged<bool> onExpiryModeChanged;
  final DateTime? expiryDate, mfgDate, purchaseDate;
  final VoidCallback onPickExpiry, onPickMfg, onPickPurchase;
  final bool saving;
  final bool isProductLocked; // <-- NEW
  final VoidCallback onSave;

  const _ManualForm({
    required this.barcodeCtrl,
    required this.formKey,
    required this.nameCtrl,
    required this.category,
    required this.onCategoryChanged,
    required this.quantity,
    required this.onQtyChanged,
    required this.weightCtrl,
    required this.weightUnit,
    required this.onWeightUnitChanged,
    required this.useExactDate,
    required this.onExpiryModeChanged,
    required this.expiryDate,
    required this.onPickExpiry,
    required this.mfgDate,
    required this.onPickMfg,
    required this.shelfLifeCtrl,
    required this.consumeWithinCtrl,
    required this.purchaseDate,
    required this.onPickPurchase,
    required this.priceCtrl,
    required this.notesCtrl,
    required this.saving,
    required this.isProductLocked, // <-- NEW
    required this.onSave,
  });

  @override
  State<_ManualForm> createState() => _ManualFormState();
}

class _ManualFormState extends State<_ManualForm> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Form(
          key: widget.formKey,
          child: ListView(
            keyboardDismissBehavior:
            ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            children: [
          // ── Basic Information ─────────────────────────────────────────────
          const _SectionLabel('Basic Information'),

          ProductBasicFields(
            nameCtrl:          widget.nameCtrl,
            barcodeCtrl:       widget.barcodeCtrl,
            selectedCategory:  widget.category.label,
            isLocked:          widget.isProductLocked, // Pass down
            onCategoryChanged: (v) {
              if (v == null) return;
              final cat = ItemCategory.values.firstWhere(
                    (c) => c.label == v,
                orElse: () => ItemCategory.fridge,
              );
              widget.onCategoryChanged(cat);
            },


          ),
              SizedBox(height: context.h(0.015)),
          // Quantity stepper
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.inputBg,
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                const Icon(Icons.format_list_numbered_outlined,
                    color: AppColors.mediumBlue, size: 18),
                const SizedBox(width: 8),
                Text('Quantity',
                    style: GoogleFonts.poppins(
                        fontSize: context.sp(14), color: AppColors.textSecondary)),
                const Spacer(),
                IconButton(
                  onPressed: widget.quantity > 1
                      ? () => widget.onQtyChanged(widget.quantity - 1)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline,
                      color: AppColors.mediumBlue),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
                SizedBox(
                  width: 32,
                  child: Text(
                    '${widget.quantity}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        fontSize: context.sp(16), fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed: () => widget.onQtyChanged(widget.quantity + 1),
                  icon: const Icon(Icons.add_circle_outline,
                      color: AppColors.mediumBlue),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ],
            ),
          ),
              SizedBox(height: context.h(0.015)),

          // Weight + unit
          Row(
            children: [
              Expanded(
                flex: 3,
                child: GestureDetector(
                  onTap: widget.isProductLocked
                      ? () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Registered product details are locked.',
                        ),
                      ),
                    );
                  }
                      : null,
                  child: AbsorbPointer(
                    absorbing: widget.isProductLocked,
                    child: TextFormField(
                      controller: widget.weightCtrl,
                      onTapOutside: (_) {
                        FocusManager.instance.primaryFocus?.unfocus();
                      },
                      keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'),
                        ),
                      ],
                        decoration: InputDecoration(
    labelText: 'Weight (optional)',
    prefixIcon: const Icon(
      Icons.scale_outlined,
      size: 18,
    ),
    filled: true,
    fillColor: AppColors.inputBg,
  ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: context.w(0.026)),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: widget.isProductLocked
                      ? () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Registered product details are locked.',
                        ),
                      ),
                    );
                  }
                      : null,
                  child: AbsorbPointer(
                    absorbing: widget.isProductLocked,
                    child:
                    DropdownButtonFormField<String>(
                      initialValue: widget.weightUnit,
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                      ),
                      items: AppStrings.weightUnits
                          .map(
                            (u) => DropdownMenuItem(
                          value: u,
                          child: Text(
                            u,
                            style: GoogleFonts.poppins(
                              fontSize: context.sp(14),
                            ),
                          ),
                        ),
                      )
                          .toList(),
                      onChanged: widget.onWeightUnitChanged,
                    ),
                  ),
                ),
              ),
            ],
          ),
              SizedBox(height: context.w(0.024)),

          // ── Expiry Details ─────────────────────────────────────────────────
          const _SectionLabel('Expiry Details'),
          Row(
            children: [
              _ModeChip(
                label: 'Exact Date',
                selected: widget.useExactDate,
                onTap: () => widget.onExpiryModeChanged(true),
              ),
              const SizedBox(width: 8),
              _ModeChip(
                label: 'After Manufacturing',
                selected: !widget.useExactDate,
                onTap: () => widget.onExpiryModeChanged(false),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.useExactDate)
            _DatePickerField(
              label: 'Tap to select expiry date',
              date: widget.expiryDate,
              onTap: widget.onPickExpiry,
            )
          else ...[
            _DatePickerField(
              label: 'Tap to select manufacturing date',
              date: widget.mfgDate,
              onTap: widget.onPickMfg,
            ),
            SizedBox(height: context.w(0.015)),
            TextFormField(
              controller: widget.shelfLifeCtrl,
              onTapOutside: (_) {
                FocusManager.instance.primaryFocus?.unfocus();
              },
              keyboardType: TextInputType.number,inputFormatters: [
              FilteringTextInputFormatter.allow(
                  RegExp(r'^\d+\.?\d{0,2}')
              ),
            ],
              decoration: const InputDecoration(
                labelText: 'Shelf Life (days)',
                prefixIcon: Icon(Icons.calendar_today_outlined, size: 18),
              ),
            ),
          ],
              SizedBox(height: context.w(0.024)),



          // ── Finance ────────────────────────────────────────────────────────
         const _SectionLabel('Finance (Optional)'),

          TextFormField(
            controller: widget.priceCtrl,
            onTapOutside: (_) {
              FocusManager.instance.primaryFocus?.unfocus();
            },
            //readOnly: widget.isProductLocked,
          //  enableInteractiveSelection: !widget.isProductLocked,

           // contextMenuBuilder: widget.isProductLocked
               // ? (_, __) => const SizedBox.shrink()
             //   : null,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),inputFormatters: [
            FilteringTextInputFormatter.allow(
                RegExp(r'^\d+\.?\d{0,2}')
            ),
          ],
            decoration: InputDecoration(
              labelText: 'Purchase Price (₱)',
              prefixIcon: const Icon(Icons.payments_outlined, size: 18),
              filled: true,
              fillColor: AppColors.inputBg,
            ),
          ),
              SizedBox(height: context.w(0.024)),
          // ── Notes ──────────────────────────────────────────────────────────
          const _SectionLabel('Notes (Optional)'),
          TextFormField(
            controller: widget.notesCtrl,
            onTapOutside: (_) {
              FocusManager.instance.primaryFocus?.unfocus();
            },
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'e.g. opened, stored in back shelf...',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 28),

          PrimaryButton(
            label: 'Save Item',
            onPressed: widget.onSave,
            isLoading: widget.saving,
            icon: Icons.check,
          ),
          const SizedBox(height: 20),
        ],
      ),
    ),
    );
  }
}

// ─── Scan Tab ─────────────────────────────────────────────────────────────────
class _ScanTab extends StatefulWidget {
  final VoidCallback onManualEntry;
  final ValueChanged<String> onBarcodeScanned;

  const _ScanTab({
    required this.onManualEntry,
    required this.onBarcodeScanned,
  });

  @override
  State<_ScanTab> createState() => _ScanTabState();
}

class _ScanTabState extends State<_ScanTab>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {

  late final MobileScannerController _controller;
  late final AnimationController _scanLineController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat(reverse: true);
  late final Animation<double> _scanLineAnimation = Tween<double>(
    begin: 0.0,
    end: 1.0,
  ).animate(
    CurvedAnimation(
      parent: _scanLineController,
      curve: Curves.easeInOut,
    ),
  );

  bool _hasScanned = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
      detectionSpeed: DetectionSpeed.normal;
      returnImage: false;
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    super.dispose();
  }

  void _onDetect(
      BarcodeCapture capture,
      void Function(void Function()) setSheetState,
      MobileScannerController controller,
      ) {
    if (_hasScanned) return;

    debugPrint('[Scanner] onDetect fired — ${capture.barcodes.length} barcode(s) found');

    for (final barcode in capture.barcodes) {
      debugPrint('[Scanner] rawValue: ${barcode.rawValue}');
      debugPrint('[Scanner] format:   ${barcode.format}');
      debugPrint('[Scanner] type:     ${barcode.type}');

      final raw = barcode.rawValue;
      if (raw == null || raw.isEmpty) {
        debugPrint('[Scanner] rawValue is null or empty — skipping');
        continue;
      }

      setSheetState(() => _hasScanned = true);
      setState(() => _hasScanned = true);

      controller.stop();

      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
          widget.onBarcodeScanned(raw);
        }
      });
      return;
    }
  }

  void _openScanner() async {
    final status = await Permission.camera.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Camera permission is required to scan'),
            action: status.isPermanentlyDenied
                ? SnackBarAction(
              label: 'Settings',
              onPressed: () => openAppSettings(),
            )
                : null,
          ),
        );
      }
      return;
    }

    if (!mounted) return;
    setState(() => _hasScanned = false);

    // Create a fresh controller every time the sheet opens
    final controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      returnImage: false,
    );

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final boxWidth = context.w(0.70);
          final boxHeight = context.h(0.20);
          return SizedBox(
            height: ctx.h(0.65),
            child: Stack(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final screenWidth = constraints.maxWidth;
                    final screenHeight = constraints.maxHeight;

                    final scanRect = Rect.fromCenter(
                      center: Offset(
                        screenWidth / 2,
                        screenHeight / 2,
                      ),
                      width: boxWidth,
                      height: boxHeight,
                    );

                    return MobileScanner(
                      controller: controller,
                      scanWindow: scanRect,
                      onDetect: (capture) =>
                          _onDetect(capture, setSheetState, controller),
                      errorBuilder: (context, error) {
                        debugPrint('[Scanner] ERROR: $error');
                        return Center(
                          child: Text('Camera error: $error',
                              style: const TextStyle(color: Colors.red)),
                        );
                      },
                    );
                  },
                ),
                // ── Dark vignette outside the scan box ───────────────────
                ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.55),
                    BlendMode.srcOut,
                  ),
                  child: Stack(
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          backgroundBlendMode: BlendMode.dstOut,
                        ),
                      ),
                      Center(
                        child: Container(
                          width: boxWidth,
                          height: boxHeight,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Scan box border ───────────────────────────────────────
                Center(
                  child: Container(
                    width: boxWidth,
                    height: boxHeight,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _hasScanned ? Colors.green : Colors.white,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                // ── Animated scan line ────────────────────────────────────
                if (!_hasScanned)
                  Center(
                    child: SizedBox(
                      width: boxWidth - 8,
                      height: boxHeight,
                      child: AnimatedBuilder(
                        animation: _scanLineAnimation,
                        builder: (_, __) {
                          return Stack(
                            clipBehavior: Clip.hardEdge,
                            children: [
                              Positioned(
                                top: _scanLineAnimation.value * (boxHeight - 4),
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 2,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        AppColors.mediumBlue.withOpacity(0.9),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),

                // ── Corner brackets ───────────────────────────────────────
                Center(
                  child: SizedBox(
                    width: boxWidth,
                    height: boxHeight,
                    child: const _CornerBrackets(),
                  ),
                ),

                // ── Instruction label ─────────────────────────────────────
                Positioned(
                  bottom: 90,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Point camera at the product barcode',
                        style: GoogleFonts.poppins(
                            color: Colors.white, fontSize: context.sp(13)),
                      ),
                    ),
                  ),
                ),

                // ── Top bar: close + flashlight ───────────────────────────
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () {
                          controller.stop();
                          Navigator.of(ctx).pop();
                        },
                        icon: const Icon(Icons.close,
                            color: Colors.white, size: 28),
                      ),
                      IconButton(
                        onPressed: () => controller.toggleTorch(),
                        icon: const Icon(Icons.flash_on,
                            color: Colors.white, size: 28),
                      ),
                    ],
                  ),
                ),

                // ── Success overlay ───────────────────────────────────────
                AnimatedOpacity(
                  opacity: _hasScanned ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: IgnorePointer(
                    child: Container(
                      color: Colors.black54,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle,
                                color: Colors.green, size: 72),
                            const SizedBox(height: 12),
                            Text(
                              'Barcode scanned!',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: context.sp(18),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Filling in product details...',
                              style: GoogleFonts.poppins(
                                  color: Colors.white70, fontSize: context.sp(13)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ).whenComplete(() {
      debugPrint('[Scanner] Sheet closed — disposing controller');
      controller.stop();
      controller.dispose();
      if (mounted) setState(() => _hasScanned = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: context.w(0.30),
              height: context.w(0.30),
              decoration: BoxDecoration(
                color: AppColors.lightBlue.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.qr_code_scanner,
                  size: 48, color: AppColors.mediumBlue),
            ),
            const SizedBox(height: 24),
            Text('Scan Product Barcode',
                style: GoogleFonts.poppins(
                    fontSize: context.sp(18), fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              'Scan the barcode on the packaging to auto-fill the product name.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: context.sp(13),
                  color: AppColors.textSecondary,
                  height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: context.w(0.55),
              child: ElevatedButton.icon(
                onPressed: _openScanner,
                icon: const Icon(Icons.camera_alt, size: 18),
                label: Text('Open Camera',
                    style:
                    GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(AppSizes.radiusXL)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: widget.onManualEntry,
              child: Text(
                "Can't scan? Enter manually",
                style: GoogleFonts.poppins(
                  fontSize: context.sp(14),
                  color: AppColors.mediumBlue,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.mediumBlue,
                ),
              ),
            ),
          ],
        ).animate().fadeIn(),
      ),
    );
  }
}



// ─── Corner Brackets ──────────────────────────────────────────────────────────
// Draws the four L-shaped corners over the scan box for a more polished look.

class _CornerBrackets extends StatelessWidget {
  const _CornerBrackets();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _CornerBracketsPainter());
  }
}

class _CornerBracketsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.mediumBlue
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const len = 20.0; // bracket arm length
    const r = 12.0;   // corner radius, should match the box's borderRadius

    // Top-left
    canvas.drawLine(const Offset(r, 0), const Offset(len, 0), paint);
    canvas.drawLine(const Offset(0, r), const Offset(0, len), paint);

    // Top-right
    canvas.drawLine(Offset(size.width - r, 0), Offset(size.width - len, 0), paint);
    canvas.drawLine(Offset(size.width, r), Offset(size.width, len), paint);

    // Bottom-left
    canvas.drawLine(Offset(0, size.height - r), Offset(0, size.height - len), paint);
    canvas.drawLine(Offset(r, size.height), Offset(len, size.height), paint);

    // Bottom-right
    canvas.drawLine(Offset(size.width, size.height - r), Offset(size.width, size.height - len), paint);
    canvas.drawLine(Offset(size.width - r, size.height), Offset(size.width - len, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: context.sp(14),
          fontWeight: FontWeight.w700,
          color: AppColors.darkBlue,
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.mediumBlue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.mediumBlue : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: context.sp(12),
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _DatePickerField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.inputBg,
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 18, color: AppColors.mediumBlue),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                date != null ? DateFormat('MMMM d, yyyy').format(date!) : label,
                style: GoogleFonts.poppins(
                  fontSize: context.sp(14),
                  color: date != null
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
