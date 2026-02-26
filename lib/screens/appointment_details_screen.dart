import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/l10n/app_localizations.dart';

class AppointmentDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> appointment;

  const AppointmentDetailsScreen({super.key, required this.appointment});

  /// Convierte '2026-01-20T17:33:25.399' → '20 Ene 2026 • 5:33 PM'
  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return 'No disponible';
    try {
      final dt = DateTime.parse(raw);
      return DateFormat("d MMM yyyy '•' h:mm a").format(dt);
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = appointment['estado'] ?? 'Pendiente';

    Color statusColor = Colors.orange;
    if (estado == 'Aprobada') statusColor = Colors.greenAccent;
    if (estado == 'Rechazada') statusColor = Colors.redAccent;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1219),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(AppLocalizations.of(context).appointmentDetails),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado del Vehículo
            Container(
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F2E),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.directions_car_filled,
                    size: 48,
                    color: Color(0xFF2196F3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    appointment['vehiculo'] ??
                        AppLocalizations.of(context).generalMaintenance,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      estado.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Sección de Información
            _buildInfoSection(
              context,
              title: AppLocalizations.of(context).appointmentInfo,
              items: [
                _buildInfoRow(
                  Icons.calendar_today,
                  AppLocalizations.of(context).requestDate,
                  _formatDate(appointment['fechaSolicitud']),
                ),
                _buildInfoRow(
                  Icons.event_available,
                  AppLocalizations.of(context).assignedDate,
                  _formatDate(appointment['fechaAsignada']),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Sección de Notas
            _buildInfoSection(
              context,
              title: AppLocalizations.of(context).notesInteraction,
              items: [
                _buildNoteRow(
                  AppLocalizations.of(context).yourComment,
                  appointment['comentario'] ??
                      AppLocalizations.of(context).noComments,
                ),
                const Divider(height: 32, color: Colors.white10),
                _buildNoteRow(
                  AppLocalizations.of(context).advisorResponse,
                  appointment['notasAdmin'] ??
                      AppLocalizations.of(context).noResponse,
                ),
              ],
            ),

            const SizedBox(height: 48),
            // Botón de Soporte
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                label: Text(AppLocalizations.of(context).consultDante),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(
    BuildContext context, {
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F2E),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF2196F3)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoteRow(String label, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF2196F3),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
