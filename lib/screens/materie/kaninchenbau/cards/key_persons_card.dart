/// 👤 SCHLÜSSELPERSONEN — wer steht hinter dieser Org/Bewegung?
///
/// Quelle: Wikidata SPARQL via Worker (`/api/kaninchenbau/keypersons`)
/// Properties: P488 chair · P169 CEO · P112 founder · P3320 board ·
///             P39 position · P35 head of state · P6 head of gov
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/thread.dart';
import '../widgets/kb_design.dart';

class KeyPersonsCard extends StatelessWidget {
  final List<KeyPerson> persons;
  final bool loading;
  final void Function(String name) onTapPerson;

  const KeyPersonsCard({
    super.key,
    required this.persons,
    required this.loading,
    required this.onTapPerson,
  });

  static const _accent = Color(0xFFEC407A);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: KbDesign.glassBox(tint: _accent),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.diversity_3_rounded,
                  color: _accent, size: 18),
              const SizedBox(width: 8),
              const Text(
                'SCHLÜSSELPERSONEN',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (persons.isNotEmpty)
                Text(
                  '${persons.length}',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Wer steht hinter dieser Organisation?',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45), fontSize: 11),
          ),
          const SizedBox(height: 14),
          if (loading)
            _buildLoading()
          else if (persons.isEmpty)
            _buildEmpty()
          else
            SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: persons.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) => _PersonTile(
                  person: persons[i],
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onTapPerson(persons[i].name);
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoading() => const Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
                color: _accent, strokeWidth: 2),
          ),
        ),
      );

  Widget _buildEmpty() => Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          'Keine Schlüsselpersonen in Wikidata erfasst.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
        ),
      );
}

class _PersonTile extends StatelessWidget {
  final KeyPerson person;
  final VoidCallback onTap;

  const _PersonTile({required this.person, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(KbDesign.radiusSm),
          color: Colors.white.withValues(alpha: 0.04),
          border:
              Border.all(color: KeyPersonsCard._accent.withValues(alpha: 0.25)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bild (oder Initial)
            SizedBox(
              height: 100,
              width: double.infinity,
              child: person.imageUrl != null
                  ? Image.network(
                      person.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _initialAvatar(),
                    )
                  : _initialAvatar(),
            ),
            // Name + Rolle
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    person.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: KeyPersonsCard._accent.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      person.role,
                      style: const TextStyle(
                        color: KeyPersonsCard._accent,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (person.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      person.description,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 9,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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

  Widget _initialAvatar() => Container(
        color: KeyPersonsCard._accent.withValues(alpha: 0.18),
        alignment: Alignment.center,
        child: Text(
          person.name.isNotEmpty ? person.name[0].toUpperCase() : '?',
          style: TextStyle(
            color: KeyPersonsCard._accent,
            fontSize: 32,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
}
