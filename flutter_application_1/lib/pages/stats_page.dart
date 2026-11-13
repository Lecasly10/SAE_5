import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/collection_stats.dart';
import '../models/scanned_car.dart';
import '../services/api.dart';
import '../services/car_service.dart';
import '../theme/spot_it_theme.dart';
import '../widgets/rarity_badge.dart';
import '../widgets/spot_it_widgets.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  late Future<CollectionStats> _stats = CarService.stats();

  void _reload() => setState(() => _stats = CarService.stats());

  @override
  Widget build(BuildContext context) {
    return SpotItPage(
      child: Column(
        children: [
          const SpotItHeader(title: 'Mes statistiques'),
          Expanded(
            child: FutureBuilder<CollectionStats>(
              future: _stats,
              builder: (context, snapshot) {
                final stats = snapshot.data;
                if (snapshot.hasError) {
                  return Center(
                    child: TextButton.icon(
                      onPressed: _reload,
                      icon: const Icon(Icons.refresh),
                      label: Text(errorMessage(snapshot.error!)),
                      style: TextButton.styleFrom(
                        foregroundColor: SpotItColors.accent,
                      ),
                    ),
                  );
                }
                if (stats == null) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: SpotItColors.accent,
                    ),
                  );
                }
                return _StatsView(stats: stats);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsView extends StatelessWidget {
  const _StatsView({required this.stats});

  final CollectionStats stats;

  @override
  Widget build(BuildContext context) {
    final completion = stats.completion;
    final rarest = stats.rarest;
    final firstSpot = stats.firstSpot;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
      children: [
        Row(
          children: [
            Expanded(child: _Number(value: stats.total, label: 'Photos')),
            const SizedBox(width: 10),
            Expanded(child: _Number(value: stats.models, label: 'Modèles')),
            const SizedBox(width: 10),
            Expanded(child: _Number(value: stats.brands, label: 'Marques')),
          ],
        ),
        if (completion != null) ...[
          const SizedBox(height: 12),
          _Panel(
            title: 'COLLECTION',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_count(stats.models, 'voiture')} sur ${stats.catalogSize} '
                  "connues de l'IA",
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
                ),
                const SizedBox(height: 10),
                _Bar(value: completion, color: SpotItColors.accent),
                const SizedBox(height: 6),
                Text(
                  '${(completion * 100).toStringAsFixed(1)} % complétée',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: SpotItColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        _Panel(
          title: 'RARETÉ',
          child: Column(
            children: [
              for (final rarity in Rarity.values.reversed)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 112,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: RarityBadge(rarity: rarity, small: true),
                        ),
                      ),
                      Expanded(
                        child: _Bar(
                          value: stats.total == 0
                              ? 0
                              : stats.rarities[rarity]! / stats.total,
                          color: rarity.color,
                        ),
                      ),
                      SizedBox(
                        width: 34,
                        child: Text(
                          '${stats.rarities[rarity]}',
                          textAlign: TextAlign.right,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (rarest != null) ...[
                const SizedBox(height: 10),
                _Line(
                  icon: Icons.emoji_events_outlined,
                  text: 'Plus rare : ${rarest.$1}',
                  color: rarest.$2.color,
                ),
              ],
              const SizedBox(height: 10),
              Text(
                'La rareté dépend de la marque, du prix neuf, du nombre '
                'd’exemplaires fabriqués et de l’âge de la voiture.',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  height: 1.4,
                  color: SpotItColors.secondaryText,
                ),
              ),
            ],
          ),
        ),
        if (stats.priced > 0) ...[
          const SizedBox(height: 12),
          _Panel(
            title: 'VALEUR DE LA COLLECTION',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatEuros(stats.value),
                  style: GoogleFonts.outfit(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: SpotItColors.accent,
                  ),
                ),
                Text(
                  'Prix neuf de ${_count(stats.priced, 'voiture')} '
                  'sur ${stats.total}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: SpotItColors.secondaryText,
                  ),
                ),
                if (stats.priciest != null) ...[
                  const SizedBox(height: 10),
                  _Line(
                    icon: Icons.sell_outlined,
                    text: 'Plus chère : ${stats.priciest!.$1} '
                        '(${formatEuros(stats.priciest!.$2)})',
                  ),
                ],
              ],
            ),
          ),
        ],
        if (stats.topBrands.isNotEmpty) ...[
          const SizedBox(height: 12),
          _Panel(
            title: 'MARQUES PRÉFÉRÉES',
            child: Column(
              children: [
                for (final (brand, count) in stats.topBrands)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 112,
                          child: Text(
                            brand,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Expanded(
                          child: _Bar(
                            value: count / stats.topBrands.first.$2,
                            color: SpotItColors.accent,
                          ),
                        ),
                        SizedBox(
                          width: 34,
                          child: Text(
                            '$count',
                            textAlign: TextAlign.right,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        _Panel(
          title: 'EN BREF',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Line(
                icon: Icons.place_outlined,
                text: '${_count(stats.located, 'voiture')} sur la carte',
              ),
              if (firstSpot != null) ...[
                const SizedBox(height: 8),
                _Line(
                  icon: Icons.event_outlined,
                  text: 'Première voiture le ${formatDate(firstSpot)}',
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

String _count(int count, String word) => '$count $word${count > 1 ? 's' : ''}';

class _Number extends StatelessWidget {
  const _Number({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: SpotItColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SpotItColors.border),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: GoogleFonts.outfit(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: SpotItColors.accent,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: SpotItColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SpotItColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SpotItColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: SpotItColors.secondaryText,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: LinearProgressIndicator(
        value: value.clamp(0, 1),
        minHeight: 8,
        color: color,
        backgroundColor: SpotItColors.border,
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.icon,
    required this.text,
    this.color = SpotItColors.accent,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
