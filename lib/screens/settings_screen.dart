import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/event_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: Consumer<EventProvider>(
        builder: (context, eventProvider, child) {
          final localStorage = eventProvider;

          return ListView(
            children: [
              _buildSection(
                context,
                title: 'Erscheinungsbild',
                children: [
                  SwitchListTile(
                    title: const Text('Dunkles Theme'),
                    subtitle: const Text('Aktiviere den Dunkelmodus'),
                    secondary: const Icon(Icons.dark_mode),
                    value: localStorage.offlineModeEnabled
                        ? false
                        : context.read<EventProvider>().lastSync != null,
                    onChanged: (value) {
                      eventProvider.toggleDarkMode();
                    },
                  ),
                ],
              ),
              _buildSection(
                context,
                title: 'Daten & Synchronisation',
                children: [
                  SwitchListTile(
                    title: const Text('Offline-Modus'),
                    subtitle: Text(
                      eventProvider.offlineModeEnabled
                          ? 'Verwende nur gecachte Daten'
                          : 'Automatisch aktualisieren',
                    ),
                    secondary: Icon(
                      eventProvider.offlineModeEnabled
                          ? Icons.cloud_off
                          : Icons.cloud_sync,
                    ),
                    value: eventProvider.offlineModeEnabled,
                    onChanged: (value) {
                      eventProvider.toggleOfflineMode();
                    },
                  ),
                  if (eventProvider.lastSync != null)
                    ListTile(
                      leading: const Icon(Icons.sync),
                      title: const Text('Letzte Synchronisation'),
                      subtitle: Text(
                        DateFormat(
                          'dd.MM.yyyy HH:mm',
                        ).format(eventProvider.lastSync!),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: eventProvider.offlineModeEnabled
                            ? null
                            : () {
                                eventProvider.refreshEvents();
                              },
                      ),
                    ),
                ],
              ),
              _buildSection(
                context,
                title: 'Statistiken',
                children: [
                  ListTile(
                    leading: const Icon(Icons.event),
                    title: const Text('Gecachte Events'),
                    trailing: Text(
                      '${eventProvider.events.length}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.favorite),
                    title: const Text('Favoriten'),
                    trailing: Text(
                      '${eventProvider.getFavoriteEvents().length}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              _buildSection(
                context,
                title: 'Über',
                children: [
                  const ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('Version'),
                    subtitle: Text('1.0.0+1'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.code),
                    title: const Text('Technologie'),
                    subtitle: const Text('Flutter + Cloudflare D1'),
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'Weltenbibliothek',
                        applicationVersion: '1.0.0',
                        applicationIcon: const Icon(Icons.map, size: 48),
                        children: [
                          const Text(
                            'Eine interaktive Wissensplattform mit Event-Karten, '
                            'Dokumentenverwaltung und Multimedia-Integration.\n\n'
                            'Powered by Flutter & Cloudflare D1',
                          ),
                        ],
                      );
                    },
                  ),
                  const ListTile(
                    leading: Icon(Icons.description_outlined),
                    title: Text('Lizenz'),
                    subtitle: Text('MIT License'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        ...children,
        const Divider(),
      ],
    );
  }
}
