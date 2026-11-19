import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/library_filter.dart';
import '../models/scanned_car.dart';
import '../theme/spot_it_theme.dart';
import 'rarity_badge.dart';

/// Barre de recherche, bouton de tri et filtres de rareté de la bibliothèque.
class LibraryToolbar extends StatelessWidget {
  const LibraryToolbar({
    required this.filter,
    required this.cars,
    required this.onChanged,
    super.key,
  });

  final LibraryFilter filter;

  /// Toute la collection, pour compter les voitures de chaque rareté.
  final List<ScannedCar> cars;
  final ValueChanged<LibraryFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final counts = {for (final r in Rarity.values) r: 0};
    for (final car in cars) {
      counts[car.rarity] = counts[car.rarity]! + 1;
    }
    final present = Rarity.values.where((r) => counts[r]! > 0).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _SearchField(
                  query: filter.query,
                  onChanged: (query) =>
                      onChanged(filter.copyWith(query: query)),
                ),
              ),
              const SizedBox(width: 8),
              _SortButton(
                sort: filter.sort,
                onSelected: (sort) => onChanged(filter.copyWith(sort: sort)),
              ),
            ],
          ),
          if (present.length > 1) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 30,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: present.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final rarity = present[index];
                  return _RarityChip(
                    rarity: rarity,
                    count: counts[rarity]!,
                    selected: filter.rarities.contains(rarity),
                    onTap: () => onChanged(filter.toggle(rarity)),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SearchField extends StatefulWidget {
  const _SearchField({required this.query, required this.onChanged});

  final String query;
  final ValueChanged<String> onChanged;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final _controller = TextEditingController(text: widget.query);

  @override
  void didUpdateWidget(_SearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // La recherche a été vidée depuis la page (bouton « Tout afficher »)
    if (widget.query != _controller.text) _controller.text = widget.query;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const border = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(20)),
      borderSide: BorderSide(color: SpotItColors.border),
    );
    return SizedBox(
      height: 40,
      child: TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        textInputAction: TextInputAction.search,
        cursorColor: SpotItColors.accent,
        style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Marque, modèle ou lieu',
          hintStyle: GoogleFonts.inter(
            fontSize: 13,
            color: SpotItColors.secondaryText,
          ),
          prefixIcon: const Icon(
            Icons.search,
            size: 18,
            color: SpotItColors.secondaryText,
          ),
          filled: true,
          fillColor: SpotItColors.surface,
          contentPadding: EdgeInsets.zero,
          border: border,
          enabledBorder: border,
          focusedBorder: border.copyWith(
            borderSide: const BorderSide(color: SpotItColors.accent),
          ),
        ),
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  const _SortButton({required this.sort, required this.onSelected});

  final LibrarySort sort;
  final ValueChanged<LibrarySort> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<LibrarySort>(
      tooltip: 'Trier : ${sort.label}',
      initialValue: sort,
      onSelected: onSelected,
      color: SpotItColors.selectedSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: SpotItColors.border),
      ),
      itemBuilder: (context) => [
        for (final option in LibrarySort.values)
          PopupMenuItem(
            value: option,
            child: Row(
              children: [
                Icon(
                  Icons.check,
                  size: 16,
                  color:
                      option == sort ? SpotItColors.accent : Colors.transparent,
                ),
                const SizedBox(width: 8),
                Text(
                  option.label,
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
                ),
              ],
            ),
          ),
      ],
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: SpotItColors.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: sort == LibrarySort.newest
                ? SpotItColors.border
                : SpotItColors.accent,
          ),
        ),
        child: const Icon(Icons.swap_vert, size: 20, color: Colors.white),
      ),
    );
  }
}

class _RarityChip extends StatelessWidget {
  const _RarityChip({
    required this.rarity,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final Rarity rarity;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = rarity.color;
    return Material(
      color: selected ? color.withValues(alpha: 0.18) : SpotItColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
          color: selected ? color : SpotItColors.border,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.diamond_outlined, size: 12, color: color),
              const SizedBox(width: 5),
              Text(
                '${rarity.label} $count',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : SpotItColors.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
