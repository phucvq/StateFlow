# Regular WidgetKit Widget — Xcode Setup Guide

Complete these steps once in Xcode before building.

---

## 1. Add `FlowStateWidget.swift` to the widget target

The file was created at `FlowStateWidgets/FlowStateWidget.swift` but Xcode won't compile it until it's in the right target.

1. In the Project Navigator, select **FlowStateWidget.swift**.
2. Open the **File Inspector** (right panel).
3. Under **Target Membership**, check **FlowStateWidgets** only (not the main app).

Also do the same for **`WidgetSharedData.swift`** (`FlowState/Shared/Extensions/WidgetSharedData.swift`):
- Check **FlowState** (main app) ✅
- Check **FlowStateWidgets** ✅  ← widgets need to read it too

---

## 2. Create the App Group

Widgets run in a separate process and can't read the main app's UserDefaults without an **App Group**.

### 2a. Add capability to the main app target

1. Select the **FlowState** project in the Navigator.
2. Select the **FlowState** target → **Signing & Capabilities** tab.
3. Click **+ Capability** → choose **App Groups**.
4. Click **+** under App Groups → enter: `group.com.flowstate.app`
5. Xcode will add `FlowState.entitlements` (or update it if it exists).

### 2b. Add the same capability to the widget target

1. Select the **FlowStateWidgets** target → **Signing & Capabilities** tab.
2. Click **+ Capability** → choose **App Groups**.
3. Click **+** and enter the **same** group ID: `group.com.flowstate.app`
4. Make sure the checkbox next to it is **ticked** in both targets.

---

## 3. Verify entitlements

Both entitlement files should now contain:

```xml
<key>com.apple.security.application-groups</key>
<array>
    <string>group.com.flowstate.app</string>
</array>
```

If you see a different App Group ID anywhere, update `kAppGroupID` in `WidgetSharedData.swift` to match.

---

## 4. Register the App Group in the Apple Developer portal (if needed)

For physical device builds, the App Group must exist in the portal:

1. Go to [developer.apple.com](https://developer.apple.com) → Certificates, Identifiers & Profiles → **App Groups**.
2. Click **+** → enter `group.com.flowstate.app` → Continue → Register.
3. Open both App IDs (`com.flowstate.app` and `com.flowstate.app.FlowStateWidgets`) and enable **App Groups**, then edit to add `group.com.flowstate.app`.
4. Regenerate provisioning profiles for both App IDs and download them into Xcode (or let Automatic Signing handle it).

---

## 5. Widget sizes supported

| Family | Description |
|---|---|
| `systemSmall` | Today focus + streak |
| `systemMedium` | Today + week + streak + last session |
| `systemLarge` | Full stats (all-time, best streak, last session) |
| `accessoryCircular` | Lock screen / watch face — circular |
| `accessoryRectangular` | Lock screen — wide bar |
| `accessoryInline` | Lock screen — single line |

---

## 6. How data flows

```
Main App (session complete)
  → TimerViewModel writes to WidgetDataWriter (App Group UserDefaults)
  → WidgetCenter.reloadAllTimelines() wakes widget

Analytics tab opened
  → AnalyticsViewModel.recompute() writes full stats including weekly/all-time

Widget Extension
  → FlowStateWidgetProvider.getTimeline() reads WidgetDataWriter
  → renders views, refreshes at midnight
```

---

## 7. Test in Simulator

1. Build & run the main app. Complete a session.
2. Long-press the Home Screen → tap **+** → search **FlowState** → pick a size.
3. The widget should show today's focus time and streak.
