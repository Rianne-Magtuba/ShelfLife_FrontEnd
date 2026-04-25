import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../constants/app_constants.dart';
import '../widgets/shared_widgets.dart';

// ─── Add to pubspec.yaml ──────────────────────────────────────────────────────
//   mobile_scanner: ^5.2.3
//
// Android: minSdkVersion 21 in android/app/build.gradle
// iOS: camera usage description in Info.plist
// ─────────────────────────────────────────────────────────────────────────────

enum _ScanStatus { idle, scanning, success, error }

class ScanPage extends StatefulWidget {
  /// Called when a valid date is confirmed (from scan or manual entry).
  final ValueChanged<DateTime>? onDateConfirmed;

  const ScanPage({super.key, this.onDateConfirmed});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage>
    with SingleTickerProviderStateMixin {
  // ── Tab state ──
  int _tabIndex = 0; // 0 = Scan, 1 = Manual

  // ── Camera / scan state ──
  final MobileScannerController _scannerCtrl = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );
  bool _torchOn = false;
  _ScanStatus _status = _ScanStatus.idle;
  DateTime? _scannedDate;
  String? _rawScanned;
  bool _isProcessing = false;

  // ── Manual entry ──
  DateTime? _manualDate;
  final _manualItemNameCtrl = TextEditingController();

  @override
  void dispose() {
    _scannerCtrl.dispose();
    _manualItemNameCtrl.dispose();
    super.dispose();
  }

  // ─── Date parsing from barcode / OCR text ────────────────────────────────

  DateTime? _tryParseDate(String raw) {
    // Common formats: MM/YYYY, MM/DD/YYYY, YYYY-MM-DD, DDMMYYYY, etc.
    raw = raw.replaceAll(RegExp(r'[^0-9/\-.]'), '');

    final patterns = [
      // YYYY-MM-DD
      RegExp(r'^(\d{4})-(\d{2})-(\d{2})$'),
      // MM/DD/YYYY or DD/MM/YYYY
      RegExp(r'^(\d{2})[/.](\d{2})[/.](\d{4})$'),
      // MM/YYYY
      RegExp(r'^(\d{2})/(\d{4})$'),
      // DDMMYYYY
      RegExp(r'^(\d{2})(\d{2})(\d{4})$'),
    ];

    for (final p in patterns) {
      final m = p.firstMatch(raw);
      if (m == null) continue;
      try {
        if (m.groupCount == 2) {
          // MM/YYYY → last day of month
          final month = int.parse(m.group(1)!);
          final year = int.parse(m.group(2)!);
          return DateTime(year, month + 1, 0);
        } else if (m.groupCount == 3) {
          final g1 = int.parse(m.group(1)!);
          final g2 = int.parse(m.group(2)!);
          final g3 = int.parse(m.group(3)!);
          // YYYY-MM-DD
          if (g1 > 1000) return DateTime(g1, g2, g3);
          // MM/DD/YYYY: if g2 > 12 assume DD/MM/YYYY
          if (g2 > 12) return DateTime(g3, g2, g1);
          return DateTime(g3, g1, g2);
        }
      } catch (_) {}
    }
    return null;
  }

  // ─── Barcode detected ────────────────────────────────────────────────────

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing || _status == _ScanStatus.success) return;

    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null) continue;

      final date = _tryParseDate(raw);
      if (date != null) {
        setState(() {
          _isProcessing = true;
          _rawScanned = raw;
          _scannedDate = date;
          _status = _ScanStatus.success;
        });
        _scannerCtrl.stop();
        return;
      }
    }

    // No date found — show error briefly
    if (_status != _ScanStatus.error) {
      setState(() => _status = _ScanStatus.error);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _status = _ScanStatus.scanning);
      });
    }
  }

  // ─── Actions ─────────────────────────────────────────────────────────────

  void _confirmScannedDate() {
    if (_scannedDate != null) {
      widget.onDateConfirmed?.call(_scannedDate!);
      Navigator.pop(context, _scannedDate);
    }
  }

  void _retryScanning() {
    setState(() {
      _status = _ScanStatus.idle;
      _scannedDate = null;
      _rawScanned = null;
      _isProcessing = false;
    });
    _scannerCtrl.start();
  }

  void _toggleTorch() {
    _scannerCtrl.toggleTorch();
    setState(() => _torchOn = !_torchOn);
  }

  Future<void> _pickManualDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 10),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.mediumBlue,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _manualDate = picked);
  }

  void _confirmManual() {
    if (_manualDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an expiry date')),
      );
      return;
    }
    widget.onDateConfirmed?.call(_manualDate!);
    Navigator.pop(context, _manualDate);
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: Column(
          children: [
            // Header with tabs
            AppHeader(
              title: 'Add New Item',
              bottom: _buildTabBar(),
              bottomHeight: 52,
            ),
            Expanded(
              child: IndexedStack(
                index: _tabIndex,
                children: [
                  _buildScanTab(),
                  _buildManualTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
        ),
        child: Row(
          children: [
            _TabButton(
              label: 'Manual Entry',
              isSelected: _tabIndex == 0,
              onTap: () => setState(() => _tabIndex = 0),
            ),
            _TabButton(
              label: '📷  Scan Date',
              isSelected: _tabIndex == 1,
              onTap: () => setState(() => _tabIndex = 1),
            ),
          ],
        ),
      ),
    );
  }

  // ── Scan Tab ──

  Widget _buildScanTab() {
    return Stack(
      children: [
        // Camera feed
        MobileScanner(
          controller: _scannerCtrl,
          onDetect: _onDetect,
        ),

        // Semi-transparent overlay
        _ScanOverlay(status: _status),

        // Guide box label
        Positioned(
          top: MediaQuery.of(context).size.height * 0.28,
          left: 0,
          right: 0,
          child: Center(
            child: _StatusLabel(status: _status),
          ),
        ),

        // Success overlay
        if (_status == _ScanStatus.success && _scannedDate != null)
          _ScannedResultOverlay(
            date: _scannedDate!,
            raw: _rawScanned ?? '',
            onConfirm: _confirmScannedDate,
            onRetry: _retryScanning,
          ),

        // Bottom controls
        if (_status != _ScanStatus.success)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _ScanBottomBar(
              torchOn: _torchOn,
              onTorchToggle: _toggleTorch,
              onManualEntry: () => setState(() => _tabIndex = 0),
            ),
          ),
      ],
    );
  }

  // ── Manual Entry Tab ──

  Widget _buildManualTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // Info banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.lightBlue,
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    color: AppColors.darkBlue, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Can\'t scan? Enter the expiry date manually below.',
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: AppColors.darkBlue),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Item name
          Text('Item Name',
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _manualItemNameCtrl,
            decoration: const InputDecoration(
              hintText: 'e.g. Milk, Yogurt...',
              prefixIcon:
                  Icon(Icons.fastfood_outlined, color: AppColors.mediumBlue),
            ),
          ),

          const SizedBox(height: 20),

          // Expiry date picker
          Text('Expiry Date',
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _pickManualDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.inputBg,
                borderRadius: BorderRadius.circular(AppSizes.radiusM),
                border: Border.all(
                  color: _manualDate != null
                      ? AppColors.mediumBlue
                      : AppColors.divider,
                  width: _manualDate != null ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_outlined,
                      color: _manualDate != null
                          ? AppColors.mediumBlue
                          : AppColors.textSecondary,
                      size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _manualDate != null
                          ? '${_manualDate!.day.toString().padLeft(2, '0')}/'
                              '${_manualDate!.month.toString().padLeft(2, '0')}/'
                              '${_manualDate!.year}'
                          : 'Select expiry date',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: _manualDate != null
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  if (_manualDate != null)
                    ExpiryChip(
                        daysLeft:
                            _manualDate!.difference(DateTime.now()).inDays),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          PrimaryButton(
            label: 'Continue',
            icon: Icons.arrow_forward,
            onPressed: _manualDate != null ? _confirmManual : null,
          ),

          const SizedBox(height: 12),

          Center(
            child: TextButton.icon(
              onPressed: () => setState(() => _tabIndex = 1),
              icon: const Icon(Icons.camera_alt_outlined, size: 16),
              label: Text('Try scanning instead',
                  style: GoogleFonts.poppins(fontSize: 13)),
              style:
                  TextButton.styleFrom(foregroundColor: AppColors.mediumBlue),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Scan Overlay ─────────────────────────────────────────────────────────────

class _ScanOverlay extends StatelessWidget {
  final _ScanStatus status;
  const _ScanOverlay({required this.status});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const boxW = 280.0;
    const boxH = 120.0;
    final boxTop = size.height * 0.28 - boxH / 2;
    final boxLeft = (size.width - boxW) / 2;

    Color borderColor;
    switch (status) {
      case _ScanStatus.success:
        borderColor = AppColors.fresh;
        break;
      case _ScanStatus.error:
        borderColor = AppColors.expired;
        break;
      default:
        borderColor = Colors.white;
    }

    return Stack(
      children: [
        // Dark overlay — four rectangles around the box
        Positioned.fill(
          child: CustomPaint(
            painter: _OverlayPainter(
              boxRect: Rect.fromLTWH(boxLeft, boxTop, boxW, boxH),
            ),
          ),
        ),
        // Guide box border
        Positioned(
          left: boxLeft,
          top: boxTop,
          child: Container(
            width: boxW,
            height: boxH,
            decoration: BoxDecoration(
              border: Border.all(color: borderColor, width: 2.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: status == _ScanStatus.scanning ? const _ScanLine() : null,
          ),
        ),
        // Corner accents
        ..._buildCorners(boxLeft, boxTop, boxW, boxH, borderColor),
      ],
    );
  }

  List<Widget> _buildCorners(
      double l, double t, double w, double h, Color color) {
    const len = 20.0;
    const thick = 3.0;
    return [
      _Corner(
          left: l,
          top: t,
          color: color,
          len: len,
          thick: thick,
          horizontal: Alignment.centerLeft,
          vertical: Alignment.topCenter),
      _Corner(
          left: l + w - len,
          top: t,
          color: color,
          len: len,
          thick: thick,
          horizontal: Alignment.centerRight,
          vertical: Alignment.topCenter),
      _Corner(
          left: l,
          top: t + h - len,
          color: color,
          len: len,
          thick: thick,
          horizontal: Alignment.centerLeft,
          vertical: Alignment.bottomCenter),
      _Corner(
          left: l + w - len,
          top: t + h - len,
          color: color,
          len: len,
          thick: thick,
          horizontal: Alignment.centerRight,
          vertical: Alignment.bottomCenter),
    ];
  }
}

class _Corner extends StatelessWidget {
  final double left, top, len, thick;
  final Color color;
  final Alignment horizontal, vertical;

  const _Corner({
    required this.left,
    required this.top,
    required this.color,
    required this.len,
    required this.thick,
    required this.horizontal,
    required this.vertical,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      child: SizedBox(
        width: len,
        height: len,
        child: CustomPaint(
          painter: _CornerPainter(
            color: color,
            thick: thick,
            hAlign: horizontal,
            vAlign: vertical,
          ),
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final double thick;
  final Alignment hAlign, vAlign;

  const _CornerPainter({
    required this.color,
    required this.thick,
    required this.hAlign,
    required this.vAlign,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thick
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final left = hAlign == Alignment.centerLeft;
    final top = vAlign == Alignment.topCenter;
    final x = left ? 0.0 : size.width;
    final y = top ? 0.0 : size.height;

    canvas.drawLine(Offset(x, y), Offset(left ? size.width : 0, y), paint);
    canvas.drawLine(Offset(x, y), Offset(x, top ? size.height : 0), paint);
  }

  @override
  bool shouldRepaint(_CornerPainter old) => false;
}

class _OverlayPainter extends CustomPainter {
  final Rect boxRect;
  const _OverlayPainter({required this.boxRect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black54;
    final full = Rect.fromLTWH(0, 0, size.width, size.height);
    final path = Path()
      ..addRect(full)
      ..addRRect(RRect.fromRectAndRadius(boxRect, const Radius.circular(12)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_OverlayPainter old) => old.boxRect != boxRect;
}

// ─── Animated Scan Line ───────────────────────────────────────────────────────

class _ScanLine extends StatefulWidget {
  const _ScanLine();

  @override
  State<_ScanLine> createState() => _ScanLineState();
}

class _ScanLineState extends State<_ScanLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        duration: const Duration(milliseconds: 1500), vsync: this)
      ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Positioned(
        top: _anim.value * 96,
        left: 8,
        right: 8,
        child: Container(
          height: 2,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Colors.transparent,
                AppColors.mediumBlue,
                Colors.transparent,
              ],
            ),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
    );
  }
}

// ─── Status Label ─────────────────────────────────────────────────────────────

class _StatusLabel extends StatelessWidget {
  final _ScanStatus status;
  const _StatusLabel({required this.status});

  @override
  Widget build(BuildContext context) {
    String text;
    Color bg;
    Color fg = Colors.white;
    IconData? icon;

    switch (status) {
      case _ScanStatus.scanning:
        text = 'Scanning…';
        bg = AppColors.mediumBlue.withOpacity(0.85);
        icon = null;
        break;
      case _ScanStatus.success:
        text = 'Date recognized!';
        bg = AppColors.fresh.withOpacity(0.9);
        icon = Icons.check_circle_outline;
        break;
      case _ScanStatus.error:
        text = 'No date found. Try again.';
        bg = AppColors.expired.withOpacity(0.9);
        icon = Icons.error_outline;
        break;
      default:
        text = 'Align expiry date inside the box';
        bg = Colors.black54;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == _ScanStatus.scanning)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            ),
          if (icon != null) Icon(icon, color: fg, size: 16),
          if (status == _ScanStatus.scanning || icon != null)
            const SizedBox(width: 6),
          Flexible(
            child: Text(text,
                style: GoogleFonts.poppins(
                    fontSize: 12, fontWeight: FontWeight.w500, color: fg)),
          ),
        ],
      ),
    );
  }
}

// ─── Scanned Result Overlay ───────────────────────────────────────────────────

class _ScannedResultOverlay extends StatelessWidget {
  final DateTime date;
  final String raw;
  final VoidCallback onConfirm;
  final VoidCallback onRetry;

  const _ScannedResultOverlay({
    required this.date,
    required this.raw,
    required this.onConfirm,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final daysLeft = date.difference(DateTime.now()).inDays;
    final formatted =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXL)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success icon
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: AppColors.freshBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline,
                  color: AppColors.fresh, size: 30),
            ),
            const SizedBox(height: 12),
            Text('Expiry Date Recognized',
                style: GoogleFonts.poppins(
                    fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Raw: $raw',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            // Date card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.inputBg,
                borderRadius: BorderRadius.circular(AppSizes.radiusM),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      color: AppColors.mediumBlue, size: 20),
                  const SizedBox(width: 10),
                  Text(formatted,
                      style: GoogleFonts.poppins(
                          fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 10),
                  ExpiryChip(daysLeft: daysLeft),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: Text('Retry',
                        style: GoogleFonts.poppins(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.divider),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusL)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: onConfirm,
                    icon: const Icon(Icons.check, size: 16),
                    label: Text('Confirm Date',
                        style: GoogleFonts.poppins(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.fresh,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusL)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bottom Bar ───────────────────────────────────────────────────────────────

class _ScanBottomBar extends StatelessWidget {
  final bool torchOn;
  final VoidCallback onTorchToggle;
  final VoidCallback onManualEntry;

  const _ScanBottomBar({
    required this.torchOn,
    required this.onTorchToggle,
    required this.onManualEntry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
      decoration: const BoxDecoration(
        color: Colors.black87,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXL)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Torch button
          GestureDetector(
            onTap: onTorchToggle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: torchOn
                    ? Colors.amber.withOpacity(0.2)
                    : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: torchOn ? Colors.amber : Colors.white30,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    torchOn ? Icons.flash_on : Icons.flash_off,
                    color: torchOn ? Colors.amber : Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    torchOn ? 'Torch On' : 'Torch Off',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: torchOn ? Colors.amber : Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Manual entry link
          TextButton(
            onPressed: onManualEntry,
            child: Text(
              "Can't scan? Enter manually",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.lightBlue,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.lightBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tab Button ───────────────────────────────────────────────────────────────

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSizes.radiusM),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? AppColors.darkBlue : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
