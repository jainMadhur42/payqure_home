// ignore_for_file: unused_element

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/assets/app_assets.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/advance_payment.dart';
import '../../domain/entities/monthly_bill.dart';
import '../../domain/entities/monthly_settlement.dart';
import '../../domain/entities/payment_transaction.dart';
import '../../domain/entities/service_entry.dart';
import '../../domain/entities/service_template.dart';

class PdfStatementService {
  const PdfStatementService();

  static Future<pw.MemoryImage>? _appIconFuture;
  static const _primary = PdfColor.fromInt(0xFF4325DB);
  static const _primaryDark = PdfColor.fromInt(0xFF24109B);
  static const _ink = PdfColor.fromInt(0xFF111327);
  static const _muted = PdfColor.fromInt(0xFF6F7488);
  static const _line = PdfColor.fromInt(0xFFE4E7F0);
  static const _background = PdfColor.fromInt(0xFFF6F7FB);
  static const _surfaceTint = PdfColor.fromInt(0xFFFAFAFD);
  static const _success = PdfColor.fromInt(0xFF0E9F52);
  static const _successSoft = PdfColor.fromInt(0xFFE5F7EC);
  static const _danger = PdfColor.fromInt(0xFFE72646);
  static const _dangerSoft = PdfColor.fromInt(0xFFFFE8EC);
  static const _warning = PdfColor.fromInt(0xFFFF6B1A);
  static const _warningSoft = PdfColor.fromInt(0xFFFFF0E8);
  static const _info = PdfColor.fromInt(0xFF1668E8);
  static const _infoSoft = PdfColor.fromInt(0xFFE8F0FF);

  Future<Uint8List> buildStatement(MonthlyBill bill) async {
    final fonts = await _StatementFonts.load();
    final appIcon = await _loadAppIcon();
    final doc = pw.Document(
      theme: pw.ThemeData.withFont(
        base: fonts.regular,
        bold: fonts.bold,
        fontFallback: [fonts.regular],
      ),
    );

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(22),
        build: (_) => _singlePageStatement(bill, appIcon),
      ),
    );
    return doc.save();
  }

  pw.Widget _singlePageStatement(MonthlyBill bill, pw.ImageProvider appIcon) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _compactBrandHeader(appIcon),
        pw.SizedBox(height: 8),
        pw.Divider(height: 1, color: _line),
        pw.SizedBox(height: 10),
        _statementHeadingAndSummary(bill),
        pw.SizedBox(height: 10),
        _compactServiceInfo(bill),
        pw.SizedBox(height: 10),
        pw.Expanded(
          flex: 52,
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Expanded(flex: 56, child: _calendarPanel(bill)),
              pw.SizedBox(width: 8),
              pw.Expanded(flex: 44, child: _statisticsPanel(bill)),
            ],
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Expanded(
          flex: 38,
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Expanded(child: _calculationPanel(bill)),
              pw.SizedBox(width: 8),
              pw.Expanded(child: _paymentPanel(bill)),
            ],
          ),
        ),
        pw.SizedBox(height: 10),
        _compactNote(bill),
      ],
    );
  }

  pw.Widget _compactBrandHeader(pw.ImageProvider appIcon) {
    return pw.Row(
      children: [
        pw.ClipRRect(
          horizontalRadius: 8,
          verticalRadius: 8,
          child: pw.SizedBox(
            width: 38,
            height: 38,
            child: pw.Image(appIcon, fit: pw.BoxFit.cover),
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Payqure Home',
                style: pw.TextStyle(
                  color: _primaryDark,
                  fontSize: 19,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Track household services and monthly settlements',
                style: const pw.TextStyle(color: _muted, fontSize: 7.5),
              ),
            ],
          ),
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'Generated on',
              style: const pw.TextStyle(color: _muted, fontSize: 7),
            ),
            pw.Text(
              _dateLabel(DateTime.now()),
              style: pw.TextStyle(
                color: _ink,
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _statementHeadingAndSummary(MonthlyBill bill) {
    final settlement = bill.settlement;
    final previousDue = settlement?.previousCarryForwardCents ?? 0;
    final advance = settlement?.advanceUsedCents ?? bill.advanceAmountCents;
    final payable = settlement?.remainingAmountCents ?? bill.payableAmountCents;
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.SizedBox(
          width: 188,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '${bill.service.name.toUpperCase()} STATEMENT',
                maxLines: 2,
                style: pw.TextStyle(
                  color: _ink,
                  fontSize: 15,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                _monthLabel(bill.monthKey),
                style: pw.TextStyle(
                  color: _primary,
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(width: 12),
        pw.Expanded(
          child: pw.Container(
            height: 74,
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: _line),
            ),
            child: pw.Row(
              children: [
                _topMetric('Gross Amount', bill.grossAmountCents, _primary),
                _verticalDivider(),
                _topMetric('Previous Due', previousDue, _primary),
                _verticalDivider(),
                _topMetric('Advance Paid', advance, _primary),
                _topMetric(
                  'Payable Amount',
                  payable,
                  _primaryDark,
                  highlighted: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _topMetric(
    String label,
    int amount,
    PdfColor color, {
    bool highlighted = false,
  }) {
    return pw.Expanded(
      child: pw.Container(
        height: double.infinity,
        padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 8),
        decoration: highlighted
            ? pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFFF0ECFF),
                borderRadius: pw.BorderRadius.circular(8),
              )
            : null,
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              maxLines: 2,
              style: pw.TextStyle(
                color: _ink,
                fontSize: 6.8,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Container(
              width: 24,
              height: 24,
              alignment: pw.Alignment.center,
              decoration: pw.BoxDecoration(
                color: color,
                shape: pw.BoxShape.circle,
              ),
              child: pw.Text(
                CurrencyFormatter.symbol,
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Text(
              _money(amount),
              maxLines: 1,
              style: pw.TextStyle(
                color: highlighted ? _primaryDark : _ink,
                fontSize: highlighted ? 11 : 9,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _verticalDivider() {
    return pw.Container(
      width: 1,
      margin: const pw.EdgeInsets.all(8),
      color: _line,
    );
  }

  pw.Widget _compactServiceInfo(MonthlyBill bill) {
    return pw.Container(
      height: 54,
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _line),
      ),
      child: pw.Row(
        children: [
          _compactInfo('Service', bill.service.name, _info),
          _compactInfo('Provider', _providerName(bill), _success),
          _compactInfo('Type', bill.service.templateType.label, _warning),
          _compactInfo('Month', _monthLabel(bill.monthKey), _primary),
          _compactInfo(
            'Status',
            bill.settlement?.status.label ?? _paymentStatus(bill),
            _danger,
            valueColor: _danger,
          ),
        ],
      ),
    );
  }

  pw.Widget _compactInfo(
    String label,
    String value,
    PdfColor accent, {
    PdfColor? valueColor,
  }) {
    return pw.Expanded(
      child: pw.Row(
        children: [
          pw.Container(
            width: 25,
            height: 25,
            alignment: pw.Alignment.center,
            decoration: pw.BoxDecoration(
              color: PdfColor(accent.red, accent.green, accent.blue, 0.12),
              shape: pw.BoxShape.circle,
            ),
            child: pw.Container(
              width: 8,
              height: 8,
              decoration: pw.BoxDecoration(
                color: accent,
                shape: pw.BoxShape.circle,
              ),
            ),
          ),
          pw.SizedBox(width: 6),
          pw.Expanded(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  label,
                  style: const pw.TextStyle(color: _muted, fontSize: 6.5),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  value,
                  maxLines: 2,
                  style: pw.TextStyle(
                    color: valueColor ?? _ink,
                    fontSize: 7.5,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _panel(String title, pw.Widget child) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _line),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              color: _primaryDark,
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 7),
          pw.Expanded(child: child),
        ],
      ),
    );
  }

  pw.Widget _calendarPanel(MonthlyBill bill) {
    return _panel(
      'CALENDAR',
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Color indicates delivery status. Date cells show only day numbers.',
            style: const pw.TextStyle(color: _muted, fontSize: 6.5),
          ),
          pw.SizedBox(height: 6),
          pw.Expanded(child: _compactCalendar(bill)),
          pw.SizedBox(height: 5),
          pw.FittedBox(child: _legend()),
        ],
      ),
    );
  }

  pw.Widget _compactCalendar(MonthlyBill bill) {
    final monthDate = _monthDate(bill.monthKey);
    final daysInMonth = DateTime(monthDate.year, monthDate.month + 1, 0).day;
    final leadingBlanks = monthDate.weekday % 7;
    final entriesByDay = {
      for (final entry in bill.service.entries) entry.day: entry,
    };
    final cells = <pw.Widget>[];
    for (var index = 0; index < 42; index++) {
      final day = index - leadingBlanks + 1;
      cells.add(
        day < 1 || day > daysInMonth
            ? pw.Container()
            : _compactCalendarCell(day, entriesByDay[day]),
      );
    }
    return pw.Column(
      children: [
        pw.Container(
          height: 20,
          color: _primaryDark,
          child: pw.Row(
            children: const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                .map(
                  (label) => pw.Expanded(
                    child: pw.Center(
                      child: pw.Text(
                        label,
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 6.5,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        pw.Expanded(
          child: pw.GridView(
            crossAxisCount: 7,
            childAspectRatio: 1.32,
            children: cells,
          ),
        ),
      ],
    );
  }

  pw.Widget _compactCalendarCell(int day, ServiceEntry? entry) {
    final status = entry?.status ?? ServiceEntryStatus.noEntry;
    final hasStatus = entry != null && status != ServiceEntryStatus.noEntry;
    final color = switch (status) {
      ServiceEntryStatus.delivered => _success,
      ServiceEntryStatus.notDelivered => _danger,
      ServiceEntryStatus.halfDay => _warning,
      ServiceEntryStatus.rateChanged => _info,
      ServiceEntryStatus.noEntry => PdfColors.white,
    };
    return pw.Container(
      alignment: pw.Alignment.center,
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: _line, width: 0.5),
      ),
      child: pw.Container(
        width: 18,
        height: 18,
        alignment: pw.Alignment.center,
        decoration: pw.BoxDecoration(
          color: color,
          shape: hasStatus ? pw.BoxShape.circle : pw.BoxShape.rectangle,
        ),
        child: pw.Text(
          '$day',
          style: pw.TextStyle(
            color: hasStatus ? PdfColors.white : _ink,
            fontSize: 7,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ),
    );
  }

  pw.Widget _statisticsPanel(MonthlyBill bill) {
    final stats = _StatementStats.from(bill);
    final isAttendance =
        bill.service.templateType == ServiceTemplateType.attendance;
    final rows = isAttendance
        ? [
            ('Present Days', '${stats.deliveredDays}', _success),
            ('Absent Days', '${stats.missedDays}', _danger),
            ('Half Days', '${stats.halfDays}', _warning),
            (
              'Tracked Days',
              '${stats.deliveredDays + stats.missedDays}',
              _info,
            ),
          ]
        : [
            ('Delivered Days', '${stats.deliveredDays}', _success),
            ('Missed Days', '${stats.missedDays}', _danger),
            (
              'Total Quantity',
              '${_decimal(stats.totalQuantity)} ${bill.service.unit}'.trim(),
              _info,
            ),
            (
              'Average Quantity',
              '${_decimal(stats.averageQuantity)} ${bill.service.unit}/day'
                  .trim(),
              _primary,
            ),
          ];
    return _panel(
      'MONTHLY STATISTICS',
      pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.start,
        children: rows
            .map(
              (row) => pw.Container(
                height: 38,
                padding: const pw.EdgeInsets.symmetric(vertical: 6),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(color: _line)),
                ),
                child: pw.Row(
                  children: [
                    pw.Container(
                      width: 24,
                      height: 24,
                      alignment: pw.Alignment.center,
                      decoration: pw.BoxDecoration(
                        color: PdfColor(
                          row.$3.red,
                          row.$3.green,
                          row.$3.blue,
                          0.12,
                        ),
                        shape: pw.BoxShape.circle,
                      ),
                      child: pw.Container(
                        width: 7,
                        height: 7,
                        decoration: pw.BoxDecoration(
                          color: row.$3,
                          shape: pw.BoxShape.circle,
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Expanded(
                      child: pw.Text(
                        row.$1,
                        style: const pw.TextStyle(color: _ink, fontSize: 8),
                      ),
                    ),
                    pw.Text(
                      row.$2,
                      maxLines: 1,
                      style: pw.TextStyle(
                        color: _ink,
                        fontSize: 8.5,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  pw.Widget _calculationPanel(MonthlyBill bill) {
    final lines = _calculationLines(bill);
    final visibleLines = lines.take(4).toList();
    return _panel(
      'CALCULATION BREAKDOWN',
      pw.Column(
        children: [
          ...visibleLines.map(
            (line) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 5),
              child: _compactAmountRow(line.label, line.amountCents),
            ),
          ),
          if (lines.length > visibleLines.length)
            pw.Text(
              '+ ${lines.length - visibleLines.length} additional calculation group(s)',
              style: const pw.TextStyle(color: _muted, fontSize: 6.5),
            ),
          pw.Spacer(),
          pw.Divider(height: 1, color: _line),
          pw.SizedBox(height: 5),
          _compactAmountRow('Gross Amount', bill.grossAmountCents, bold: true),
          _compactAmountRow(
            'Advance Paid',
            bill.advanceAmountCents,
            bold: true,
          ),
          pw.SizedBox(height: 5),
          _highlightAmountRow('Final Payable', _statementRemaining(bill)),
        ],
      ),
    );
  }

  pw.Widget _paymentPanel(MonthlyBill bill) {
    final settlement = bill.settlement;
    return _panel(
      'PAYMENT SUMMARY',
      pw.Column(
        children: [
          _compactAmountRow(
            'Gross Amount',
            settlement?.grossAmountCents ?? bill.grossAmountCents,
          ),
          _compactAmountRow(
            'Previous Due',
            settlement?.previousCarryForwardCents ?? 0,
          ),
          _compactAmountRow(
            'Advance Used',
            settlement?.advanceUsedCents ?? bill.advanceAmountCents,
          ),
          pw.Divider(height: 10, color: _line),
          _compactAmountRow(
            'Payable',
            settlement?.payableAmountCents ?? bill.payableAmountCents,
            bold: true,
          ),
          _compactAmountRow(
            'Paid',
            settlement?.paidAmountCents ?? 0,
            bold: true,
          ),
          pw.Spacer(),
          _highlightAmountRow('Remaining', _statementRemaining(bill)),
          pw.SizedBox(height: 5),
          _highlightAmountRow(
            settlement != null && settlement.advanceToNextMonthCents > 0
                ? 'Advance to Next Month'
                : 'Carry Forward to Next Month',
            settlement?.advanceToNextMonthCents ??
                settlement?.carryForwardToNextMonthCents ??
                _statementRemaining(bill),
          ),
        ],
      ),
    );
  }

  pw.Widget _compactAmountRow(String label, int cents, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              label,
              maxLines: 1,
              style: pw.TextStyle(
                color: _ink,
                fontSize: 7.5,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ),
          pw.Text(
            _money(cents),
            style: pw.TextStyle(
              color: _ink,
              fontSize: 7.5,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _highlightAmountRow(String label, int cents) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 6),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFF3F0FF),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              label,
              maxLines: 1,
              style: pw.TextStyle(
                color: _primaryDark,
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Text(
            _money(cents),
            style: pw.TextStyle(
              color: _primaryDark,
              fontSize: 8.5,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _compactNote(MonthlyBill bill) {
    final notes = _notes(bill);
    final message = notes.isEmpty
        ? 'Thank you for using Payqure Home. Keep your household services and payments organized.'
        : notes.take(2).join('  •  ');
    return pw.Container(
      height: 42,
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _line),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: 26,
            height: 26,
            alignment: pw.Alignment.center,
            decoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF0ECFF),
              shape: pw.BoxShape.circle,
            ),
            child: pw.Text(
              'N',
              style: pw.TextStyle(
                color: _primary,
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Note',
                  style: pw.TextStyle(
                    color: _primaryDark,
                    fontSize: 7.5,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  message,
                  maxLines: 2,
                  style: const pw.TextStyle(color: _muted, fontSize: 6.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _statementRemaining(MonthlyBill bill) {
    return bill.settlement?.remainingAmountCents ?? bill.payableAmountCents;
  }

  Future<pw.MemoryImage> _loadAppIcon() async {
    return _appIconFuture ??= rootBundle
        .load(AppAssets.appIcon)
        .then((bytes) => pw.MemoryImage(bytes.buffer.asUint8List()));
  }

  pw.Widget _header(MonthlyBill bill, pw.ImageProvider appIcon) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(18),
      decoration: pw.BoxDecoration(
        gradient: const pw.LinearGradient(
          colors: [_primary, _primaryDark],
          begin: pw.Alignment.topLeft,
          end: pw.Alignment.bottomRight,
        ),
        borderRadius: pw.BorderRadius.circular(18),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _logoMark(appIcon),
          pw.SizedBox(width: 14),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Payqure Home',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  'Household Service Statement',
                  style: pw.TextStyle(
                    color: PdfColors.white.shade(0.82),
                    fontSize: 10,
                  ),
                ),
                pw.SizedBox(height: 14),
                pw.Text(
                  '${bill.service.name} Statement',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  _monthLabel(bill.monthKey),
                  style: pw.TextStyle(
                    color: PdfColors.white.shade(0.86),
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Generated on',
                style: pw.TextStyle(
                  color: PdfColors.white.shade(0.68),
                  fontSize: 9,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                _dateLabel(DateTime.now()),
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _logoMark(pw.ImageProvider appIcon) {
    return pw.ClipRRect(
      horizontalRadius: 10,
      verticalRadius: 10,
      child: pw.SizedBox(
        width: 44,
        height: 44,
        child: pw.Image(appIcon, fit: pw.BoxFit.cover),
      ),
    );
  }

  pw.Widget _serviceInfoCard(MonthlyBill bill) {
    return _card(
      pw.Column(
        children: [
          pw.Row(
            children: [
              _infoBlock('Service', bill.service.name),
              pw.SizedBox(width: 10),
              _infoBlock('Provider', _providerName(bill)),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              _infoBlock('Type', bill.service.templateType.label),
              pw.SizedBox(width: 10),
              _infoBlock('Month', _monthLabel(bill.monthKey)),
              pw.SizedBox(width: 10),
              _infoBlock('Status', _paymentStatus(bill), accent: _primary),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _financialSummary(MonthlyBill bill) {
    return pw.Row(
      children: [
        _amountCard('Gross Amount', bill.grossAmountCents, _info),
        pw.SizedBox(width: 8),
        _amountCard('Advance Paid', bill.advanceAmountCents, _warning),
        pw.SizedBox(width: 8),
        _amountCard('Payable Amount', bill.payableAmountCents, _primary),
      ],
    );
  }

  pw.Widget _amountCard(String label, int cents, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: color == _primary ? _primary : PdfColors.white,
          borderRadius: pw.BorderRadius.circular(14),
          border: pw.Border.all(color: color == _primary ? _primary : _line),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                color: color == _primary ? PdfColors.white.shade(0.78) : _muted,
                fontSize: 9,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              _money(cents),
              style: pw.TextStyle(
                color: color == _primary ? PdfColors.white : color,
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _calendar(MonthlyBill bill) {
    final monthDate = _monthDate(bill.monthKey);
    final daysInMonth = DateTime(monthDate.year, monthDate.month + 1, 0).day;
    final leadingBlanks = monthDate.weekday % 7;
    final entriesByDay = {
      for (final entry in bill.service.entries) entry.day: entry,
    };
    final rows = <List<pw.Widget>>[];
    var day = 1;
    for (var week = 0; week < 6; week++) {
      final row = <pw.Widget>[];
      for (var weekday = 0; weekday < 7; weekday++) {
        final cellIndex = week * 7 + weekday;
        if (cellIndex < leadingBlanks || day > daysInMonth) {
          row.add(pw.SizedBox(height: 24));
        } else {
          row.add(_calendarCell(day, entriesByDay[day]));
          day++;
        }
      }
      rows.add(row);
      if (day > daysInMonth) {
        break;
      }
    }

    return _card(
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Color indicates delivery status. Date cells intentionally show only day numbers.',
            style: const pw.TextStyle(color: _muted, fontSize: 8),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                .map(
                  (day) => pw.Expanded(
                    child: pw.Text(
                      day,
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        color: _muted,
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          pw.SizedBox(height: 6),
          pw.Table(
            defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
            children: rows
                .map(
                  (row) => pw.TableRow(
                    children: row
                        .map(
                          (cell) => pw.Padding(
                            padding: const pw.EdgeInsets.all(2),
                            child: cell,
                          ),
                        )
                        .toList(),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  pw.Widget _calendarCell(int day, ServiceEntry? entry) {
    final color = _entryBackground(entry?.status ?? ServiceEntryStatus.noEntry);
    final border = _entryBorder(entry?.status ?? ServiceEntryStatus.noEntry);
    final textColor =
        entry == null || entry.status == ServiceEntryStatus.noEntry
        ? _muted
        : _ink;
    return pw.Container(
      height: 24,
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: border),
      ),
      child: pw.Center(
        child: pw.Text(
          '$day',
          style: pw.TextStyle(
            color: textColor,
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ),
    );
  }

  pw.Widget _legend() {
    return pw.Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        _legendDot('Delivered', _success),
        _legendDot('Not Delivered', _danger),
        _legendDot('Quantity / Half Day', _warning),
        _legendDot('Rate Changed', _info),
        _legendDot('No Entry', _muted),
      ],
    );
  }

  pw.Widget _statistics(MonthlyBill bill) {
    final stats = _StatementStats.from(bill);
    final isAttendance =
        bill.service.templateType == ServiceTemplateType.attendance;
    final items = isAttendance
        ? [
            ('Present Days', '${stats.deliveredDays}'),
            ('Absent Days', '${stats.missedDays}'),
            ('Half Days', '${stats.halfDays}'),
          ]
        : [
            ('Delivered Days', '${stats.deliveredDays}'),
            ('Missed Days', '${stats.missedDays}'),
            (
              'Total Quantity',
              '${_decimal(stats.totalQuantity)} ${bill.service.unit}'.trim(),
            ),
            (
              'Average Quantity',
              '${_decimal(stats.averageQuantity)} ${bill.service.unit}/day'
                  .trim(),
            ),
          ];

    return _card(
      pw.Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items
            .map(
              (item) => pw.Container(
                width: isAttendance ? 154 : 112,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: _background,
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      item.$1,
                      style: const pw.TextStyle(color: _muted, fontSize: 8),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      item.$2,
                      style: pw.TextStyle(
                        color: _ink,
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  pw.Widget _calculationBreakdown(MonthlyBill bill) {
    final lines = _calculationLines(bill);
    return _card(
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          ...lines.map(
            (line) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      line.label,
                      style: const pw.TextStyle(color: _ink, fontSize: 10),
                    ),
                  ),
                  pw.Text(
                    line.amountCents == 0
                        ? CurrencyFormatter.cents(0)
                        : _money(line.amountCents),
                    style: pw.TextStyle(
                      color: _ink,
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          pw.Divider(color: _line),
          _totalRow('Gross Amount', bill.grossAmountCents),
          _totalRow('Advance Paid', -bill.advanceAmountCents, color: _danger),
          pw.Container(
            margin: const pw.EdgeInsets.only(top: 6),
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: _primary,
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Text(
                    'Final Payable',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Text(
                  _money(bill.payableAmountCents),
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _advancePayments(List<AdvancePayment> advances) {
    final total = advances.fold<int>(
      0,
      (sum, advance) => sum + advance.amountCents,
    );
    return _card(
      pw.Column(
        children: [
          ...advances.map(
            (advance) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(_dateLabel(advance.paidOn), style: _boldText()),
                        if (advance.note.isNotEmpty)
                          pw.Text(
                            _paymentMode(advance.note),
                            style: const pw.TextStyle(
                              color: _muted,
                              fontSize: 9,
                            ),
                          ),
                      ],
                    ),
                  ),
                  pw.Text(
                    _money(advance.amountCents),
                    style: _boldText(color: _warning),
                  ),
                ],
              ),
            ),
          ),
          pw.Divider(color: _line),
          _totalRow('Total Advance', total, color: _warning),
        ],
      ),
    );
  }

  pw.Widget _paymentSummary(MonthlyBill bill) {
    final settlement = bill.settlement!;
    return _card(
      pw.Column(
        children: [
          _totalRow('Gross Amount', settlement.grossAmountCents),
          if (settlement.previousCarryForwardCents > 0)
            _totalRow('Previous Due', settlement.previousCarryForwardCents),
          _totalRow(
            'Advance Used',
            -settlement.advanceUsedCents,
            color: _warning,
          ),
          _totalRow('Payable', settlement.payableAmountCents),
          _totalRow('Paid', -settlement.paidAmountCents, color: _success),
          pw.Divider(color: _line),
          _totalRow(
            'Remaining',
            settlement.remainingAmountCents,
            color: settlement.remainingAmountCents > 0 ? _danger : _success,
          ),
          if (settlement.carryForwardToNextMonthCents > 0)
            _totalRow(
              'Carry Forward to Next Month',
              settlement.carryForwardToNextMonthCents,
              color: _danger,
            ),
          if (settlement.advanceToNextMonthCents > 0)
            _totalRow(
              'Extra Paid Added to Advance',
              settlement.advanceToNextMonthCents,
              color: _success,
            ),
        ],
      ),
    );
  }

  pw.Widget _paymentHistory(List<PaymentTransaction> payments) {
    return _card(
      pw.Column(
        children: payments
            .map(
              (payment) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        '${_dateLabel(payment.paymentDate)} · ${payment.mode.label}',
                        style: _boldText(),
                      ),
                    ),
                    pw.Text(
                      _money(payment.amountCents),
                      style: _boldText(color: _success),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  pw.Widget _notesSection(MonthlyBill bill) {
    return _card(
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: _notes(bill)
            .map(
              (note) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 6),
                child: pw.Text(
                  note,
                  style: const pw.TextStyle(color: _ink, fontSize: 10),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  pw.Widget _footer(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _line)),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              'Generated by Payqure Home · Track household services and monthly settlements',
              style: const pw.TextStyle(color: _muted, fontSize: 8),
            ),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(color: _muted, fontSize: 8),
          ),
        ],
      ),
    );
  }

  pw.Widget _sectionTitle(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        color: _ink,
        fontSize: 14,
        fontWeight: pw.FontWeight.bold,
      ),
    );
  }

  pw.Widget _card(pw.Widget child) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _surfaceTint,
        borderRadius: pw.BorderRadius.circular(14),
        border: pw.Border.all(color: _line),
      ),
      child: child,
    );
  }

  pw.Widget _infoBlock(String label, String value, {PdfColor? accent}) {
    return pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: const pw.TextStyle(color: _muted, fontSize: 8)),
          pw.SizedBox(height: 3),
          pw.Text(
            value,
            maxLines: 2,
            style: pw.TextStyle(
              color: accent ?? _ink,
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _legendDot(String label, PdfColor color) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Container(
          width: 7,
          height: 7,
          decoration: pw.BoxDecoration(color: color, shape: pw.BoxShape.circle),
        ),
        pw.SizedBox(width: 4),
        pw.Text(label, style: const pw.TextStyle(color: _muted, fontSize: 8)),
      ],
    );
  }

  pw.Widget _totalRow(String label, int amountCents, {PdfColor color = _ink}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        children: [
          pw.Expanded(child: pw.Text(label, style: _boldText())),
          pw.Text(_money(amountCents), style: _boldText(color: color)),
        ],
      ),
    );
  }

  pw.TextStyle _boldText({PdfColor color = _ink}) {
    return pw.TextStyle(
      color: color,
      fontSize: 10,
      fontWeight: pw.FontWeight.bold,
    );
  }

  List<_CalculationLine> _calculationLines(MonthlyBill bill) {
    final service = bill.service;
    return switch (service.templateType) {
      ServiceTemplateType.attendance => _attendanceCalculationLines(bill),
      ServiceTemplateType.fixedMonthly => _fixedMonthlyCalculationLines(bill),
      ServiceTemplateType.quantity => _quantityCalculationLines(bill),
    };
  }

  List<_CalculationLine> _quantityCalculationLines(MonthlyBill bill) {
    final service = bill.service;
    final groups = <String, _CalculationGroup>{};
    for (final entry in service.entries) {
      if (entry.status == ServiceEntryStatus.noEntry) {
        continue;
      }
      if (entry.status == ServiceEntryStatus.notDelivered) {
        final key = 'not-delivered';
        groups.putIfAbsent(key, () => _CalculationGroup.notDelivered()).days++;
        continue;
      }
      final key =
          '${entry.quantity}-${entry.unit}-${entry.rateCents}-${entry.status.name}';
      groups
          .putIfAbsent(
            key,
            () => _CalculationGroup(
              quantity: entry.quantity,
              unit: entry.unit,
              rateCents: entry.rateCents,
            ),
          )
          .add(entry.amountCents);
    }

    return groups.values.map((group) {
      if (group.notDelivered) {
        return _CalculationLine(
          '${group.days} Day${group.days == 1 ? '' : 's'} Not Delivered',
          0,
        );
      }
      final unit = group.unit.trim();
      final quantity = unit.isEmpty
          ? _decimal(group.quantity)
          : '${_decimal(group.quantity)} $unit';
      final label =
          '${group.days} Day${group.days == 1 ? '' : 's'} × $quantity × ${_money(group.rateCents)}';
      return _CalculationLine(label, group.amountCents);
    }).toList();
  }

  List<_CalculationLine> _attendanceCalculationLines(MonthlyBill bill) {
    final groups = <String, _CalculationGroup>{};
    var absentDays = 0;
    for (final entry in bill.service.entries) {
      switch (entry.status) {
        case ServiceEntryStatus.noEntry:
          break;
        case ServiceEntryStatus.notDelivered:
          absentDays += 1;
          break;
        case ServiceEntryStatus.halfDay:
          final key = 'half-${entry.rateCents}';
          groups
              .putIfAbsent(
                key,
                () => _CalculationGroup(
                  quantity: 0.5,
                  unit: 'day',
                  rateCents: entry.rateCents,
                )..halfDay = true,
              )
              .add(entry.amountCents);
          break;
        case ServiceEntryStatus.delivered:
        case ServiceEntryStatus.rateChanged:
          final key = 'present-${entry.rateCents}';
          groups
              .putIfAbsent(
                key,
                () => _CalculationGroup(
                  quantity: 1,
                  unit: 'day',
                  rateCents: entry.rateCents,
                ),
              )
              .add(entry.amountCents);
          break;
      }
    }

    final lines = groups.values.map((group) {
      final dayLabel = group.halfDay ? 'Half Day' : 'Present Day';
      final multiplier = group.halfDay ? ' × 0.5' : '';
      return _CalculationLine(
        '${group.days} $dayLabel${group.days == 1 ? '' : 's'} × ${_money(group.rateCents)} / day$multiplier',
        group.amountCents,
      );
    }).toList();
    if (absentDays > 0) {
      lines.add(
        _CalculationLine(
          '$absentDays Absent Day${absentDays == 1 ? '' : 's'}',
          0,
        ),
      );
    }
    return lines;
  }

  List<_CalculationLine> _fixedMonthlyCalculationLines(MonthlyBill bill) {
    final deliveredDays = bill.service.entries
        .where(
          (entry) =>
              entry.status == ServiceEntryStatus.delivered ||
              entry.status == ServiceEntryStatus.rateChanged ||
              entry.status == ServiceEntryStatus.halfDay,
        )
        .length;
    final missedDays = bill.service.entries
        .where((entry) => entry.status == ServiceEntryStatus.notDelivered)
        .length;
    return [
      _CalculationLine(
        '${bill.service.name} monthly fixed charge',
        bill.grossAmountCents,
      ),
      if (deliveredDays > 0)
        _CalculationLine(
          '$deliveredDays Delivered Day${deliveredDays == 1 ? '' : 's'} tracked',
          0,
        ),
      if (missedDays > 0)
        _CalculationLine(
          '$missedDays Missed Day${missedDays == 1 ? '' : 's'} tracked',
          0,
        ),
    ];
  }

  List<String> _notes(MonthlyBill bill) {
    return bill.service.entries
        .where((entry) => entry.note.trim().isNotEmpty)
        .map(
          (entry) =>
              '${_dateLabel(_entryDate(bill.monthKey, entry.day))}: ${entry.note.trim()}',
        )
        .toList();
  }

  PdfColor _entryBackground(ServiceEntryStatus status) {
    return switch (status) {
      ServiceEntryStatus.delivered => _successSoft,
      ServiceEntryStatus.notDelivered => _dangerSoft,
      ServiceEntryStatus.halfDay => _warningSoft,
      ServiceEntryStatus.rateChanged => _infoSoft,
      ServiceEntryStatus.noEntry => _background,
    };
  }

  PdfColor _entryBorder(ServiceEntryStatus status) {
    return switch (status) {
      ServiceEntryStatus.delivered => PdfColor(
        _success.red,
        _success.green,
        _success.blue,
        0.28,
      ),
      ServiceEntryStatus.notDelivered => PdfColor(
        _danger.red,
        _danger.green,
        _danger.blue,
        0.28,
      ),
      ServiceEntryStatus.halfDay => PdfColor(
        _warning.red,
        _warning.green,
        _warning.blue,
        0.28,
      ),
      ServiceEntryStatus.rateChanged => PdfColor(
        _info.red,
        _info.green,
        _info.blue,
        0.28,
      ),
      ServiceEntryStatus.noEntry => _line,
    };
  }

  String _providerName(MonthlyBill bill) {
    for (final item in bill.service.description.split(' • ')) {
      final separator = item.indexOf(':');
      if (separator == -1) {
        continue;
      }
      if (item.substring(0, separator).trim().toLowerCase() == 'provider') {
        final value = item.substring(separator + 1).trim();
        if (value.isNotEmpty) {
          return value;
        }
      }
    }
    return 'Not added';
  }

  String _paymentStatus(MonthlyBill bill) {
    if (bill.payableAmountCents <= 0) {
      return 'Paid';
    }
    if (bill.advanceAmountCents > 0) {
      return 'Partially Paid';
    }
    return 'Pending';
  }

  String _paymentMode(String note) {
    final marker = 'Payment mode:';
    final index = note.indexOf(marker);
    if (index == -1) {
      return note;
    }
    return note.substring(index + marker.length).trim();
  }

  String _money(int cents) => CurrencyFormatter.rupees(cents / 100);

  String _decimal(double value) {
    return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
  }

  DateTime _entryDate(String monthKey, int day) {
    final month = _monthDate(monthKey);
    return DateTime(month.year, month.month, day);
  }

  DateTime _monthDate(String monthKey) {
    final parts = monthKey.split('-');
    final year = int.tryParse(parts.first) ?? DateTime.now().year;
    final month = parts.length > 1
        ? int.tryParse(parts[1]) ?? DateTime.now().month
        : DateTime.now().month;
    return DateTime(year, month);
  }

  String _monthLabel(String monthKey) {
    final date = _monthDate(monthKey);
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _dateLabel(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }
}

class _StatementFonts {
  const _StatementFonts({required this.regular, required this.bold});

  final pw.Font regular;
  final pw.Font bold;
  static Future<_StatementFonts>? _cachedFonts;

  static Future<_StatementFonts> load() {
    return _cachedFonts ??= rootBundle
        .load('assets/fonts/Roboto-Regular.ttf')
        .then((bytes) {
          final font = pw.Font.ttf(bytes);
          return _StatementFonts(regular: font, bold: font);
        });
  }
}

class _StatementStats {
  const _StatementStats({
    required this.deliveredDays,
    required this.missedDays,
    required this.halfDays,
    required this.totalQuantity,
    required this.averageQuantity,
  });

  final int deliveredDays;
  final int missedDays;
  final int halfDays;
  final double totalQuantity;
  final double averageQuantity;

  factory _StatementStats.from(MonthlyBill bill) {
    final delivered = bill.service.entries.where(
      (entry) =>
          entry.status == ServiceEntryStatus.delivered ||
          entry.status == ServiceEntryStatus.rateChanged,
    );
    final halfDays = bill.service.entries.where(
      (entry) => entry.status == ServiceEntryStatus.halfDay,
    );
    final missed = bill.service.entries.where(
      (entry) => entry.status == ServiceEntryStatus.notDelivered,
    );
    final deliveredCount = delivered.length + halfDays.length;
    final quantity = bill.service.entries.fold<double>(
      0,
      (sum, entry) =>
          entry.status == ServiceEntryStatus.notDelivered ||
              entry.status == ServiceEntryStatus.noEntry
          ? sum
          : sum + entry.quantity,
    );
    return _StatementStats(
      deliveredDays: deliveredCount,
      missedDays: missed.length,
      halfDays: halfDays.length,
      totalQuantity: quantity,
      averageQuantity: deliveredCount == 0 ? 0 : quantity / deliveredCount,
    );
  }
}

class _CalculationGroup {
  _CalculationGroup({
    required this.quantity,
    required this.unit,
    required this.rateCents,
  });

  factory _CalculationGroup.notDelivered() {
    return _CalculationGroup(quantity: 0, unit: '', rateCents: 0)
      ..notDelivered = true;
  }

  final double quantity;
  final String unit;
  final int rateCents;
  int days = 0;
  int amountCents = 0;
  bool notDelivered = false;
  bool halfDay = false;

  void add(int amount) {
    days += 1;
    amountCents += amount;
  }
}

class _CalculationLine {
  const _CalculationLine(this.label, this.amountCents);

  final String label;
  final int amountCents;
}
