# Weather widget

Apple WeatherKit supplies current conditions, the next five hours, and four days. The small, medium, and large Home Screen families share the app preview and styling. Weather has a separate, user-requested location; it does not silently reuse or change prayer coordinates. Coordinates are sent to Apple Weather only after setting up weather. Temperature units and cached data are shared with the extension.

## Before live device / release testing

Enable WeatherKit for **both** Apple Developer App IDs:
- `com.widgetar.app`
- `com.widgetar.app.WidgetsExtension`

On each App ID, tick WeatherKit under **both** tabs: Capabilities and App Services. Xcode automatic signing does not tick App Services. If it is missing, the app signs and uploads normally but every request fails with `WDSJWTAuthenticatorServiceListener.Errors Code=2`, which the app logs under subsystem `com.widgetar.app`, category `weather`.

Regenerate or refresh signing profiles with the WeatherKit capability. The four entitlement files already declare `com.apple.developer.weatherkit`. This does not activate the service on the developer account. An unsigned simulator build verifies compilation, not WeatherKit authorization.

Use the app’s Weather settings to choose the current location, then refresh. Verify data appears, tap the Home Screen widget to open its settings, and test offline behavior. The widget requests a refresh after 30 minutes; WidgetKit decides the actual update time. Last readings are marked outdated after two hours and hidden after 24 hours. Failed requests retain valid cached readings; a new location invalidates the old cache. App previews show explicitly labeled sample data if live readings are absent; installed widgets never use sample data.

Apple Weather attribution is shown with the returned legal URL whenever actual data is displayed. No severe-weather alerts are fetched or presented. Update the hosted privacy policy before publishing to explain the optional Apple Weather location request; the iOS permission description is already updated locally.

References:
- https://developer.apple.com/weatherkit/
- https://developer.apple.com/documentation/weatherkit/weatherattribution

Validation: `Tests/run-weather-checks.sh [booted-simulator-UUID]` checks units, Codable cache persistence, stale/expired data, location isolation, and corrupt cache handling. Visual checks should cover all sizes in Arabic and English. Forecast times use the saved location’s time zone.
