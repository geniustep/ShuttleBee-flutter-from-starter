import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:bridgecore_flutter_starter/core/data/datasources/remote_data_source.dart';
import 'package:bridgecore_flutter_starter/core/utils/logger.dart';

/// Dynamic forms builder service
class FormsBuilderService {
  static final FormsBuilderService _instance =
      FormsBuilderService._internal();
  factory FormsBuilderService() => _instance;
  FormsBuilderService._internal();

  final OdooRemoteDataSource _remote = OdooRemoteDataSource();

  /// Load form definition from Odoo
  Future<FormDefinition?> loadFormDefinition({
    required String model,
    int? viewId,
  }) async {
    try {
      // Fetch form view from Odoo
      final viewData = await _remote.callKw(
        model: model,
        method: 'fields_get',
        args: [],
        kwargs: {
          'attributes': [
            'string',
            'type',
            'required',
            'readonly',
            'selection',
            'relation',
          ],
        },
      );

      if (viewData is! Map<String, dynamic>) {
        return null;
      }

      return FormDefinition.fromOdooFields(
        model: model,
        fields: viewData,
      );
    } catch (e) {
      AppLogger.error('Error loading form definition: $e');
      return null;
    }
  }

  /// Build form widget from definition
  Widget buildForm({
    required FormDefinition definition,
    required GlobalKey<FormBuilderState> formKey,
    Map<String, dynamic>? initialValues,
    Function(Map<String, dynamic>)? onSubmit,
  }) {
    return FormBuilder(
      key: formKey,
      initialValue: initialValues ?? {},
      child: Column(
        children: [
          ...definition.fields.map((field) => _buildField(field)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.saveAndValidate() ?? false) {
                onSubmit?.call(formKey.currentState!.value);
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  /// Build individual form field
  Widget _buildField(FormFieldDefinition field) {
    switch (field.type) {
      case FieldType.char:
      case FieldType.text:
        return FormBuilderTextField(
          name: field.name,
          decoration: InputDecoration(
            labelText: field.label,
            hintText: field.help,
          ),
          validator: _buildStringValidators(field),
          enabled: !field.readonly,
          maxLines: field.type == FieldType.text ? 3 : 1,
        );

      case FieldType.integer:
      case FieldType.float:
        return FormBuilderTextField(
          name: field.name,
          decoration: InputDecoration(
            labelText: field.label,
            hintText: field.help,
          ),
          validator: _buildStringValidators(field),
          enabled: !field.readonly,
          keyboardType: TextInputType.number,
        );

      case FieldType.boolean:
        return FormBuilderCheckbox(
          name: field.name,
          title: Text(field.label),
          enabled: !field.readonly,
        );

      case FieldType.selection:
        return FormBuilderDropdown(
          name: field.name,
          decoration: InputDecoration(
            labelText: field.label,
            hintText: field.help,
          ),
          validator: _buildStringValidators(field),
          enabled: !field.readonly,
          items: field.selectionOptions!
              .map(
                (option) => DropdownMenuItem(
                  value: option.value,
                  child: Text(option.label),
                ),
              )
              .toList(),
        );

      case FieldType.date:
        return FormBuilderDateTimePicker(
          name: field.name,
          decoration: InputDecoration(
            labelText: field.label,
            hintText: field.help,
          ),
          validator: field.required
              ? (value) => value == null ? 'This field is required' : null
              : null,
          enabled: !field.readonly,
          inputType: InputType.date,
        );

      case FieldType.datetime:
        return FormBuilderDateTimePicker(
          name: field.name,
          decoration: InputDecoration(
            labelText: field.label,
            hintText: field.help,
          ),
          validator: field.required
              ? (value) => value == null ? 'This field is required' : null
              : null,
          enabled: !field.readonly,
          inputType: InputType.both,
        );

      case FieldType.many2one:
        return FormBuilderTextField(
          name: field.name,
          decoration: InputDecoration(
            labelText: field.label,
            hintText: field.help,
            suffixIcon: const Icon(Icons.search),
          ),
          validator: _buildStringValidators(field),
          enabled: !field.readonly,
          readOnly: true,
          onTap: () {
            // Open selection dialog
            // This would show a searchable list from the related model
          },
        );

      default:
        return FormBuilderTextField(
          name: field.name,
          decoration: InputDecoration(
            labelText: field.label,
            hintText: field.help,
          ),
          enabled: !field.readonly,
        );
    }
  }

  /// Build validators for field
  FormFieldValidator<String>? _buildStringValidators(
      FormFieldDefinition field) {
    final validators = <FormFieldValidator<String>>[];

    if (field.required) {
      validators.add(FormBuilderValidators.required());
    }

    if (field.type == FieldType.integer || field.type == FieldType.float) {
      validators.add(FormBuilderValidators.numeric());
    }

    if (validators.isEmpty) return null;

    return FormBuilderValidators.compose(validators);
  }

  /// Save form data to Odoo
  Future<int?> saveForm({
    required String model,
    required Map<String, dynamic> values,
    int? recordId,
  }) async {
    try {
      if (recordId != null) {
        // Update existing record
        await _remote.update(
          model: model,
          ids: [recordId],
          values: values,
        );
        AppLogger.info('Form updated: $model ($recordId)');
        return recordId;
      } else {
        // Create new record
        final id = await _remote.create(
          model: model,
          values: values,
        );
        AppLogger.info('Form created: $model ($id)');
        return id;
      }
    } catch (e) {
      AppLogger.error('Error saving form: $e');
      return null;
    }
  }
}

/// Form definition
class FormDefinition {
  final String model;
  final List<FormFieldDefinition> fields;

  FormDefinition({
    required this.model,
    required this.fields,
  });

  factory FormDefinition.fromOdooFields({
    required String model,
    required Map<String, dynamic> fields,
  }) {
    final fieldDefinitions = <FormFieldDefinition>[];

    fields.forEach((fieldName, fieldData) {
      final data = fieldData as Map<String, dynamic>;
      fieldDefinitions.add(FormFieldDefinition.fromOdooField(
        name: fieldName,
        data: data,
      ));
    });

    return FormDefinition(
      model: model,
      fields: fieldDefinitions,
    );
  }
}

/// Form field definition
class FormFieldDefinition {
  final String name;
  final String label;
  final FieldType type;
  final bool required;
  final bool readonly;
  final String? help;
  final List<SelectionOption>? selectionOptions;
  final String? relatedModel;
  final List<String>? dependsOn;
  final String? invisibleCondition;

  FormFieldDefinition({
    required this.name,
    required this.label,
    required this.type,
    this.required = false,
    this.readonly = false,
    this.help,
    this.selectionOptions,
    this.relatedModel,
    this.dependsOn,
    this.invisibleCondition,
  });

  factory FormFieldDefinition.fromOdooField({
    required String name,
    required Map<String, dynamic> data,
  }) {
    final typeStr = data['type'] as String;
    final type = FieldType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => FieldType.char,
    );

    List<SelectionOption>? options;
    if (data['selection'] != null) {
      options = (data['selection'] as List)
          .map((item) => SelectionOption(
                value: item[0].toString(),
                label: item[1] as String,
              ))
          .toList();
    }

    return FormFieldDefinition(
      name: name,
      label: data['string'] as String? ?? name,
      type: type,
      required: data['required'] as bool? ?? false,
      readonly: data['readonly'] as bool? ?? false,
      help: data['help'] as String?,
      selectionOptions: options,
      relatedModel: data['relation'] as String?,
    );
  }
}

/// Field type
enum FieldType {
  char,
  text,
  integer,
  float,
  boolean,
  date,
  datetime,
  selection,
  many2one,
  one2many,
  many2many,
  binary,
  html,
}

/// Selection option
class SelectionOption {
  final String value;
  final String label;

  SelectionOption({
    required this.value,
    required this.label,
  });
}
