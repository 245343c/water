import 'package:sri_sai_ro_water/data/models/customer.dart';
import 'package:sri_sai_ro_water/data/models/shop.dart';

/// One shop's monthly CRM account for the same customer phone.
///
/// A customer can be added by multiple admins/plants. The app links by phone
/// and shows one billing account per linked shop.
class CustomerShopBilling {
  const CustomerShopBilling({required this.shop, required this.customer});

  final Shop shop;
  final Customer customer;
}
