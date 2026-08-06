import 'package:flutter_contacts/flutter_contacts.dart';

abstract interface class DeviceContactPicker {
  Future<List<String>> pickPhoneNumbers();
}

class FlutterDeviceContactPicker implements DeviceContactPicker {
  const FlutterDeviceContactPicker();

  @override
  Future<List<String>> pickPhoneNumbers() async {
    final granted = await FlutterContacts.requestPermission(readonly: true);
    if (!granted) return const [];
    final selected = await FlutterContacts.openExternalPick();
    if (selected == null) return const [];
    final contact = await FlutterContacts.getContact(selected.id);
    if (contact == null) return const [];
    return contact.phones.map((phone) => phone.number).toSet().toList();
  }
}
