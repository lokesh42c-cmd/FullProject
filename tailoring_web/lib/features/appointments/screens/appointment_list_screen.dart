import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/layouts/main_layout.dart';
import '../providers/appointment_provider.dart';
import '../models/appointment.dart';
import '../widgets/add_edit_appointment_dialog.dart';
import '../widgets/date_range_dialog.dart';

enum DateFilterType { today, week, all, custom }

class AppointmentListScreen extends StatefulWidget {
  const AppointmentListScreen({super.key});

  @override
  State<AppointmentListScreen> createState() => _AppointmentListScreenState();
}

class _AppointmentListScreenState extends State<AppointmentListScreen> {
  DateFilterType _dateFilter = DateFilterType.all;
  DateTime? _startDate;
  DateTime? _endDate;
  String _search = '';
  String _status = 'ALL';

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppointmentProvider()..loadAppointments(),
      child: MainLayout(
        currentRoute: '/appointments',
        child: Consumer<AppointmentProvider>(
          builder: (context, provider, _) {
            final filtered = _applyFilters(provider.appointments);

            return Scaffold(
              appBar: AppBar(
                title: const Text('Appointments'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: provider.loadAppointments,
                  ),
                ],
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () => _openDialog(context),
                child: const Icon(Icons.add),
              ),
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildFilters(context),
                    const SizedBox(height: 12),
                    Expanded(child: _buildTable(filtered)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ================= FILTER UI =================

  Widget _buildFilters(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _chip('Today', DateFilterType.today),
            const SizedBox(width: 8),
            _chip('This Week', DateFilterType.week),
            const SizedBox(width: 8),
            _chip('All', DateFilterType.all),
            const Spacer(),
            TextButton.icon(
              icon: const Icon(Icons.date_range),
              label: const Text('Range'),
              onPressed: _openDateRange,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search by name or phone',
                ),
                onChanged: (v) {
                  setState(() => _search = v.trim());
                },
              ),
            ),
            const SizedBox(width: 12),
            DropdownButton<String>(
              value: _status,
              items: const [
                DropdownMenuItem(value: 'ALL', child: Text('All')),
                DropdownMenuItem(value: 'SCHEDULED', child: Text('Scheduled')),
                DropdownMenuItem(
                  value: 'RESCHEDULED',
                  child: Text('Rescheduled'),
                ),
                DropdownMenuItem(value: 'NO_SHOW', child: Text('No Show')),
                DropdownMenuItem(value: 'COMPLETED', child: Text('Completed')),
              ],
              onChanged: (v) => setState(() => _status = v!),
            ),
          ],
        ),
      ],
    );
  }

  Widget _chip(String label, DateFilterType type) {
    final selected = _dateFilter == type;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() {
          _dateFilter = type;
          _startDate = null;
          _endDate = null;
        });
      },
    );
  }

  // ================= DATA FILTER LOGIC =================

  List<Appointment> _applyFilters(List<Appointment> list) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekEnd = today.add(const Duration(days: 6));

    return list.where((a) {
      final date = DateTime.parse(a.date);

      // Date filter
      bool dateMatch = true;
      if (_dateFilter == DateFilterType.today) {
        dateMatch = date.isAtSameMomentAs(today);
      } else if (_dateFilter == DateFilterType.week) {
        dateMatch = !date.isBefore(today) && !date.isAfter(weekEnd);
      } else if (_dateFilter == DateFilterType.custom &&
          _startDate != null &&
          _endDate != null) {
        dateMatch = !date.isBefore(_startDate!) && !date.isAfter(_endDate!);
      }

      // Search
      final searchMatch =
          _search.isEmpty ||
          a.name.toLowerCase().contains(_search.toLowerCase()) ||
          a.phone.contains(_search);

      // Status
      final statusMatch = _status == 'ALL' || a.status == _status;

      return dateMatch && searchMatch && statusMatch;
    }).toList();
  }

  // ================= TABLE =================

  Widget _buildTable(List<Appointment> list) {
    if (list.isEmpty) {
      return const Center(child: Text('No appointments'));
    }

    return SingleChildScrollView(
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('Phone')),
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Time')),
          DataColumn(label: Text('Service')),
          DataColumn(label: Text('Notes')),
          DataColumn(label: Text('Status')),
        ],
        rows: list.map((a) {
          return DataRow(
            cells: [
              DataCell(Text(a.name), onTap: () => _openDialog(context, a)),
              DataCell(Text(a.phone), onTap: () => _openDialog(context, a)),
              DataCell(Text(a.date), onTap: () => _openDialog(context, a)),
              DataCell(Text(a.startTime), onTap: () => _openDialog(context, a)),
              DataCell(Text(a.service ?? '')),
              DataCell(
                SizedBox(
                  width: 220,
                  child: Text(
                    a.notes ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(Text(a.status)),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ================= ACTIONS =================

  void _openDialog(BuildContext parentContext, [Appointment? appointment]) {
    showDialog(
      context: parentContext,
      builder: (dialogContext) {
        return AddEditAppointmentDialog(initialAppointment: appointment);
      },
    );
  }

  Future<void> _openDateRange() async {
    final result = await showDialog(
      context: context,
      builder: (_) => const DateRangeDialog(),
    );

    if (result != null) {
      setState(() {
        _dateFilter = DateFilterType.custom;
        _startDate = result['start'];
        _endDate = result['end'];
      });
    }
  }
}
