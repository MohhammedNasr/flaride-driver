import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';
import 'package:flaride_driver/features/driver/parcels/parcel_order_model.dart';
import 'package:flaride_driver/features/driver/parcels/parcel_trip_completed_screen.dart';

class ParcelRatingScreen extends StatefulWidget {
  final ActiveParcelOrder order;
  const ParcelRatingScreen({super.key, required this.order});

  @override
  State<ParcelRatingScreen> createState() => _ParcelRatingScreenState();
}

class _ParcelRatingScreenState extends State<ParcelRatingScreen> {
  int _rating = 0;
  final Set<String> _selectedTags = {};
  final TextEditingController _feedbackController = TextEditingController();

  final List<String> _tags = ['Polite', 'Ready on time', 'Friendly', 'Clean', 'Quiet'];

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customerName = widget.order.pickupContactName ?? widget.order.customer?.name ?? 'Customer';

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Text(
                'Rate your passenger',
                style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.darkGray),
              ),
              const SizedBox(height: 8),
              Text(
                'how was your ride with $customerName?',
                style: TextStyle(fontSize: 14, color: AppColors.midGray),
              ),
              const SizedBox(height: 24),
              // Star rating
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () => setState(() => _rating = index + 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        index < _rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 40,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              // Tags
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: _tags.map((tag) {
                  final isSelected = _selectedTags.contains(tag);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedTags.remove(tag);
                        } else {
                          _selectedTags.add(tag);
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.darkGray : AppColors.white,
                        border: Border.all(color: isSelected ? AppColors.darkGray : AppColors.lightGray, width: 1.5),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        tag,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? AppColors.white : AppColors.darkGray,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),
              // Feedback
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Additional Feedback(optional)',
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkGray),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _feedbackController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Write something about the tip..',
                  hintStyle: TextStyle(fontSize: 14, color: AppColors.midGray),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 40),
                    child: Icon(Icons.chat_bubble_outline, color: AppColors.midGray, size: 20),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.lightGray),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.lightGray),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.primaryOrange),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const Spacer(flex: 3),
              // Submit
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to trip completed screen
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ParcelTripCompletedScreen(order: widget.order),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    'Submit Rating',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
