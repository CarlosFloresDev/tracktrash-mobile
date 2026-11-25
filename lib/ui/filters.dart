import 'package:flutter/material.dart';
import 'eco_design.dart';

const _accents = {
  'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u', 'ñ': 'n', //
  'Á': 'a', 'É': 'e', 'Í': 'i', 'Ó': 'o', 'Ú': 'u', 'Ü': 'u', 'Ñ': 'n',
};

/// Lowercases and strips Spanish accents so "Cayma" matches "cayma" and "Cartón" matches "carton".
String normalizeText(String? value) {
  final buffer = StringBuffer();
  for (final char in (value ?? '').split('')) {
    buffer.write(_accents[char] ?? char.toLowerCase());
  }
  return buffer.toString().trim();
}

/// True when every word of [query] appears somewhere in [fields].
bool matchesQuery(String query, Iterable<Object?> fields) {
  final words = normalizeText(
    query,
  ).split(RegExp(r'\s+')).where((word) => word.isNotEmpty);
  if (words.isEmpty) return true;
  final haystack = normalizeText(
    fields.where((field) => field != null).join(' '),
  );
  return words.every(haystack.contains);
}

/// Rounded search box with a clear button.
class SearchField extends StatefulWidget {
  const SearchField({
    super.key,
    required this.hint,
    required this.onChanged,
    this.value = '',
  });

  final String hint;
  final ValueChanged<String> onChanged;

  /// Current query owned by the screen; when it is reset from outside, the box clears too.
  final String value;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  late final _controller = TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(SearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) _controller.text = widget.value;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: _controller,
    textInputAction: TextInputAction.search,
    onChanged: (value) {
      setState(() {});
      widget.onChanged(value);
    },
    decoration: InputDecoration(
      hintText: widget.hint,
      prefixIcon: const Icon(Icons.search_rounded),
      suffixIcon: _controller.text.isEmpty
          ? null
          : IconButton(
              tooltip: 'Limpiar búsqueda',
              icon: const Icon(Icons.close_rounded),
              onPressed: () {
                _controller.clear();
                setState(() {});
                widget.onChanged('');
              },
            ),
    ),
  );
}

/// One option of a [FilterChipsRow]. A null [value] means "all".
class ChipOption<T> {
  const ChipOption(this.value, this.label, {this.count});
  final T? value;
  final String label;
  final int? count;
}

/// Horizontally scrolling single-choice chips.
class FilterChipsRow<T> extends StatelessWidget {
  const FilterChipsRow({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<ChipOption<T>> options;
  final T? selected;
  final ValueChanged<T?> onSelected;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 44,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: options.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final option = options[index];
        final isSelected = option.value == selected;
        return ChoiceChip(
          label: Text(
            option.count == null
                ? option.label
                : '${option.label} · ${option.count}',
          ),
          selected: isSelected,
          showCheckmark: false,
          selectedColor: EcoColors.pine,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : EcoColors.pine,
            fontWeight: FontWeight.w600,
          ),
          onSelected: (_) => onSelected(option.value),
        );
      },
    ),
  );
}

/// "Mostrando 5 de 20" line with a reset link when filters are active.
class FilterSummary extends StatelessWidget {
  const FilterSummary({
    super.key,
    required this.shown,
    required this.total,
    required this.active,
    required this.onReset,
  });

  final int shown;
  final int total;
  final bool active;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        'Mostrando $shown de $total',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      const Spacer(),
      if (active)
        TextButton(onPressed: onReset, child: const Text('Limpiar filtros')),
    ],
  );
}
