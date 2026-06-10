# Architecture

Hisaab uses a feature-first structure with Riverpod for dependency injection
and reactive state.

```text
lib/
  app/                 # App widget and app-wide theme
  core/                # Shared storage and platform integrations
  features/
    ledger/
      data/            # Hive repositories and Riverpod providers
      model/           # Plain Dart domain models
      presentation/    # Pages, widgets, and feature UI state
    settings/
      data/
      model/
      presentation/
```

## Feature Rules

1. UI code reads providers and does not create Hive boxes or platform channels.
2. Data code owns persistence, serialization, and external data sources.
3. Model code stays framework-independent and contains domain calculations.
4. Add a feature under `lib/features/<feature_name>` with `data`, `model`, and
   `presentation` folders.
5. Put shared infrastructure in `core` only when at least two features use it.

The files in `lib/screens` are compatibility exports. New code should import
the owning feature directly.
