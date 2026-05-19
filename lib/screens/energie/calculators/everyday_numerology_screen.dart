// Adresse, Telefon und Kennzeichen numerologisch auswerten.
// Cinema-Glass-Style konsistent mit anderen Calculator-Screens.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../services/spirit_calculations/numerology_engine.dart';
import '../../../services/streak_tracking_service.dart';
import '../../../widgets/cinematic/wb_ambient_particles.dart';
import '../../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../../widgets/cinematic/wb_vignette.dart';
import '../../../theme/wb_cinematic_tokens.dart';
import 'shared_calc_bg.dart';

class EverydayNumerologyScreen extends StatefulWidget {
  const EverydayNumerologyScreen({super.key});

  @override
  State<EverydayNumerologyScreen> createState() =>
      _EverydayNumerologyScreenState();
}

class _EverydayNumerologyScreenState extends State<EverydayNumerologyScreen> {
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();

  int? _addressNumber;
  int? _phoneNumber;
  int? _plateNumber;

  @override
  void initState() {
    super.initState();
    StreakTrackingService().trackToolUsage('numerology_everyday');
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _plateCtrl.dispose();
    super.dispose();
  }

  void _calcAddress() {
    final n = NumerologyEngine.calculateAddressNumber(_addressCtrl.text);
    setState(() => _addressNumber = n);
  }

  void _calcPhone() {
    final n = NumerologyEngine.calculatePhoneNumber(_phoneCtrl.text);
    setState(() => _phoneNumber = n);
  }

  void _calcPlate() {
    final n = NumerologyEngine.calculateLicensePlate(_plateCtrl.text);
    setState(() => _plateNumber = n);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF06040F),
      extendBodyBehindAppBar: true,
      appBar: const WBGlassAppBar(
        title: 'Alltags-Numerologie',
        world: WBWorld.energie,
      ),
      body: CalcAnimatedBg(
        primaryColor: const Color(0xFF7C4DFF),
        secondaryColor: const Color(0xFFCE93D8),
        child: Stack(
          children: [
            const IgnorePointer(
              child: WBAmbientParticles(world: WBWorld.energie, count: 30),
            ),
            const WBVignette(),
            SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                children: [
                  const _IntroCard(),
                  const SizedBox(height: 18),
                  _SectionCard(
                    title: 'Deine Adresse',
                    hint: 'Strasse + Hausnummer',
                    icon: Icons.home_rounded,
                    controller: _addressCtrl,
                    inputType: TextInputType.streetAddress,
                    onCalc: _calcAddress,
                    result: _addressNumber,
                    meaning: _addressNumber == null
                        ? null
                        : NumerologyEngine.getAddressNumberMeaning(
                            _addressNumber!),
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: 'Deine Telefonnummer',
                    hint: 'z.B. +43 660 1234567',
                    icon: Icons.phone_rounded,
                    controller: _phoneCtrl,
                    inputType: TextInputType.phone,
                    formatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9\s+\-/]'))
                    ],
                    onCalc: _calcPhone,
                    result: _phoneNumber,
                    meaning: _phoneNumber == null
                        ? null
                        : NumerologyEngine.getAddressNumberMeaning(
                            _phoneNumber!),
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: 'Dein Kennzeichen',
                    hint: 'z.B. W-12345',
                    icon: Icons.directions_car_rounded,
                    controller: _plateCtrl,
                    inputType: TextInputType.text,
                    formatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'[A-Za-z0-9\-\s]'))
                    ],
                    onCalc: _calcPlate,
                    result: _plateNumber,
                    meaning: _plateNumber == null
                        ? null
                        : NumerologyEngine.getAddressNumberMeaning(
                            _plateNumber!),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.06),
                Colors.white.withValues(alpha: 0.02),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFF7C4DFF).withValues(alpha: 0.35),
            ),
          ),
          child: const Text(
            'Jede Zahl traegt eine Schwingung. Pruefe deine Adresse, '
            'Telefonnummer oder dein Kennzeichen - oft erklaert die '
            'Hauszahl, warum sich ein Ort harmonisch oder anstrengend '
            'anfuehlt.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final TextInputType inputType;
  final List<TextInputFormatter>? formatters;
  final VoidCallback onCalc;
  final int? result;
  final String? meaning;

  const _SectionCard({
    required this.title,
    required this.hint,
    required this.icon,
    required this.controller,
    required this.inputType,
    this.formatters,
    required this.onCalc,
    required this.result,
    required this.meaning,
  });

  @override
  Widget build(BuildContext context) {
    final accent = const Color(0xFF7C4DFF);
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withValues(alpha: 0.12),
                accent.withValues(alpha: 0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accent.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.18),
                blurRadius: 22,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: accent, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      color: accent.withValues(alpha: 0.95),
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: inputType,
                inputFormatters: formatters,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                onSubmitted: (_) => onCalc(),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onCalc,
                  icon: const Icon(Icons.calculate_rounded),
                  label: const Text('Berechnen'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              if (result != null) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            accent.withValues(alpha: 0.6),
                            accent.withValues(alpha: 0.15),
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.6),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.5),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$result',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        meaning ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
