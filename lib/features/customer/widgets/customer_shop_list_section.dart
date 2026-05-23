import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sri_sai_ro_water/data/models/shop.dart';
import 'package:sri_sai_ro_water/features/customer/widgets/customer_shop_widgets.dart';
import 'package:sri_sai_ro_water/features/customer/widgets/customer_theme.dart';

/// Reusable shop search + list (Home and bulk Account tab).
class CustomerShopListSection extends StatefulWidget {
  const CustomerShopListSection({
    super.key,
    required this.shops,
    this.sectionTitle = 'Shops near you',
    this.topPadding = 0,
    this.searchHint = 'Search shops by name or area...',
    this.emptyTitle = 'No shops found',
    this.emptyMessage = 'Try another search or check back later.',
  });

  final List<Shop> shops;
  final String sectionTitle;
  final double topPadding;
  final String searchHint;
  final String emptyTitle;
  final String emptyMessage;

  @override
  State<CustomerShopListSection> createState() =>
      _CustomerShopListSectionState();
}

class _CustomerShopListSectionState extends State<CustomerShopListSection> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Shop> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.shops;
    return widget.shops
        .where(
          (s) =>
              s.name.toLowerCase().contains(q) ||
              s.address.toLowerCase().contains(q) ||
              s.place.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: widget.topPadding),
        CustomerSearchBar(
          controller: _searchController,
          hint: widget.searchHint,
          onChanged: (q) => setState(() => _query = q),
        ),
        CustomerSectionTitle(
          title: _query.isEmpty
              ? '${widget.sectionTitle} (${list.length})'
              : 'Results (${list.length})',
        ),
        if (list.isEmpty)
          CustomerEmptyState(
            icon: Icons.storefront_outlined,
            title: widget.emptyTitle,
            message: widget.emptyMessage,
          )
        else
          ...list.map(
            (shop) => CustomerShopCard(
              shop: shop,
              onTap: () => context.push('/customer/shop/${shop.id}'),
            ),
          ),
        SizedBox(height: customerBottomInset(context, extra: 8)),
      ],
    );
  }
}
