// Copyright SIX DAY LLC. All rights reserved.

import Foundation

enum KeystoreError: LocalizedError {
    case failedToDeleteAccount
    case failedToDecryptKey
    case failedToImport(Error)
    case duplicateAccount
    case failedToSignTransaction
    case failedToUpdatePassword
    case failedToCreateWallet
    case failedToImportPrivateKey
    case failedToParseJSON
    case accountNotFound
    case failedToSignMessage
    case failedToExportPrivateKey
    case failedToExportMnemonics

    var errorDescription: String? {
        switch self {
        case .failedToDeleteAccount:
            return NSLocalizedString("failed.to.delete.account", value: "Failed to delete account", comment: "")
        case .failedToDecryptKey:
            return NSLocalizedString("could.not.decrypt.key.with.given.passphrase", value: "Could not decrypt key with given passphrase", comment: "")
        case .failedToImport(let error):
            let general = NSLocalizedString("can.not.import.your.wallet", value: "Can not import your wallet", comment: "")
            let errorString = NSLocalizedString(error.localizedDescription.lowercased(), value: error.localizedDescription, comment: "")
            return "\(general) \(errorString)"
        case .duplicateAccount:
            return NSLocalizedString("you.already.added.this.address.to.wallets", value: "You already added this address to wallets", comment: "")
        case .failedToSignTransaction:
            return NSLocalizedString("failed.to.sign.transaction", value: "Failed to sign transaction", comment: "")
        case .failedToUpdatePassword:
            return NSLocalizedString("failed.to.update.password", value: "Failed to update password", comment: "")
        case .failedToCreateWallet:
            return NSLocalizedString("failed.to.create.wallet", value: "Failed to create wallet", comment: "")
        case .failedToImportPrivateKey:
            return NSLocalizedString("failed.to.import.private.key", value: "Failed to import private key", comment: "")
        case .failedToParseJSON:
            return NSLocalizedString("failed.to.parse.key.json", value: "Failed to parse key JSON", comment: "")
        case .accountNotFound:
            return NSLocalizedString("account.not.found", value: "Account not found", comment: "")
        case .failedToSignMessage:
            return NSLocalizedString("failed.to.sign.message", value: "Failed to sign message", comment: "")
        case .failedToExportPrivateKey:
            return NSLocalizedString("failed.to.export.private.key", value: "Failed to export private key", comment: "")
        case .failedToExportMnemonics:
            return NSLocalizedString("failed.to.export.mnemonics", value: "Failed to export mnemonics", comment: "")
        }
    }
}
