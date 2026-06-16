import 'dart:math' as math;

import '../models/quantenphysik_model.dart';

// Re-export QuantumPoint so existing imports of this service keep resolving it.
export '../models/quantenphysik_model.dart' show QuantumPoint;

/// Stateless computation helpers for quantum physics phenomena.
/// All units are normalized: hbar = 1, mass = 1, box length L = 1.
class QuantenphysikService {
  QuantenphysikService._();

  static const double _pi = math.pi;

  // ── Particle in a box ──────────────────────────────────────────────────────

  /// Time-evolved wave function psi_n(x, t) for particle in infinite potential well.
  /// psi_n(x, t) = sqrt(2) * sin(n*pi*x) * cos(E_n * t)
  /// where E_n = n^2 * pi^2 / 2 (normalized).
  static List<QuantumPoint> waveFunction(
    int n,
    double time, {
    int points = 250,
  }) {
    final result = <QuantumPoint>[];
    final energy = n * n * _pi * _pi / 2.0;
    for (var i = 0; i <= points; i++) {
      final x = i / points;
      final psi =
          math.sqrt(2.0) * math.sin(n * _pi * x) * math.cos(energy * time);
      result.add(QuantumPoint(x, psi));
    }
    return result;
  }

  /// Stationary probability density |psi_n(x)|^2 = 2 * sin^2(n*pi*x).
  static List<QuantumPoint> probabilityDensity(int n, {int points = 250}) {
    final result = <QuantumPoint>[];
    for (var i = 0; i <= points; i++) {
      final x = i / points;
      final sinVal = math.sin(n * _pi * x);
      result.add(QuantumPoint(x, 2.0 * sinVal * sinVal));
    }
    return result;
  }

  // ── Double-slit interference ───────────────────────────────────────────────

  /// Intensity pattern on screen for double-slit experiment.
  /// I(theta) = I0 * sinc^2(beta) * cos^2(delta)
  /// where beta = pi*a*sin(theta)/lambda, delta = pi*d*sin(theta)/lambda
  ///
  /// [wavelength]     lambda in normalized units
  /// [slitSeparation] d — center-to-center slit distance
  /// [slitWidth]      a — width of each individual slit
  ///
  /// Returns intensity vs. screen position in x in [-2, 2].
  static List<QuantumPoint> doubleSlit({
    required double wavelength,
    required double slitSeparation,
    required double slitWidth,
    int points = 300,
  }) {
    final result = <QuantumPoint>[];
    for (var i = 0; i <= points; i++) {
      // Screen position -2..2
      final screenX = (i / points - 0.5) * 4.0;
      // sin(theta) from geometry (screen at distance 2)
      final sinTheta = screenX / math.sqrt(screenX * screenX + 4.0);
      final beta = _pi * slitWidth * sinTheta / wavelength;
      final delta = _pi * slitSeparation * sinTheta / wavelength;
      // sinc(beta) = sin(beta)/beta with limit 1 at beta=0
      final sincBeta = beta.abs() < 1e-10 ? 1.0 : math.sin(beta) / beta;
      final intensity = sincBeta * sincBeta * math.cos(delta) * math.cos(delta);
      result.add(QuantumPoint(screenX, intensity.clamp(0.0, 1.0)));
    }
    return result;
  }

  // ── Quantum tunneling ──────────────────────────────────────────────────────

  /// WKB transmission coefficient through a rectangular barrier.
  /// T = exp(-2 * kappa * barrierWidth), kappa = sqrt(2m(V-E)) / hbar.
  static double tunnelingProbability({
    required double barrierHeight,
    required double particleEnergy,
    required double barrierWidth,
  }) {
    final delta = (barrierHeight - particleEnergy).clamp(0.0, double.infinity);
    if (delta < 1e-10) return 1.0;
    final kappa = math.sqrt(2.0 * delta);
    return math.exp((-2.0 * kappa * barrierWidth).clamp(-20.0, 0.0));
  }

  /// Schematic wave function showing tunneling through a barrier.
  /// x range: -1 to 2. Barrier occupies 0 to barrierWidth.
  /// Before barrier: incident + reflected wave; inside: evanescent; after: transmitted.
  static List<QuantumPoint> tunnelingWave({
    required double barrierHeight,
    required double particleEnergy,
    required double barrierWidth,
    required double time,
    int points = 300,
  }) {
    final result = <QuantumPoint>[];
    final k = math.sqrt(2.0 * particleEnergy.clamp(0.01, double.infinity));
    final delta = (barrierHeight - particleEnergy).clamp(0.0, double.infinity);
    final kappa = math.sqrt(2.0 * delta);
    final T = tunnelingProbability(
      barrierHeight: barrierHeight,
      particleEnergy: particleEnergy,
      barrierWidth: barrierWidth,
    );
    final txAmp = math.sqrt(T);

    for (var i = 0; i <= points; i++) {
      final x = -1.0 + i / points * 3.0; // x in [-1, 2]
      double psi;
      if (x < 0) {
        // Incident + partial reflection -> standing-wave-like superposition
        psi = math.sin(k * x + time) + 0.3 * math.sin(-k * x + time);
      } else if (x <= barrierWidth) {
        // Evanescent decay inside barrier
        final decayFactor = kappa < 1e-10 ? 1.0 : math.exp(-kappa * x);
        psi = decayFactor * math.cos(time) * 0.8;
      } else {
        // Transmitted wave (attenuated amplitude)
        psi = txAmp * math.sin(k * (x - barrierWidth) + time);
      }
      result.add(QuantumPoint(x, psi));
    }
    return result;
  }

  // ── Heisenberg uncertainty ─────────────────────────────────────────────────

  /// Gaussian wave packet in position space, x in [-3, 3].
  /// psi(x) = exp(-x^2 / (2 * sigmaX^2))
  static List<QuantumPoint> gaussianPacket(double sigmaX, {int points = 200}) {
    final result = <QuantumPoint>[];
    final twoSigmaSq = 2.0 * sigmaX * sigmaX;
    for (var i = 0; i <= points; i++) {
      final x = -3.0 + i / points * 6.0;
      result.add(QuantumPoint(x, math.exp(-x * x / twoSigmaSq)));
    }
    return result;
  }

  /// Gaussian in momentum space, p in [-3, 3].
  /// From Fourier transform: sigmaP = hbar / (2 * sigmaX) = 1/(2*sigmaX) normalized.
  static List<QuantumPoint> momentumDistribution(
    double sigmaX, {
    int points = 200,
  }) {
    final sigmaP = 0.5 / sigmaX; // hbar/(2*sigmaX) with hbar=1
    final twoSigmaSqP = 2.0 * sigmaP * sigmaP;
    final result = <QuantumPoint>[];
    for (var i = 0; i <= points; i++) {
      final p = -3.0 + i / points * 6.0;
      result.add(QuantumPoint(p, math.exp(-p * p / twoSigmaSqP)));
    }
    return result;
  }
}
