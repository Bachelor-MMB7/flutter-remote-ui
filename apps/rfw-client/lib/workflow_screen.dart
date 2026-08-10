import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:rfw/formats.dart';
import 'package:rfw/rfw.dart';
import 'package:pyck/local_widgets.dart';

class WorkflowScreen extends StatefulWidget {
  const WorkflowScreen({super.key});

  @override
  State<WorkflowScreen> createState() => _WorkflowScreenState();
}

class _WorkflowScreenState extends State<WorkflowScreen> {
  final Runtime _runtime = Runtime();
  final DynamicContent _data = DynamicContent();

  /// SO2 deployment-time measurement
  /// started at fetch start, read again once the rendering pipeline for that frame has been flushed.
  final Stopwatch _deployWatch = Stopwatch();

  /// SO3 tapping-time measurement
  final Stopwatch _tapWatch = Stopwatch();
  /// first build after the tap — splits the span into wait (0 → build_start) and work (build_start → first_frame)
  int? _buildStartUs;

  RemoteWidgetLibrary? _remoteWidgets;
  int _currentStep = 0;
  String _tenant = 'tenant-a';
  final _workflow = 'goods-receipt';
  /// set this to the base URL of your server
  static final _serverBase =
      Platform.isAndroid ? 'http://10.0.2.2:8080' : 'http://localhost:8080';

  int _quantity = 1;
  String? _photoPath;
  String? _orderNumber;
  String? _selectedLocation;

  void _onEvent(String name, DynamicMap arguments) {
    _tapWatch..reset()..start(); // t_tap_start
    _buildStartUs = null;
    if (name == "next") {
      _next();
    } else if (name == "submit") {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('submitted'), backgroundColor: Color(0xFF30A46C), duration: Duration(milliseconds: 500),));
      setState(() {
        _currentStep = 0;
        _quantity = 1;
        _photoPath = null;
        _orderNumber = null;
        _selectedLocation = null;
      });
      _data.update('workflow', <String, Object>{});
    } else if (name == "incrementQuantity") {
      _quantity++;
      _pushWorkflowData();
    } else if (name == "decrementQuantity") {
      if (_quantity > 1) {
        _quantity--;
      }
      _pushWorkflowData();
    } else if (name == "photoTaken") {
      _photoPath = arguments['photoPath'] as String?;
      _pushWorkflowData();
    } else if (name == "setOrderNumber") {
      _orderNumber = arguments['value'] as String?;
      _pushWorkflowData();
    } else if (name == "selectLocation") {
      _selectedLocation = arguments['location'] as String?;
      _pushWorkflowData();
    }
  }

  void _next() {
    setState(() {
      _currentStep++;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final firstFrameUs = _tapWatch.elapsedMicroseconds;
      debugPrint('SO3 tap_to_frame=${firstFrameUs}us build_start=${_buildStartUs ?? 0}us step=$_currentStep');
    });
  }

  Future<void> _loadFromServer() async {
    final uri = '$_serverBase/tenants/$_tenant/workflows/$_workflow.rfw';

    try {
      _deployWatch..reset()..start(); // t_fetch_start
      // 3 s cap so an unreachable server falls back to the cached definition instead of blocking the screen
      final response = await http.get(Uri.parse(uri)).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final fetchDoneMs = _deployWatch.elapsedMilliseconds; // t_fetch_done
        final remoteWidgets = decodeLibraryBlob(response.bodyBytes);
        final file = await _getLocalFile();
        await file.writeAsBytes(response.bodyBytes);
        _runtime.update(remoteName, remoteWidgets);
        setState(() {
          _remoteWidgets = remoteWidgets;
        });
        // t_first_frame: fires once the rendering pipeline for this frame has been flushed
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final firstFrameMs = _deployWatch.elapsedMilliseconds;
          debugPrint(
            'SO2 deployment: fetch=${fetchDoneMs}ms first_frame=${firstFrameMs}ms',
          );
        });
      } else {
        throw Exception(
          'Failed to load workflow from server: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('fetch failed ($e), falling back to cached definition');
      try {
        final rfwFile = await _getLocalFile();
        final bytes = await rfwFile.readAsBytes();
        final remoteWidgets = decodeLibraryBlob(bytes);

        _runtime.update(remoteName, remoteWidgets);
        setState(() {
          _remoteWidgets = remoteWidgets;
        });
      } catch (e) {
        debugPrint('no usable cache ($e), falling back to bundled default');
        final fallback = await rootBundle.loadString('assets/rfw/default.rfwtxt');
        final remoteWidgets = parseLibraryFile(fallback);

        _runtime.update(remoteName, remoteWidgets);
        setState(() {
          _remoteWidgets = remoteWidgets;
        });

        if(!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Offline: Using Generic template'), backgroundColor: Colors.red,));
      }
    }
  }

  Future<File> _getLocalFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_tenant-$_workflow.rfw');
  }

  void _pushWorkflowData() {
    _data.update('workflow', {
      'quantity': _quantity.toString(),
      'photoPath': ?_photoPath,
      'orderNumber': ?_orderNumber,
      'location': ?_selectedLocation,
    });
  }

  Widget _tenantDropDown() {
    return DropdownButton<String>(
      value: _tenant,
      items: [
        DropdownMenuItem(value: 'tenant-a', child: Text('Tenant A')),
        DropdownMenuItem(value: 'tenant-b', child: Text('Tenant B')),
      ],
      onChanged: (String? value) {
        setState(() {
          _tenant = value!;
          _currentStep = 0;
          _remoteWidgets = null;
          _quantity = 1;
          _photoPath = null;
          _orderNumber = null;
          _selectedLocation = null;
        });
        _loadFromServer();
        _data.update('workflow', <String, Object>{});
      },
    );
  }

  static const LibraryName coreName = LibraryName(<String>['core', 'widgets']);
  static const LibraryName remoteName = LibraryName(<String>['remote']);
  static const LibraryName localName = LibraryName(<String>[
    'local',
    'widgets',
  ]);

  @override
  void initState() {
    super.initState();
    _update();
    _loadFromServer();
  }

  @override
  void reassemble() {
    super.reassemble();
    _update();
  }

  void _update() {
    _runtime.update(coreName, createCoreWidgets());
    _runtime.update(localName, createLocalWidgets());
  }

  @override
  Widget build(BuildContext context) {
    if (_tapWatch.isRunning && _buildStartUs == null) {
      // t_build_start: wait time from tap until the build starts (build = RFW interpretation + Flutter); real build time needs to be calculated afterwards
      _buildStartUs = _tapWatch.elapsedMicroseconds;
    }
    return Scaffold(
      appBar: AppBar(title: _tenantDropDown()),
      body: _remoteWidgets == null
          ? const Center(child: CircularProgressIndicator())
          : RemoteWidget(
              runtime: _runtime,
              data: _data,
              widget: FullyQualifiedWidgetName(remoteName, 'Step$_currentStep'),
              onEvent: _onEvent,
            ),
    );
  }
}