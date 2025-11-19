import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart' as material;

class PdfService {
  /// Generates a PDF for a saved cart order
  ///
  /// [customerName] - The display name of the customer
  /// [items] - List of cart items from the database
  /// [fisNo] - The order/invoice number
  /// [customerCode] - The customer code
  static Future<Uint8List> generateCartPdf({
    required String customerName,
    required List<Map<String, dynamic>> items,
    required String fisNo,
    String? customerCode,
  }) async {
    final pdf = pw.Document();

    // Load logo
    pw.ImageProvider? logoImage;
    try {
      final logoData = await rootBundle.load('assets/logo.png');
      logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (e) {
      // If logo not found, continue without it
      logoImage = null;
    }

    // Pre-load all product images
    final productImages = <String, pw.ImageProvider?>{};
    for (final item in items) {
      final stokKodu = item['stokKodu']?.toString() ?? '';
      final imsrc = item['imsrc']?.toString();
      if (imsrc != null && imsrc.isNotEmpty) {
        productImages[stokKodu] = await _loadProductImage(imsrc);
      }
    }

    // Calculate totals
    double subtotal = 0.0;
    double totalDiscount = 0.0;
    double totalVat = 0.0;
    double grandTotal = 0.0;

    for (final item in items) {
      final quantity = _parseDouble(item['miktar']);
      final price = _parseDouble(item['birimFiyat']);
      final vat = _parseDouble(item['vat']);
      final discount = _parseDouble(item['iskonto']);

      final itemSubtotal = quantity * price;
      final discountAmount = itemSubtotal * (discount / 100);
      final discountedSubtotal = itemSubtotal - discountAmount;
      final vatAmount = discountedSubtotal * (vat / 100);
      final itemTotal = discountedSubtotal + vatAmount;

      subtotal += itemSubtotal;
      totalDiscount += discountAmount;
      totalVat += vatAmount;
      grandTotal += itemTotal;
    }

    // Build PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header with logo and title
          _buildHeader(logoImage, fisNo, customerName, customerCode),
          pw.SizedBox(height: 20),

          // Items table
          _buildItemsTable(items, productImages),
          pw.SizedBox(height: 20),

          // Summary section
          _buildSummary(subtotal, totalDiscount, totalVat, grandTotal),
        ],
      ),
    );

    return pdf.save();
  }

  /// Builds the PDF header section
  static pw.Widget _buildHeader(
    pw.ImageProvider? logo,
    String fisNo,
    String customerName,
    String? customerCode,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Logo and company info
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (logo != null)
              pw.Image(logo, width: 80, height: 80),
            pw.SizedBox(height: 10),
            pw.Text(
              'Order Invoice',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),

        // Order details
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'Order #$fisNo',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              customerCode != null && customerCode.isNotEmpty
                  ? 'Customer: $customerCode - $customerName'
                  : 'Customer: $customerName',
              style: const pw.TextStyle(fontSize: 12),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              'Date: ${DateTime.now().toString().split(' ')[0]}',
              style: const pw.TextStyle(fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds the items table
  static pw.Widget _buildItemsTable(
    List<Map<String, dynamic>> items,
    Map<String, pw.ImageProvider?> productImages,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: {
        0: const pw.FixedColumnWidth(80),  // Image (increased)
        1: const pw.FixedColumnWidth(70),  // Stock Code
        2: const pw.FlexColumnWidth(2),    // Product Name (more reduced)
        3: const pw.FixedColumnWidth(35),  // Quantity (reduced)
        4: const pw.FixedColumnWidth(40),  // Unit
        5: const pw.FixedColumnWidth(45),  // Price (reduced)
        6: const pw.FixedColumnWidth(60),  // Discount (more increased)
        7: const pw.FixedColumnWidth(50),  // Total (reduced)
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _buildTableHeader('Image'),
            _buildTableHeader('Stock Code'),
            _buildTableHeader('Product Name'),
            _buildTableHeader('Qty'),
            _buildTableHeader('Unit'),
            _buildTableHeader('Price'),
            _buildTableHeader('Discount'),
            _buildTableHeader('Total'),
          ],
        ),

        // Item rows
        ...items.map((item) => _buildItemRow(item, productImages)),
      ],
    );
  }

  /// Builds a table header cell
  static pw.Widget _buildTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  /// Builds a single item row in the table
  static pw.TableRow _buildItemRow(
    Map<String, dynamic> item,
    Map<String, pw.ImageProvider?> productImages,
  ) {
    final quantity = _parseDouble(item['miktar']);
    final price = _parseDouble(item['birimFiyat']);
    final vat = _parseDouble(item['vat']);
    final discount = _parseDouble(item['iskonto']);
    final unitType = item['birimTipi']?.toString() ?? 'Unit';
    final stockCode = item['stokKodu']?.toString() ?? '-';
    final productName = item['urunAdi']?.toString() ?? '-';

    // Calculate total
    final itemSubtotal = quantity * price;
    final discountAmount = itemSubtotal * (discount / 100);
    final discountedSubtotal = itemSubtotal - discountAmount;
    final vatAmount = discountedSubtotal * (vat / 100);
    final total = discountedSubtotal + vatAmount;

    // Get product image
    final productImage = productImages[stockCode];

    return pw.TableRow(
      children: [
        // Product image
        _buildTableCell(
          productImage != null
              ? pw.Container(
                  width: 70,
                  height: 70,
                  child: pw.Image(
                    productImage,
                    fit: pw.BoxFit.cover,
                  ),
                )
              : pw.Container(
                  width: 70,
                  height: 70,
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey200,
                    border: pw.Border.all(color: PdfColors.grey400),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'No\nImage',
                      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                ),
        ),

        // Stock code
        _buildTableCell(
          pw.Text(
            stockCode,
            style: const pw.TextStyle(fontSize: 9),
            textAlign: pw.TextAlign.center,
          ),
        ),

        // Product name
        _buildTableCell(
          pw.Text(
            productName,
            style: const pw.TextStyle(fontSize: 9),
            maxLines: 2,
            overflow: pw.TextOverflow.clip,
          ),
        ),

        // Quantity
        _buildTableCell(
          pw.Text(
            _formatNumber(quantity),
            style: const pw.TextStyle(fontSize: 9),
            textAlign: pw.TextAlign.center,
          ),
        ),

        // Unit
        _buildTableCell(
          pw.Text(
            unitType,
            style: const pw.TextStyle(fontSize: 9),
            textAlign: pw.TextAlign.center,
          ),
        ),

        // Price
        _buildTableCell(
          pw.Text(
            '£${price.toStringAsFixed(2)}',
            style: const pw.TextStyle(fontSize: 9),
            textAlign: pw.TextAlign.center,
          ),
        ),

        // Discount
        _buildTableCell(
          pw.Text(
            discount > 0 ? '${_formatNumber(discount)}%' : '-',
            style: pw.TextStyle(
              fontSize: 9,
              color: discount > 0 ? PdfColors.red700 : PdfColors.black,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ),

        // Total
        _buildTableCell(
          pw.Text(
            '£${total.toStringAsFixed(2)}',
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ),
      ],
    );
  }

  /// Builds a table cell with padding
  static pw.Widget _buildTableCell(pw.Widget child) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: child,
    );
  }

  /// Builds the summary section at the bottom
  static pw.Widget _buildSummary(
    double subtotal,
    double totalDiscount,
    double totalVat,
    double grandTotal,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          width: 250,
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _buildSummaryRow('Subtotal:', '£${subtotal.toStringAsFixed(2)}'),
              pw.SizedBox(height: 5),
              _buildSummaryRow(
                'Total Discount:',
                '-£${totalDiscount.toStringAsFixed(2)}',
                valueColor: PdfColors.red700,
              ),
              pw.SizedBox(height: 5),
              _buildSummaryRow('VAT:', '£${totalVat.toStringAsFixed(2)}'),
              pw.Divider(thickness: 1),
              _buildSummaryRow(
                'Grand Total:',
                '£${grandTotal.toStringAsFixed(2)}',
                isBold: true,
                fontSize: 14,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds a summary row
  static pw.Widget _buildSummaryRow(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 12,
    PdfColor? valueColor,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  /// Helper method to parse double values
  static double _parseDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '0') ?? 0.0;
  }

  /// Helper method to format numbers (remove .0 for integers)
  static String _formatNumber(double value) {
    if (value % 1 == 0) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }

  /// Loads product image from local storage
  /// Returns null if image doesn't exist
  static Future<pw.ImageProvider?> _loadProductImage(String? imsrc) async {
    try {
      if (imsrc == null || imsrc.isEmpty) return null;

      final uri = Uri.parse(imsrc);
      final fileName = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
      if (fileName.isEmpty) return null;

      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/$fileName';
      final file = File(filePath);

      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        return pw.MemoryImage(bytes);
      }

      return null;
    } catch (e) {
      print('Error loading product image: $e');
      return null;
    }
  }

  /// Opens PDF preview dialog
  static Future<void> previewPdf(
    material.BuildContext context,
    Uint8List pdfData,
    String fileName,
  ) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfData,
      name: fileName,
    );
  }

  /// Saves PDF to device and shares it
  static Future<void> savePdf(
    Uint8List pdfData,
    String fileName,
  ) async {
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/$fileName');
    await file.writeAsBytes(pdfData);

    await Printing.sharePdf(
      bytes: pdfData,
      filename: fileName,
    );
  }
}