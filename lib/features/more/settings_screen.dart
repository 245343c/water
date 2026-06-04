import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/add_edit_customer_widgets.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customers_screen_widgets.dart';
import 'package:sri_sai_ro_water/features/more/widgets/business_setup_form.dart';

/// Full-screen editor — same fields as the More tab business card.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<BusinessSetupFormState>();

  void _save(WaterPlantRepository repo) {
    if (_formKey.currentState?.save(repo) != true) return;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Settings saved', style: GoogleFonts.poppins()),
        behavior: SnackBarBehavior.floating,
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WaterPlantRepository>(
      builder: (context, repo, _) {
        return Scaffold(
          backgroundColor: CustomersColors.screenBg,
          body: AddEditCustomerScaffold(
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AddEditCustomerHeader(
                    title: 'Business settings',
                    subtitle: 'Same as More → Your business',
                    onBack: () => context.pop(),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(8, 14, 8, 16),
                      children: [
                        AddEditCustomerSectionCard(
                          title: 'Your business',
                          subtitle:
                              'Profile, shop location and customer app',
                          child: BusinessSetupForm(
                            key: _formKey,
                            showSaveButton: false,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AddEditCustomerSaveButton(
                    label: 'Save settings',
                    onPressed: () => _save(repo),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
