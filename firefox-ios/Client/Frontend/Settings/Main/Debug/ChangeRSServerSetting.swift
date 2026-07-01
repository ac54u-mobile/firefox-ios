// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Shared

class ChangeRSServerSetting: HiddenSetting {
    private let prefsKey = PrefsKeys.RemoteSettings.remoteSettingsEnvironment
    private let customUrlKey = PrefsKeys.RemoteSettings.remoteSettingsCustomUrl
    private let prefs: Prefs = { return (AppContainer.shared.resolve() as Profile).prefs }()

    override var title: NSAttributedString? {
        guard let theme else { return nil }
        // Not localized for now.
        return NSAttributedString(string: "Remote Settings Server",
                                  attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let currentEnvRaw = prefs.stringForKey(prefsKey) ?? RemoteSettingsEnvironment.prod.rawValue
        let currentCustom = prefs.stringForKey(customUrlKey) ?? ""
        let currentDetail = currentEnvRaw == RemoteSettingsEnvironment.custom.rawValue
            ? "Custom: \(currentCustom)"
            : currentEnvRaw.capitalized
        let message = """
        Current: \(currentDetail)

        Changes take effect on the next app launch.
        """
        let alert = UIAlertController(title: "Remote Settings Server",
                                      message: message,
                                      preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Custom URL", style: .default, handler: { [weak self] _ in
            guard let self else { return }
            let inputAlert = UIAlertController(title: "Custom RS URL", message: nil, preferredStyle: .alert)
            inputAlert.addTextField { textField in
                textField.placeholder = "https://your-mirror.example.com/v1"
                textField.text = self.prefs.stringForKey(self.customUrlKey)
            }
            inputAlert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
                guard let self else { return }
                if let text = inputAlert.textFields?.first?.text, !text.isEmpty {
                    self.prefs.setString(text, forKey: self.customUrlKey)
                    self.prefs.setString(RemoteSettingsEnvironment.custom.rawValue, forKey: self.prefsKey)
                }
            })
            inputAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            navigationController?.present(inputAlert, animated: true)
        }))
        alert.addAction(UIAlertAction(title: "Production V2", style: .default, handler: { [weak self] _ in
            guard let self else { return }
            self.prefs.setString(RemoteSettingsEnvironment.prodV2.rawValue, forKey: self.prefsKey)
        }))
        alert.addAction(UIAlertAction(title: "Staging V2", style: .default, handler: { [weak self] _ in
            guard let self else { return }
            self.prefs.setString(RemoteSettingsEnvironment.stageV2.rawValue, forKey: self.prefsKey)
        }))
        alert.addAction(UIAlertAction(title: "Dev V2", style: .default, handler: { [weak self] _ in
            guard let self else { return }
            self.prefs.setString(RemoteSettingsEnvironment.devV2.rawValue, forKey: self.prefsKey)
        }))
        alert.addAction(UIAlertAction(title: "Production", style: .default, handler: { [weak self] _ in
            guard let self else { return }
            self.prefs.removeObjectForKey(self.prefsKey)
        }))
        alert.addAction(UIAlertAction(title: "Staging", style: .default, handler: { [weak self] _ in
            guard let self else { return }
            self.prefs.setString(RemoteSettingsEnvironment.stage.rawValue, forKey: self.prefsKey)
        }))
        alert.addAction(UIAlertAction(title: "Dev", style: .default, handler: { [weak self] _ in
            guard let self else { return }
            self.prefs.setString(RemoteSettingsEnvironment.dev.rawValue, forKey: self.prefsKey)
        }))
        settings.present(alert, animated: true)
    }
}
