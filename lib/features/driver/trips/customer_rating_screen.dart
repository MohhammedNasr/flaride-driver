import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';

class CustomerRatingScreen extends StatefulWidget {
  final String tripId;
  final String passengerName;
  final String fare;
  final String paymentMethod;
  const CustomerRatingScreen({super.key, required this.tripId, required this.passengerName, required this.fare, required this.paymentMethod});
  @override
  State<CustomerRatingScreen> createState() => _State();
}

class _State extends State<CustomerRatingScreen> {
  int _rating = 0;
  bool _submitting = false;

  Future<void> _submit() async {
    setState(() => _submitting = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          const Spacer(),
          const Icon(Icons.check_circle, color: AppColors.primaryGreen, size: 64),
          const SizedBox(height: 16),
          Text('Trip Completed!', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(widget.fare, style: GoogleFonts.poppins(fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.primaryOrange)),
          Text(widget.paymentMethod == 'cash' ? 'Collect cash' : 'Card payment', style: GoogleFonts.poppins(fontSize: 14, color: AppColors.midGray)),
          const SizedBox(height: 32),
          Text('Rate ${widget.passengerName}', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _stars(),
          const Spacer(),
          _btn(),
          const SizedBox(height: 12),
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('Skip', style: GoogleFonts.poppins(color: AppColors.midGray))),
        ]),
      )),
    );
  }

  Widget _stars() => Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) => GestureDetector(onTap: () => setState(() => _rating = i + 1), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Icon(i < _rating ? Icons.star_rounded : Icons.star_outline_rounded, size: 44, color: i < _rating ? Colors.amber : Colors.grey.shade300)))));

  Widget _btn() => SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _rating == 0 || _submitting ? null : _submit, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryOrange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: _submitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text('Submit Rating', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600))));
}
