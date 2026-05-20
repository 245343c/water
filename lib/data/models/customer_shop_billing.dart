import 'package:sri_sai_ro_water/data/models/customer.dart';
import 'package:sri_sai_ro_water/data/models/shop.dart';

/// One shop's CRM account for a bulk app user (same person, multiple shops).
class CustomerShopBilling {
  const CustomerShopBilling({
    required this.shop,
    required this.customer,
  });

  final Shop shop;
  final Customer customer;
}
