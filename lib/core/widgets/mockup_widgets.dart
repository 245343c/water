import 'package:flutter/material.dart';
import 'package:sri_sai_ro_water/core/theme/app_colors.dart';
import 'package:sri_sai_ro_water/core/theme/app_decorations.dart';
import 'package:sri_sai_ro_water/core/theme/app_text_styles.dart';
import 'package:sri_sai_ro_water/core/utils/date_utils_ext.dart';

/// White overview panel with month dropdown + child grid (Dashboard mockup).
class MockupOverviewCard extends StatelessWidget {
  const MockupOverviewCard({
    super.key,
    required this.month,
    required this.onMonthTap,
    required this.child,
  });

  final DateTime month;
  final VoidCallback onMonthTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppDecorations.card,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('This Month Overview', style: AppTextStyles.sectionTitle),
              ),
              _MonthDropdown(month: month, onTap: onMonthTap),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _MonthDropdown extends StatelessWidget {
  const _MonthDropdown({required this.month, required this.onTap});
  final DateTime month;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              month.monthYear,
              style: AppTextStyles.body.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.keyboard_arrow_down, size: 20, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class MockupStatCell extends StatelessWidget {
  const MockupStatCell({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.icon,
    this.iconColor,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecorations.statCell,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Spacer(),
              if (icon != null)
                Icon(icon, size: 20, color: iconColor ?? AppColors.primary),
            ],
          ),
          const Spacer(),
          Text(label, style: AppTextStyles.statLabel, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.statValue.copyWith(
              color: valueColor ?? AppColors.textPrimary,
              fontSize: value.length > 9 ? 17 : 20,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Customer name + phone row used on delivery screens (mockup).
class MockupCustomerStrip extends StatelessWidget {
  const MockupCustomerStrip({
    super.key,
    required this.name,
    required this.phone,
    this.initials,
    this.colorIndex = 0,
    this.showWhatsapp = false,
    this.onWhatsapp,
  });

  final String name;
  final String phone;
  final String? initials;
  final int colorIndex;
  final bool showWhatsapp;
  final VoidCallback? onWhatsapp;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (initials != null) ...[
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.avatarColors[colorIndex % AppColors.avatarColors.length],
            child: Text(
              initials!,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.avatarTextColors[colorIndex % AppColors.avatarTextColors.length],
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: AppTextStyles.customerName),
              const SizedBox(height: 2),
              Text(phone, style: AppTextStyles.bodySecondary),
            ],
          ),
        ),
        if (showWhatsapp)
          Material(
            color: AppColors.successLight,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onWhatsapp,
              customBorder: const CircleBorder(),
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.chat, color: AppColors.whatsapp, size: 22),
              ),
            ),
          ),
      ],
    );
  }
}

class MockupPaymentMethods<T> extends StatelessWidget {
  const MockupPaymentMethods({
    super.key,
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
  });

  final List<T> options;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecorations.card,
      child: RadioGroup<T>(
        groupValue: selected,
        onChanged: (value) {
          if (value != null) onSelected(value);
        },
        child: Column(
          children: [
            for (var i = 0; i < options.length; i++) ...[
              if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
              RadioListTile<T>(
                title: Text(labelOf(options[i]), style: AppTextStyles.body),
                value: options[i],
                activeColor: AppColors.primary,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class MockupMonthNav extends StatelessWidget {
  const MockupMonthNav({
    super.key,
    required this.month,
    required this.onPrev,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecorations.card,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        children: [
          IconButton(
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_left, color: AppColors.primary),
          ),
          Expanded(
            child: Text(
              month.monthYear,
              textAlign: TextAlign.center,
              style: AppTextStyles.sectionTitle.copyWith(color: AppColors.primary),
            ),
          ),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class MockupStatusBadge extends StatelessWidget {
  const MockupStatusBadge({super.key, required this.label, required this.isPaid});

  final String label;
  final bool isPaid;

  @override
  Widget build(BuildContext context) {
    final bg = isPaid ? AppColors.successLight : AppColors.warningLight;
    final fg = isPaid ? AppColors.success : AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class MockupSearchBar extends StatelessWidget {
  const MockupSearchBar({
    super.key,
    required this.controller,
    required this.hint,
    this.onChanged,
    this.onFilter,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilter;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
        suffixIcon: IconButton(
          icon: const Icon(Icons.tune, color: AppColors.textSecondary),
          onPressed: onFilter,
        ),
      ),
    );
  }
}
