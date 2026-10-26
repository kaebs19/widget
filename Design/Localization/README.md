# Arabic and English: first phase

The app language can be selected under Settings → General. The default follows the device’s preferred supported language. The preference is shared with the widget extension and does not change saved widget identifiers or user content.

`Shared/Localization/AppLanguage.swift` resolves the language and loads model/UI strings from the selected language bundle. `Shared/Resources/Localizable.xcstrings` contains Arabic source text and English translations and belongs to both targets through the synchronized Shared folder. Use `L10n.text` for translated strings returned by models or passed through String-based view helpers. Missing translations fall back to their Arabic source key.

This phase covers gallery controls, widget names/descriptions, category/size labels, and static general settings labels. App and presented-sheet direction follows the selected language. Widget previews intentionally retain their existing Arabic content and layout until their content is localized.

Remaining work before claiming complete English support:
- Detailed finance, health, prayer, customization, help, and credits screens, including dynamic settings summaries.
- Widget body content, intent configuration, notifications, permission descriptions, and localized app display names.
- Locale-aware dates/numbers and plural forms across all features; preserve explicit numeral-style preferences.
- Arabic Quran and remembrance source text should remain intact; any translations need a vetted source.
- Visual QA on devices for both languages, long English labels, accessibility sizes, and switching languages while sheets are open.

Build both targets with Xcode, then run:

```sh
Tests/run-localization-checks.sh /path/to/Widgets.app
Tests/run-localization-checks.sh /path/to/Widgets.app/PlugIns/WidgetsExtension.appex
```

These checks cover locale resolution, direction, persisted selection, missing-key fallback, singular/plural gallery counts, and actual compiled translation resources.
