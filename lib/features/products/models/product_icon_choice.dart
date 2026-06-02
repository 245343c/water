import 'package:flutter/material.dart';

class ProductIconChoice {
  const ProductIconChoice({
    required this.key,
    required this.label,
    required this.icon,
  });

  final String key;
  final String label;
  final IconData icon;
}

const List<ProductIconChoice> kProductIconChoices = [
  ProductIconChoice(
    key: 'waterBottle',
    label: 'Bottle',
    icon: Icons.water_drop_outlined,
  ),
  ProductIconChoice(
    key: 'normalCan',
    label: 'Normal Can',
    icon: Icons.local_drink_outlined,
  ),
  ProductIconChoice(
    key: 'coolCan',
    label: 'Cool Can',
    icon: Icons.ac_unit_rounded,
  ),
  ProductIconChoice(
    key: 'lorry',
    label: 'Lorry',
    icon: Icons.local_shipping_outlined,
  ),
  ProductIconChoice(
    key: 'auto',
    label: 'Auto',
    icon: Icons.electric_rickshaw_outlined,
  ),
  ProductIconChoice(
    key: 'canCrate',
    label: 'Can Crate',
    icon: Icons.inventory_2_outlined,
  ),
];

ProductIconChoice productIconByKey(String? key) {
  for (final choice in kProductIconChoices) {
    if (choice.key == key) return choice;
  }
  return kProductIconChoices.first;
}
