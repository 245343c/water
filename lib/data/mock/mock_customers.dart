import 'package:sri_sai_ro_water/core/constants/customer_pricing_keys.dart';
import 'package:sri_sai_ro_water/data/models/customer.dart';
import 'package:sri_sai_ro_water/data/models/customer_billing_mode.dart';
import 'package:sri_sai_ro_water/data/models/customer_product_price.dart';

Customer get seedAbi => Customer(
  id: 'c1',
  name: 'Abi',
  phone: '9632580741',
  billingMode: CustomerBillingMode.monthlyContract,
  email: 'abi@email.com',
  place: 'Hyderabad, Telangana',
  address: 'Hyderabad, Telangana',
  productPrices: const [
    CustomerProductPrice(
      productId: CustomerPricingKeys.canProductId,
      variantId: CustomerPricingKeys.normalVariantId,
      unitPrice: 18,
    ),
    CustomerProductPrice(
      productId: CustomerPricingKeys.canProductId,
      variantId: CustomerPricingKeys.coolVariantId,
      unitPrice: 28,
    ),
  ],
);

Customer get seedRamesh => Customer(
  id: 'c2',
  name: 'Ramesh Kumar',
  phone: '98850 12345',
  billingMode: CustomerBillingMode.monthlyContract,
  email: 'ramesh.kumar@email.com',
  place: 'Gandhi Nagar, Rajahmundry',
  address: 'Door No: 12-5-8, Gandhi Nagar',
);

Customer get seedLakshmi => Customer(
  id: 'c3',
  name: 'Lakshmi Devi',
  phone: '98765 43210',
  billingMode: CustomerBillingMode.monthlyContract,
  place: 'RTC Colony, Rajahmundry',
  address: 'Plot 45, RTC Colony',
);

Customer get seedSuresh => Customer(
  id: 'c4',
  name: 'Suresh Babu',
  phone: '91234 56789',
  billingMode: CustomerBillingMode.monthlyContract,
  place: 'Danavaipeta, Rajahmundry',
  address: 'Flat 302, Sai Residency',
);

List<Customer> seedCoreCustomers() => [
  seedAbi,
  seedRamesh,
  seedLakshmi,
  seedSuresh,
];

List<Customer> seedDriverDemoCustomers() => [
  Customer(
    id: 'c5',
    name: 'Priya Sharma',
    phone: '99887 76655',
    email: 'priya@email.com',
    place: 'Korukonda Road',
    address: 'H.No 8-2-120, Korukonda Road',
  ),
  Customer(
    id: 'c6',
    name: 'Venkatesh Reddy',
    phone: '98480 11223',
    place: 'Morampudi',
    address: 'Near Temple, Morampudi',
  ),
  Customer(
    id: 'c7',
    name: 'Anitha Stores',
    phone: '95501 33445',
    email: 'anitha.stores@email.com',
    place: 'Main Road',
    address: 'Shop 12, Main Road Complex',
  ),
];
