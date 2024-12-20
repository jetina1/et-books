import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart'; // For portrait mode lock

class PdfScreen extends StatefulWidget {
  final String pdfUrl;

  const PdfScreen({super.key, required this.pdfUrl});

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
      final filePath = '${dir.path}/temp.pdf';
      print(
          'pdffffffffffffffffffffffff pathhhhhhhhhhhhhhhhhhh********************');
      print(widget.pdfUrl);
      // Download the PDF
      await dio.download(widget.pdfUrl, filePath);

      // Update state to show the PDF
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
        backgroundColor = Colors.white; // Light background for reading
        textColor = Colors.black; // Dark text for readability
        pdfViewColor = Colors.white; // Light PDF background
      } else if (mode == 'Night Light') {
        backgroundColor = Colors.black; // Dark background
        textColor = Colors.yellow; // Yellow text to reduce eye strain
        pdfViewColor = Colors.black; // Dark PDF background
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Book PDF',
          style: TextStyle(
            color: textColor, // Dynamic text color
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: backgroundColor, // Dynamic background color
        iconTheme: IconThemeData(color: textColor), // Dynamic icon color
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
        color: backgroundColor, // Dynamic body background
        child: isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: textColor, // Dynamic loading indicator color
                ),
              )
            : localFilePath == null
                ? Center(
                    child: Text(
                      "Failed to load PDF.",
                      style: TextStyle(
                        color: textColor, // Dynamic text color
                        fontSize: 16,
                      ),
                    ),
                  )
                : Container(
                    color: pdfViewColor, // Dynamic PDFView background
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
