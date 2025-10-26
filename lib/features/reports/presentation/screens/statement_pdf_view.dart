import 'dart:io';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:pos_app/core/theme/app_theme.dart';
import 'package:pos_app/features/customer/presentation/providers/cartcustomer_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class StatementPdfView extends StatefulWidget {
  const StatementPdfView({super.key});

  @override
  State<StatementPdfView> createState() => _StatementPdfViewState();
}

class _StatementPdfViewState extends State<StatementPdfView> {
  String? _pdfPath;
  bool _isLoading = false; // İlk yüklemede false, kullanıcı butona bassın
  String? _errorMessage;
  int _totalPages = 0;
  int _currentPage = 0;
  DateTime _selectedDate = DateTime(2025, 1, 1); // Default tarih
  bool _showDetail = true; // Detay göster (1) veya gösterme (0)

  @override
  void initState() {
    super.initState();
    // İlk açılışta PDF yükleme, kullanıcı parametreleri seçip butona bassın
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

      // Format tarih as YYYY-MM-DD
      final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final detayParam = _showDetail ? '1' : '0';

      // API endpoint with tarih and detay parameters
      final url = 'https://test.rowhub.net/index.php?r=apimobil/getekstre&carikod=$customerCode&tarih=$formattedDate&detay=$detayParam';

      print('📄 Downloading PDF from: $url');

      // Download PDF
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        // Get temporary directory
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/document_$customerCode.pdf');

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

  Future<void> _sharePdf() async {
    if (_pdfPath == null) return;

    try {
      final customer = Provider.of<SalesCustomerProvider>(context, listen: false).selectedCustomer;
      final customerCode = customer?.kod ?? 'unknown';

      await Share.shareXFiles(
        [XFile(_pdfPath!)],
        text: 'document_$customerCode',
        subject: 'document_$customerCode',
      );
    } catch (e) {
      print('❌ Error sharing PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
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
              icon: const Icon(Icons.share),
              onPressed: _sharePdf,
              tooltip: 'Share',
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

        ],
      ),
      bottomNavigationBar: Container(
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Page indicator (if PDF loaded)
              if (_pdfPath != null && _totalPages > 0) ...[
                Text(
                  'Page ${_currentPage + 1} of $_totalPages',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],

              // Tarih seçici ve Detay checkbox
              Row(
                children: [
                  // Tarih seçici
                  Expanded(
                    child: InkWell(
                      onTap: _selectDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('dd.MM.yyyy').format(_selectedDate),
                              style: const TextStyle(fontSize: 14),
                            ),
                            const Icon(Icons.calendar_today, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Detay checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: _showDetail,
                        onChanged: (value) {
                          setState(() {
                            _showDetail = value ?? true;
                          });
                        },
                      ),
                      const Text('Detail'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Load Report butonu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _downloadAndDisplayPdf,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.lightPrimaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Load Report', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}