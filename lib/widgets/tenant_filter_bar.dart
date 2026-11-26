import 'package:material_ui/material_ui.dart';

/// Sort order for the tenant room directory.
enum RoomSort {
  newest('Newest first'),
  priceLow('Price: low to high'),
  priceHigh('Price: high to low');

  const RoomSort(this.label);

  final String label;
}

/// Search, budget, and sort controls for tenant room browsing.
class TenantFilterBar extends StatelessWidget {
  const TenantFilterBar({
    super.key,
    required this.searchController,
    required this.query,
    required this.maxPrice,
    required this.sort,
    required this.onQueryChanged,
    required this.onMaxPriceChanged,
    required this.onSortChanged,
  });

  static const List<double?> priceOptions = <double?>[
    null,
    3000,
    5000,
    10000,
    15000,
  ];

  final TextEditingController searchController;
  final String query;
  final double? maxPrice;
  final RoomSort sort;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<double?> onMaxPriceChanged;
  final ValueChanged<RoomSort> onSortChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: searchController,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search by room, city, or barangay',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            onPressed: () {
                              searchController.clear();
                              onQueryChanged('');
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                  onChanged: onQueryChanged,
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<RoomSort>(
                tooltip: 'Sort rooms',
                initialValue: sort,
                onSelected: onSortChanged,
                itemBuilder: (_) => <PopupMenuEntry<RoomSort>>[
                  for (final option in RoomSort.values)
                    PopupMenuItem<RoomSort>(
                      value: option,
                      child: Text(option.label),
                    ),
                ],
                icon: Icon(Icons.sort_rounded, color: scheme.primary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: <Widget>[
              for (final option in priceOptions) ...<Widget>[
                if (option != priceOptions.first) const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(
                    option == null
                        ? 'Any budget'
                        : 'Up to \u20B1${(option / 1000).toStringAsFixed(0)}k',
                  ),
                  selected: maxPrice == option,
                  onSelected: (_) => onMaxPriceChanged(option),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
