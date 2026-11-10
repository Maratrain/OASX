import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:oasx/modules/settings/widgets/setting_card.dart';
import 'package:oasx/modules/settings/widgets/setting_item.dart';
import 'package:oasx/service/illustration_service.dart';
import 'package:oasx/translation/i18n_content.dart';

class IllustrationSettingsCard extends StatefulWidget {
  const IllustrationSettingsCard({super.key, this.service});
  final IllustrationService? service;
  @override
  State<IllustrationSettingsCard> createState() =>
      _IllustrationSettingsCardState();
}

class _IllustrationSettingsCardState extends State<IllustrationSettingsCard> {
  late final IllustrationService _service =
      widget.service ?? Get.find<IllustrationService>();
  late final TextEditingController _interval = TextEditingController(
    text: '${_service.intervalSeconds.value}',
  );
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _interval.dispose();
    super.dispose();
  }

  void _saveInterval() {
    if (!_formKey.currentState!.validate()) return;
    _service.setInterval(int.parse(_interval.text));
  }

  @override
  Widget build(BuildContext context) {
    final bodyStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor);
    return SettingCard(
      title: I18n.illustrationSetting.tr,
      items: [
        SettingItem(
          left: Text(I18n.illustrationEnable.tr),
          right: Obx(
            () => Switch(
              value: _service.enabled.value,
              onChanged: _service.setEnabled,
            ),
          ),
        ),
        SettingItem(
          left: Obx(
            () => Text(
              '${I18n.illustrationTransparency.tr}：${_service.transparency.value}%',
            ),
          ),
          right: SizedBox(
            width: 200,
            child: Obx(
              () => Slider(
                value: _service.transparency.value.toDouble(),
                min: 0,
                max: 100,
                divisions: 100,
                label: '${_service.transparency.value}%',
                onChanged: (value) =>
                    _service.setTransparency(value.round()),
              ),
            ),
          ),
        ),
        SettingItem(
          left: Text(I18n.illustrationInterval.tr),
          right: Form(
            key: _formKey,
            child: SizedBox(
              width: 220,
              child: TextFormField(
                key: const ValueKey('illustration-interval'),
                controller: _interval,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: I18n.illustrationInterval.tr,
                  suffixText: I18n.seconds.tr,
                  helperText: I18n.illustrationIntervalHelp.tr,
                ),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) {
                  final n = int.tryParse(value ?? '');
                  return n == null || n < 10 || n > 60
                      ? I18n.illustrationIntervalError.tr
                      : null;
                },
                onChanged: (_) {
                  final n = int.tryParse(_interval.text);
                  if (n != null && n >= 10 && n <= 60) {
                    _service.setInterval(n);
                  }
                },
                onFieldSubmitted: (_) => _saveInterval(),
                onTapOutside: (_) {
                  _saveInterval();
                  FocusScope.of(context).unfocus();
                },
              ),
            ),
          ),
        ),
      ],
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(I18n.illustrationTransparencyHelp.tr, style: bodyStyle),
          const SizedBox(height: 6),
          Obx(() {
            final count = _service.pictures.length;
            return Text(
              count == 0
                  ? I18n.illustrationEmpty.tr
                  : I18n.illustrationLoaded.trParams({'count': '$count'}),
            );
          }),
          Obx(() {
            if (_service.directoryPath.value.isEmpty) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: SelectableText(
                '${I18n.illustrationDirectory.tr}：${_service.directoryPath.value}',
                style: bodyStyle,
              ),
            );
          }),
          Obx(() {
            if (!_service.loadFailed.value) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                I18n.illustrationLoadError.tr,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            );
          }),
          const SizedBox(height: 6),
          Text(I18n.illustrationHelp.tr, style: bodyStyle),
        ],
      ),
    );
  }
}
