import 'dart:io';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:pos_app/core/theme/app_theme.dart';
import 'package:pos_app/core/network/api_config.dart';
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
  bool _isLoading = false;
  String? _errorMessage;
  PdfDocument? _pdfDocument;
  int _totalPages = 0;
  int _currentPage = 0;
  DateTime _startDate = DateTime(DateTime.now().year, 1, 1);
  DateTime _endDate = DateTime.now();
  bool _showDetail = true;
  bool _uninvoicedDeliveryNote = true;

  late TextEditingController _startDateController;
  late TextEditingController _endDateController;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _startDateController = TextEditingController(text: DateFormat('dd.MM.yyyy').format(_startDate));
    _endDateController = TextEditingController(text: DateFormat('dd.MM.yyyy').format(_endDate));
    _pageController.addListener(() {
      final page = _pageController.page?.round() ?? 0;
      if (page != _currentPage) {
        setState(() {
          _currentPage = page;
        });
      }
    });
  }

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    _pageController.dispose();
    _pdfDocument?.close();
    super.dispose();
  }

  DateTime? _parseDate(String input) {
    try {
      // Parse dd.MM.yyyy format
      return DateFormat('dd.MM.yyyy').parseStrict(input);
    } catch (e) {
      return null;
    }
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

      // Parse tarihleri text field'lardan
      final parsedStartDate = _parseDate(_startDateController.text);
      final parsedEndDate = _parseDate(_endDateController.text);

      if (parsedStartDate == null) {
        throw Exception('Invalid start date format. Use dd.MM.yyyy');
      }
      if (parsedEndDate == null) {
        throw Exception('Invalid end date format. Use dd.MM.yyyy');
      }

      // Update internal dates
      _startDate = parsedStartDate;
      _endDate = parsedEndDate;

      // Format tarih as YYYY-MM-DD
      final formattedStartDate = DateFormat('yyyy-MM-dd').format(_startDate);
      final formattedEndDate = DateFormat('yyyy-MM-dd').format(_endDate);
      final detayParam = _showDetail ? '1' : '0';
      final ftParam = _uninvoicedDeliveryNote ? '1' : '0';

      // API endpoint with tarih (start), tarih2 (end), detay and ft parameters - Use ApiConfig base URL
      final url = '${ApiConfig.baseUrl}/index.php?r=apimobil/getekstre&carikod=$customerCode&tarih=$formattedStartDate&tarih2=$formattedEndDate&detay=$detayParam&ft=$ftParam';

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

        // Open PDF document with pdfx
        final document = await PdfDocument.openFile(file.path);
        final pageCount = document.pagesCount;

        print('✅ PDF opened: $pageCount pages');

        setState(() {
          _pdfPath = file.path;
          _pdfDocument = document;
          _totalPages = pageCount;
          _currentPage = 0;
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


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.lightBackgroundColor,
      resizeToAvoidBottomInset: true,
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
          // PDF Viewer or Loading/Error - Expanded (kalan tüm alanı kapla)
          if (_pdfDocument != null || _isLoading || _errorMessage != null)
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
                      : PageView.builder(
                          controller: _pageController,
                          itemCount: _totalPages,
                          itemBuilder: (context, index) {
                            return _PdfPageWithZoom(
                              document: _pdfDocument!,
                              pageNumber: index + 1,
                            );
                          },
                        ),
                      ),

          // Spacer - PDF yoksa kontroller ortada
          if (_pdfDocument == null && !_isLoading && _errorMessage == null)
            const Spacer(),

          // Controls section - Alt kısım (sabit yükseklik)
          Container(
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
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                  // Page indicator (if PDF loaded)
                  if (_pdfDocument != null && _totalPages > 0) ...[
                    Text(
                      'Page ${_currentPage + 1} of $_totalPages',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Üst satır: 2 tarih input field
                  Row(
                    children: [
                      // Başlangıç tarihi
                      Expanded(
                        child: TextField(
                          controller: _startDateController,
                          decoration: InputDecoration(
                            labelText: 'Start Date',
                            labelStyle: const TextStyle(fontSize: 12),
                            hintText: 'dd.MM.yyyy',
                            hintStyle: TextStyle(fontSize: 11, color: Colors.grey[400]),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: AppTheme.lightPrimaryColor),
                            ),
                            suffixIcon: const Icon(Icons.calendar_today, size: 16),
                          ),
                          style: const TextStyle(fontSize: 13),
                          keyboardType: TextInputType.datetime,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Bitiş tarihi
                      Expanded(
                        child: TextField(
                          controller: _endDateController,
                          decoration: InputDecoration(
                            labelText: 'End Date',
                            labelStyle: const TextStyle(fontSize: 12),
                            hintText: 'dd.MM.yyyy',
                            hintStyle: TextStyle(fontSize: 11, color: Colors.grey[400]),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: AppTheme.lightPrimaryColor),
                            ),
                            suffixIcon: const Icon(Icons.calendar_today, size: 16),
                          ),
                          style: const TextStyle(fontSize: 13),
                          keyboardType: TextInputType.datetime,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Alt satır: 2 checkbox
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // Detail checkbox
                      InkWell(
                        onTap: () {
                          setState(() {
                            _showDetail = !_showDetail;
                          });
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: _showDetail,
                              onChanged: (value) {
                                setState(() {
                                  _showDetail = value ?? true;
                                });
                              },
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                            const Text('Detail', style: TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Uninvoiced Delivery Note checkbox
                      InkWell(
                        onTap: () {
                          setState(() {
                            _uninvoicedDeliveryNote = !_uninvoicedDeliveryNote;
                          });
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: _uninvoicedDeliveryNote,
                              onChanged: (value) {
                                setState(() {
                                  _uninvoicedDeliveryNote = value ?? false;
                                });
                              },
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                            const Text('Uninvoiced Delivery Note', style: TextStyle(fontSize: 13)),
                          ],
                        ),
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
        ],
      ),
    );
  }
}

// Custom widget for each PDF page with zoom functionality
class _PdfPageWithZoom extends StatefulWidget {
  final PdfDocument document;
  final int pageNumber;

  const _PdfPageWithZoom({
    required this.document,
    required this.pageNumber,
  });

  @override
  State<_PdfPageWithZoom> createState() => _PdfPageWithZoomState();
}

class _PdfPageWithZoomState extends State<_PdfPageWithZoom> {
  PdfPageImage? _pageImage;
  bool _isLoading = true;
  final TransformationController _transformationController = TransformationController();

  @override
  void initState() {
    super.initState();
    _loadPage();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _loadPage() async {
    try {
      final page = await widget.document.getPage(widget.pageNumber);
      final pageImage = await page.render(
        width: page.width * 2, // Render at 2x resolution for better quality
        height: page.height * 2,
        format: PdfPageImageFormat.png,
      );
      await page.close();

      if (mounted) {
        setState(() {
          _pageImage = pageImage;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading page ${widget.pageNumber}: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppTheme.lightPrimaryColor,
        ),
      );
    }

    if (_pageImage == null) {
      return const Center(
        child: Text('Failed to load page'),
      );
    }

    return InteractiveViewer(
      transformationController: _transformationController,
      minScale: 1.0,
      maxScale: 4.0,
      panEnabled: true,
      scaleEnabled: true,
      child: Center(
        child: Image.memory(
          _pageImage!.bytes,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}