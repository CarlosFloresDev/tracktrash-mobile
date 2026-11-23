import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/enums.dart';
import '../data/models.dart';
import 'eco_design.dart';

final _dateFormat = DateFormat('d MMM y', 'es');
final _timestampFormat = DateFormat('d MMM, HH:mm', 'es');
final _numberFormat = NumberFormat('#,##0.##', 'es_PE');

String formatDate(DateTime date) => _dateFormat.format(date);
String formatTimestamp(DateTime date) => _timestampFormat.format(date);
String formatQuantity(double value) => _numberFormat.format(value);
String formatKg(double value) => '${formatQuantity(value)} kg';

enum MaterialKind { paper, plastic, glass, metal, carton, oil, organic, other }

/// Maps catalog names (as seeded by the backend team) to an icon family.
MaterialKind materialKind(String name) {
  final value = name
      .toLowerCase()
      .replaceAll(RegExp('[áàä]'), 'a')
      .replaceAll(RegExp('[éèë]'), 'e')
      .replaceAll(RegExp('[íìï]'), 'i')
      .replaceAll(RegExp('[óòö]'), 'o')
      .replaceAll(RegExp('[úùü]'), 'u');
  if (RegExp('tetra|envase').hasMatch(value)) return MaterialKind.carton;
  if (RegExp('papel|carton').hasMatch(value)) return MaterialKind.paper;
  if (RegExp('plastic|pet|botella').hasMatch(value)) {
    return MaterialKind.plastic;
  }
  if (RegExp('vidrio|glass').hasMatch(value)) return MaterialKind.glass;
  if (RegExp('metal|lata|aluminio').hasMatch(value)) return MaterialKind.metal;
  if (RegExp('aceite').hasMatch(value)) return MaterialKind.oil;
  if (RegExp('organ|compost').hasMatch(value)) return MaterialKind.organic;
  return MaterialKind.other;
}

class MaterialBadge extends StatelessWidget {
  const MaterialBadge({super.key, required this.kind, this.size = 46});
  final MaterialKind kind;
  final double size;

  static const _style = {
    MaterialKind.paper: (
      Icons.description_outlined,
      Color(0xFFA8793A),
      Color(0xFFF5EFE3),
    ),
    MaterialKind.plastic: (
      Icons.local_drink_outlined,
      Color(0xFF1D6FA5),
      Color(0xFFE8F3FA),
    ),
    MaterialKind.glass: (
      Icons.wine_bar_outlined,
      Color(0xFF217A51),
      Color(0xFFEEF8F2),
    ),
    MaterialKind.metal: (
      Icons.inventory_2_outlined,
      Color(0xFF52606D),
      Color(0xFFEEF1F4),
    ),
    MaterialKind.carton: (
      Icons.local_cafe_outlined,
      Color(0xFFA16207),
      Color(0xFFFDF5DC),
    ),
    MaterialKind.oil: (
      Icons.water_drop_outlined,
      Color(0xFFA16207),
      Color(0xFFFDF5DC),
    ),
    MaterialKind.organic: (
      Icons.eco_outlined,
      Color(0xFF1F6444),
      Color(0xFFE6F9B4),
    ),
    MaterialKind.other: (
      Icons.category_outlined,
      Color(0xFF217A51),
      Color(0xFFEEF8F2),
    ),
  };

  @override
  Widget build(BuildContext context) {
    final (icon, color, background) = _style[kind]!;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(size * .3),
      ),
      child: Icon(icon, color: color, size: size * .5),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});
  final RequestStatus status;

  static const _colors = {
    RequestStatus.pending: (Color(0xFFA16207), Color(0xFFFDF5DC)),
    RequestStatus.assigned: (Color(0xFF1D6FA5), Color(0xFFE8F3FA)),
    RequestStatus.inProgress: (Color(0xFFA8793A), Color(0xFFF5EFE3)),
    RequestStatus.completed: (Color(0xFF1A4D37), Color(0xFFDCF1E5)),
    RequestStatus.cancelled: (Color(0xFFC2410C), Color(0xFFFFF1E8)),
  };

  @override
  Widget build(BuildContext context) {
    final (foreground, background) = _colors[status]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.highlight = false,
  });
  final String label;
  final String value;
  final IconData icon;
  final bool highlight;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: highlight ? EcoColors.lime : Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFFE6EBE1)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: EcoColors.green, size: 22),
        const SizedBox(height: 12),
        Text(
          value,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: EcoColors.pine,
            letterSpacing: -.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 12.5, color: EcoColors.muted),
        ),
      ],
    ),
  );
}

class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: EcoColors.green),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
        ),
      ],
    ),
  );
}

class RatingStars extends StatelessWidget {
  const RatingStars({super.key, required this.value, this.size = 18});
  final double value;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '${value.toStringAsFixed(1)} de 5',
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            i <= value.round()
                ? Icons.star_rounded
                : Icons.star_outline_rounded,
            size: size,
            color: i <= value.round()
                ? EcoColors.green
                : const Color(0xFFC9D3C6),
          ),
      ],
    ),
  );
}

/// Material row used by request details, recovered materials and the list summaries.
class MaterialLine extends StatelessWidget {
  const MaterialLine({
    super.key,
    required this.residue,
    required this.quantity,
    required this.unit,
  });
  final ResidueType? residue;
  final double quantity;
  final MeasurementUnit unit;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        MaterialBadge(kind: materialKind(residue?.name ?? '')),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            residue?.name ?? 'Material',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: EcoColors.pine,
            ),
          ),
        ),
        Text(
          '${formatQuantity(quantity)} ${unit.label}',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: EcoColors.pine,
          ),
        ),
      ],
    ),
  );
}

void showFailure(BuildContext context, Object error) {
  final message = error.toString();
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
}

void showSuccess(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
}
