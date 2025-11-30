import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../models/meal_plan.dart';
import '../services/meal_plan_service.dart';
import '../services/notification_service.dart';
import '../services/cache_service.dart';
import 'login_screen.dart';

class MealPlansScreen extends StatefulWidget {
  const MealPlansScreen({super.key});

  @override
  State<MealPlansScreen> createState() => _MealPlansScreenState();
}

class _MealPlansScreenState extends State<MealPlansScreen> {
  final MealPlanService _mealPlanService = MealPlanService();
  final NotificationService _notificationService = NotificationService();
  final CacheService _cacheService = CacheService();
  List<MealPlan> _mealPlans = [];
  bool _isLoading = false;
  String? _errorMessage;
  DateTime _selectedWeekStart = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedWeekStart = _getWeekStart(DateTime.now());
    _loadMealPlans();
  }

  DateTime _getWeekStart(DateTime date) {
    // Get Monday of the week
    return date.subtract(Duration(days: date.weekday - 1));
  }

  Future<void> _loadMealPlans() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final startDate = DateFormat('yyyy-MM-dd').format(_selectedWeekStart);
      final endDate = DateFormat('yyyy-MM-dd').format(
        _selectedWeekStart.add(const Duration(days: 6)),
      );

      final mealPlans = await _mealPlanService.getMealPlans(
        startDate: startDate,
        endDate: endDate,
      );

      setState(() {
        _mealPlans = mealPlans;
        _isLoading = false;
      });

      // Cache meal plans for offline access
      await _cacheService.cacheMealPlans(mealPlans.map((mp) => mp.toJson()).toList());

      // Schedule notifications for upcoming meal plans
      await _scheduleNotificationsForMealPlans(mealPlans);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });

      // If authentication failed, navigate to login
      if (e.toString().contains('Authentication failed')) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      }
    }
  }

  void _previousWeek() {
    setState(() {
      _selectedWeekStart = _selectedWeekStart.subtract(const Duration(days: 7));
    });
    _loadMealPlans();
  }

  void _nextWeek() {
    setState(() {
      _selectedWeekStart = _selectedWeekStart.add(const Duration(days: 7));
    });
    _loadMealPlans();
  }

  void _goToToday() {
    setState(() {
      _selectedWeekStart = _getWeekStart(DateTime.now());
    });
    _loadMealPlans();
  }

  /// Schedule notifications for all upcoming meal plans
  Future<void> _scheduleNotificationsForMealPlans(List<MealPlan> mealPlans) async {
    // Convert meal plans to the format expected by notification service
    final mealPlanMaps = mealPlans
        .where((mp) => !mp.isCompleted) // Only schedule for incomplete meals
        .map((mp) => {
              'id': mp.id,
              'planned_date': mp.plannedDate,
              'meal_type': mp.mealType,
              'recipe_name': mp.recipe?.name ?? 'Your meal',
            })
        .toList();

    await _notificationService.scheduleMealPlanNotifications(mealPlanMaps);
  }

  List<MealPlan> _getMealPlansForDay(DateTime date, String mealType) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    return _mealPlans.where((mp) => mp.plannedDate == dateStr && mp.mealType == mealType).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Week Navigation
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(Icons.chevron_left_rounded, color: AppColors.onSurface),
                  onPressed: _previousWeek,
                ),
              ),
              Column(
                children: [
                  Text(
                    DateFormat('MMMM yyyy').format(_selectedWeekStart),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: _goToToday,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.today_rounded, size: 16, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            'Today',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(Icons.chevron_right_rounded, color: AppColors.onSurface),
                  onPressed: _nextWeek,
                ),
              ),
            ],
          ),
        ),

        // Content
        Expanded(
          child: _isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppColors.primary),
                      const SizedBox(height: 16),
                      Text(
                        'Loading meal plans...',
                        style: TextStyle(color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                )
              : _errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Oops! Something went wrong',
                              style: Theme.of(context).textTheme.titleLarge,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _errorMessage!,
                              style: TextStyle(color: AppColors.onSurfaceVariant),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _loadMealPlans,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Try Again'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadMealPlans,
                      color: AppColors.primary,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 100),
                        child: Column(
                          children: List.generate(7, (index) {
                            final date = _selectedWeekStart.add(Duration(days: index));
                            return _buildDayCard(date);
                          }),
                        ),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildDayCard(DateTime date) {
    final isToday = DateFormat('yyyy-MM-dd').format(date) == DateFormat('yyyy-MM-dd').format(DateTime.now());
    final dayName = DateFormat('EEEE').format(date);
    final dateStr = DateFormat('MMM d').format(date);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isToday ? AppColors.primary.withValues(alpha: 0.08) : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: isToday ? Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isToday ? 0.08 : 0.04),
            blurRadius: isToday ? 15 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          childrenPadding: const EdgeInsets.only(bottom: 16),
          title: Row(
            children: [
              Text(
                dayName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isToday ? AppColors.primary : AppColors.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                dateStr,
                style: TextStyle(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
              if (isToday) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Today',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          children: [
            _buildMealTypeSection(date, 'breakfast', Icons.wb_sunny_rounded, AppColors.accent),
            _buildMealTypeSection(date, 'lunch', Icons.lunch_dining_rounded, AppColors.primary),
            _buildMealTypeSection(date, 'dinner', Icons.dinner_dining_rounded, AppColors.secondary),
            _buildMealTypeSection(date, 'snack', Icons.cookie_rounded, AppColors.warning),
          ],
        ),
      ),
    );
  }

  Widget _buildMealTypeSection(DateTime date, String mealType, IconData icon, Color color) {
    final meals = _getMealPlansForDay(date, mealType);
    final mealTypeLabel = mealType[0].toUpperCase() + mealType.substring(1);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 10),
              Text(
                mealTypeLabel,
                style: TextStyle(fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (meals.isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 34),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'No meal planned',
                  style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13),
                ),
              ),
            )
          else
            ...meals.map((meal) => _buildMealPlanCard(meal)),
        ],
      ),
    );
  }

  Widget _buildMealPlanCard(MealPlan mealPlan) {
    return Padding(
      padding: const EdgeInsets.only(left: 34, top: 4, bottom: 4),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: mealPlan.isCompleted
              ? AppColors.success.withValues(alpha: 0.1)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: mealPlan.isCompleted
                ? AppColors.success.withValues(alpha: 0.3)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: mealPlan.isCompleted
                    ? AppColors.success.withValues(alpha: 0.2)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                mealPlan.isCompleted ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: mealPlan.isCompleted ? AppColors.success : AppColors.onSurfaceVariant,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mealPlan.recipe?.name ?? 'Recipe #${mealPlan.recipeId}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: mealPlan.isCompleted ? AppColors.success : AppColors.onSurface,
                    ),
                  ),
                  if (mealPlan.userNotes != null && mealPlan.userNotes!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      mealPlan.userNotes!,
                      style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
