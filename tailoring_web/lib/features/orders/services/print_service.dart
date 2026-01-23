import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:html' as html;
import 'dart:js' as js;

class PrintService {
  static void printCustomerCopy(Map<String, dynamic> orderData) {
    final htmlContent = _generateCustomerHtml(orderData);
    _openPrintWindow(htmlContent, 'Customer Copy');
  }

  static void printWorkshopCopy(Map<String, dynamic> orderData) {
    final htmlContent = _generateWorkshopHtml(orderData);
    _openPrintWindow(htmlContent, 'Workshop Copy');
  }

  static void _openPrintWindow(String htmlContent, String title) {
    // Escape the HTML content for JavaScript
    final escapedHtml = htmlContent
        .replaceAll('\\', '\\\\')
        .replaceAll("'", "\\'")
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '');

    // Use pure JavaScript interop
    js.context.callMethod('eval', [
      '''
      (function() {
        var printWindow = window.open('', '_blank', 'width=800,height=600');
        if (printWindow) {
          printWindow.document.write('$escapedHtml');
          printWindow.document.close();
          setTimeout(function() {
            printWindow.print();
          }, 500);
        }
      })();
    ''',
    ]);
  }

  static String _generateCustomerHtml(Map<String, dynamic> orderData) {
    final orderNumber = orderData['order_number'] ?? 'N/A';
    final customerName = orderData['customer_name'] ?? 'N/A';
    final customerPhone = orderData['customer_phone'] ?? 'N/A';
    final orderDate = orderData['order_date'] ?? '';
    final expectedDelivery = orderData['expected_delivery_date'] ?? '';
    final estimatedTotal = (orderData['estimated_total'] ?? 0.0).toDouble();
    final items = (orderData['items'] as List?) ?? [];

    // Calculate totals
    double subtotal = 0.0;
    double totalTax = 0.0;

    String itemsHtml = '';
    for (var item in items) {
      final itemName = item['item_name'] ?? '';
      final quantity = (item['quantity'] ?? 0).toDouble();
      final unitPrice = (item['unit_price'] ?? 0.0).toDouble();
      final discount = (item['discount'] ?? 0.0).toDouble();
      final taxPercent = (item['tax_percentage'] ?? 0.0).toDouble();

      final itemSubtotal = (quantity * unitPrice) - discount;
      final itemTax = itemSubtotal * taxPercent / 100;
      final itemTotal = itemSubtotal + itemTax;

      subtotal += itemSubtotal;
      totalTax += itemTax;

      itemsHtml +=
          '''
        <tr>
          <td style="padding: 8px; border-bottom: 1px solid #eee;">$itemName</td>
          <td style="padding: 8px; border-bottom: 1px solid #eee; text-align: center;">$quantity</td>
          <td style="padding: 8px; border-bottom: 1px solid #eee; text-align: right;">₹${unitPrice.toStringAsFixed(2)}</td>
          <td style="padding: 8px; border-bottom: 1px solid #eee; text-align: right;">₹${itemTotal.toStringAsFixed(2)}</td>
        </tr>
      ''';
    }

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Customer Copy - $orderNumber</title>
  <style>
    @media print {
      body { margin: 0; }
      .no-print { display: none; }
    }
    body {
      font-family: Arial, sans-serif;
      padding: 20px;
      max-width: 800px;
      margin: 0 auto;
    }
    .header {
      text-align: center;
      border-bottom: 3px solid #333;
      padding-bottom: 20px;
      margin-bottom: 20px;
    }
    .company-name {
      font-size: 28px;
      font-weight: bold;
      color: #1976D2;
      margin-bottom: 5px;
    }
    .copy-type {
      font-size: 18px;
      color: #666;
      font-weight: bold;
    }
    .section {
      margin-bottom: 20px;
    }
    .section-title {
      font-size: 16px;
      font-weight: bold;
      color: #333;
      border-bottom: 2px solid #1976D2;
      padding-bottom: 5px;
      margin-bottom: 10px;
    }
    .info-row {
      display: flex;
      justify-content: space-between;
      padding: 5px 0;
    }
    .info-label {
      font-weight: bold;
      color: #666;
    }
    table {
      width: 100%;
      border-collapse: collapse;
      margin: 10px 0;
    }
    th {
      background-color: #f5f5f5;
      padding: 10px;
      text-align: left;
      font-weight: bold;
      border-bottom: 2px solid #333;
    }
    .total-section {
      margin-top: 20px;
      border-top: 2px solid #333;
      padding-top: 10px;
    }
    .total-row {
      display: flex;
      justify-content: space-between;
      padding: 5px 0;
      font-size: 16px;
    }
    .grand-total {
      font-size: 20px;
      font-weight: bold;
      color: #1976D2;
      border-top: 2px solid #333;
      margin-top: 10px;
      padding-top: 10px;
    }
    .footer {
      margin-top: 40px;
      padding-top: 20px;
      border-top: 2px solid #333;
      text-align: center;
      color: #666;
      font-size: 12px;
    }
    .terms {
      margin-top: 20px;
      padding: 15px;
      background-color: #f9f9f9;
      border-left: 3px solid #1976D2;
      font-size: 12px;
      color: #666;
    }
  </style>
</head>
<body>
  <div class="header">
    <div class="company-name">TailoringWeb</div>
    <div class="copy-type">CUSTOMER COPY</div>
  </div>

  <div class="section">
    <div class="section-title">Order Information</div>
    <div class="info-row">
      <span class="info-label">Order Number:</span>
      <span>$orderNumber</span>
    </div>
    <div class="info-row">
      <span class="info-label">Order Date:</span>
      <span>${_formatDate(orderDate)}</span>
    </div>
    <div class="info-row">
      <span class="info-label">Expected Delivery:</span>
      <span>${_formatDate(expectedDelivery)}</span>
    </div>
  </div>

  <div class="section">
    <div class="section-title">Customer Details</div>
    <div class="info-row">
      <span class="info-label">Name:</span>
      <span>$customerName</span>
    </div>
    <div class="info-row">
      <span class="info-label">Phone:</span>
      <span>$customerPhone</span>
    </div>
  </div>

  <div class="section">
    <div class="section-title">Order Items</div>
    <table>
      <thead>
        <tr>
          <th>Item</th>
          <th style="text-align: center;">Qty</th>
          <th style="text-align: right;">Rate</th>
          <th style="text-align: right;">Amount</th>
        </tr>
      </thead>
      <tbody>
        $itemsHtml
      </tbody>
    </table>
  </div>

  <div class="total-section">
    <div class="total-row">
      <span>Subtotal:</span>
      <span>₹${subtotal.toStringAsFixed(2)}</span>
    </div>
    <div class="total-row">
      <span>Tax (GST):</span>
      <span>₹${totalTax.toStringAsFixed(2)}</span>
    </div>
    <div class="total-row grand-total">
      <span>Grand Total:</span>
      <span>₹${estimatedTotal.toStringAsFixed(2)}</span>
    </div>
  </div>

  <div class="terms">
    <strong>Terms & Conditions:</strong><br>
    • Please bring this receipt when collecting your order<br>
    • Any alterations after delivery may incur additional charges<br>
    • Payment due at time of collection<br>
    • We are not responsible for items not collected within 30 days
  </div>

  <div class="footer">
    <p>Thank you for your business!</p>
    <p>For any queries, please contact us with your order number</p>
  </div>
</body>
</html>
    ''';
  }

  static String _generateWorkshopHtml(Map<String, dynamic> orderData) {
    final orderNumber = orderData['order_number'] ?? 'N/A';
    final customerName = orderData['customer_name'] ?? 'N/A';
    final customerPhone = orderData['customer_phone'] ?? 'N/A';
    final orderDate = orderData['order_date'] ?? '';
    final expectedDelivery = orderData['expected_delivery_date'] ?? '';
    final priority = orderData['priority'] ?? 'MEDIUM';
    final customerInstructions = orderData['customer_instructions'] ?? '';
    final items = (orderData['items'] as List?) ?? [];

    String itemsHtml = '';
    for (var item in items) {
      final itemName = item['item_name'] ?? '';
      final itemType = item['item_type'] ?? '';
      final quantity = item['quantity'] ?? 0;
      final description = item['item_description'] ?? '';
      final barcode = item['item_barcode'] ?? '';

      itemsHtml +=
          '''
        <div style="page-break-inside: avoid; border: 2px solid #333; padding: 15px; margin-bottom: 20px; background-color: #f9f9f9;">
          <h3 style="margin: 0 0 10px 0; color: #1976D2;">$itemName</h3>
          <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 10px;">
            <div><strong>Type:</strong> $itemType</div>
            <div><strong>Quantity:</strong> $quantity</div>
            <div style="grid-column: 1 / -1;"><strong>Barcode:</strong> $barcode</div>
            ${description.isNotEmpty ? '<div style="grid-column: 1 / -1;"><strong>Description:</strong> $description</div>' : ''}
          </div>
          <div style="margin-top: 15px; padding-top: 15px; border-top: 1px dashed #ccc;">
            <strong>Measurements:</strong> (To be filled)
          </div>
          <div style="margin-top: 10px; min-height: 80px; border: 1px dashed #999; padding: 10px;">
            <em style="color: #999;">Workshop Notes:</em>
          </div>
        </div>
      ''';
    }

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Workshop Copy - $orderNumber</title>
  <style>
    @media print {
      body { margin: 0; }
      .no-print { display: none; }
    }
    body {
      font-family: Arial, sans-serif;
      padding: 20px;
      max-width: 800px;
      margin: 0 auto;
    }
    .header {
      text-align: center;
      border-bottom: 3px solid #333;
      padding-bottom: 20px;
      margin-bottom: 20px;
    }
    .company-name {
      font-size: 28px;
      font-weight: bold;
      color: #d32f2f;
      margin-bottom: 5px;
    }
    .copy-type {
      font-size: 18px;
      color: #666;
      font-weight: bold;
      text-transform: uppercase;
    }
    .priority-badge {
      display: inline-block;
      padding: 5px 15px;
      margin-top: 10px;
      border-radius: 4px;
      font-weight: bold;
      font-size: 14px;
    }
    .priority-high { background-color: #ffebee; color: #c62828; border: 2px solid #c62828; }
    .priority-medium { background-color: #fff3e0; color: #e65100; border: 2px solid #e65100; }
    .priority-low { background-color: #e8f5e9; color: #2e7d32; border: 2px solid #2e7d32; }
    .section {
      margin-bottom: 20px;
    }
    .section-title {
      font-size: 16px;
      font-weight: bold;
      color: #333;
      border-bottom: 2px solid #d32f2f;
      padding-bottom: 5px;
      margin-bottom: 10px;
    }
    .info-grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 10px;
    }
    .info-item {
      padding: 8px;
      background-color: #f5f5f5;
      border-left: 3px solid #d32f2f;
    }
    .info-label {
      font-weight: bold;
      color: #666;
      font-size: 12px;
    }
    .info-value {
      font-size: 14px;
      color: #333;
      margin-top: 3px;
    }
    .instructions-box {
      padding: 15px;
      background-color: #fff3e0;
      border-left: 4px solid #ff9800;
      margin: 15px 0;
      font-style: italic;
    }
  </style>
</head>
<body>
  <div class="header">
    <div class="company-name">TailoringWeb</div>
    <div class="copy-type">⚠️ WORKSHOP COPY - INTERNAL USE ONLY</div>
    <div class="priority-badge priority-${priority.toLowerCase()}">
      PRIORITY: $priority
    </div>
  </div>

  <div class="section">
    <div class="section-title">Order Information</div>
    <div class="info-grid">
      <div class="info-item">
        <div class="info-label">ORDER NUMBER</div>
        <div class="info-value" style="font-size: 18px; font-weight: bold; color: #d32f2f;">$orderNumber</div>
      </div>
      <div class="info-item">
        <div class="info-label">ORDER DATE</div>
        <div class="info-value">${_formatDate(orderDate)}</div>
      </div>
      <div class="info-item">
        <div class="info-label">EXPECTED DELIVERY</div>
        <div class="info-value" style="font-weight: bold;">${_formatDate(expectedDelivery)}</div>
      </div>
      <div class="info-item">
        <div class="info-label">CUSTOMER PHONE</div>
        <div class="info-value">$customerPhone</div>
      </div>
    </div>
  </div>

  <div class="section">
    <div class="section-title">Customer: $customerName</div>
    ${customerInstructions.isNotEmpty ? '<div class="instructions-box"><strong>Customer Instructions:</strong><br>$customerInstructions</div>' : ''}
  </div>

  <div class="section">
    <div class="section-title">Items to Produce</div>
    $itemsHtml
  </div>

  <div style="margin-top: 40px; padding-top: 20px; border-top: 2px solid #333;">
    <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 20px;">
      <div>
        <strong>Assigned To:</strong><br>
        <div style="border-bottom: 1px solid #333; margin-top: 30px;"></div>
      </div>
      <div>
        <strong>Completed By:</strong><br>
        <div style="border-bottom: 1px solid #333; margin-top: 30px;"></div>
      </div>
    </div>
  </div>
</body>
</html>
    ''';
  }

  static String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}
