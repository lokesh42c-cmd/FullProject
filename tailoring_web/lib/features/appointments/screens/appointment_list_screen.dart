// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../../core/layouts/main_layout.dart';
// import '../providers/appointment_provider.dart';
// import '../widgets/add_edit_appointment_dialog.dart';
// import '../models/appointment.dart';

// class AppointmentListScreen extends StatefulWidget {
//   const AppointmentListScreen({super.key});

//   @override
//   State<AppointmentListScreen> createState() => _AppointmentListScreenState();
// }

// class _AppointmentListScreenState extends State<AppointmentListScreen> {
//   String _status = 'ALL';
//   String _search = '';

//   @override
//   Widget build(BuildContext context) {
//     return ChangeNotifierProvider(
//       create: (_) => AppointmentProvider()..loadAppointments(),
//       child: MainLayout(
//         currentRoute: '/appointments',
//         child: Consumer<AppointmentProvider>(
//           builder: (context, provider, _) {
//             return Scaffold(
//               appBar: AppBar(
//                 title: const Text('Appointments'),
//                 actions: [
//                   IconButton(
//                     icon: const Icon(Icons.refresh),
//                     onPressed: () => provider.loadAppointments(),
//                   ),
//                 ],
//               ),
//               floatingActionButton: FloatingActionButton(
//                 onPressed: () => _openDialog(context),
//                 child: const Icon(Icons.add),
//               ),
//               body: Column(
//                 children: [
//                   _buildFilters(provider),
//                   Expanded(child: _buildBody(context, provider)),
//                 ],
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }

//   /// -------- TOP FILTERS --------
//   Widget _buildFilters(AppointmentProvider provider) {
//     return Padding(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         children: [
//           Row(
//             children: [
//               ActionChip(
//                 label: const Text('Today'),
//                 onPressed: () {
//                   final now = DateTime.now();
//                   provider.loadAppointments(fromDate: now, toDate: now);
//                 },
//               ),
//               const SizedBox(width: 8),
//               ActionChip(
//                 label: const Text('This Week'),
//                 onPressed: () {
//                   final now = DateTime.now();
//                   final start = now.subtract(Duration(days: now.weekday - 1));
//                   final end = start.add(const Duration(days: 6));
//                   provider.loadAppointments(fromDate: start, toDate: end);
//                 },
//               ),
//               const SizedBox(width: 8),
//               ActionChip(
//                 label: const Text('All'),
//                 onPressed: () => provider.loadAppointments(),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           Row(
//             children: [
//               Expanded(
//                 child: TextField(
//                   decoration: const InputDecoration(
//                     hintText: 'Search by name or phone',
//                     prefixIcon: Icon(Icons.search),
//                   ),
//                   onChanged: (v) => _search = v,
//                   onSubmitted: (_) {
//                     provider.loadAppointments(search: _search);
//                   },
//                 ),
//               ),
//               const SizedBox(width: 12),
//               DropdownButton<String>(
//                 value: _status,
//                 items: const [
//                   DropdownMenuItem(value: 'ALL', child: Text('All')),
//                   DropdownMenuItem(
//                     value: 'SCHEDULED',
//                     child: Text('Scheduled'),
//                   ),
//                   DropdownMenuItem(
//                     value: 'COMPLETED',
//                     child: Text('Completed'),
//                   ),
//                   DropdownMenuItem(
//                     value: 'CANCELLED',
//                     child: Text('Cancelled'),
//                   ),
//                   DropdownMenuItem(value: 'NO_SHOW', child: Text('No Show')),
//                 ],
//                 onChanged: (v) {
//                   setState(() => _status = v!);
//                   provider.loadAppointments(status: _status, search: _search);
//                 },
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   /// -------- LIST / TABLE --------
//   Widget _buildBody(BuildContext context, AppointmentProvider provider) {
//     if (provider.isLoading) {
//       return const Center(child: CircularProgressIndicator());
//     }

//     if (provider.appointments.isEmpty) {
//       return const Center(child: Text('No appointments found'));
//     }

//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16),
//       child: DataTable(
//         columns: const [
//           DataColumn(label: Text('Name')),
//           DataColumn(label: Text('Phone')),
//           DataColumn(label: Text('Date')),
//           DataColumn(label: Text('Time')),
//           DataColumn(label: Text('Service')),
//           DataColumn(label: Text('Notes')),
//           DataColumn(label: Text('Status')),
//         ],
//         rows: provider.appointments.map((Appointment a) {
//           return DataRow(
//             cells: [
//               DataCell(Text(a.name), onTap: () => _openDialog(context, a)),
//               DataCell(Text(a.phone), onTap: () => _openDialog(context, a)),
//               DataCell(Text(a.date), onTap: () => _openDialog(context, a)),
//               DataCell(Text(a.startTime), onTap: () => _openDialog(context, a)),
//               DataCell(
//                 Text(a.service ?? ''),
//                 onTap: () => _openDialog(context, a),
//               ),
//               DataCell(
//                 SizedBox(
//                   width: 220,
//                   child: Text(
//                     a.notes ?? '',
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//                 onTap: () => _openDialog(context, a),
//               ),
//               DataCell(Text(a.status), onTap: () => _openDialog(context, a)),
//             ],
//           );
//         }).toList(),
//       ),
//     );
//   }

//   // void _openDialog(BuildContext context, [Appointment? appointment]) {
//   //   showDialog(
//   //     context: context,
//   //     builder: (_) => ChangeNotifierProvider.value(
//   //       value: context.read<AppointmentProvider>(),
//   //       child: AddEditAppointmentDialog(initialAppointment: appointment),
//   //     ),
//   //   );
//   // }
// }
