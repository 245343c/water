class CustomerCanBalance {
  const CustomerCanBalance({
    required this.normalDelivered,
    required this.coolDelivered,
    required this.normalReturned,
    required this.coolReturned,
  });

  final int normalDelivered;
  final int coolDelivered;
  final int normalReturned;
  final int coolReturned;

  int get normalWithCustomer => normalDelivered - normalReturned;
  int get coolWithCustomer => coolDelivered - coolReturned;
  int get totalWithCustomer => normalWithCustomer + coolWithCustomer;
}

