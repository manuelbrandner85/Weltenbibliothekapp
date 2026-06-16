/// Data models for the quantum physics simulator (Quantenphysik-Simulator).
///
/// These plain Dart classes are the single source of truth for both the
/// computed simulation data ([QuantumPoint]) and the static, display-oriented
/// description of each simulated phenomenon ([QuantumPhenomenon]).
///
/// NOTE: No Dart 3 named record types are used here on purpose — they crash
/// dart2js on the Flutter Web build (see CLAUDE.md Kernregel 8).
library;

/// (x, y) data point used across all quantum physics visualizations.
///
/// Produced by `QuantenphysikService` and consumed by the CustomPainters in
/// the simulator screen. Units are normalized (hbar = 1, mass = 1, box L = 1).
class QuantumPoint {
  final double x;
  final double y;

  const QuantumPoint(this.x, this.y);
}

/// The four quantum phenomena the simulator can visualize, in tab order.
enum QuantumPhenomenonType {
  doppelspalt,
  wellenfunktion,
  tunneling,
  unschaerfe,
}

/// Static description of one simulated quantum phenomenon.
///
/// Stores the German UI strings (tab label, title, explanation) and the
/// physics formula rendered in the simulator. Keeping this data in the model
/// layer lets the screen stay purely presentational and avoids duplicating
/// copy across tabs.
class QuantumPhenomenon {
  /// Stable identifier for the phenomenon.
  final QuantumPhenomenonType type;

  /// Short label shown on the TabBar.
  final String tabLabel;

  /// Headline shown above the canvas.
  final String title;

  /// User-facing explanation (German UI text).
  final String description;

  /// Physics formula rendered in the monospace formula box.
  final String formula;

  const QuantumPhenomenon({
    required this.type,
    required this.tabLabel,
    required this.title,
    required this.description,
    required this.formula,
  });
}

/// Catalogue of all phenomena offered by the simulator, in tab order.
///
/// The simulator screen drives its TabBar and per-tab copy from this list, so
/// adding or re-wording a phenomenon only requires editing the model.
const List<QuantumPhenomenon> kQuantumPhenomena = <QuantumPhenomenon>[
  QuantumPhenomenon(
    type: QuantumPhenomenonType.doppelspalt,
    tabLabel: 'Doppelspalt',
    title: 'Doppelspalt-Experiment',
    description:
        'Licht oder Elektronen treten durch zwei schmale Spalte und erzeugen '
        'ein Interferenzmuster auf dem Schirm. Die Intensitaet I haengt von '
        'Wellenlaenge lambda, Spaltbreite a und Spaltabstand d ab.',
    formula:
        'I = I₀ · sinc²(β) · cos²(δ)\n'
        'β = π a sin(θ) / λ\n'
        'δ = π d sin(θ) / λ',
  ),
  QuantumPhenomenon(
    type: QuantumPhenomenonType.wellenfunktion,
    tabLabel: 'Wellenfunktion',
    title: 'Teilchen im Kasten',
    description:
        'Ein Teilchen ist in einem unendlich tiefen Potenzialtopf eingesperrt. '
        'Die Wellenfunktion psi_n(x) beschreibt seinen Zustand. '
        'Die Aufenthaltswahrscheinlichkeit ist durch |psi|^2 gegeben.',
    formula:
        'ψₙ(x) = √(2/L) · sin(nπx/L)\n'
        'Eₙ = n²π²ℏ² / (2mL²)',
  ),
  QuantumPhenomenon(
    type: QuantumPhenomenonType.tunneling,
    tabLabel: 'Tunneling',
    title: 'Quanten-Tunneling',
    description:
        'Ein Teilchen kann eine Potenzialbarriere durchdringen, die es '
        'klassisch nicht ueberwinden koennte. Die Tunnelwahrscheinlichkeit '
        'nimmt exponentiell mit der Barrierenbreite ab.',
    formula:
        'T ≈ exp(-2κL)\n'
        'κ = √[2m(V - E)] / ℏ',
  ),
  QuantumPhenomenon(
    type: QuantumPhenomenonType.unschaerfe,
    tabLabel: 'Unschaerfe',
    title: "Heisenberg'sche Unschaerferelation",
    description:
        'Ort und Impuls eines Teilchens koennen nicht gleichzeitig beliebig '
        'genau gemessen werden. Wenn Delta_x kleiner wird, waechst Delta_p '
        'zwangslaeufig an.',
    formula:
        'Δx · Δp ≥ ℏ / 2\n'
        '(Heisenberg, 1927)',
  ),
];
