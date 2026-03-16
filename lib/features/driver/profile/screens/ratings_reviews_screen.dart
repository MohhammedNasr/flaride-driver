import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';
import 'package:flaride_driver/core/providers/driver_provider.dart';
import 'package:flaride_driver/core/config/api_config.dart';

class RatingsReviewsScreen extends StatefulWidget {
  const RatingsReviewsScreen({super.key});

  @override
  State<RatingsReviewsScreen> createState() => _RatingsReviewsScreenState();
}

class _RatingsReviewsScreenState extends State<RatingsReviewsScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _reviewsData;
  String _sortBy = 'recent';
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  int _currentOffset = 0;
  final int _limit = 20;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  @override
  void initState() {
    super.initState();
    _loadReviews();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMoreReviews();
    }
  }

  Future<void> _loadReviews({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentOffset = 0;
        _isLoading = true;
      });
    }

    try {
      final driverProvider = context.read<DriverProvider>();
      final driverId = driverProvider.driver?.id;

      if (driverId == null) {
        setState(() {
          _error = 'Driver ID not found';
          _isLoading = false;
        });
        return;
      }

      final token = await _getToken();
      if (token == null) {
        setState(() {
          _error = 'Not authenticated';
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.apiBaseUrl}/drivers/$driverId/reviews?sort=$_sortBy&limit=$_limit&offset=0'),
        headers: ApiConfig.getAuthHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _reviewsData = data;
          _currentOffset = _limit;
          _isLoading = false;
          _error = null;
        });
      } else {
        setState(() {
          _error = 'Failed to load reviews';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreReviews() async {
    if (_isLoadingMore || _reviewsData == null) return;
    
    final pagination = _reviewsData!['pagination'];
    if (pagination == null || !(pagination['has_more'] ?? false)) return;

    setState(() => _isLoadingMore = true);

    try {
      final driverProvider = context.read<DriverProvider>();
      final driverId = driverProvider.driver?.id;
      final token = await _getToken();
      
      if (token == null || driverId == null) {
        setState(() => _isLoadingMore = false);
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.apiBaseUrl}/drivers/$driverId/reviews?sort=$_sortBy&limit=$_limit&offset=$_currentOffset'),
        headers: ApiConfig.getAuthHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          final existingReviews = List<Map<String, dynamic>>.from(_reviewsData!['reviews'] ?? []);
          final newReviews = List<Map<String, dynamic>>.from(data['reviews'] ?? []);
          existingReviews.addAll(newReviews);
          _reviewsData!['reviews'] = existingReviews;
          _reviewsData!['pagination'] = data['pagination'];
          _currentOffset += _limit;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingMore = false);
    }
  }

  void _onSortChanged(String sort) {
    if (_sortBy != sort) {
      setState(() => _sortBy = sort);
      _loadReviews(refresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkGray),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Ratings & Reviews',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.darkGray,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange))
          : _error != null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.midGray),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: GoogleFonts.poppins(color: AppColors.midGray),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _loadReviews(refresh: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
            ),
            child: Text('Retry', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final summary = _reviewsData?['summary'];
    final reviews = List<Map<String, dynamic>>.from(_reviewsData?['reviews'] ?? []);

    return RefreshIndicator(
      onRefresh: () => _loadReviews(refresh: true),
      color: AppColors.primaryOrange,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(child: _buildSummaryCard(summary)),
          SliverToBoxAdapter(child: _buildRatingBreakdown(summary)),
          SliverToBoxAdapter(child: _buildSortHeader(reviews.length)),
          if (reviews.isEmpty)
            SliverToBoxAdapter(child: _buildEmptyState())
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index == reviews.length) {
                    return _isLoadingMore
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator(color: AppColors.primaryOrange)),
                          )
                        : const SizedBox.shrink();
                  }
                  return _buildReviewCard(reviews[index]);
                },
                childCount: reviews.length + 1,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(Map<String, dynamic>? summary) {
    final averageRating = (summary?['average_rating'] ?? 0.0).toDouble();
    final totalReviews = summary?['total_reviews'] ?? 0;
    final ratingStatus = summary?['rating_status'] ?? 'good';
    final statusMessage = summary?['status_message'] ?? 'Good standing';
    final ratingTrend = summary?['rating_trend'] ?? 'stable';

    Color statusColor;
    IconData statusIcon;
    switch (ratingStatus) {
      case 'excellent':
        statusColor = Colors.green;
        statusIcon = Icons.verified;
        break;
      case 'good':
        statusColor = AppColors.primaryGreen;
        statusIcon = Icons.thumb_up;
        break;
      case 'warning':
        statusColor = Colors.orange;
        statusIcon = Icons.warning;
        break;
      case 'critical':
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
      default:
        statusColor = AppColors.primaryGreen;
        statusIcon = Icons.thumb_up;
    }

    IconData trendIcon;
    Color trendColor;
    switch (ratingTrend) {
      case 'improving':
        trendIcon = Icons.trending_up;
        trendColor = Colors.green;
        break;
      case 'declining':
        trendIcon = Icons.trending_down;
        trendColor = Colors.red;
        break;
      default:
        trendIcon = Icons.trending_flat;
        trendColor = AppColors.midGray;
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryOrange, AppColors.primaryOrange.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryOrange.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                averageRating.toStringAsFixed(1),
                style: GoogleFonts.poppins(
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Icon(trendIcon, color: Colors.white, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return Icon(
                index < averageRating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                color: Colors.white,
                size: 24,
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            '$totalReviews reviews',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  statusMessage,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBreakdown(Map<String, dynamic>? summary) {
    final breakdown = Map<String, dynamic>.from(summary?['rating_breakdown'] ?? {});
    final percentages = Map<String, dynamic>.from(summary?['rating_percentages'] ?? {});
    final totalReviews = summary?['total_reviews'] ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rating Breakdown',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(5, (index) {
            final stars = 5 - index;
            final count = breakdown['$stars'] ?? 0;
            final percentage = (percentages['$stars'] ?? 0).toDouble();
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    child: Text(
                      '$stars',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.darkGray,
                      ),
                    ),
                  ),
                  const Icon(Icons.star_rounded, color: AppColors.primaryOrange, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: AppColors.lightGray,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          stars >= 4 ? Colors.green : stars >= 3 ? AppColors.primaryOrange : Colors.red,
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '$count',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.midGray,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSortHeader(int reviewCount) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Reviews ($reviewCount)',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.darkGray,
            ),
          ),
          PopupMenuButton<String>(
            onSelected: _onSortChanged,
            initialValue: _sortBy,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.lightGray),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getSortLabel(_sortBy),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.midGray,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, color: AppColors.midGray, size: 20),
                ],
              ),
            ),
            itemBuilder: (context) => [
              PopupMenuItem(value: 'recent', child: Text('Most Recent', style: GoogleFonts.poppins())),
              PopupMenuItem(value: 'highest', child: Text('Highest Rated', style: GoogleFonts.poppins())),
              PopupMenuItem(value: 'lowest', child: Text('Lowest Rated', style: GoogleFonts.poppins())),
            ],
          ),
        ],
      ),
    );
  }

  String _getSortLabel(String sort) {
    switch (sort) {
      case 'highest':
        return 'Highest';
      case 'lowest':
        return 'Lowest';
      default:
        return 'Recent';
    }
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.rate_review_outlined,
            size: 80,
            color: AppColors.midGray.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Reviews Yet',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete deliveries to receive reviews from customers',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.midGray,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final rating = (review['rating'] ?? 0).toInt();
    final comment = review['comment'] ?? '';
    final reviewer = review['reviewer'];
    final reviewerName = reviewer?['name'] ?? 'Customer';
    final reviewerAvatar = reviewer?['avatar_url'];
    final timeAgo = review['time_ago'] ?? '';
    final orderNumber = review['order_number'];
    final isVerified = review['is_verified'] ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.lightGray,
                backgroundImage: reviewerAvatar != null ? NetworkImage(reviewerAvatar) : null,
                child: reviewerAvatar == null
                    ? Text(
                        reviewerName.isNotEmpty ? reviewerName[0].toUpperCase() : 'C',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: AppColors.midGray,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            reviewerName,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.darkGray,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isVerified) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.verified, color: Colors.blue, size: 14),
                        ],
                      ],
                    ),
                    Text(
                      timeAgo,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.midGray,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: AppColors.primaryOrange,
                    size: 18,
                  );
                }),
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              comment,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.darkGray,
                height: 1.5,
              ),
            ),
          ],
          if (orderNumber != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.lightGray,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Order #$orderNumber',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppColors.midGray,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
