import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flaride_driver/core/theme/app_colors.dart';
import 'package:flaride_driver/core/services/receipt_service.dart';
import 'package:intl/intl.dart';

class OrderReceiptWidget extends StatefulWidget {
  final String orderId;
  final VoidCallback? onClose;

  const OrderReceiptWidget({
    super.key,
    required this.orderId,
    this.onClose,
  });

  @override
  State<OrderReceiptWidget> createState() => _OrderReceiptWidgetState();
}

class _OrderReceiptWidgetState extends State<OrderReceiptWidget> {
  final ReceiptService _service = ReceiptService();
  ReceiptData? _receipt;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReceipt();
  }

  Future<void> _loadReceipt() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });
      final receipt = await _service.getReceipt(widget.orderId);
      setState(() {
        _receipt = receipt;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _formatCurrency(int amount) {
    return '${NumberFormat('#,###').format(amount ~/ 100)} CFA';
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) return '';
    return DateFormat('MMM d, h:mm a').format(date);
  }

  Future<void> _openInBrowser() async {
    final url = _service.getReceiptHtmlUrl(widget.orderId);
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _shareReceipt() async {
    if (_receipt == null) return;
    final url = _service.getReceiptHtmlUrl(widget.orderId);
    await Share.share(
      'Order Receipt #${_receipt!.orderCode}\n'
      'From: ${_receipt!.restaurant.name}\n'
      'Total: ${_formatCurrency(_receipt!.totals.amountPaid)}\n\n'
      'View receipt: $url',
      subject: 'Order Receipt #${_receipt!.orderCode}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order Receipt',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: _shareReceipt,
                      icon: const Icon(Icons.share_outlined),
                      tooltip: 'Share',
                    ),
                    IconButton(
                      onPressed: _openInBrowser,
                      icon: const Icon(Icons.print_outlined),
                      tooltip: 'Print',
                    ),
                    if (widget.onClose != null)
                      IconButton(
                        onPressed: widget.onClose,
                        icon: const Icon(Icons.close),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 48, color: Colors.red[300]),
                            const SizedBox(height: 16),
                            Text(
                              'Failed to load receipt',
                              style: GoogleFonts.poppins(
                                color: Colors.grey[600],
                              ),
                            ),
                            TextButton(
                              onPressed: _loadReceipt,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _buildReceipt(),
          ),
        ],
      ),
    );
  }

  Widget _buildReceipt() {
    if (_receipt == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Brand header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'FlaRide',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _receipt!.orderType,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[900],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _receipt!.customerName,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      _receipt!.orderCode,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Disposable items
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Disposable items: ${_receipt!.disposableItems ? "Yes" : "No"}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),

          const Divider(),

          // Items
          ..._receipt!.items.map((item) => _buildItemRow(item)),

          const Divider(),

          // Totals
          _buildTotalRow('Subtotal', _receipt!.totals.subtotal),
          _buildTotalRow('Tax', _receipt!.totals.vat),
          if (_receipt!.totals.discount > 0)
            _buildTotalRow('Discount', -_receipt!.totals.discount,
                isDiscount: true),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Amount paid',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _formatCurrency(_receipt!.totals.amountPaid),
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryOrange,
                  ),
                ),
              ],
            ),
          ),

          const Divider(),

          // Timestamps
          _buildTimestampRow('Placed at', _receipt!.timestamps.placedAt),
          if (_receipt!.timestamps.dueAt != null)
            _buildTimestampRow('Due at', _receipt!.timestamps.dueAt),

          const Divider(),

          // Footer
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Text(
                  'Thank you for ordering from',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _receipt!.restaurant.name,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildItemRow(ReceiptItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${item.quantity} x ',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              Expanded(
                child: Text(
                  item.name,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
              ),
              Text(
                _formatCurrency(item.totalPrice),
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          if (item.options.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 24, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: item.options.map((opt) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${opt.group}: ${opt.choice}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        if (opt.price > 0)
                          Text(
                            _formatCurrency(opt.price),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          if (item.specialInstructions != null &&
              item.specialInstructions!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 24, top: 4),
              child: Text(
                'Note: ${item.specialInstructions}',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[500],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, int amount, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          Text(
            isDiscount
                ? '-${_formatCurrency(amount.abs())}'
                : _formatCurrency(amount),
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: isDiscount ? Colors.grey[500] : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimestampRow(String label, DateTime? date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          Text(
            _formatDateTime(date),
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows receipt in a bottom sheet
Future<void> showOrderReceipt(BuildContext context, String orderId) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => OrderReceiptWidget(
        orderId: orderId,
        onClose: () => Navigator.pop(context),
      ),
    ),
  );
}
