import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../di/injector.dart';
import '../bloc/contacts_cubit.dart';

class ContactsPage extends StatelessWidget {
  final AppContainer container;

  const ContactsPage({super.key, required this.container});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ContactsCubit>(
      create: (_) => ContactsCubit(
        loadContacts: container.loadContacts,
        upsertContact: container.upsertContact,
      ),
      child: const _ContactsView(),
    );
  }
}

class _ContactsView extends StatelessWidget {
  const _ContactsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('People')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context),
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: const Text('Add person'),
      ),
      body: BlocConsumer<ContactsCubit, ContactsState>(
        listener: (context, state) {
          final error = state.errorMessage;
          if (error != null) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(error)));
          }
        },
        builder: (context, state) {
          if (state.loading && state.contacts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.contacts.isEmpty) {
            return const Center(
              child: Text('Tag people in your memories to get birthday alerts.'),
            );
          }
          return ListView.separated(
            itemCount: state.contacts.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final contact = state.contacts[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(contact.displayName.isEmpty
                      ? '?'
                      : contact.displayName[0].toUpperCase()),
                ),
                title: Text(contact.displayName),
                subtitle: contact.birthday == null
                    ? const Text('No birthday set')
                    : Text(
                        'Birthday: ${contact.birthday!.month.toString().padLeft(2, '0')}-${contact.birthday!.day.toString().padLeft(2, '0')}'),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context) async {
    final nameController = TextEditingController();
    DateTime? birthday;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add person'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration:
                    const InputDecoration(labelText: 'Display name'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(birthday == null
                        ? 'No birthday'
                        : 'Birthday: ${birthday!.year}-${birthday!.month.toString().padLeft(2, '0')}-${birthday!.day.toString().padLeft(2, '0')}'),
                  ),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: dialogContext,
                        initialDate: DateTime(1995),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setDialogState(() => birthday = picked);
                      }
                    },
                    child: const Text('Pick'),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved != true) return;
    final name = nameController.text.trim();
    if (name.isEmpty || !context.mounted) return;

    context.read<ContactsCubit>().add(
          displayName: name,
          birthdayMonth: birthday?.month,
          birthdayDay: birthday?.day,
        );
  }
}
