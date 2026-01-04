import 'package:flutter/material.dart';
import 'package:tailoring_web/core/theme/app_theme.dart';
import 'package:tailoring_web/core/api/api_client.dart';

class AddEditCustomerDialog extends StatefulWidget {
  final int? customerId;
  final Map<String, dynamic>? customerData;

  const AddEditCustomerDialog({super.key, this.customerId, this.customerData});

  @override
  State<AddEditCustomerDialog> createState() => _AddEditCustomerDialogState();
}

class _AddEditCustomerDialogState extends State<AddEditCustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _apiClient = ApiClient();
  bool _isLoading = false;

  // Selection States
  String _customerType = 'INDIVIDUAL';
  String _gender = 'MALE';
  String _country = 'India';

  // Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _emailController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _gstinController = TextEditingController();
  final _panController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.customerData != null) {
      _loadCustomerData();
    }
  }

  void _loadCustomerData() {
    final data = widget.customerData!;
    setState(() {
      _customerType = data['customer_type'] ?? 'INDIVIDUAL';
      _gender = data['gender'] ?? 'MALE';
    });
    _nameController.text = data['name'] ?? '';
    _phoneController.text = data['phone'] ?? '';
    _whatsappController.text = data['whatsapp_number'] ?? '';
    _emailController.text = data['email'] ?? '';
    _businessNameController.text = data['business_name'] ?? '';
    _gstinController.text = data['gstin'] ?? '';
    _panController.text = data['pan'] ?? '';
    _addressLine1Controller.text = data['address_line1'] ?? '';
    _addressLine2Controller.text = data['address_line2'] ?? '';
    _cityController.text = data['city'] ?? '';
    _stateController.text = data['state'] ?? '';
    _pincodeController.text = data['pincode'] ?? '';
    _country = data['country'] ?? 'India';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    _businessNameController.dispose();
    _gstinController.dispose();
    _panController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  String? _validatePhone(String? value, {required bool isMandatory}) {
    if (value == null || value.isEmpty || value.trim().isEmpty) {
      if (isMandatory) {
        return 'Phone number is required';
      }
      return null;
    }

    final cleaned = value.trim();

    if (!RegExp(r'^\d+$').hasMatch(cleaned)) {
      return 'Only numbers allowed';
    }

    if (cleaned.length < 10) {
      return 'Must be 10 digits (${cleaned.length}/10)';
    }

    if (cleaned.length > 10) {
      return 'Must be exactly 10 digits (${cleaned.length}/10)';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.customerId != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: Container(
        width: 800,
        constraints: BoxConstraints(
          maxHeight:
              MediaQuery.of(context).size.height * 0.9, // 90% of screen height
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(isEditing),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                physics:
                    const AlwaysScrollableScrollPhysics(), // Force scrolling
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCustomerInfoSection(),
                      const SizedBox(height: 24),
                      if (_customerType == 'BUSINESS') ...[
                        _buildBusinessInfoSection(),
                        const SizedBox(height: 24),
                      ],
                      _buildAddressSection(),
                    ],
                  ),
                ),
              ),
            ),
            _buildFooter(isEditing),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isEditing) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          Text(
            isEditing ? 'Edit Customer' : 'Add New Customer',
            style: AppTheme.heading2,
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('👤 CUSTOMER INFORMATION', style: AppTheme.heading3),
        const SizedBox(height: 16),
        Row(
          children: [
            Text(
              'Customer Type *',
              style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 20),
            Radio<String>(
              value: 'INDIVIDUAL',
              groupValue: _customerType,
              onChanged: (value) => setState(() => _customerType = value!),
            ),
            const Text('Individual (B2C)', style: AppTheme.bodyMedium),
            const SizedBox(width: 24),
            Radio<String>(
              value: 'BUSINESS',
              groupValue: _customerType,
              onChanged: (value) => setState(() => _customerType = value!),
            ),
            const Text('Business (B2B)', style: AppTheme.bodyMedium),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildTextField(
                controller: _nameController,
                label: 'Name *',
                hint: 'Enter customer name',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Gender',
                        style: AppTheme.bodySmall.copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const Text(
                        ' *',
                        style: TextStyle(color: AppTheme.danger),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.borderLight, width: 3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _gender,
                        isExpanded: true,
                        style: AppTheme.bodyMedium,
                        items: const [
                          DropdownMenuItem(value: 'MALE', child: Text('Male')),
                          DropdownMenuItem(
                            value: 'FEMALE',
                            child: Text('Female'),
                          ),
                          DropdownMenuItem(
                            value: 'OTHER',
                            child: Text('Other'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => _gender = value!);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildTextField(
                controller: _phoneController,
                label: 'Phone *',
                hint: 'Enter phone number',
                keyboardType: TextInputType.phone,
                validator: (value) => _validatePhone(value, isMandatory: true),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildTextField(
                controller: _whatsappController,
                label: 'WhatsApp',
                hint: 'Enter WhatsApp number',
                keyboardType: TextInputType.phone,
                validator: (value) => _validatePhone(value, isMandatory: false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _emailController,
          label: 'Email',
          hint: 'Enter email address',
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
              if (!emailRegex.hasMatch(value.trim())) {
                return 'Enter a valid email address';
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildBusinessInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('🏢 BUSINESS INFORMATION', style: AppTheme.heading3),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _businessNameController,
          label: 'Business Name',
          hint: 'Enter business name',
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildTextField(
                controller: _gstinController,
                label: 'GSTIN',
                hint: 'Enter GSTIN',
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    if (value.trim().length != 15) {
                      return 'GSTIN must be exactly 15 characters';
                    }
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildTextField(
                controller: _panController,
                label: 'PAN',
                hint: 'Enter PAN',
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    if (value.trim().length != 10) {
                      return 'PAN must be exactly 10 characters';
                    }
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('📍 ADDRESS', style: AppTheme.heading3),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _addressLine1Controller,
          label: 'Address Line 1 *',
          hint: 'Enter street address',
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Address is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _addressLine2Controller,
          label: 'Address Line 2',
          hint: 'Apartment, suite, etc. (optional)',
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildTextField(
                controller: _cityController,
                label: 'City *',
                hint: 'Enter city',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'City is required';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildTextField(
                controller: _stateController,
                label: 'State *',
                hint: 'Enter state',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'State is required';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildTextField(
                controller: _pincodeController,
                label: 'Pincode *',
                hint: 'Enter pincode',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Pincode is required';
                  }
                  if (value.length != 6) {
                    return 'Pincode must be 6 digits';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Country',
                        style: AppTheme.bodySmall.copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const Text(
                        ' *',
                        style: TextStyle(color: AppTheme.danger),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundGrey,
                      border: Border.all(color: AppTheme.borderLight, width: 3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Text(_country, style: AppTheme.bodyMedium),
                        const Spacer(),
                        Text(
                          '(Default)',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: AppTheme.bodySmall.copyWith(
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
            if (validator != null)
              const Text(' *', style: TextStyle(color: AppTheme.danger)),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(
                color: AppTheme.borderLight,
                width: 3,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(
                color: AppTheme.borderLight,
                width: 3,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(
                color: AppTheme.primaryBlue,
                width: 3,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: AppTheme.danger, width: 3),
            ),
          ),
          style: AppTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildFooter(bool isEditing) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(minimumSize: const Size(100, 40)),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _isLoading ? null : () => _saveCustomer(isEditing),
            style: ElevatedButton.styleFrom(minimumSize: const Size(140, 40)),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(isEditing ? 'Save Changes' : 'Save Customer'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCustomer(bool isEditing) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final customerData = {
        'customer_type': _customerType,
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'whatsapp_number': _whatsappController.text.trim().isEmpty
            ? null
            : _whatsappController.text.trim(),
        'email': _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        'business_name': _businessNameController.text.trim().isEmpty
            ? null
            : _businessNameController.text.trim(),
        'gstin': _gstinController.text.trim().isEmpty
            ? null
            : _gstinController.text.trim(),
        'pan': _panController.text.trim().isEmpty
            ? null
            : _panController.text.trim(),
        'address_line1': _addressLine1Controller.text.trim(),
        'address_line2': _addressLine2Controller.text.trim().isEmpty
            ? null
            : _addressLine2Controller.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'pincode': _pincodeController.text.trim(),
        'country': _country,
        'gender': _gender,
      };

      if (isEditing) {
        await _apiClient.put(
          'orders/customers/${widget.customerId}/',
          data: customerData,
        );
        if (mounted) {
          // Don't update state after pop - dialog is closing
          Navigator.pop(context, true);
        }
      } else {
        final response = await _apiClient.post(
          'orders/customers/',
          data: customerData,
        );
        final customerId = response.data['id'] as int;

        if (mounted) {
          Navigator.pop(context, customerId);
        }
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppTheme.danger),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
    // ✅ REMOVED: finally block that was causing setState after Navigator.pop
  }
}
