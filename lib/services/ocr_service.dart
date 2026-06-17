import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrResult {
  final String title;
  final double amount;
  final String category;
  final bool isIncome;
  final String rawText;

  OcrResult({
    required this.title,
    required this.amount,
    required this.category,
    required this.isIncome,
    required this.rawText,
  });
}

class OcrService {
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Scans the receipt image and returns parsed receipt data.
  Future<OcrResult> scanReceipt(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      final rawText = recognizedText.text;
      final parsed = _parseReceiptText(rawText);

      return OcrResult(
        title: parsed['title'] ?? '',
        amount: parsed['amount'] ?? 0.0,
        category: parsed['category'] ?? '🍔 Makanan',
        isIncome: parsed['isIncome'] ?? false,
        rawText: rawText,
      );
    } catch (e) {
      return OcrResult(
        title: '',
        amount: 0.0,
        category: '🍔 Makanan',
        isIncome: false,
        rawText: 'Error: $e',
      );
    }
  }

  /// Closes the TextRecognizer and releases resources.
  void dispose() {
    _textRecognizer.close();
  }

  /// Parses receipt text to extract Store Name, Total Amount, and Category.
  Map<String, dynamic> _parseReceiptText(String text) {
    final lines = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    
    if (lines.isEmpty) {
      return {
        'title': '',
        'amount': 0.0,
        'category': '🍔 Makanan',
        'isIncome': false,
      };
    }

    // 1. Identify Store/Title
    String title = '';
    final unwantedPatterns = [
      RegExp(r'\d{2}[:.-]\d{2}'), // Time or date parts (e.g. 12:30 or 15-06)
      RegExp(r'telp|phone|hubungi|jl\.|jalan|no\.|NPWP|nama|kasir|cashier|transaksi|struk|nota', caseSensitive: false),
      RegExp(r'^\d+$'), // Purely numbers
      RegExp(r'^[=\-+*._#@()]+$'), // Divider/special lines
    ];

    for (int i = 0; i < lines.length && i < 6; i++) {
      final line = lines[i];
      bool isUnwanted = false;
      for (final pattern in unwantedPatterns) {
        if (pattern.hasMatch(line)) {
          isUnwanted = true;
          break;
        }
      }
      if (!isUnwanted && line.length > 2) {
        title = line;
        break;
      }
    }

    if (title.isEmpty) {
      title = 'Struk Belanja';
    }

    // Clean title: remove trailing punctuation or symbols
    title = title.replaceAll(RegExp(r'[^\w\s\-]'), '').trim();
    // Capitalize first letter of each word to make it look nice
    if (title.isNotEmpty) {
      title = title.split(' ').map((word) {
        if (word.isEmpty) return '';
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      }).join(' ');
    }

    // 2. Identify Total Amount
    double amount = 0.0;
    final totalKeywords = [
      'total', 'grand total', 'jumlah', 'bayar', 'netto', 'net', 'subtotal', 'tunai', 'cash', 'debit', 'tagihan', 'pembayaran', 'due'
    ];

    // Regex for matching prices. E.g. Rp 185.000, 185.000, 150000, 12,500.00
    final amountRegex = RegExp(
      r'(?:rp\.?\s*)?(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{2})?|\d{3,10})',
      caseSensitive: false,
    );

    bool foundTotalAmount = false;
    for (final line in lines) {
      final lowerLine = line.toLowerCase();
      bool containsTotalKeyword = false;
      for (final keyword in totalKeywords) {
        if (lowerLine.contains(keyword)) {
          containsTotalKeyword = true;
          break;
        }
      }

      if (containsTotalKeyword) {
        final matches = amountRegex.allMatches(line);
        if (matches.isNotEmpty) {
          final lastMatch = matches.last.group(1);
          if (lastMatch != null) {
            final parsed = _parseCleanDouble(lastMatch);
            // In receipts, the total is usually larger than individual item prices (subtotals might be smaller than total, which is fine)
            if (parsed > amount) {
              amount = parsed;
              foundTotalAmount = true;
            }
          }
        }
      }
    }

    // Fallback: If no keyword match was found, search all numbers in the text and get the maximum
    if (!foundTotalAmount || amount == 0.0) {
      double maxAmount = 0.0;
      for (final line in lines) {
        // Exclude lines with date/time patterns to avoid parsing year 2026 or time 18:30 as amounts
        if (line.contains(':') || line.contains('/') || line.contains('-')) {
          if (RegExp(r'\d{2}/\d{2}/\d{4}|\d{4}-\d{2}-\d{2}|\d{2}:\d{2}').hasMatch(line)) {
            continue;
          }
        }

        final matches = amountRegex.allMatches(line);
        for (final match in matches) {
          final val = match.group(1);
          if (val != null) {
            final parsed = _parseCleanDouble(val);
            // Limit values to typical receipt bounds (between 100 and 100,000,000)
            if (parsed >= 100 && parsed < 100000000) {
              // Exclude change/kembalian lines to avoid grabbing change as total amount
              if (line.toLowerCase().contains('kembali') || line.toLowerCase().contains('change')) {
                continue;
              }
              if (parsed > maxAmount) {
                maxAmount = parsed;
              }
            }
          }
        }
      }
      amount = maxAmount;
    }

    // 3. Category Detection
    String category = '🍔 Makanan'; // Default fallback
    final textLower = text.toLowerCase();

    final categoryKeywords = {
      '🍔 Makanan': ['makan', 'bakso', 'kopi', 'cafe', 'restoran', 'food', 'drink', 'nasi', 'burger', 'mie', 'kfc', 'mcd', 'warung', 'soto', 'sate', 'beverage', 'coffee', 'tea', 'bakery', 'roti', 'kue', 'martabak', 'dapur', 'resto'],
      '🚗 Transportasi': ['grab', 'gojek', 'taxi', 'taksi', 'bensin', 'pertamina', 'spbu', 'toll', 'tol', 'tiket', 'kai', 'kereta', 'penerbangan', 'flight', 'airline', 'ojek', 'mrt', 'lrt', 'bus', 'transjakarta', 'shell'],
      '🛒 Belanja': ['superindo', 'indomaret', 'alfamart', 'belanja', 'mart', 'mall', 'shopee', 'tokopedia', 'carefour', 'hypermart', 'lotte', 'giant', 'watsons', 'guardian', 'minimarket', 'supermarket', 'plaza', 'baju', 'pakaian', 'sepatu', 'fashion', 'transmart'],
      '🧾 Tagihan': ['listrik', 'pdam', 'internet', 'wifi', 'bpjs', 'asuransi', 'telepon', 'pulsa', 'quota', 'paket data', 'telkom', 'pln', 'indihome', 'firstmedia', 'billing', 'tagihan', 'iuran'],
      '🎬 Hiburan': ['bioskop', 'cinema', 'xxi', 'cgv', 'game', 'steam', 'netflix', 'spotify', 'karaoke', 'tiket konser', 'konser', 'playstation', 'timezone', 'dufan', 'taman', 'rekreasi'],
      '💊 Kesehatan': ['apotek', 'dokter', 'klinik', 'obat', 'kesehatan', 'panadol', 'paracetamol', 'sakit', 'kimia farma', 'k24', 'puskesmas', 'siloam', 'rs', 'rumah sakit', 'vitamin', 'suplemen', 'farmasi'],
    };

    int bestScore = 0;
    for (final entry in categoryKeywords.entries) {
      int score = 0;
      for (final keyword in entry.value) {
        if (title.toLowerCase().contains(keyword)) {
          score += 5; // Higher weight for title match
        }
        if (textLower.contains(keyword)) {
          score += 1;
        }
      }
      if (score > bestScore) {
        bestScore = score;
        category = entry.key;
      }
    }

    return {
      'title': title,
      'amount': amount,
      'category': category,
      'isIncome': false, // Receipts are expenses
    };
  }

  double _parseCleanDouble(String val) {
    String cleaned = val.replaceAll(RegExp(r'\s+'), '').replaceAll(RegExp(r'rp', caseSensitive: false), '');
    
    if (cleaned.contains('.') && cleaned.contains(',')) {
      final lastDot = cleaned.lastIndexOf('.');
      final lastComma = cleaned.lastIndexOf(',');
      if (lastDot > lastComma) {
        cleaned = cleaned.replaceAll(',', ''); 
      } else {
        cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
      }
    } else if (cleaned.contains('.')) {
      final lastDotIndex = cleaned.lastIndexOf('.');
      final afterDotLength = cleaned.length - lastDotIndex - 1;
      if (afterDotLength == 3) {
        cleaned = cleaned.replaceAll('.', '');
      } else if (afterDotLength == 2) {
        // Keep dot as decimal separator
      } else {
        cleaned = cleaned.replaceAll('.', '');
      }
    } else if (cleaned.contains(',')) {
      final lastCommaIndex = cleaned.lastIndexOf(',');
      final afterCommaLength = cleaned.length - lastCommaIndex - 1;
      if (afterCommaLength == 3) {
        cleaned = cleaned.replaceAll(',', '');
      } else if (afterCommaLength == 2) {
        cleaned = cleaned.replaceAll(',', '.');
      } else {
        cleaned = cleaned.replaceAll(',', '');
      }
    }

    return double.tryParse(cleaned) ?? 0.0;
  }
}
