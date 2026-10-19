import QtQuick
import Drift

SettingsSectionCard {
    title: qsTr("Marketplace")
    visible: Market.configured && Market.authenticated

    ThemedLabel {
        width: parent.width
        text: Market.accountName.length > 0
              ? qsTr("Account connected (%1)").arg(Market.accountName)
              : qsTr("Marketplace account connected")
        color: Theme.c.settingsMarketplaceSection.foreground
    }

    ThemedButton {
        text: qsTr("Disconnect")
        variant: "ghost"
        tooltip: qsTr("Unlink the marketplace account from this device")
        onClicked: Market.disconnectAccount()
    }
}
