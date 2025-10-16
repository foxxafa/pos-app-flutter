import 'dart:io';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:pos_app/core/theme/app_theme.dart';
import 'package:pos_app/features/customer/presentation/providers/cartcustomer_provider.dart';
import 'package:provider/provider.dart';

class StatementPdfView extends StatefulWidget {
  const StatementPdfView({super.key});

  @override
  State<StatementPdfView> createState() => _StatementPdfViewState();
}

class _StatementPdfViewState extends State<StatementPdfView> {
  String? _pdfPath;
  bool _isLoading = true;
  String? _errorMessage;
  int _totalPages = 0;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _downloadAndDisplayPdf();
  }

  Future<void> _downloadAndDisplayPdf() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final customer = Provider.of<SalesCustomerProvider>(context, listen: false).selectedCustomer;
      final customerCode = customer?.kod;

      if (customerCode == null || customerCode.isEmpty) {
        throw Exception('Customer code not found');
      }

      // API endpoint
      final url = 'https://test.rowhub.net/index.php?r=apimobil/getekstre&carikod=$customerCode';

      print('📄 Downloading PDF from: $url');

      // Download PDF
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        // Get temporary directory
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/statement_$customerCode.pdf');

        // Write PDF to file
        await file.writeAsBytes(response.bodyBytes);

        print('✅ PDF downloaded successfully: ${file.path}');

        setState(() {
          _pdfPath = file.path;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to download PDF: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error downloading PDF: $e');
      setState(() {
        _errorMessage = 'Failed to load statement: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.lightBackgroundColor,
      appBar: AppBar(
        title: Text('customer_menu.statement'.tr()),
        actions: [
          if (_pdfPath != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _downloadAndDisplayPdf,
              tooltip: 'Refresh',
            ),
        ],
      ),
      body: Column(
        children: [
          // PDF Viewer or Loading/Error (Full Screen)
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                          color: AppTheme.lightPrimaryColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading statement...',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.red[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Error',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: _downloadAndDisplayPdf,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Try Again'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.lightPrimaryColor,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _pdfPath != null
                        ? PDFView(
                            filePath: _pdfPath!,
                            enableSwipe: true,
                            swipeHorizontal: false,
                            autoSpacing: true,
                            pageFling: true,
                            pageSnap: true,
                            onRender: (pages) {
                              setState(() {
                                _totalPages = pages ?? 0;
                              });
                            },
                            onPageChanged: (page, total) {
                              setState(() {
                                _currentPage = page ?? 0;
                              });
                            },
                            onError: (error) {
                              print('❌ PDF View Error: $error');
                              setState(() {
                                _errorMessage = 'Error displaying PDF: $error';
                              });
                            },
                            onPageError: (page, error) {
                              print('❌ PDF Page Error: $error');
                            },
                          )
                        : Center(
                            child: Text(
                              'No PDF available',
                              style: theme.textTheme.bodyLarge,
                            ),
                          ),
          ),

          // Page indicator
          if (_pdfPath != null && _totalPages > 0)
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Text(
                  'Page ${_currentPage + 1} of $_totalPages',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}