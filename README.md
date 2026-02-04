# Kurdish Words Uploader

A Flutter desktop application for managing and uploading Kurdish words to Arweave for permanent, immutable storage.

## Features

- **Manual Entry**: Enter Kurdish words one by one with dynamic fields for:
  - Word (required)
  - Pronunciation (optional)
  - Multiple meanings in different languages (e.g., English, Persian, Arabic)
  - Multiple dialect variations (e.g., Kurmanji, Sorani)

- **JSON Import**: Import words from a JSON file (single word or array of words)

- **JSON Preview**: Preview the formatted JSON before uploading

- **Arweave Upload**: Upload data to Arweave blockchain for permanent storage
  - Immutable and tamper-proof
  - Transaction ID and view link provided after upload
  - Automatic wallet integration (JWK format)

## Prerequisites

- Flutter SDK (3.24.0 or higher)
- Dart SDK (3.9.2 or higher)
- Windows/macOS/Linux for desktop support

## Download

### Latest Release

Download the latest release from [GitHub Releases](https://github.com/YOUR_USERNAME/kurdinal/releases):

- **Windows**: Download `kurdinal-windows-*.zip`, extract and run `kurdinal.exe`
- **macOS**: Download `kurdinal-macos-*.tar.gz`, extract and move `kurdinal.app` to Applications
- **Linux**: Download `kurdinal-linux-*.tar.gz`, extract and run `./kurdinal`

## Installation (Development)

1. Clone the repository:
```bash
git clone <repository-url>
cd kurdinal
```

2. Install dependencies:
```bash
flutter pub get
```

3. Generate JSON serialization code:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

4. Run the app:
```bash
flutter run -d windows  # For Windows
# or
flutter run -d macos    # For macOS
# or
flutter run -d linux    # For Linux
```

## Usage

### Manual Entry Mode

1. Launch the app and click "Manual Entry"
2. Enter the Kurdish word (required)
3. Optionally enter pronunciation
4. Click "+" to add meaning fields:
   - Enter language code (e.g., "en", "fa", "ar")
   - Enter the meaning in that language
5. Click "+" to add dialect fields:
   - Enter dialect name (e.g., "kurmanji", "sorani")
   - Enter the dialect variation
6. Click "Save Word" to add to the list
7. Click the preview icon to see all words as JSON
8. Click "Upload to Arweave" to proceed

### JSON Import Mode

1. Click "Import JSON" from the home screen
2. Click "Select JSON File" and choose a JSON file
3. The file should be in one of these formats:

**Single word:**
```json
{
  "word": "example",
  "meanings": {
    "en": "meaning in English",
    "fa": "معنی به فارسی"
  },
  "pronunciation": "pronunciation",
  "dialects": {
    "kurmanji": "variation 1",
    "sorani": "variation 2"
  }
}
```

**Array of words:**
```json
[
  {
    "word": "word1",
    "meanings": {"en": "meaning1"},
    "pronunciation": "pron1",
    "dialects": {}
  },
  {
    "word": "word2",
    "meanings": {"en": "meaning2"},
    "pronunciation": "pron2",
    "dialects": {}
  }
]
```

### Uploading to Arweave

1. After previewing your words, click "Upload to Arweave"
2. Click "Load Wallet (JWK)" and select your Arweave wallet file
   - You can create a wallet at https://www.arweave.org/
   - Save the wallet as a JSON file (JWK format)
3. Once the wallet is loaded, click "Upload to Arweave"
4. Wait for the transaction to complete
5. You'll receive:
   - Transaction ID
   - View URL (e.g., https://arweave.net/{transaction-id})

**Important Notes:**
- Once uploaded, data is **permanent and immutable** - it cannot be edited or deleted
- You need AR tokens in your wallet to pay for uploads (small data may be free)
- Wallet keys are only loaded in memory during the session for security

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/
│   └── kurdish_word.dart    # Word model with JSON serialization
├── providers/
│   ├── words_provider.dart  # Riverpod state for words list
│   └── arweave_provider.dart # Arweave service provider
├── screens/
│   ├── home_screen.dart     # Home screen with mode selection
│   ├── form_screen.dart     # Manual entry form
│   ├── import_screen.dart   # JSON import screen
│   └── upload_screen.dart   # Arweave upload screen
├── services/
│   └── arweave_service.dart # Arweave integration service
└── widgets/
    └── preview_dialog.dart  # JSON preview dialog
```

## Dependencies

- `flutter_riverpod`: State management
- `file_picker`: File selection for JSON import and wallet loading
- `json_annotation` & `json_serializable`: JSON serialization
- `crypto`: Cryptographic functions
- `pointycastle`: RSA signing for Arweave transactions
- `http`: HTTP requests to Arweave API

## Arweave Integration

The app uses the Arweave REST API directly for maximum compatibility. The implementation includes:

- Wallet loading from JWK files
- Transaction creation with proper tags
- RSA-PSS signing (using pointycastle)
- Transaction posting to Arweave network

**Note**: For production use, consider integrating a dedicated Arweave SDK such as:
- `arweave-dart` from GitHub (CDDelta/arweave-dart)
- Or other community-maintained Arweave packages

## Security

- Wallet keys are never stored permanently
- Keys are only loaded in memory during the session
- Wallet is cleared when the app closes
- No sensitive data is logged

## Troubleshooting

### Build Errors

If you encounter build errors:

1. Run `flutter clean`
2. Run `flutter pub get`
3. Run `flutter pub run build_runner build --delete-conflicting-outputs`
4. Try building again

### Arweave Upload Issues

- Ensure your wallet has sufficient AR tokens
- Check your internet connection
- Verify the wallet file is a valid JWK format
- For large files, ensure you have enough AR for the transaction fee

### JSON Import Errors

- Ensure the JSON file is valid
- Check that all required fields are present
- Verify the structure matches the expected format

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## License

This project is open source and available for use.

## Acknowledgments

- Built with Flutter
- Uses Arweave for permanent storage
- Material Design for UI
