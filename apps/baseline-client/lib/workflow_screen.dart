import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pyck/widgets.dart';

class WorkflowScreen extends StatefulWidget {
  const WorkflowScreen({super.key});

  @override
  State<WorkflowScreen> createState() => _WorkflowScreenState();
}

class _WorkflowScreenState extends State<WorkflowScreen> {
  ///SO3 tapping-time measurement
  final Stopwatch _tapWatch = Stopwatch();
  /// first build after the tap — splits the span into wait (0→build_start) and work (build_start→first_frame)
  int? _buildStartUs;

  int _quantity = 1;
  String? _orderNumber;
  String? _photoPath;
  String? _selectedLocation;
  int _currentStep = 0;

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() => _photoPath = photo.path);
    }
  }

  void _next() {
    _tapWatch..reset()..start(); // t_tap_start
    _buildStartUs = null;
    setState(() => _currentStep++);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final firstFrameUs = _tapWatch.elapsedMicroseconds;
      debugPrint('SO3 tap_to_frame=${firstFrameUs}us build_start=${_buildStartUs ?? 0}us step=$_currentStep');
    });
  }

  void _submit() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('submitted'),
        backgroundColor: Color(0xFF30A46C),
        duration: Duration(milliseconds: 500),
      ),
    );
    // workflow completed: back to step 0 for the next receipt
    setState(() {
      _currentStep = 0;
      _quantity = 1;
      _orderNumber = null;
      _photoPath = null;
      _selectedLocation = null;
    });
  }

  Widget _step0() {
    return ActivityContainer(
      child: ListView(
        children: [
          ActivityHeader(step: 1, title: 'Goods Receipt — SDUI Industries'),
          TextInput(
            label: 'Order number',
            onChanged: (text) => setState(() => _orderNumber = text),
          ),
          ProductDetail(description: 'Washers', sku: 'WAS-001'),
          QuantityStepper(
            label: 'Received quantity',
            value: _quantity,
            onIncrement: () => setState(() => _quantity++),
            onDecrement: () => setState(() {
              if (_quantity > 1) _quantity--;
            }),
          ),
          ConfirmButton(
            text: 'Continue',
            enabled: (_orderNumber ?? '').isNotEmpty,
            onPressed: _next,
          ),
        ],
      ),
    );
  }

  Widget _step1() {
    return ActivityContainer(
      child: ListView(
        children: [
          ActivityHeader(step: 2, title: 'Quality Inspection'),
          const InfoBox(
            text: 'Check the goods for damage and photograph any issues.',
          ),
          const SizedBox(height: 16),
          PhotoButton(text: 'Add condition photo', onPressed: _takePhoto),
          const SizedBox(height: 16),
          ImagePreview(previewPath: _photoPath),
          ConfirmButton(
            text: 'Continue',
            enabled: true,
            onPressed: _next,
          ),
        ],
      ),
    );
  }

  Widget _step2() {
    return ActivityContainer(
      child: ListView(
        children: [
          ActivityHeader(step: 3, title: 'Storage Location'),
          SelectableOption(
            label: 'High-Bay Rack A',
            value: 'High-Bay Rack A',
            selectedValue: _selectedLocation,
            onPressed: () =>
                setState(() => _selectedLocation = 'High-Bay Rack A'),
          ),
          SelectableOption(
            label: 'Picking Area B',
            value: 'Picking Area B',
            selectedValue: _selectedLocation,
            onPressed: () =>
                setState(() => _selectedLocation = 'Picking Area B'),
          ),
          SelectableOption(
            label: 'Hazmat Store',
            value: 'Hazmat Store',
            selectedValue: _selectedLocation,
            onPressed: () => setState(() => _selectedLocation = 'Hazmat Store'),
          ),
          const SizedBox(height: 16),
          ConfirmButton(
            text: 'Continue',
            enabled: (_selectedLocation ?? '').isNotEmpty,
            onPressed: _next,
          ),
        ],
      ),
    );
  }

  Widget _step3() {
    return ActivityContainer(
      child: ListView(
        children: [
          ActivityHeader(step: 4, title: 'Receipt Summary'),
          const SizedBox(height: 16),
          SummaryRow(label: 'Order number', value: _orderNumber ?? ''),
          const SummaryRow(label: 'Product', value: 'Washers'),
          const SummaryRow(label: 'SKU', value: 'WAS-001'),
          SummaryRow(label: 'Quantity', value: '$_quantity'),
          SummaryRow(label: 'Location', value: _selectedLocation ?? ''),
          const SizedBox(height: 16),
          ImagePreview(previewPath: _photoPath),
          const SizedBox(height: 16),
          ConfirmButton(
            text: 'Confirm Receipt',
            enabled: true,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_tapWatch.isRunning && _buildStartUs == null) {
      // t_build_start: wait time from tap until the build starts (build = Flutter only) ; real build time needs to be calculated afterwards
      _buildStartUs = _tapWatch.elapsedMicroseconds;
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tenant B'),
      ),
      body: switch (_currentStep) {
        0 => _step0(),
        1 => _step1(),
        2 => _step2(),
        3 => _step3(),
        _ => const SizedBox.shrink(),
      },
    );
  }
}