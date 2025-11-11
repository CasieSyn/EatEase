import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/meal_plan.dart';
import '../services/meal_plan_service.dart';
import 'login_screen.dart';

class MealPlansScreen extends StatefulWidget {
  const MealPlansScreen({super.key});

  @override
  State<MealPlansScreen> createState() => _MealPlansScreenState();
}

class _MealPlansScreenState extends State<MealPlansScreen> {
  final MealPlanService _mealPlanService = MealPlanService();
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
          color: Colors.green[50],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _previousWeek,
              ),
              Column(
                children: [
                  Text(
                    DateFormat('MMMM yyyy').format(_selectedWeekStart),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  TextButton.icon(
                    onPressed: _goToToday,
                    icon: const Icon(Icons.today, size: 16),
                    label: const Text('Today'),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _nextWeek,
              ),
            ],
          ),
        ),

        // Content
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.green))
              : _errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text('Error: $_errorMessage'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadMealPlans,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadMealPlans,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: isToday ? 4 : 1,
      color: isToday ? Colors.green[50] : null,
      child: ExpansionTile(
        title: Row(
          children: [
            Text(
              dayName,
              style: TextStyle(
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              dateStr,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            if (isToday) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Today',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ],
        ),
        children: [
          _buildMealTypeSection(date, 'breakfast', Icons.wb_sunny, Colors.orange),
          _buildMealTypeSection(date, 'lunch', Icons.lunch_dining, Colors.blue),
          _buildMealTypeSection(date, 'dinner', Icons.dinner_dining, Colors.purple),
          _buildMealTypeSection(date, 'snack', Icons.cookie, Colors.brown),
        ],
      ),
    );
  }

  Widget _buildMealTypeSection(DateTime date, String mealType, IconData icon, Color color) {
    final meals = _getMealPlansForDay(date, mealType);
    final mealTypeLabel = mealType[0].toUpperCase() + mealType.substring(1);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                mealTypeLabel,
                style: TextStyle(fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (meals.isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: Text(
                'No meal planned',
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
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
      padding: const EdgeInsets.only(left: 28, top: 4, bottom: 4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: mealPlan.isCompleted ? Colors.green[50] : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: mealPlan.isCompleted ? Colors.green : Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            if (mealPlan.isCompleted)
              const Icon(Icons.check_circle, color: Colors.green, size: 20)
            else
              const Icon(Icons.circle_outlined, color: Colors.grey, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mealPlan.recipe?.name ?? 'Recipe #${mealPlan.recipeId}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  if (mealPlan.userNotes != null && mealPlan.userNotes!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      mealPlan.userNotes!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
