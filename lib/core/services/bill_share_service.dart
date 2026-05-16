import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sri_sai_ro_water/data/models/customer.dart';

/// Shares or saves bill PDF files using the device share sheet (WhatsApp, Drive, etc.).
abstract final class BillShareService {
  static Future<void> sharePdf({
    required File file,
    required Customer customer,
    required String businessName,
    required String monthLabel,
  }) async {
    final message =
        'Monthly bill for ${customer.name} ($monthLabel) from $businessName.\n'
        'Amounts are in Indian Rupees (${CurrencySymbol.label}).';

    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(
            file.path,
            mimeType: 'application/pdf',
            name: file.uri.pathSegments.last,
          ),
        ],
        text: message,
        subject: '$businessName — Bill $monthLabel',
      ),
    );
  }

  /// Saves a copy under app documents and returns the saved file path.
  static Future<String> saveToDocuments(File source, String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final billsDir = Directory('${dir.path}/bills');
    if (!billsDir.existsSync()) {
      billsDir.createSync(recursive: true);
    }
    final dest = File('${billsDir.path}/$fileName');
    await source.copy(dest.path);
    return dest.path;
  }
}

/// Official Indian Rupee sign (Unicode U+20B9) — not "Rs" or "INR".
abstract final class CurrencySymbol {
  static const String rupee = '₹';
  static const String label = '₹ (INR)';
}
