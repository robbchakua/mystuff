import 'package:flutter/material.dart';

enum ItemStatus { missing, inUse, inLocation }

extension ItemStatusDetails on ItemStatus {
  String get apiValue => switch (this) {
        ItemStatus.missing => 'missing',
        ItemStatus.inUse => 'in_use',
        ItemStatus.inLocation => 'in_location',
      };

  String get label => switch (this) {
        ItemStatus.missing => 'Missing',
        ItemStatus.inUse => 'In Use',
        ItemStatus.inLocation => 'In location',
      };

  IconData get icon => switch (this) {
        ItemStatus.missing => Icons.error_outline,
        ItemStatus.inUse => Icons.handyman_outlined,
        ItemStatus.inLocation => Icons.inventory_2_outlined,
      };

  Color get color => switch (this) {
        ItemStatus.missing => Colors.redAccent,
        ItemStatus.inUse => Colors.orangeAccent,
        ItemStatus.inLocation => Colors.green,
      };
}

ItemStatus parseItemStatus(dynamic value) => switch (value?.toString()) {
      'missing' => ItemStatus.missing,
      'in_use' => ItemStatus.inUse,
      _ => ItemStatus.inLocation,
    };
