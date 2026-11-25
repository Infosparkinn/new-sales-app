import 'package:flutter/material.dart';
import '../../core/theme.dart';

class CalculatorDialog extends StatefulWidget {
  const CalculatorDialog({super.key});

  @override
  State<CalculatorDialog> createState() => _CalculatorDialogState();
}

class _CalculatorDialogState extends State<CalculatorDialog> {
  String _display = '0';
  double _firstOperand = 0;
  String _operator = '';
  bool _shouldResetDisplay = false;

  void _onDigitPress(String digit) {
    setState(() {
      if (_display == '0' || _shouldResetDisplay) {
        _display = digit;
        _shouldResetDisplay = false;
      } else {
        _display += digit;
      }
    });
  }

  void _onOperatorPress(String op) {
    setState(() {
      _firstOperand = double.tryParse(_display) ?? 0;
      _operator = op;
      _shouldResetDisplay = true;
    });
  }

  void _onEqualPress() {
    final secondOperand = double.tryParse(_display) ?? 0;
    double result = 0;

    switch (_operator) {
      case '+':
        result = _firstOperand + secondOperand;
        break;
      case '-':
        result = _firstOperand - secondOperand;
        break;
      case '×':
        result = _firstOperand * secondOperand;
        break;
      case '÷':
        result = secondOperand != 0 ? _firstOperand / secondOperand : 0;
        break;
      default:
        return;
    }

    setState(() {
      _display = result % 1 == 0 ? result.toInt().toString() : result.toStringAsFixed(2);
      _operator = '';
      _shouldResetDisplay = true;
    });
  }

  void _onTaxSlabPress(double taxRate) {
    final amount = double.tryParse(_display) ?? 0;
    final taxAmount = amount * (taxRate / 100);
    final total = amount + taxAmount;
    setState(() {
      _display = total % 1 == 0 ? total.toInt().toString() : total.toStringAsFixed(2);
      _shouldResetDisplay = true;
    });
  }

  void _onClear() {
    setState(() {
      _display = '0';
      _firstOperand = 0;
      _operator = '';
      _shouldResetDisplay = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.calculate_rounded, color: AppTheme.primary),
                    SizedBox(width: 8),
                    Text('Quick Billing Calculator', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Calculator Display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              alignment: Alignment.centerRight,
              child: Text(
                _display,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 12),

            // Quick GST tax shortcuts
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _taxButton('+5%', 5.0),
                _taxButton('+12%', 12.0),
                _taxButton('+18%', 18.0),
                _taxButton('+28%', 28.0),
              ],
            ),
            const SizedBox(height: 12),

            // Buttons grid
            Row(
              children: [
                _btn('C', color: Colors.red.shade100, textColor: Colors.red.shade900, onTap: _onClear),
                _btn('÷', color: Colors.blue.shade50, textColor: AppTheme.primary, onTap: () => _onOperatorPress('÷')),
                _btn('×', color: Colors.blue.shade50, textColor: AppTheme.primary, onTap: () => _onOperatorPress('×')),
                _btn('-', color: Colors.blue.shade50, textColor: AppTheme.primary, onTap: () => _onOperatorPress('-')),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _btn('7', onTap: () => _onDigitPress('7')),
                _btn('8', onTap: () => _onDigitPress('8')),
                _btn('9', onTap: () => _onDigitPress('9')),
                _btn('+', color: Colors.blue.shade50, textColor: AppTheme.primary, onTap: () => _onOperatorPress('+')),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _btn('4', onTap: () => _onDigitPress('4')),
                _btn('5', onTap: () => _onDigitPress('5')),
                _btn('6', onTap: () => _onDigitPress('6')),
                _btn('=', color: AppTheme.primary, textColor: Colors.white, onTap: _onEqualPress),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _btn('1', onTap: () => _onDigitPress('1')),
                _btn('2', onTap: () => _onDigitPress('2')),
                _btn('3', onTap: () => _onDigitPress('3')),
                _btn('0', onTap: () => _onDigitPress('0')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _taxButton(String label, double rate) {
    return InkWell(
      onTap: () => _onTaxSlabPress(rate),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.purple.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.purple.shade200),
        ),
        child: Text(label, style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold, fontSize: 11)),
      ),
    );
  }

  Widget _btn(String label, {Color? color, Color? textColor, required VoidCallback onTap}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color ?? Colors.white,
            foregroundColor: textColor ?? Colors.black87,
            elevation: 1,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: onTap,
          child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
