import 'package:flutter/material.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';
import 'package:flaride_driver/core/config/api_config.dart';
import 'package:flaride_driver/core/services/auth_service.dart';
import 'package:flaride_driver/shared/widgets/skeleton_loader.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final AuthService _authService = AuthService();
  
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _goalsData;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await _authService.getToken();
      if (token == null) {
        setState(() {
          _error = 'Not authenticated';
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.apiBaseUrl}/api/driver/goals'),
        headers: ApiConfig.getAuthHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _goalsData = data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load goals';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading goals: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Goals & Achievements'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.darkGray,
        elevation: 0,
      ),
      body: _isLoading
          ? _buildLoadingSkeleton()
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _loadGoals,
                  color: AppColors.primaryOrange,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDailyGoals(),
                        const SizedBox(height: 24),
                        _buildWeeklyGoals(),
                        const SizedBox(height: 24),
                        _buildBonuses(),
                        const SizedBox(height: 24),
                        _buildAchievements(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          EarningsCardSkeleton(),
          SizedBox(height: 16),
          EarningsCardSkeleton(),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadGoals,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyGoals() {
    final dailyGoals = _goalsData?['daily_goals'] as Map<String, dynamic>?;
    if (dailyGoals == null) return const SizedBox.shrink();

    return _buildGoalCard(
      title: "Today's Goals",
      icon: Icons.today,
      color: AppColors.primaryOrange,
      goals: dailyGoals,
    );
  }

  Widget _buildWeeklyGoals() {
    final weeklyGoals = _goalsData?['weekly_goals'] as Map<String, dynamic>?;
    if (weeklyGoals == null) return const SizedBox.shrink();

    return _buildGoalCard(
      title: 'Weekly Goals',
      icon: Icons.calendar_view_week,
      color: AppColors.primaryGreen,
      goals: weeklyGoals,
    );
  }

  Widget _buildGoalCard({
    required String title,
    required IconData icon,
    required Color color,
    required Map<String, dynamic> goals,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...goals.entries.map((entry) {
            final goal = entry.value as Map<String, dynamic>;
            final current = (goal['current'] as num).toDouble();
            final target = (goal['target'] as num).toDouble();
            final unit = goal['unit'] as String? ?? '';
            final progress = (current / target).clamp(0.0, 1.0);
            final isComplete = current >= target;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatGoalName(entry.key),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.midGray,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            '${current.toInt()}/${target.toInt()} $unit',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isComplete ? AppColors.primaryGreen : AppColors.darkGray,
                            ),
                          ),
                          if (isComplete) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.primaryGreen,
                              size: 16,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppColors.lightGray,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isComplete ? AppColors.primaryGreen : color,
                      ),
                      minHeight: 8,
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

  Widget _buildBonuses() {
    final bonuses = _goalsData?['bonuses'] as List<dynamic>?;
    if (bonuses == null || bonuses.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Active Bonuses',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.darkGray,
          ),
        ),
        const SizedBox(height: 12),
        ...bonuses.map((bonus) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryOrange,
                  AppColors.primaryOrange.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_fire_department, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bonus['name'] ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        bonus['description'] ?? '',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAchievements() {
    final achievements = _goalsData?['achievements'] as List<dynamic>?;
    if (achievements == null || achievements.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Achievements',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.darkGray,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: achievements.map((achievement) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryGreen.withOpacity(0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    achievement['icon'] ?? '🏆',
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    achievement['name'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkGray,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _formatGoalName(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
