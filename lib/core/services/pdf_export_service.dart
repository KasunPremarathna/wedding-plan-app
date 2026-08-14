import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../data/models/models.dart';
import '../../presentation/providers/app_providers.dart';

class PdfExportService {
  static pw.PageTheme _buildTheme() {
    return pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      buildBackground: (context) => pw.FullPage(
        ignoreMargins: true,
        child: pw.Center(
          child: pw.Transform.rotate(
            angle: -0.5,
            child: pw.Text(
              'Wedding Planner LK',
              style: pw.TextStyle(
                fontSize: 60,
                color: PdfColors.grey200,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Future<void> exportBudgetToPdf(BudgetState budget, int mealCost, int attendingGuests, int liquorConsumers) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageTheme: _buildTheme(),
        build: (pw.Context context) {
          return [
            pw.Text('Wedding Budget Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.pink700)),
            pw.SizedBox(height: 20),
            pw.Text('Total Budget: LKR ${budget.totalBudget}'),
            pw.Text('Total Spent: LKR ${budget.totalSpent}'),
            pw.Text('Remaining: LKR ${budget.remaining}'),
            pw.SizedBox(height: 10),
            pw.Text('Estimated Meal Cost: LKR ${attendingGuests * mealCost} ($attendingGuests guests)'),
            pw.Text('Estimated Liquor Cost: LKR ${liquorConsumers * 5000} ($liquorConsumers guests)'),
            pw.SizedBox(height: 20),
            pw.Text('Expenses:', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              context: context,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.pink700),
              data: [
                ['Category', 'Note', 'Amount (LKR)', 'Date'],
                ...budget.expenses.map((e) => [e.category, e.note, e.amount.toString(), e.date]),
              ],
            ),
          ];
        },
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'budget_report.pdf');
  }

  static Future<void> exportGuestListToPdf(List<Guest> guests) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageTheme: _buildTheme(),
        build: (pw.Context context) {
          return [
            pw.Text('Guest List Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.pink700)),
            pw.SizedBox(height: 10),
            pw.Text('Total Guests: ${guests.length}'),
            pw.Text('Attending: ${guests.where((g) => g.rsvpStatus == 'Attending').length}'),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              context: context,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.pink700),
              data: [
                ['Name', 'Group', 'RSVP', 'Meal', 'Liquor'],
                ...guests.map((g) => [g.name, g.group, g.rsvpStatus, g.mealPreference, g.consumesLiquor ? 'Yes' : 'No']),
              ],
            ),
          ];
        },
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'guest_list.pdf');
  }
}
