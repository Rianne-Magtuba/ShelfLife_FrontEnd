import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';
import '../widgets/shared_widgets.dart';
import '../data/models/auth_models.dart';
import '../data/services/product_service.dart';

class RegisterProductPage extends StatefulWidget {
  final String scannedBarcode;
  const RegisterProductPage({super.key, required this.scannedBarcode});

  @override
  State<RegisterProductPage> createState() => _RegisterProductPageState();
}

class _RegisterProductPageState extends State<RegisterProductPage> {
  final _formKey  = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  String _category = 'Fridge';
  bool   _saving   = false;

  // ⚠️ Change to ProductService() when backend is ready
  final IProductService _service = MockProductService();

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final product = await _service.registerProduct(
        ProductRequest(
          barcode:  widget.scannedBarcode,
          name:     _nameCtrl.text.trim(),
          category: _category,
        ),
      );
      if (!mounted) return;
      // Returns the registered product back to AddItemPage for auto-fill
      context.pop(product);

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.expired,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────────────
            Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 12,
                left: 16, right: 16, bottom: 24,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.darkBlue, AppColors.mediumBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft:  Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white, size: 20),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Register New Product',
                            style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                        Text('Add this item to the global catalog',
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Form ─────────────────────────────────────────────────────
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(AppSizes.paddingM),
                  children: [
                    const SizedBox(height: 8),

                    // Info banner
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.lightBlue,
                        borderRadius:
                        BorderRadius.circular(AppSizes.radiusM),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              color: AppColors.darkBlue, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Barcode not in catalog. Fill in the "
                                  "details and everyone will benefit next time!",
                              style: GoogleFonts.poppins(
                                  fontSize: 13, color: AppColors.darkBlue),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(),

                    const SizedBox(height: 20),

                    // Barcode — read-only, auto-filled from scanner
                    TextFormField(
                      initialValue: widget.scannedBarcode,
                      readOnly: true,
                      style: GoogleFonts.poppins(
                          color: AppColors.textSecondary),
                      decoration: const InputDecoration(
                        labelText: 'Barcode (auto-filled)',
                        prefixIcon: Icon(Icons.qr_code, size: 18),
                      ),
                    ).animate().fadeIn(delay: 50.ms),

                    const SizedBox(height: 14),

                    // ── Shared widget — same Name + Category fields ────────
                    // as AddItemPage's _ManualForm, zero duplication
                    ProductBasicFields(
                      nameCtrl:         _nameCtrl,
                      selectedCategory: _category,
                      onCategoryChanged: (v) {
                        if (v != null) setState(() => _category = v);
                      },
                    ).animate().fadeIn(delay: 100.ms),

                    const SizedBox(height: 32),

                    PrimaryButton(
                      label:     'Register Product',
                      onPressed: _submit,
                      isLoading: _saving,
                      icon:      Icons.check,
                    ).animate().fadeIn(delay: 200.ms),
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