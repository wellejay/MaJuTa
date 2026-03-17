import Foundation

/// Returns the localized string for the current in-app language.
/// Arabic is the development language — keys ARE the Arabic strings.
/// For English, looks up translations in en.lproj/Localizable.strings.
///
/// Usage: Text(L("العنوان بالعربي"))
///        .navigationTitle(L("القروض"))
func L(_ key: String) -> String {
    let lang = UserDefaults.standard.string(forKey: "appLanguage") ?? "ar"
    guard lang != "ar" else { return key }
    guard let path = Bundle.main.path(forResource: lang, ofType: "lproj"),
          let bundle = Bundle(path: path) else { return key }
    let translation = bundle.localizedString(forKey: key, value: key, table: nil)
    return translation
}
