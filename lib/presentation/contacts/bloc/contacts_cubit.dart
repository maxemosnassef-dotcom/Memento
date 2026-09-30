import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/use_case.dart';
import '../../../domain/entities/contact.dart';
import '../../../domain/usecases/load_contacts.dart';
import '../../../domain/usecases/upsert_contact.dart';

class ContactsState extends Equatable {
  final List<Contact> contacts;
  final bool loading;
  final bool saving;
  final String? errorMessage;

  const ContactsState({
    this.contacts = const [],
    this.loading = false,
    this.saving = false,
    this.errorMessage,
  });

  ContactsState copyWith({
    List<Contact>? contacts,
    bool? loading,
    bool? saving,
    String? Function()? errorMessage,
  }) {
    return ContactsState(
      contacts: contacts ?? this.contacts,
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [contacts, loading, saving, errorMessage];
}

class ContactsCubit extends Cubit<ContactsState> {
  final LoadContacts _loadContacts;
  final UpsertContact _upsertContact;

  ContactsCubit({
    required LoadContacts loadContacts,
    required UpsertContact upsertContact,
  })  : _loadContacts = loadContacts,
        _upsertContact = upsertContact,
        super(const ContactsState()) {
    load();
  }

  Future<void> load() async {
    emit(state.copyWith(loading: true));
    final result = await _loadContacts.execute(const NoParams());
    result.fold(
      onError: (failure) =>
          emit(state.copyWith(loading: false, errorMessage: () => failure.message)),
      onSuccess: (contacts) =>
          emit(state.copyWith(loading: false, contacts: contacts)),
    );
  }

  Future<void> add({
    required String displayName,
    int? birthdayMonth,
    int? birthdayDay,
  }) async {
    emit(state.copyWith(saving: true, errorMessage: () => null));
    final result = await _upsertContact.execute(ContactInput(
      displayName: displayName,
      birthdayMonth: birthdayMonth,
      birthdayDay: birthdayDay,
    ));
    result.fold(
      onError: (failure) =>
          emit(state.copyWith(saving: false, errorMessage: () => failure.message)),
      onSuccess: (_) async {
        await load();
        emit(state.copyWith(saving: false));
      },
    );
  }
}
