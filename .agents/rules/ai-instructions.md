# Stock Tracker App - Antigravity Agent Rules

## Developer Profile & Context
- Developer: Mehmet Murt (Computer Engineering Student)
- Project: Multi-asset financial tracker (Stock/Crypto/Forex/Metals)
- IDE: IntelliJ IDEA

## Technical Architecture & Conventions
- **Data Models:** Located in `lib/Models/market_asset.dart` (`MarketAsset` contains static metadata and live metrics).
- **Configuration:** Static configurations reside in `lib/ConfigClasses/market_config.dart` (`MarketAssetConfig`).
- **Services:** `lib/Services/generic_market_service.dart` exposes `Stream<List<MarketAsset>>`.
- **API Layer:** `main_api.dart` handles concurrent fetches via `Future.wait`.

## UI & State Management Rules
- **State Management:** Use Flutter's native `StreamBuilder` connected to `GenericMarketService`. Do NOT introduce external state management (BLoC, Riverpod, Provider) unless explicitly requested.
- **Widget Structure:** Prefer `StatelessWidget` for UI components. Separate heavy UI blocks to prevent unnecessary rebuilds.
- **Stream Lifecycle:** Every `StreamBuilder` MUST handle all three states gracefully:
  1. `ConnectionState.waiting` -> Show `CircularProgressIndicator` or Skeleton loading.
  2. `snapshot.hasError` -> Display a readable error card with retry capability.
  3. `snapshot.hasData` -> Render the main UI dashboard.

## Financial UI/UX Standards
- **Typography:** Always use monospace font features (`FontFeature.tabularFigures()` or `TextStyle(fontFamily: 'monospace')`) for numerical values, prices, and percentages to prevent layout jitter on updates.
- **Color Coding:** 
  - Green (`Colors.green` / `#4CAF50`) for positive trends/price changes.
  - Red (`Colors.red` / `#F44336`) for negative trends/price changes.
- **Card Design:** Use clean card-based layouts with clear hierarchy (Ticker/Symbol -> Name -> Price -> Change %).

## Code Generation Requirements
- Always provide clean, complete, copy-pasteable Dart code.
- Ensure file paths and imports align with `lib/...` structure.
