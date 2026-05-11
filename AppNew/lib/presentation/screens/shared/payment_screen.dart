import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/payment_bloc/payment_bloc.dart';
import '../../blocs/customer_bloc/customer_bloc.dart';
import '../../blocs/installment_bloc/installment_bloc.dart';
import '../../../core/config/theme/app_colors.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/models/installment_model.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _amountController = TextEditingController();
  final _discountValueController = TextEditingController();
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _customerSearchController = TextEditingController();

  CustomerModel? _selectedCustomer;
  InstallmentModel? _selectedInstallment;
  String _paymentType = 'partial';
  String _discountType = 'percentage';
  String _currency = 'IQD';
  DateTime _paymentDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    context.read<CustomerBloc>().add(LoadCustomers());
  }

  void _searchCustomer(String query) {
    context.read<CustomerBloc>().add(LoadCustomers(search: query.isEmpty ? null : query));
  }

  void _selectCustomer(CustomerModel c) {
    setState(() {
      _selectedCustomer = c;
      _selectedInstallment = null;
    });
    context.read<InstallmentBloc>().add(LoadInstallments(customerId: c.id, status: 'active'));
    Navigator.pop(context);
  }

  double get _amountDue {
    if (_selectedInstallment == null) return 0;
    final remaining = _selectedInstallment!.remainingAmount;
    if (_paymentType == 'full') return remaining;
    final installmentAmount = _selectedInstallment!.installmentAmount;
    return installmentAmount > remaining ? remaining : installmentAmount;
  }

  double get _discountedAmount {
    if (_paymentType != 'full') return _amountDue;
    final amount = _amountDue;
    final discVal = double.tryParse(_discountValueController.text) ?? 0;
    if (discVal <= 0) return amount;
    if (_discountType == 'percentage') return amount * (1 - discVal / 100);
    return amount - discVal;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى اختيار عميل')));
      return;
    }
    if (_selectedInstallment == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى اختيار قسط')));
      return;
    }
    final amount = double.tryParse(_amountController.text) ?? _discountedAmount;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى إدخال مبلغ صحيح')));
      return;
    }

    final baseData = <String, dynamic>{
      'plan_id': _selectedInstallment!.id,
      'amount_paid': amount,
      'payment_date': '${_paymentDate.year}-${_paymentDate.month.toString().padLeft(2, '0')}-${_paymentDate.day.toString().padLeft(2, '0')}',
      'notes': _notesController.text.trim(),
    };

    if (_paymentType == 'full') {
      baseData['discount_type'] = _discountType;
      baseData['discount_value'] = double.tryParse(_discountValueController.text) ?? 0;
      context.read<PaymentBloc>().add(CreateFullSettlement(baseData));
    } else {
      context.read<PaymentBloc>().add(CreatePayment(baseData));
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _discountValueController.dispose();
    _notesController.dispose();
    _customerSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تسديد دفعة')),
      body: BlocListener<PaymentBloc, PaymentState>(
        listener: (context, state) {
          if (state is PaymentSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تسجيل الدفعة')));
            Navigator.pop(context);
          } else if (state is PaymentError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Icon(Icons.payment, size: 48, color: AppColors.electric),
                const SizedBox(height: 16),
                const Text('تسديد دفعة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
                const SizedBox(height: 24),

                // Customer selection
                _buildSectionTitle('العميل'),
                const SizedBox(height: 8),
                if (_selectedCustomer != null)
                  Card(
                    child: ListTile(
                      title: Text(_selectedCustomer!.fullName, style: const TextStyle(fontFamily: 'Tajawal')),
                      subtitle: Text(_selectedCustomer!.phone ?? '', style: const TextStyle(fontFamily: 'Tajawal')),
                      trailing: IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() { _selectedCustomer = null; _selectedInstallment = null; })),
                    ),
                  )
                else
                  _buildCustomerSearch(),

                const SizedBox(height: 20),

                // Installment selection
                _buildSectionTitle('القسط'),
                const SizedBox(height: 8),
                if (_selectedInstallment != null)
                  Card(
                    child: ListTile(
                      title: Text('قسط بقيمة ${_selectedInstallment!.installmentAmount} ${_selectedInstallment!.currency}', style: const TextStyle(fontFamily: 'Tajawal')),
                      subtitle: Text('المتبقي: ${_selectedInstallment!.remainingAmount} ${_selectedInstallment!.currency}', style: const TextStyle(fontFamily: 'Tajawal')),
                      trailing: IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _selectedInstallment = null)),
                    ),
                  )
                else if (_selectedCustomer != null)
                  _buildInstallmentList(),

                const SizedBox(height: 20),

                // Payment type
                _buildSectionTitle('نوع التسديد'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        value: 'partial',
                        groupValue: _paymentType,
                        title: const Text('قسط current', style: TextStyle(fontFamily: 'Tajawal', fontSize: 13)),
                        onChanged: (v) => setState(() => _paymentType = v ?? 'partial'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        value: 'full',
                        groupValue: _paymentType,
                        title: const Text('تسديد كامل', style: TextStyle(fontFamily: 'Tajawal', fontSize: 13)),
                        onChanged: (v) => setState(() => _paymentType = v ?? 'partial'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),

                // Discount (full settlement only)
                if (_paymentType == 'full') ...[
                  const SizedBox(height: 16),
                  _buildSectionTitle('تخفيض'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          value: 'percentage',
                          groupValue: _discountType,
                          title: const Text('نسبة %', style: TextStyle(fontFamily: 'Tajawal', fontSize: 13)),
                          onChanged: (v) => setState(() => _discountType = v ?? 'percentage'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          value: 'fixed',
                          groupValue: _discountType,
                          title: const Text('مبلغ ثابت', style: TextStyle(fontFamily: 'Tajawal', fontSize: 13)),
                          onChanged: (v) => setState(() => _discountType = v ?? 'percentage'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                  TextFormField(
                    controller: _discountValueController,
                    decoration: InputDecoration(
                      labelText: 'قيمة التخفيض (${_discountType == 'percentage' ? '%' : _currency})',
                      prefixIcon: const Icon(Icons.discount),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                  if (_discountedAmount < _amountDue && _discountValueController.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('المبلغ بعد الخصم: $_discountedAmount $_currency',
                        style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
                    ),
                ],

                const SizedBox(height: 20),

                // Amount
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    labelText: 'المبلغ المدفوع',
                    prefixIcon: const Icon(Icons.monetization_on),
                    hintText: _paymentType == 'full' ? _discountedAmount.toStringAsFixed(0) : _amountDue.toStringAsFixed(0),
                  ),
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 16),

                // Currency
                DropdownButtonFormField<String>(
                  initialValue: _currency,
                  decoration: const InputDecoration(labelText: 'العملة', prefixIcon: Icon(Icons.currency_exchange)),
                  items: const [
                    DropdownMenuItem(value: 'IQD', child: Text('IQD', style: TextStyle(fontFamily: 'Tajawal'))),
                    DropdownMenuItem(value: 'USD', child: Text('USD', style: TextStyle(fontFamily: 'Tajawal'))),
                  ],
                  onChanged: (v) => setState(() => _currency = v ?? 'IQD'),
                ),

                const SizedBox(height: 16),

                // Date
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(context: context, initialDate: _paymentDate, firstDate: DateTime(2020), lastDate: DateTime.now());
                    if (picked != null) setState(() => _paymentDate = picked);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'تاريخ الدفع', prefixIcon: Icon(Icons.date_range)),
                    child: Text('${_paymentDate.year}-${_paymentDate.month.toString().padLeft(2, '0')}-${_paymentDate.day.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontFamily: 'Tajawal')),
                  ),
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(labelText: 'ملاحظات', prefixIcon: Icon(Icons.notes)),
                  maxLines: 2,
                ),

                const SizedBox(height: 24),

                BlocBuilder<PaymentBloc, PaymentState>(
                  builder: (context, state) {
                    if (state is PaymentLoading) return const Center(child: CircularProgressIndicator());
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(onPressed: _submit, child: const Text('تأكيد الدفع')),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Tajawal')),
        const SizedBox(width: 8),
        const Divider(),
      ],
    );
  }

  Widget _buildCustomerSearch() {
    return InkWell(
      onTap: () => _showCustomerPicker(),
      child: InputDecorator(
        decoration: const InputDecoration(labelText: 'اختيار عميل', prefixIcon: Icon(Icons.search), suffixIcon: Icon(Icons.arrow_drop_down)),
        child: Text(_customerSearchController.text.isEmpty ? 'انقر للبحث' : _customerSearchController.text,
          style: const TextStyle(fontFamily: 'Tajawal')),
      ),
    );
  }

  void _showCustomerPicker() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('اختيار عميل', style: TextStyle(fontFamily: 'Tajawal')),
            content: SizedBox(
              width: double.maxFinite, height: 400,
              child: Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(labelText: 'بحث', prefixIcon: Icon(Icons.search), labelStyle: TextStyle(fontFamily: 'Tajawal')),
                    onChanged: _searchCustomer,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: BlocBuilder<CustomerBloc, CustomerState>(
                      builder: (context, state) {
                        if (state is CustomerLoading) return const Center(child: CircularProgressIndicator());
                        if (state is CustomerLoaded && state.customers.isEmpty) return const Center(child: Text('لا يوجد عملاء', style: TextStyle(fontFamily: 'Tajawal')));
                        if (state is CustomerLoaded) {
                          return ListView(
                            children: state.customers.map((c) => ListTile(
                              title: Text(c.fullName, style: const TextStyle(fontFamily: 'Tajawal')),
                              subtitle: Text(c.phone ?? '', style: const TextStyle(fontFamily: 'Tajawal')),
                              onTap: () { _selectCustomer(c); },
                            )).toList(),
                          );
                        }
                        return const Center(child: Text('جاري التحميل...', style: TextStyle(fontFamily: 'Tajawal')));
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInstallmentList() {
    return BlocBuilder<InstallmentBloc, InstallmentState>(
      builder: (context, state) {
        if (state is InstallmentLoading) return const Center(child: CircularProgressIndicator());
        if (state is InstallmentLoaded) {
          if (state.installments.isEmpty) return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('لا توجد أقساط نشطة لهذا العميل', style: TextStyle(fontFamily: 'Tajawal'))));
          return Column(
            children: state.installments.map((inst) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text('قسط - ${inst.installmentAmount} ${inst.currency}', style: const TextStyle(fontFamily: 'Tajawal')),
                subtitle: Text('المتبقي: ${inst.remainingAmount} ${inst.currency} - ${inst.frequency}', style: const TextStyle(fontFamily: 'Tajawal')),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () {
                  setState(() {
                    _selectedInstallment = inst;
                    _currency = inst.currency;
                  });
                },
              ),
            )).toList(),
          );
        }
        return const SizedBox();
      },
    );
  }
}
