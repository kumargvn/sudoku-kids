# Sudoku Kids 🦉

A free, ad-free Sudoku app for iPhone and iPad that helps kids get excited about logic and numbers.

## What's inside

- **Classic 9×9 Sudoku** with four levels: Easy 🐣, Medium 🐥, Hard 🦊, Expert 🦁
- **Three modes**
  - **Play**: pick a level, limited hints
  - **Daily Challenge**: one new puzzle a day (the same for everyone), with a day streak 🔥
  - **Learn to Play**: unlimited hints, and the number pad dims numbers that can't fit
- **Hints that teach**: instead of just revealing an answer, a hint highlights the row, column or box and explains *why* only one number fits. Kids can try it themselves ("I'll try!") or have it filled in ("Show me").
- Every puzzle has exactly one answer. Easy and Medium can always be solved with the beginner techniques the hints teach, so kids never hit a wall.
- Notes (pencil marks), undo, erase, mistake highlighting, timer
- Stars ⭐ for finishing with few hints and mistakes, confetti on every win
- Progress and the current game are saved on the device. No accounts, no ads, no tracking, no data collection.

## Project layout

```
SudokuKids/
  Engine/        Puzzle generator, solver, hint engine (pure Swift, unit tested)
  Model/         Game state, progress storage, haptics
  Views/         SwiftUI screens
  Assets.xcassets
SudokuKidsTests/ Unit tests for the engine
project.yml      XcodeGen project definition
.github/workflows/ios.yml   CI: test on every push, upload to TestFlight from main
```

## Run it on your Mac

1. Install Xcode (latest) and XcodeGen: `brew install xcodegen`
2. In this folder: `xcodegen generate`
3. Open `SudokuKids.xcodeproj`, pick a simulator, press ▶︎

To run on your own iPhone, select the SudokuKids target → Signing & Capabilities → choose your team.

## GitHub Actions

`.github/workflows/ios.yml` has two jobs:

| Job | When it runs | What it does |
| --- | --- | --- |
| Build & test | every push and pull request | generates the project, builds, runs unit tests on an iPhone simulator |
| Upload to TestFlight | pushes to `main`, when enabled | archives, signs (automatic cloud signing) and uploads to App Store Connect |

### Turning on TestFlight uploads

You need a paid Apple Developer account.

1. **Bundle ID**: Certificates, IDs & Profiles → Identifiers → + → App ID. Use the same ID as `PRODUCT_BUNDLE_IDENTIFIER` in `project.yml` (default `com.gudivada.sudokukids`; change it there if you pick another).
2. **App record**: App Store Connect → Apps → + New App, using that bundle ID.
3. **API key**: App Store Connect → Users and Access → Integrations → App Store Connect API → Team Keys → +. Give it **Admin** access (needed so CI can create the signing certificate). Download the `.p8` file and note the Key ID and Issuer ID.
4. **Repository secrets** (Settings → Secrets and variables → Actions → Secrets):
   - `ASC_KEY_ID`: the key's ID
   - `ASC_ISSUER_ID`: the Issuer ID shown above the key list
   - `ASC_PRIVATE_KEY`: the full contents of the `.p8` file, including the BEGIN/END lines
   - `APPLE_TEAM_ID`: your 10-character Team ID (developer.apple.com → Account → Membership details)
5. **Repository variable** (same page → Variables tab): `ENABLE_TESTFLIGHT` = `true`

Push to `main` (or run the workflow manually from the Actions tab). The build number is the workflow run number, so every upload is unique. Builds show up in TestFlight after Apple finishes processing, usually within 30 minutes.

### Notes

- Never commit the `.p8` key; `.gitignore` blocks it.
- If you list the app in the App Store **Kids** category, Apple requires no third-party ads or analytics. This app has none.
- The workflow uses the `macos-26` runner with the latest stable Xcode, which Apple requires for App Store uploads.
