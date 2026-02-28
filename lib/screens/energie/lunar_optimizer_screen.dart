import 'package:flutter/material.dart';
import '../../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0
import 'package:intl/intl.dart';
import '../../models/lunar_phase.dart';
import '../../services/haptic_service.dart';

/// 🌙 LUNAR CYCLE OPTIMIZER - Lebe nach dem Mond
class LunarOptimizerScreen extends StatefulWidget {
  const LunarOptimizerScreen({super.key});

  @override
  State<LunarOptimizerScreen> createState() => _LunarOptimizerScreenState();
}

class _LunarOptimizerScreenState extends State<LunarOptimizerScreen> with SingleTickerProviderStateMixin {
  late LunarPhase _currentPhase;
  late AnimationController _moonController;
  DateTime _selectedDate = DateTime.now();
  bool _showCalendar = false;

  @override
  void initState() {
    super.initState();
    _currentPhase = LunarPhase.calculate(_selectedDate);
    
    _moonController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _moonController.dispose();
    super.dispose();
  }

  void _changeDate(DateTime newDate) {
    setState(() {
      _selectedDate = newDate;
      _currentPhase = LunarPhase.calculate(newDate);
    });
    HapticService.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A0E2E),
              Color(0xFF0A0A0A),
              Color(0xFF000000),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _showCalendar ? _buildCalendarView() : _buildPhaseView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LUNAR OPTIMIZER',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Lebe im Einklang mit dem Mond',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              _showCalendar ? Icons.today : Icons.calendar_month,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _showCalendar = !_showCalendar;
              });
              HapticService.selectionClick();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Date selector
          _buildDateSelector(),
          
          const SizedBox(height: 24),
          
          // Moon visualization
          _buildMoonVisualization(),
          
          const SizedBox(height: 32),
          
          // Phase info
          _buildPhaseInfo(),
          
          const SizedBox(height: 24),
          
          // Recommendations
          _buildRecommendations(),
          
          const SizedBox(height: 24),
          
          // Best crystals
          _buildCrystals(),
          
          const SizedBox(height: 24),
          
          // Next phases
          _buildNextPhases(),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    final today = DateTime.now();
    final isToday = _selectedDate.year == today.year &&
        _selectedDate.month == today.month &&
        _selectedDate.day == today.day;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.white),
          onPressed: () {
            _changeDate(_selectedDate.subtract(const Duration(days: 1)));
          },
        ),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (picked != null) {
              _changeDate(picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6A1B9A), Color(0xFF8E24AA)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6A1B9A).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('dd.MM.yyyy').format(_selectedDate),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isToday) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'HEUTE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right, color: Colors.white),
          onPressed: () {
            _changeDate(_selectedDate.add(const Duration(days: 1)));
          },
        ),
      ],
    );
  }

  Widget _buildMoonVisualization() {
    return AnimatedBuilder(
      animation: _moonController,
      builder: (context, child) {
        return Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6A1B9A).withValues(alpha: 0.5 + _moonController.value * 0.3),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Glow effect
              Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF6A1B9A).withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              // Moon emoji
              Text(
                _currentPhase.emoji,
                style: const TextStyle(fontSize: 120),
              ),
              // Illumination text
              Positioned(
                bottom: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(_currentPhase.illumination * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPhaseInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6A1B9A).withValues(alpha: 0.3),
            const Color(0xFF6A1B9A).withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF6A1B9A),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            _currentPhase.phaseName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _currentPhase.description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF6A1B9A).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.energy_savings_leaf, color: Color(0xFFBA68C8), size: 16),
                const SizedBox(width: 8),
                Text(
                  _currentPhase.energyType,
                  style: const TextStyle(
                    color: Color(0xFFBA68C8),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '✨ Empfehlungen',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ..._currentPhase.recommendations.map((rec) => _buildListItem(rec, Colors.green, Icons.check_circle)),
        const SizedBox(height: 16),
        const Text(
          '⚠️ Vermeiden',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ..._currentPhase.avoidActions.map((avoid) => _buildListItem(avoid, Colors.red, Icons.cancel)),
      ],
    );
  }

  Widget _buildListItem(String text, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCrystals() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '💎 Beste Kristalle',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _currentPhase.bestCrystals.map((crystal) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6A1B9A), Color(0xFF8E24AA)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6A1B9A).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                crystal,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNextPhases() {
    final nextFullMoon = LunarPhase.getNextPhaseDate(_selectedDate, 'Vollmond');
    final nextNewMoon = LunarPhase.getNextPhaseDate(_selectedDate, 'Neumond');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📅 Nächste Mondphasen',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildPhasePreview('🌕 Nächster Vollmond', nextFullMoon),
        const SizedBox(height: 8),
        _buildPhasePreview('🌑 Nächster Neumond', nextNewMoon),
      ],
    );
  }

  Widget _buildPhasePreview(String title, DateTime date) {
    final daysUntil = date.difference(_selectedDate).inDays;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('dd. MMMM yyyy', 'de').format(date),
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF6A1B9A).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'in $daysUntil ${daysUntil == 1 ? "Tag" : "Tagen"}',
              style: const TextStyle(
                color: Color(0xFFBA68C8),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarView() {
    final calendar = LunarPhase.getMonthCalendar(_selectedDate.year, _selectedDate.month);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('MMMM yyyy', 'de').format(_selectedDate),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.8,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: calendar.length,
            itemBuilder: (context, index) {
              final phase = calendar[index];
              final isSelected = phase.date.day == _selectedDate.day;
              
              return GestureDetector(
                onTap: () {
                  _changeDate(phase.date);
                  setState(() {
                    _showCalendar = false;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF6A1B9A).withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF6A1B9A)
                          : Colors.white.withValues(alpha: 0.1),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${phase.date.day}',
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        phase.emoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
