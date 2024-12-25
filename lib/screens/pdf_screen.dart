import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart'; // For portrait mode lock

class PdfScreen extends StatefulWidget {
  final String pdfUrl;
  final int bookId;
  final int userId;

  const PdfScreen({
    super.key,
    required this.pdfUrl,
    required this.bookId,
    required this.userId,
  });

  @override
  _PdfScreenState createState() => _PdfScreenState();
}

class _PdfScreenState extends State<PdfScreen> {
  String? localFilePath;
  bool isLoading = true;

  // Eye protection modes
  Color backgroundColor = Colors.black; // Default Night Mode
  Color textColor = Colors.yellow; // Default Text Color
  Color pdfViewColor = Colors.black; // PDFView background

  @override
  void initState() {
    super.initState();

    // Lock orientation to portrait mode
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    // print(
    // 'pdfUrl*************************************************************************************************************************: ${widget.pdfUrl}');

    downloadPdf();
  }

  @override
  void dispose() {
    // Reset orientation settings when leaving the screen
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  Future<void> downloadPdf() async {
    try {
      final dio = Dio();
      final dir = await getTemporaryDirectory(); // Use a temporary directory
      final filePath = '${dir.path}/temp_${widget.bookId}.pdf';

      // Download the PDF
      await dio.download(widget.pdfUrl, filePath);

      setState(() {
        localFilePath = filePath;
        isLoading = false;
      });
    } catch (e) {
      print('Error downloading PDF: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void toggleMode(String mode) {
    setState(() {
      if (mode == 'Reading Mode') {
        backgroundColor = Colors.white;
        textColor = Colors.black;
        pdfViewColor = Colors.white;
      } else if (mode == 'Night Light') {
        backgroundColor = Colors.black;
        textColor = Colors.yellow;
        pdfViewColor = Colors.black;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Book PDF - Book ID: ${widget.bookId}, User ID: ${widget.userId}',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: backgroundColor,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          PopupMenuButton<String>(
            onSelected: toggleMode,
            icon: Icon(Icons.settings, color: textColor),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'Reading Mode',
                child: Text('Reading Mode'),
              ),
              const PopupMenuItem(
                value: 'Night Light',
                child: Text('Night Light'),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        color: backgroundColor,
        child: isLoading
            ? Center(
                child: CircularProgressIndicator(color: textColor),
              )
            : localFilePath == null
                ? Center(
                    child: Text(
                      "Failed to load PDF.",
                      style: TextStyle(color: textColor, fontSize: 16),
                    ),
                  )
                : Container(
                    color: pdfViewColor,
                    child: PDFView(
                      filePath: localFilePath,
                      enableSwipe: true,
                      swipeHorizontal: true,
                      autoSpacing: false,
                      pageFling: true,
                      onRender: (pages) {
                        print("PDF Rendered with $pages pages.");
                      },
                      onError: (error) {
                        print("Error loading PDF: $error");
                      },
                      onPageError: (page, error) {
                        print("Error on page $page: $error");
                      },
                    ),
                  ),
      ),
    );
  }
}
