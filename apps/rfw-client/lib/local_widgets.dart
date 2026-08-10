import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rfw/rfw.dart';

WidgetLibrary createLocalWidgets() {
  return LocalWidgetLibrary(<String, LocalWidgetBuilder>{
    'ActivityContainer': (BuildContext context, DataSource source) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: source.child(<Object>['child']),
        ),
      );
    },

    'ActivityHeader': (BuildContext context, DataSource source) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Step ${source.v<int>(<Object>['step']) ?? 0}',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            Text(
              source.v<String>(<Object>['title']) ?? '',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    },

    'ConfirmButton': (BuildContext context, DataSource source) {
      final bool require = source.v<bool>(<Object>['require']) ?? false;
      final bool enabled =
          !require ||
          (source.v<String>(<Object>['requiredValue']) ?? '').isNotEmpty;
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF12A594),
            foregroundColor: Colors.white,
          ),
          onPressed: enabled ? source.voidHandler(<Object>['onPressed']) : null,
          child: Text(source.v<String>(<Object>['text']) ?? ''),
        ),
      );
    },

    'TextInput': (BuildContext context, DataSource source) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            source.v<String>(<Object>['label']) ?? '',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          TextFormField(
            decoration: const InputDecoration(border: OutlineInputBorder()),
            onChanged: source.handler<ValueChanged<String>>(
              <Object>['onChanged'],
              (trigger) => (input) {
                trigger({'value': input});
              },
            ),
          ),
        ],
      );
    },

    'ProductDetail': (BuildContext context, DataSource source) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: <Widget>[
            const Icon(Icons.inventory_2_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                source.v<String>(<Object>['description']) ?? '',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              'SKU ${source.v<String>(<Object>['sku']) ?? ''}',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    },

    'QuantityStepper': (BuildContext context, DataSource source) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            source.v<String>(<Object>['label']) ?? '',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: source.voidHandler(<Object>['onDecrement']),
              ),
              Text(
                source.v<String>(<Object>['value']) ?? '1',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: source.voidHandler(<Object>['onIncrement']),
              ),
            ],
          ),
        ],
      );
    },

    'InfoBox': (BuildContext context, DataSource source) {
      return Container(
        alignment: Alignment.center,
        child: Text(
          source.v<String>(<Object>["text"]) ?? '',
          textAlign: TextAlign.center,
        ),
      );
    },

    'PhotoButton': (BuildContext context, DataSource source) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF2EFF9),
            foregroundColor: Color(0xFF12A594),
          ),
          icon: const Icon(Icons.camera_alt),
          onPressed: source.handler<VoidCallback>(
            ['onPressed'],
            (trigger) => () async {
              final picker = ImagePicker();
              //open camera
              final XFile? photo = await picker.pickImage(
                source: ImageSource.camera,
              );
              if (photo != null) trigger({'photoPath': photo.path});
            },
          ),
          label: Text(source.v<String>(['text']) ?? ''),
        ),
      );
    },

    'ImagePreview': (BuildContext context, DataSource source) {
      final previewPath = source.v<String>(['previewPath']);
      if (previewPath == null) {
        return const SizedBox.shrink();
      } else {
        final file = File(previewPath);
        //show image
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Image.file(file, height: 200),
        );
      }
    },

    'SelectableOption': (BuildContext context, DataSource source) {
      final String value = source.v<String>(<Object>['value']) ?? '';
      final String? selectedValue = source.v<String>(<Object>['selectedValue']);
      final bool isSelected = value == selectedValue;
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        color: isSelected ? Colors.blue.shade50 : null,
        child: ListTile(
          leading: const Icon(Icons.warehouse_outlined),
          title: Text(source.v<String>(<Object>['label']) ?? ''),
          trailing: isSelected
              ? const Icon(Icons.check_circle, color: Colors.blue)
              : null,
          onTap: source.voidHandler(<Object>['onPressed']),
        ),
      );
    },

    'SummaryRow': (BuildContext context, DataSource source) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              source.v<String>(<Object>['label']) ?? '',
              style: const TextStyle(color: Colors.grey),
            ),
            Text(
              source.v<String>(<Object>['value']) ?? '',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    },
  });
}