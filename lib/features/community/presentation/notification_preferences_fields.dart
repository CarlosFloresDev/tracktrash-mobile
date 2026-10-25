import 'package:flutter/material.dart';
import '../domain/community_models.dart';

class NotificationPreferencesFields extends StatelessWidget {
  const NotificationPreferencesFields({
    super.key,
    required this.enabled,
    required this.preferences,
    required this.onEnabledChanged,
    required this.onPreferencesChanged,
    this.busy = false,
  });
  final bool enabled, busy;
  final NotificationPreferences preferences;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<NotificationPreferences> onPreferencesChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: 24),
      Text('Tus avisos', style: Theme.of(context).textTheme.titleLarge),
      SwitchListTile(
        key: const Key('notice-master'),
        contentPadding: EdgeInsets.zero,
        title: const Text('Recibir avisos en la app'),
        subtitle: const Text(
          'Puedes pausarlos sin perder tu selección por tipo.',
        ),
        value: enabled,
        onChanged: busy ? null : onEnabledChanged,
      ),
      _toggle(
        'notice-schedules',
        'Horarios de recolección',
        'Recordatorios de tus rutas suscritas.',
        preferences.schedules,
        (v) => preferences.copyWith(schedules: v),
      ),
      _toggle(
        'notice-pickups',
        'Seguimiento de recojos',
        'Aceptación, viaje, cancelación y confirmación de entrega.',
        preferences.pickups,
        (v) => preferences.copyWith(pickups: v),
      ),
      _toggle(
        'notice-issues',
        'Atención de reportes',
        'Registro y resolución de tus incidencias.',
        preferences.issues,
        (v) => preferences.copyWith(issues: v),
      ),
      _toggle(
        'notice-rewards',
        'Canjes y beneficios',
        'Confirmaciones de tus canjes.',
        preferences.rewards,
        (v) => preferences.copyWith(rewards: v),
      ),
      const Text(
        'Guarda los cambios para aplicarlos a nuevos avisos. Tu historial, puntos y operaciones se conservan. Estos avisos aparecen dentro de TrackTrash.',
        style: TextStyle(fontSize: 12),
      ),
    ],
  );

  Widget _toggle(
    String key,
    String title,
    String detail,
    bool value,
    NotificationPreferences Function(bool) update,
  ) => SwitchListTile(
    key: Key(key),
    contentPadding: EdgeInsets.zero,
    title: Text(title),
    subtitle: Text(detail),
    value: value,
    onChanged: busy || !enabled ? null : (v) => onPreferencesChanged(update(v)),
  );
}
