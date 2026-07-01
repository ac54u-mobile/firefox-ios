// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import UIKit

/// Legacy translation settings view controller used when the `translationLanguagePicker`
/// feature flag is OFF (Phase 1 / pre-language-picker behavior).
final class TranslationSettingsViewController: SettingsTableViewController {
    let prefs: Prefs
    private let customUrlKey = PrefsKeys.RemoteSettings.remoteSettingsCustomUrl
    private let envKey = PrefsKeys.RemoteSettings.remoteSettingsEnvironment

    init(prefs: Prefs, windowUUID: WindowUUID) {
        self.prefs = prefs
        super.init(style: .grouped, windowUUID: windowUUID)
        self.title = .Settings.Translation.Title
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var theme: Theme {
        themeManager.getCurrentTheme(for: windowUUID)
    }

    override func generateSettings() -> [SettingSection] {
        return [translationSection, serverSection]
    }

    private var translationSection: SettingSection {
        let enableFeatureSwitch = BoolSetting(
            prefs: prefs,
            theme: theme,
            prefKey: PrefsKeys.Settings.translationsFeature,
            defaultValue: true,
            titleText: .Settings.Translation.ToggleTitle
        ) { [weak self] _ in
            guard let self else { return }
            let isEnabled = self.prefs.boolForKey(PrefsKeys.Settings.translationsFeature) ?? true
            store.dispatch(
                TranslationsAction(
                    isTranslationsEnabled: isEnabled,
                    translationConfiguration: TranslationConfiguration(
                        prefs: self.prefs,
                        isUserSettingEnabled: isEnabled
                    ),
                    windowUUID: self.windowUUID,
                    actionType: TranslationsActionType.didTranslationSettingsChange
                )
            )
        }
        return SettingSection(
            title: NSAttributedString(
                string: .Settings.Translation.SectionTitle
            ),
            children: [enableFeatureSwitch]
        )
    }

    private var serverSection: SettingSection {
        let currentURL = prefs.stringForKey(customUrlKey) ?? ""
        let serverSetting = TranslationServerSetting(
            prefs: prefs,
            url: currentURL,
            theme: theme,
            settings: self
        )
        return SettingSection(
            title: NSAttributedString(
                string: "Model Server",
                attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary]
            ),
            children: [serverSetting]
        )
    }
}

private final class TranslationServerSetting: Setting {
    private let prefs: Prefs
    private let customUrlKey = PrefsKeys.RemoteSettings.remoteSettingsCustomUrl
    private let envKey = PrefsKeys.RemoteSettings.remoteSettingsEnvironment
    private weak var settings: SettingsTableViewController?

    override var style: UITableViewCell.CellStyle { .value1 }
    override var accessoryView: UIImageView? {
        guard let theme else { return nil }
        return SettingDisclosureUtility.buildDisclosureIndicator(theme: theme)
    }

    override var status: NSAttributedString? {
        let url = prefs.stringForKey(customUrlKey) ?? ""
        let text = url.isEmpty ? "Not set" : url
        guard let theme else { return nil }
        return NSAttributedString(
            string: text,
            attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textSecondary]
        )
    }

    init(prefs: Prefs, url: String, theme: Theme, settings: SettingsTableViewController) {
        self.prefs = prefs
        self.settings = settings
        super.init(
            title: NSAttributedString(
                string: "Server URL",
                attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary]
            )
        )
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let alert = UIAlertController(
            title: "Translation Model Server",
            message: "Enter the base URL of your reverse proxy.\nExample: http://your-server:81/v1\n\nRestart app after saving.",
            preferredStyle: .alert
        )
        alert.addTextField { textField in
            textField.placeholder = "http://your-server:81/v1"
            textField.text = self.prefs.stringForKey(self.customUrlKey)
            textField.keyboardType = .URL
            textField.autocapitalizationType = .none
            textField.autocorrectionType = .no
        }
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let self, let text = alert.textFields?.first?.text, !text.isEmpty else { return }
            self.prefs.setString(text, forKey: self.customUrlKey)
            self.prefs.setString(RemoteSettingsEnvironment.custom.rawValue, forKey: self.envKey)
            self.settings?.tableView.reloadData()
        })
        alert.addAction(UIAlertAction(title: "Clear", style: .destructive) { [weak self] _ in
            guard let self else { return }
            self.prefs.removeObjectForKey(self.customUrlKey)
            self.prefs.removeObjectForKey(self.envKey)
            self.settings?.tableView.reloadData()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        settings?.present(alert, animated: true)
    }
}
