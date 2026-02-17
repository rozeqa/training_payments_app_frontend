import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class HoursRegisterPdf {
  static Future<void> generateAndShare({
    required int year,
    required int month, // 1-12
    Map<int, num> hoursByDay = const {},
  }) async {
    final doc = pw.Document();

    final fontRegular = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();

    final monthName = DateFormat.MMMM('pl').format(DateTime(year, month, 1));
    final monthYearText = '$monthName $year';

    const String contractNumber = '02-06-2020';
    const String contractorName = 'Magdalena Domańska';

    num total = 0;
    for (int day = 1; day <= 31; day++) {
      total += (hoursByDay[day] ?? 0);
    }

    pw.Widget cell(
      String text, {
      pw.TextAlign align = pw.TextAlign.left,
      bool bold = false,
    }) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        child: pw.Text(
          text,
          textAlign: align,
          style: pw.TextStyle(
            font: bold ? fontBold : fontRegular,
            fontSize: 8.5,
          ),
        ),
      );
    }

    // “Wykropkowana” linia do podpisu (stabilna na każdej platformie)
    pw.Widget dottedLine() {
      return pw.Container(
        height: 14,
        alignment: pw.Alignment.center,
        child: pw.Text(
          // dużo kropek, żeby wypełnić szerokość
          '................................................................................',
          maxLines: 1,
          overflow: pw.TextOverflow.clip,
          style: pw.TextStyle(
            font: fontRegular,
            fontSize: 10,
            color: PdfColors.grey700,
          ),
        ),
      );
    }

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(24, 18, 24, 18),
        build: (context) {
          return pw.DefaultTextStyle(
            style: pw.TextStyle(font: fontRegular, fontSize: 10),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Center(
                  child: pw.Text(
                    'Rejestr godzin realizacji zlecenia',
                    style: pw.TextStyle(font: fontBold, fontSize: 15),
                  ),
                ),
                pw.SizedBox(height: 8),

                pw.Text(
                  'Rozliczenie liczby godzin wykonywania usług do umowy zlecenia z dnia $contractNumber',
                ),
                pw.SizedBox(height: 4),

                pw.Text(
                  'w $monthYearText',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
                ),
                pw.SizedBox(height: 6),

                pw.Row(
                  children: [
                    pw.Text('Zleceniobiorca: '),
                    pw.Expanded(child: pw.Text(contractorName)),
                  ],
                ),
                pw.SizedBox(height: 8),

                // TABELA
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.7),
                  columnWidths: {
                    0: const pw.FixedColumnWidth(90),
                    1: const pw.FlexColumnWidth(),
                  },
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                      children: [
                        cell('Dzień miesiąca', bold: true, align: pw.TextAlign.center),
                        cell('Liczba godzin realizacji zlecenia',
                            bold: true, align: pw.TextAlign.center),
                      ],
                    ),
                    for (int day = 1; day <= 31; day++)
                      pw.TableRow(
                        children: [
                          cell('$day', align: pw.TextAlign.center),
                          cell(
                            ((hoursByDay[day] ?? 0) == 0)
                                ? ''
                                : _fmtHours(hoursByDay[day]!),
                            align: pw.TextAlign.center,
                          ),
                        ],
                      ),
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        cell('Łącznie', bold: true, align: pw.TextAlign.center),
                        cell(_fmtHours(total), bold: true, align: pw.TextAlign.center),
                      ],
                    ),
                  ],
                ),

                // PODPISY POD TABELĄ – lewy i prawy
                pw.SizedBox(height: 40),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        children: [
                          dottedLine(),
                          pw.SizedBox(height: 3),
                          pw.Text(
                            'Podpis zleceniobiorcy',
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                              fontSize: 9,
                              color: PdfColors.grey700,
                              font: fontRegular,
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 24),
                    pw.Expanded(
                      child: pw.Column(
                        children: [
                          dottedLine(),
                          pw.SizedBox(height: 3),
                          pw.Text(
                            'Podpis zleceniodawcy',
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                              fontSize: 9,
                              color: PdfColors.grey700,
                              font: fontRegular,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'rejestr_godzin_${year}_${month.toString().padLeft(2, '0')}.pdf',
    );
  }

  static String _fmtHours(num h) {
    final d = h.toDouble();
    if (d == d.roundToDouble()) return d.toInt().toString();
    return d.toString();
  }
}
