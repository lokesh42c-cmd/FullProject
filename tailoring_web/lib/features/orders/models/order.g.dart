// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Order _$OrderFromJson(Map<String, dynamic> json) => Order(
  id: (json['id'] as num).toInt(),
  orderNumber: json['order_number'] as String,
  customer: (json['customer'] as num).toInt(),
  customerName: json['customer_name'] as String?,
  customerPhone: json['customer_phone'] as String?,
  orderDate: json['order_date'] as String,
  expectedDeliveryDate: json['expected_delivery_date'] as String?,
  actualDeliveryDate: json['actual_delivery_date'] as String?,
  orderStatus: json['order_status'] as String,
  orderStatusDisplay: json['order_status_display'] as String?,
  deliveryStatus: json['delivery_status'] as String,
  deliveryStatusDisplay: json['delivery_status_display'] as String?,
  estimatedTotal: json['estimated_total'] as String,
  paymentTerms: json['payment_terms'] as String?,
  orderSummary: json['order_summary'] as String?,
  customerInstructions: json['customer_instructions'] as String?,
  qrCode: json['qr_code'] as String?,
  isLocked: json['is_locked'] as bool,
  isOverdue: json['is_overdue'] as bool?,
  daysUntilDelivery: (json['days_until_delivery'] as num?)?.toInt(),
  items: (json['items'] as List<dynamic>?)
      ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  referencePhotos: (json['reference_photos'] as List<dynamic>?)
      ?.map((e) => OrderReferencePhoto.fromJson(e as Map<String, dynamic>))
      .toList(),
  createdBy: (json['created_by'] as num?)?.toInt(),
  updatedBy: (json['updated_by'] as num?)?.toInt(),
  createdAt: json['created_at'] as String?,
  updatedAt: json['updated_at'] as String?,
);

Map<String, dynamic> _$OrderToJson(Order instance) => <String, dynamic>{
  'id': instance.id,
  'order_number': instance.orderNumber,
  'customer': instance.customer,
  'customer_name': instance.customerName,
  'customer_phone': instance.customerPhone,
  'order_date': instance.orderDate,
  'expected_delivery_date': instance.expectedDeliveryDate,
  'actual_delivery_date': instance.actualDeliveryDate,
  'order_status': instance.orderStatus,
  'order_status_display': instance.orderStatusDisplay,
  'delivery_status': instance.deliveryStatus,
  'delivery_status_display': instance.deliveryStatusDisplay,
  'estimated_total': instance.estimatedTotal,
  'payment_terms': instance.paymentTerms,
  'order_summary': instance.orderSummary,
  'customer_instructions': instance.customerInstructions,
  'qr_code': instance.qrCode,
  'is_locked': instance.isLocked,
  'is_overdue': instance.isOverdue,
  'days_until_delivery': instance.daysUntilDelivery,
  'items': instance.items,
  'reference_photos': instance.referencePhotos,
  'created_by': instance.createdBy,
  'updated_by': instance.updatedBy,
  'created_at': instance.createdAt,
  'updated_at': instance.updatedAt,
};

OrderItem _$OrderItemFromJson(Map<String, dynamic> json) => OrderItem(
  id: (json['id'] as num?)?.toInt(),
  itemType: json['item_type'] as String,
  item: (json['item'] as num?)?.toInt(),
  itemName: json['item_name'] as String?,
  itemBarcode: json['item_barcode'] as String?,
  itemDescription: json['item_description'] as String?,
  quantity: (json['quantity'] as num).toInt(),
  unitPrice: json['unit_price'] as String,
  discount: json['discount'] as String? ?? '0',
  taxPercentage: json['tax_percentage'] as String,
  subtotal: json['subtotal'] as String?,
  taxAmount: json['tax_amount'] as String?,
  totalPrice: json['total_price'] as String?,
  status: json['status'] as String?,
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$OrderItemToJson(OrderItem instance) => <String, dynamic>{
  'id': instance.id,
  'item_type': instance.itemType,
  'item': instance.item,
  'item_name': instance.itemName,
  'item_barcode': instance.itemBarcode,
  'item_description': instance.itemDescription,
  'quantity': instance.quantity,
  'unit_price': instance.unitPrice,
  'discount': instance.discount,
  'tax_percentage': instance.taxPercentage,
  'subtotal': instance.subtotal,
  'tax_amount': instance.taxAmount,
  'total_price': instance.totalPrice,
  'status': instance.status,
  'notes': instance.notes,
};

OrderReferencePhoto _$OrderReferencePhotoFromJson(Map<String, dynamic> json) =>
    OrderReferencePhoto(
      id: (json['id'] as num).toInt(),
      order: (json['order'] as num).toInt(),
      photo: json['photo'] as String,
      photoUrl: json['photo_url'] as String,
      uploadedAt: json['uploaded_at'] as String,
    );

Map<String, dynamic> _$OrderReferencePhotoToJson(
  OrderReferencePhoto instance,
) => <String, dynamic>{
  'id': instance.id,
  'order': instance.order,
  'photo': instance.photo,
  'photo_url': instance.photoUrl,
  'uploaded_at': instance.uploadedAt,
};
