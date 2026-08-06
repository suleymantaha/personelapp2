import 'package:flutter_contacts/flutter_contacts.dart';

abstract interface class DeviceContactPicker {
  Future<String?> pickPhoneNumber();
}

class FlutterDeviceContactPicker implements DeviceContactPicker {
  const FlutterDeviceContactPicker();

  @override
  Future<String?> pickPhoneNumber() async {
    final granted = await FlutterContacts.requestPermission(readonly: true);
    if (!granted) return null;
    final selected = await FlutterContacts.openExternalPick();
    if (selected == null) return null;
    final contact = await FlutterContacts.getContact(selected.id);
    if (contact == null || contact.phones.isEmpty) return null;
    return contact.phones.first.number;
  }
}
