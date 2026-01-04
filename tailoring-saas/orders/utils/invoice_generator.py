"""
IMPROVED Invoice PDF Generator with GST Breakdown
This displays GST details properly at the bottom
Replace your orders/utils/invoice_generator.py with this file
"""

from reportlab.lib.pagesizes import A4
from reportlab.lib.units import inch, mm
from reportlab.lib import colors
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.enums import TA_LEFT, TA_CENTER, TA_RIGHT
from decimal import Decimal
from datetime import datetime
import os
from django.conf import settings
from io import BytesIO


class InvoicePDFGenerator:
    """
    Generate GST-compliant invoice PDF for India
    """
    
    def __init__(self, invoice):
        self.invoice = invoice
        self.buffer = BytesIO()
        self.width, self.height = A4
        self.styles = getSampleStyleSheet()
        
        # Custom styles
        self.title_style = ParagraphStyle(
            'CustomTitle',
            parent=self.styles['Heading1'],
            fontSize=24,
            textColor=colors.HexColor('#2C3E50'),
            spaceAfter=30,
            alignment=TA_CENTER,
            fontName='Helvetica-Bold'
        )
        
        self.header_style = ParagraphStyle(
            'CustomHeader',
            parent=self.styles['Heading2'],
            fontSize=12,
            textColor=colors.HexColor('#34495E'),
            spaceAfter=12,
            fontName='Helvetica-Bold'
        )
        
        self.normal_style = ParagraphStyle(
            'CustomNormal',
            parent=self.styles['Normal'],
            fontSize=9,
            spaceAfter=6
        )
        
        self.small_style = ParagraphStyle(
            'CustomSmall',
            parent=self.styles['Normal'],
            fontSize=8,
            textColor=colors.HexColor('#7F8C8D')
        )
    
    def generate(self):
        """Generate the complete invoice PDF"""
        doc = SimpleDocTemplate(
            self.buffer,
            pagesize=A4,
            rightMargin=20*mm,
            leftMargin=20*mm,
            topMargin=20*mm,
            bottomMargin=20*mm
        )
        
        elements = []
        
        # Add all sections
        elements.extend(self._create_header())
        elements.append(Spacer(1, 5*mm))
        
        elements.extend(self._create_invoice_info())
        elements.append(Spacer(1, 5*mm))
        
        elements.extend(self._create_parties_info())
        elements.append(Spacer(1, 5*mm))
        
        elements.extend(self._create_items_table())
        elements.append(Spacer(1, 5*mm))
        
        elements.extend(self._create_amount_summary())
        elements.append(Spacer(1, 5*mm))
        
        elements.extend(self._create_amount_in_words())
        elements.append(Spacer(1, 5*mm))
        
        elements.extend(self._create_footer())
        
        # Build PDF
        doc.build(elements, onFirstPage=self._add_watermark, onLaterPages=self._add_watermark)
        
        self.buffer.seek(0)
        return self.buffer
    
    def _create_header(self):
        """Create invoice header with company info"""
        elements = []
        
        tenant_name = self.invoice.tenant.name if self.invoice.tenant else "Your Company Name"
        company_name = Paragraph(f"<b>{tenant_name}</b>", self.title_style)
        elements.append(company_name)
        
        tenant = self.invoice.tenant
        if tenant:
            address_lines = []
            if hasattr(tenant, 'address') and tenant.address:
                address_lines.append(tenant.address)
            if hasattr(tenant, 'city') and tenant.city:
                city_state = tenant.city
                if hasattr(tenant, 'state') and tenant.state:
                    city_state += f", {tenant.state}"
                if hasattr(tenant, 'pincode') and tenant.pincode:
                    city_state += f" - {tenant.pincode}"
                address_lines.append(city_state)
            
            if hasattr(tenant, 'phone') and tenant.phone:
                address_lines.append(f"Phone: {tenant.phone}")
            if hasattr(tenant, 'email') and tenant.email:
                address_lines.append(f"Email: {tenant.email}")
            if hasattr(tenant, 'gstin') and tenant.gstin:
                address_lines.append(f"<b>GSTIN: {tenant.gstin}</b>")
            
            company_details = Paragraph("<br/>".join(address_lines), self.normal_style)
            elements.append(company_details)
        
        invoice_type_text = "TAX INVOICE" if self.invoice.invoice_type == 'TAX_INVOICE' else "BILL OF SUPPLY"
        invoice_type = Paragraph(
            f'<b>{invoice_type_text}</b>',
            ParagraphStyle(
                'InvoiceType',
                parent=self.header_style,
                alignment=TA_CENTER,
                fontSize=14,
                textColor=colors.HexColor('#E74C3C') if self.invoice.invoice_type == 'TAX_INVOICE' else colors.HexColor('#27AE60')
            )
        )
        elements.append(Spacer(1, 3*mm))
        elements.append(invoice_type)
        
        return elements
    
    def _create_invoice_info(self):
        """Create invoice number and date section"""
        elements = []
        
        data = [
            ['Invoice Number:', self.invoice.invoice_number, 'Invoice Date:', self.invoice.invoice_date.strftime('%d-%b-%Y')],
            ['Order Number:', self.invoice.order.order_number if self.invoice.order else 'N/A', 
             'Due Date:', self.invoice.due_date.strftime('%d-%b-%Y') if self.invoice.due_date else 'Immediate']
        ]
        
        table = Table(data, colWidths=[35*mm, 50*mm, 30*mm, 50*mm])
        table.setStyle(TableStyle([
            ('FONTNAME', (0, 0), (0, -1), 'Helvetica-Bold'),
            ('FONTNAME', (2, 0), (2, -1), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, -1), 9),
            ('TEXTCOLOR', (0, 0), (0, -1), colors.HexColor('#34495E')),
            ('TEXTCOLOR', (2, 0), (2, -1), colors.HexColor('#34495E')),
            ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ]))
        
        elements.append(table)
        return elements
    
    def _create_parties_info(self):
        """Create billing info"""
        elements = []
        
        customer = self.invoice.customer
        
        bill_to = [
            '<b>Bill To:</b>',
            f'<b>{customer.name}</b>',
        ]
        
        if customer.customer_type == 'BUSINESS' and customer.business_name:
            bill_to.append(customer.business_name)
        
        if customer.address_line1:
            bill_to.append(customer.address_line1)
        if customer.address_line2:
            bill_to.append(customer.address_line2)
        
        city_line = []
        if customer.city:
            city_line.append(customer.city)
        if customer.state:
            city_line.append(customer.state)
        if customer.pincode:
            city_line.append(customer.pincode)
        if city_line:
            bill_to.append(', '.join(city_line))
        
        if customer.phone:
            bill_to.append(f'Phone: {customer.phone}')
        if customer.email:
            bill_to.append(f'Email: {customer.email}')
        if customer.gstin:
            bill_to.append(f'<b>GSTIN: {customer.gstin}</b>')
        
        bill_to_text = '<br/>'.join(bill_to)
        
        data = [
            [Paragraph(bill_to_text, self.normal_style)]
        ]
        
        table = Table(data, colWidths=[170*mm])
        table.setStyle(TableStyle([
            ('BOX', (0, 0), (-1, -1), 1, colors.HexColor('#BDC3C7')),
            ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#ECF0F1')),
            ('VALIGN', (0, 0), (-1, -1), 'TOP'),
            ('LEFTPADDING', (0, 0), (-1, -1), 10),
            ('RIGHTPADDING', (0, 0), (-1, -1), 10),
            ('TOPPADDING', (0, 0), (-1, -1), 10),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 10),
        ]))
        
        elements.append(table)
        return elements
    
    def _create_items_table(self):
        """Create invoice items table"""
        elements = []
        
        header = ['#', 'Description', 'HSN', 'Qty', 'Unit', 'Rate', 'Disc%', 'Tax%', 'Amount']
        data = [header]
        
        items = self.invoice.items.all()
        for idx, item in enumerate(items, 1):
            data.append([
                str(idx),
                item.description[:40],
                item.hsn_code or '-',
                str(item.quantity),
                item.unit,
                f'₹{item.unit_price:,.2f}',
                f'{item.discount_percentage}%' if item.discount_percentage > 0 else '-',
                f'{item.tax_percentage}%' if item.tax_percentage > 0 else '-',
                f'₹{item.total_amount:,.2f}'
            ])
        
        col_widths = [8*mm, 60*mm, 15*mm, 12*mm, 12*mm, 20*mm, 12*mm, 12*mm, 24*mm]
        table = Table(data, colWidths=col_widths, repeatRows=1)
        
        table.setStyle(TableStyle([
            # Header
            ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#34495E')),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, 0), 9),
            ('ALIGN', (0, 0), (-1, 0), 'CENTER'),
            
            # Body
            ('FONTNAME', (0, 1), (-1, -1), 'Helvetica'),
            ('FONTSIZE', (0, 1), (-1, -1), 8),
            ('ALIGN', (0, 1), (0, -1), 'CENTER'),
            ('ALIGN', (3, 1), (-1, -1), 'RIGHT'),
            ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
            
            # Grid
            ('GRID', (0, 0), (-1, -1), 0.5, colors.HexColor('#BDC3C7')),
            ('BOX', (0, 0), (-1, -1), 1, colors.HexColor('#34495E')),
            
            # Padding
            ('LEFTPADDING', (0, 0), (-1, -1), 5),
            ('RIGHTPADDING', (0, 0), (-1, -1), 5),
            ('TOPPADDING', (0, 0), (-1, -1), 6),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
        ]))
        
        elements.append(table)
        return elements
    
    def _create_amount_summary(self):
        """Create amount summary with GST breakdown - IMPROVED VERSION"""
        elements = []
        
        # Calculate values - use invoice values directly
        subtotal = float(self.invoice.subtotal) if self.invoice.subtotal else 0
        discount = float(self.invoice.total_discount) if self.invoice.total_discount else 0
        taxable = float(self.invoice.taxable_amount) if self.invoice.taxable_amount else subtotal - discount
        
        cgst = float(self.invoice.cgst_amount) if self.invoice.cgst_amount else 0
        sgst = float(self.invoice.sgst_amount) if self.invoice.sgst_amount else 0
        igst = float(self.invoice.igst_amount) if self.invoice.igst_amount else 0
        total_tax = cgst + sgst + igst
        
        round_off = float(self.invoice.round_off) if self.invoice.round_off else 0
        grand_total = float(self.invoice.grand_total) if self.invoice.grand_total else 0
        amount_paid = float(self.invoice.amount_paid) if self.invoice.amount_paid else 0
        balance_due = float(self.invoice.balance_due) if self.invoice.balance_due else grand_total - amount_paid
        
        # Build summary data
        summary_data = []
        
        # Subtotal
        summary_data.append(['Subtotal:', f'₹{subtotal:,.2f}'])
        
        # Discount (if any)
        if discount > 0:
            summary_data.append(['Discount:', f'- ₹{discount:,.2f}'])
        
        # Taxable amount
        summary_data.append(['Taxable Amount:', f'₹{taxable:,.2f}'])
        
        # Add horizontal line before GST
        summary_data.append(['', ''])
        
        # GST Breakdown
        if cgst > 0 or sgst > 0:
            summary_data.append(['<b>GST Breakdown:</b>', ''])
            summary_data.append(['  CGST:', f'₹{cgst:,.2f}'])
            summary_data.append(['  SGST:', f'₹{sgst:,.2f}'])
        
        if igst > 0:
            summary_data.append(['<b>GST Breakdown:</b>', ''])
            summary_data.append(['  IGST:', f'₹{igst:,.2f}'])
        
        # Total tax
        if total_tax > 0:
            summary_data.append(['<b>Total GST:</b>', f'<b>₹{total_tax:,.2f}</b>'])
        
        # Add horizontal line before grand total
        summary_data.append(['', ''])
        
        # Round off (if any)
        if round_off != 0:
            summary_data.append(['Round Off:', f'₹{round_off:,.2f}'])
        
        # Grand total
        summary_data.append(['<b>Grand Total:</b>', f'<b>₹{grand_total:,.2f}</b>'])
        
        # Add horizontal line
        summary_data.append(['', ''])
        
        # Payment details (if any payment made)
        if amount_paid > 0:
            summary_data.append(['Amount Paid:', f'₹{amount_paid:,.2f}'])
            summary_data.append(['<b>Balance Due:</b>', f'<b>₹{balance_due:,.2f}</b>'])
        
        # Create table
        table = Table(summary_data, colWidths=[130*mm, 40*mm])
        
        # Apply styles
        style_commands = [
            ('ALIGN', (0, 0), (0, -1), 'RIGHT'),
            ('ALIGN', (1, 0), (1, -1), 'RIGHT'),
            ('FONTNAME', (0, 0), (-1, -1), 'Helvetica'),
            ('FONTSIZE', (0, 0), (-1, -1), 10),
            ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
            ('TOPPADDING', (0, 0), (-1, -1), 3),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 3),
        ]
        
        # Add lines for specific rows
        for i, row in enumerate(summary_data):
            # Bold rows
            if row[0].startswith('<b>'):
                style_commands.append(('FONTNAME', (0, i), (-1, i), 'Helvetica-Bold'))
                style_commands.append(('FONTSIZE', (0, i), (-1, i), 11))
            
            # Lines
            if row[0] == '' and row[1] == '':
                style_commands.append(('LINEABOVE', (0, i), (-1, i), 0.5, colors.HexColor('#BDC3C7')))
        
        # Grand total and balance styling
        style_commands.append(('TEXTCOLOR', (0, -3), (-1, -3), colors.HexColor('#27AE60')))
        style_commands.append(('FONTSIZE', (0, -3), (-1, -3), 12))
        
        if balance_due > 0:
            style_commands.append(('TEXTCOLOR', (0, -1), (-1, -1), colors.HexColor('#E74C3C')))
            style_commands.append(('FONTSIZE', (0, -1), (-1, -1), 11))
        
        table.setStyle(TableStyle(style_commands))
        
        elements.append(table)
        return elements
    
    def _create_amount_in_words(self):
        """Create amount in words section"""
        elements = []
        
        amount_words = self._convert_to_words(float(self.invoice.grand_total))
        
        text = Paragraph(
            f'<b>Amount in Words:</b> {amount_words} Only',
            ParagraphStyle(
                'AmountWords',
                parent=self.normal_style,
                fontSize=10,
                textColor=colors.HexColor('#2C3E50')
            )
        )
        
        elements.append(text)
        return elements
    
    def _create_footer(self):
        """Create invoice footer"""
        elements = []
        
        if self.invoice.notes:
            notes_text = Paragraph(
                f'<b>Notes:</b><br/>{self.invoice.notes}',
                self.small_style
            )
            elements.append(notes_text)
            elements.append(Spacer(1, 3*mm))
        
        signature_data = [
            ['', 'For ' + (self.invoice.tenant.name if self.invoice.tenant else 'Company Name')],
            ['', ''],
            ['', ''],
            ['Customer Signature', 'Authorized Signatory']
        ]
        
        table = Table(signature_data, colWidths=[85*mm, 85*mm])
        table.setStyle(TableStyle([
            ('FONTNAME', (0, -1), (-1, -1), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, -1), 9),
            ('ALIGN', (0, -1), (0, -1), 'CENTER'),
            ('ALIGN', (1, -1), (1, -1), 'CENTER'),
            ('LINEABOVE', (0, -1), (0, -1), 1, colors.black),
            ('LINEABOVE', (1, -1), (1, -1), 1, colors.black),
            ('VALIGN', (0, 0), (-1, -1), 'BOTTOM'),
        ]))
        
        elements.append(table)
        
        footer_text = Paragraph(
            '<i>This is a computer-generated invoice and does not require a physical signature.</i>',
            ParagraphStyle(
                'Footer',
                parent=self.small_style,
                alignment=TA_CENTER,
                fontSize=7,
                textColor=colors.HexColor('#95A5A6')
            )
        )
        elements.append(Spacer(1, 2*mm))
        elements.append(footer_text)
        
        return elements
    
    def _add_watermark(self, canvas, doc):
        """Add watermark if invoice is draft"""
        if self.invoice.status == 'DRAFT':
            canvas.saveState()
            canvas.setFont('Helvetica-Bold', 60)
            canvas.setFillColorRGB(0.9, 0.9, 0.9, alpha=0.3)
            canvas.translate(self.width/2, self.height/2)
            canvas.rotate(45)
            canvas.drawCentredString(0, 0, "DRAFT")
            canvas.restoreState()
    
    def _convert_to_words(self, number):
        """Convert number to words (Indian numbering system)"""
        units = ["", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine"]
        teens = ["Ten", "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen", 
                 "Sixteen", "Seventeen", "Eighteen", "Nineteen"]
        tens = ["", "", "Twenty", "Thirty", "Forty", "Fifty", "Sixty", "Seventy", "Eighty", "Ninety"]
        
        def convert_group(n):
            if n == 0:
                return ""
            elif n < 10:
                return units[n]
            elif n < 20:
                return teens[n-10]
            elif n < 100:
                return tens[n//10] + (" " + units[n%10] if n%10 != 0 else "")
            else:
                return units[n//100] + " Hundred" + (" " + convert_group(n%100) if n%100 != 0 else "")
        
        if number == 0:
            return "Zero Rupees"
        
        rupees = int(number)
        paise = int(round((number - rupees) * 100))
        
        result = []
        
        if rupees >= 10000000:
            crores = rupees // 10000000
            result.append(convert_group(crores) + " Crore")
            rupees %= 10000000
        
        if rupees >= 100000:
            lakhs = rupees // 100000
            result.append(convert_group(lakhs) + " Lakh")
            rupees %= 100000
        
        if rupees >= 1000:
            thousands_part = rupees // 1000
            result.append(convert_group(thousands_part) + " Thousand")
            rupees %= 1000
        
        if rupees > 0:
            result.append(convert_group(rupees))
        
        rupees_text = " ".join(result) + " Rupees"
        
        if paise > 0:
            return rupees_text + " and " + convert_group(paise) + " Paise"
        
        return rupees_text


def generate_invoice_pdf(invoice):
    """Helper function to generate invoice PDF"""
    generator = InvoicePDFGenerator(invoice)
    return generator.generate()