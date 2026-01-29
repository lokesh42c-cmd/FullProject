import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/layouts/main_layout.dart';
import '../providers/appointment_provider.dart';
import '../widgets/add_edit_appointment_dialog.dart';
import '../widgets/date_range_dialog.dart';
import '../models/appointment.dart';

class AppointmentListScreen extends StatefulWidget {
  const AppointmentListScreen({super.key});

  @override
  State<AppointmentListScreen> createState() => _AppointmentListScreenState();
}

class _AppointmentListScreenState extends State<AppointmentListScreen> {
  String _status = 'ALL';
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppointmentProvider()..loadAppointments(),
      child: MainLayout(
        currentRoute: '/appointments',
        child: Consumer<AppointmentProvider>(
          builder: (context, provider, _) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Appointments'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => provider.loadAppointments(
                      status: _status,
                      search: _search,
                    ),
                  ),
                ],
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () => _openDialog(context),
                child: const Icon(Icons.add),
              ),
              body: Column(
                children: [
                  _buildFilters(provider),
                  Expanded(child: _buildBody(context, provider)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilters(AppointmentProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              ActionChip(
                label: const Text('Today'),
                onPressed: () {
                  final now = DateTime.now();
                  provider.loadAppointments(
                    fromDate: now,
                    toDate: now,
                    status: _status,
                    search: _search,
                  );
                },
              ),
              const SizedBox(width: 8),
              ActionChip(
                label: const Text('Custom Range'),
                onPressed: () async {
                  // CAPTURING THE APPLY RESULT
                  final range = await showDialog<Map<String, DateTime>>(
                    context: context,
                    builder: (_) => const DateRangeDialog(),
                  );
                  if (range != null) {
                    provider.loadAppointments(
                      fromDate: range['start'],
                      toDate: range['end'],
                      status: _status,
                      search: _search,
                    );
                  }
                },
              ),
              const SizedBox(width: 8),
              ActionChip(
                label: const Text('All'),
                onPressed: () => provider.loadAppointments(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search by name or phone',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => _search = v,
                  onSubmitted: (v) =>
                      provider.loadAppointments(status: _status, search: v),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _status,
                items: const [
                  DropdownMenuItem(value: 'ALL', child: Text('All Status')),
                  DropdownMenuItem(
                    value: 'SCHEDULED',
                    child: Text('Scheduled'),
                  ),
                  DropdownMenuItem(
                    value: 'COMPLETED',
                    child: Text('Completed'),
                  ),
                  DropdownMenuItem(
                    value: 'CANCELLED',
                    child: Text('Cancelled'),
                  ),
                ],
                onChanged: (v) {
                  setState(() => _status = v!);
                  provider.loadAppointments(status: _status, search: _search);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppointmentProvider provider) {
    if (provider.isLoading)
      return const Center(child: CircularProgressIndicator());
    if (provider.appointments.isEmpty)
      return const Center(child: Text('No appointments found'));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Name')),
            DataColumn(label: Text('Phone')),
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Status')),
          ],
          rows: provider.appointments
              .map(
                (a) => DataRow(
                  cells: [
                    DataCell(
                      Text(a.name),
                      onTap: () => _openDialog(context, a),
                    ),
                    DataCell(
                      Text(a.phone),
                      onTap: () => _openDialog(context, a),
                    ),
                    DataCell(
                      Text(a.date),
                      onTap: () => _openDialog(context, a),
                    ),
                    DataCell(
                      Text(a.status),
                      onTap: () => _openDialog(context, a),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  void _openDialog(BuildContext context, [Appointment? appointment]) {
    final provider = Provider.of<AppointmentProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (_) => AddEditAppointmentDialog(
        provider: provider,
        initialAppointment: appointment,
      ),
    );
  }
}
