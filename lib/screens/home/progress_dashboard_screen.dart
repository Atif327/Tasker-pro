import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../database/database_helper.dart';
import '../../models/task_model.dart';
import '../../services/auth_service.dart';

class ProgressDashboardScreen extends StatefulWidget {
  const ProgressDashboardScreen({super.key});

  @override
  State<ProgressDashboardScreen> createState() => _ProgressDashboardScreenState();
}

class _ProgressDashboardScreenState extends State<ProgressDashboardScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final AuthService _auth = AuthService();

  bool _loading = true;
  List<Task> _all = [];
  List<Task> _completed = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = await _auth.getCurrentUserId();
    if (userId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final all = await _db.getAllTasks(userId);
    final completed = await _db.getCompletedTasks(userId);
    if (!mounted) return;
    setState(() {
      _all = all;
      _completed = completed;
      _loading = false;
    });
  }

  Map<DateTime, int> _dailyCompletions({int days = 56}) {
    final Map<DateTime, int> map = {};
    final now = DateTime.now();
    for (int i = 0; i < days; i++) {
      final d = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      map[d] = 0;
    }
    for (final t in _completed) {
      final c = t.completedAt ?? t.dueDate;
      final key = DateTime(c.year, c.month, c.day);
      if (map.containsKey(key)) map[key] = (map[key] ?? 0) + 1;
    }
    return map;
  }

  int _currentStreak() {
    int streak = 0;
    DateTime cursor = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final set = _completed
        .map((t) => t.completedAt ?? t.dueDate)
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet();
    while (set.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  double _completionRate({int days = 30}) {
    final now = DateTime.now();
    final cutoff = now.subtract(Duration(days: days));
    final recent = _all.where((t) => t.createdAt.isAfter(cutoff)).toList();
    if (recent.isEmpty) return 0.0;
    final done = recent.where((t) => t.isCompleted).length;
    return done / recent.length;
  }

  Map<String, int> _timeOfDayProductivity() {
    final Map<String, int> buckets = {'Night': 0, 'Morning': 0, 'Afternoon': 0, 'Evening': 0};
    for (final t in _completed) {
      final dt = (t.completedAt ?? t.dueTime ?? t.dueDate);
      final hour = dt.hour;
      if (hour >= 6 && hour < 12) {
        buckets['Morning'] = (buckets['Morning'] ?? 0) + 1;
      } else if (hour >= 12 && hour < 18) {
        buckets['Afternoon'] = (buckets['Afternoon'] ?? 0) + 1;
      } else if (hour >= 18 && hour < 24) {
        buckets['Evening'] = (buckets['Evening'] ?? 0) + 1;
      } else {
        buckets['Night'] = (buckets['Night'] ?? 0) + 1;
      }
    }
    return buckets;
  }

  Color _cellColor(int count, BuildContext context) {
    if (count == 0) return Theme.of(context).brightness == Brightness.dark ? Colors.grey[850]! : Colors.grey[200]!;
    if (count == 1) return Colors.green[200]!;
    if (count == 2) return Colors.green[400]!;
    if (count <= 4) return Colors.green[600]!;
    return Colors.green[800]!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Progress Dashboard')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Streak & 30-day completion
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Streak',
                          value: '${_currentStreak()}d',
                          icon: Icons.local_fire_department,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatCard(
                          title: '30d Rate',
                          value: '${(100 * _completionRate()).toStringAsFixed(0)}%',
                          icon: Icons.task_alt,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Overall counts
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Total',
                          value: '${_all.length}',
                          icon: Icons.list_alt,
                          color: Colors.teal,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatCard(
                          title: 'Done',
                          value: '${_completed.length}',
                          icon: Icons.check_circle,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Pending',
                          value: '${_all.where((t) => !t.isCompleted).length}',
                          icon: Icons.pending_actions,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatCard(
                          title: 'Repeat',
                          value: '${_all.where((t) => t.isRepeating).length}',
                          icon: Icons.repeat,
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Heatmap
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Completion Heatmap', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          _Heatmap(dailyCounts: _dailyCompletions()),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Time of day productivity
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Time-of-day Productivity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          _TimeOfDayBars(buckets: _timeOfDayProductivity()),
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

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: color.withOpacity(0.15), child: Icon(icon, color: color)),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _Heatmap extends StatelessWidget {
  final Map<DateTime, int> dailyCounts; // last 56 days
  const _Heatmap({required this.dailyCounts});

  @override
  Widget build(BuildContext context) {
    final keys = dailyCounts.keys.toList()..sort();
    // Organize by weeks (8 weeks x 7 days)
    final List<List<DateTime>> weeks = [];
    for (int i = 0; i < keys.length; i += 7) {
      final slice = keys.sublist(i, (i + 7).clamp(0, keys.length));
      weeks.add(slice);
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: weeks.map((week) {
          return Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: Column(
              children: week.map((d) {
                final count = dailyCounts[d] ?? 0;
                return Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  decoration: BoxDecoration(
                    color: _cellColor(count, context),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _cellColor(int count, BuildContext context) {
    if (count == 0) return Theme.of(context).brightness == Brightness.dark ? Colors.grey[850]! : Colors.grey[200]!;
    if (count == 1) return Colors.green[200]!;
    if (count == 2) return Colors.green[400]!;
    if (count <= 4) return Colors.green[600]!;
    return Colors.green[800]!;
  }
}

class _TimeOfDayBars extends StatelessWidget {
  final Map<String, int> buckets;
  const _TimeOfDayBars({required this.buckets});

  @override
  Widget build(BuildContext context) {
    final maxVal = (buckets.values.isEmpty ? 1 : (buckets.values.reduce((a, b) => a > b ? a : b))).toDouble().clamp(1, double.infinity);
    return Column(
      children: buckets.entries.map((e) {
        final pct = (e.value / maxVal);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
            children: [
              SizedBox(width: 90, child: Text(e.key)),
              Expanded(
                child: Stack(
                  children: [
                    Container(height: 12, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(6))),
                    FractionallySizedBox(
                      widthFactor: pct.isNaN ? 0 : pct,
                      child: Container(height: 12, decoration: BoxDecoration(color: Colors.purple, borderRadius: BorderRadius.circular(6))),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text('${e.value}')
            ],
          ),
        );
      }).toList(),
    );
  }
}
