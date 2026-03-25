import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/state/vault_controller.dart';
import '../../../core/utils/otpauth_parser.dart';

enum AddAuthenticatorMode { scan, manual }

class AddAuthenticatorScreen extends ConsumerStatefulWidget {
  const AddAuthenticatorScreen({super.key});

  @override
  ConsumerState<AddAuthenticatorScreen> createState() =>
      _AddAuthenticatorScreenState();
}

class _AddAuthenticatorScreenState
    extends ConsumerState<AddAuthenticatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _issuerController = TextEditingController();
  final _accountController = TextEditingController();
  final _secretController = TextEditingController();
  final _digitsController = TextEditingController(text: '6');
  final _periodController = TextEditingController(text: '30');
  final _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  AddAuthenticatorMode _mode = AddAuthenticatorMode.scan;
  String _algorithm = 'SHA1';
  bool _saving = false;
  ParsedOtpAuth? _scanned;

  @override
  void dispose() {
    _issuerController.dispose();
    _accountController.dispose();
    _secretController.dispose();
    _digitsController.dispose();
    _periodController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _hydrateFromParsed(ParsedOtpAuth parsed) {
    _issuerController.text = parsed.issuer;
    _accountController.text = parsed.accountName;
    _secretController.text = parsed.secret;
    _digitsController.text = parsed.digits.toString();
    _periodController.text = parsed.period.toString();
    _algorithm = parsed.algorithm.toUpperCase();
  }

  Future<void> _saveFromForm() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() => _saving = true);
    final notifier = ref.read(vaultControllerProvider.notifier);
    final item = notifier.buildOtp(
      issuer: _issuerController.text,
      accountName: _accountController.text,
      secret: _secretController.text,
      algorithm: _algorithm,
      digits: int.tryParse(_digitsController.text) ?? 6,
      period: int.tryParse(_periodController.text) ?? 30,
    );
    await notifier.addOtp(item);
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Add Authenticator'),
        backgroundColor: Colors.white.withValues(alpha: 0.8),
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: <Widget>[
            SegmentedButton<AddAuthenticatorMode>(
              segments: const <ButtonSegment<AddAuthenticatorMode>>[
                ButtonSegment(
                  value: AddAuthenticatorMode.scan,
                  label: Text('Scan QR Code'),
                  icon: Icon(Icons.qr_code_scanner),
                ),
                ButtonSegment(
                  value: AddAuthenticatorMode.manual,
                  label: Text('Enter Manually'),
                  icon: Icon(Icons.keyboard),
                ),
              ],
              selected: <AddAuthenticatorMode>{_mode},
              onSelectionChanged: (value) {
                setState(() {
                  _mode = value.first;
                });
              },
            ),
            const SizedBox(height: 20),
            if (_mode == AddAuthenticatorMode.scan)
              _buildScanner()
            else
              _buildManualForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildScanner() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(
            height: 340,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                MobileScanner(
                  controller: _scannerController,
                  onDetect: (capture) {
                    if (_scanned != null) return;
                    final raw = capture.barcodes.firstOrNull?.rawValue;
                    if (raw == null) return;
                    final parsed = OtpAuthParser.parse(raw);
                    if (parsed == null) return;
                    setState(() {
                      _scanned = parsed;
                      _hydrateFromParsed(parsed);
                    });
                  },
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.9),
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          _scanned == null
              ? 'Position the QR code in the frame. Your camera scans automatically.'
              : 'QR scanned: ${_scanned!.issuer} (${_scanned!.accountName})',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 16),
        if (_scanned != null)
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() => _scanned = null);
                  },
                  child: const Text('Scan Again'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _saving ? null : _saveFromForm,
                  child: Text(_saving ? 'Saving...' : 'Save Account'),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildManualForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: <Widget>[
          _field(
            label: 'Issuer',
            child: TextFormField(
              controller: _issuerController,
              decoration: const InputDecoration(hintText: 'e.g., GitHub'),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) return 'Issuer is required.';
                return null;
              },
            ),
          ),
          _field(
            label: 'Account',
            child: TextFormField(
              controller: _accountController,
              decoration: const InputDecoration(
                hintText: 'e.g., john@company.com',
              ),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) return 'Account is required.';
                return null;
              },
            ),
          ),
          _field(
            label: 'Secret',
            child: TextFormField(
              controller: _secretController,
              decoration: const InputDecoration(hintText: 'Base32 secret'),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) return 'Secret is required.';
                return null;
              },
            ),
          ),
          ExpansionTile(
            title: const Text('Advanced'),
            childrenPadding: const EdgeInsets.only(bottom: 12),
            children: <Widget>[
              _field(
                label: 'Algorithm',
                child: DropdownButtonFormField<String>(
                  initialValue: _algorithm,
                  items: const <String>['SHA1', 'SHA256', 'SHA512']
                      .map(
                        (item) => DropdownMenuItem<String>(
                          value: item,
                          child: Text(item),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _algorithm = value ?? 'SHA1'),
                ),
              ),
              _field(
                label: 'Digits',
                child: TextFormField(
                  controller: _digitsController,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final parsed = int.tryParse(value ?? '');
                    if (parsed == null || parsed < 6 || parsed > 8) {
                      return 'Use 6-8 digits.';
                    }
                    return null;
                  },
                ),
              ),
              _field(
                label: 'Period (seconds)',
                child: TextFormField(
                  controller: _periodController,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final parsed = int.tryParse(value ?? '');
                    if (parsed == null || parsed < 15 || parsed > 120) {
                      return 'Use 15-120 seconds.';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _saveFromForm,
              child: Text(_saving ? 'Saving...' : 'Save Authenticator'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({required String label, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}
