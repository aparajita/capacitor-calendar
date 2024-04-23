<p align="center">
  <img src="assets/images/text-logo.png" alt="capacitor-calendar-logo" height="136"/>
  <br>
    <em>
        The Capacitor Calendar Plugin enables full calendar functionality on iOS and Android, with added reminder support for iOS devices.
    </em>
</p>
<p align="center">
    <a href="https://capacitor-calendar.pages.dev/"><strong>https://capacitor-calendar.pages.dev</strong></a>
    <br>
</p>
<p align="center">
    <a href="documentation.md">Documentation</a>
    ·
    <a href="SECURITY.md#deployment-targets">Deployment Targets</a>
    <br>
</p>

## Table of Contents

- [Install](#install)
- [Demo](#demo--click-for-details-)
- [Permissions](#permissions)
- [API](#-api)
- [Documentation](#-documentation)
- [Contributions](#-contributions)

## Install

```bash
npm install @ebarooni/capacitor-calendar
npx cap sync
```

## [Demo (click for details)](./example/README.md)

|                 iOS 17                 |                 Android 14                 |
| :------------------------------------: | :----------------------------------------: |
| ![](./example/src/assets/ios-demo.gif) | ![](./example/src/assets/android-demo.gif) |

On iOS, `readCalendar` permission is not needed when you a

re creating an event using the native prompt.
The video is just for showing the functionality, otherwise the `createEventWithPrompt` method works without the `readCalendar` authorization.

## Permissions

To be able to use the plugin, you will need to add the required permissions to your app. The required platform-specific
permissions can be found below:

- [iOS](./ios/PERMISSIONS.md)
- [Android](./android/PERMISSIONS.md)

## 📋 API

- `checkPermission(...)`
- `checkAllPermissions()`
- `requestPermission(...)`
- `requestAllPermissions()`
- `createEventWithPrompt()`
- `selectCalendarsWithPrompt(...)`
- `listCalendars()`
- `getDefaultCalendar()`
- `createEvent(...)`
- `getDefaultRemindersList()`
- `getRemindersLists()`
- `createReminder(...)`
- `openCalendar(...)`
- `openReminders()`
- `listEventsInRange(...)`
- `deleteEventsById(...)`

## 📚 Documentation

For detailed explanations, usage examples, and additional information:

- **documentation.md**: Autogenerated doc are available in the [documentation](documentation.md) file.
- **definitions.ts**: Complete documentation with usage examples is available in the [src/definitions.ts](src/definitions.ts) file.

## 💙 Contributions

> [!WARNING]
> Thank you for your interest in contributing to the project! At the moment, the focus is on reaching the first major
> release. Until then, the contributions will not be accepted. This approach allows to set a solid
> foundation and maintain consistency throughout the development process.
>
> Community input is highly valued, and you are encouraged to engage with the project by providing feedback and suggestions.
> Feel free to open issues for bugs you've discovered or enhancements you'd like to see.
>
> Stay tuned for updates. Looking forward to collaborating with you in the future once contributions are opened up!
