enum ProductCategory {
  bottle('Bottles', 'Packaged water in multiple sizes'),
  can('Cans', '20L refill cans — normal & cool');

  const ProductCategory(this.label, this.subtitle);
  final String label;
  final String subtitle;
}
