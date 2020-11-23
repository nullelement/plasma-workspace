/*
 * Copyright 2013 Kai Uwe Broulik <kde@privat.broulik.de>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License or (at your option) version 3 or any later version
 * accepted by the membership of KDE e.V. (or its successor approved
 * by the membership of KDE e.V.), which shall act as a proxy
 * defined in Section 14 of version 3 of the license.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>
 */

import QtQuick 2.12
import QtQuick.Controls 2.8 as QQC2
import QtQuick.Layouts 1.0
import QtQuick.Dialogs 1.1

import org.kde.kquickcontrolsaddons 2.0 // For kcmshell
import org.kde.plasma.private.digitalclock 1.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.kirigami 2.14 as Kirigami

ColumnLayout {
    id: timeZonesPage

    property alias cfg_selectedTimeZones: timeZones.selectedTimeZones

    TimeZoneModel {

        id: timeZones
        onSelectedTimeZonesChanged: {
            if (selectedTimeZones.length === 0) {
                // Don't let the user remove all time zones
                messageWidget.visible = true;
                timeZones.selectLocalTimeZone();
            }
        }
    }

    QQC2.ScrollView {
        Layout.fillWidth: true
        Layout.preferredHeight: Kirigami.Units.gridUnit * 19
        Component.onCompleted: background.visible = true // enable border

        ListView {
            id: configuredTimezoneList
            clip: true // Avoid visual glitches
            focus: true // keyboard navigation
            activeFocusOnTab: true // keyboard navigation

            model: TimeZoneFilterProxy {
                sourceModel: timeZones
                onlyShowChecked: true
            }

            // Using a hand-rolled delegate because Kirigami.BasicListItem doesn't
            // support being given extra items to display on the end
            delegate: Kirigami.AbstractListItem {
                width: configuredTimezoneList.width
                // Don't need a highlight effect since the list item does
                // nothing when clicked
                activeBackgroundColor: "transparent"
                contentItem: RowLayout {
                    QQC2.RadioButton {
                        visible: configuredTimezoneList.count > 1
                        checked: plasmoid.configuration.lastSelectedTimezone === model.timeZoneId
                        onToggled: plasmoid.configuration.lastSelectedTimezone = model.timeZoneId
                    }
                    ColumnLayout {
                        Layout.minimumHeight: Kirigami.Units.iconSizes.large
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        QQC2.Label {
                            Layout.fillWidth: true
                            text: model.city
                            elide: Text.ElideRight
                        }
                        QQC2.Label {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignTop
                            text: plasmoid.configuration.lastSelectedTimezone === model.timeZoneId && configuredTimezoneList.count > 1 ? "Clock is currently using this time zone" : ""
                            elide: Text.ElideRight
                            font: Kirigami.Theme.smallFont
                            opacity: 0.7
                            visible: text.length > 0
                        }
                    }
                    QQC2.Button {
                        visible: model.isLocalTimeZone && KCMShell.authorize("clock.desktop").length > 0
                        text: i18n("Switch Local Time Zone...")
                        icon.name: "preferences-system-time"
                        onClicked: KCMShell.openSystemSettings("clock")
                    }
                    QQC2.Button {
                        visible: !model.isLocalTimeZone && configuredTimezoneList.count > 1
                        icon.name: "edit-delete"
                        onClicked: model.checked = false;
                        QQC2.ToolTip {
                            text: i18n("Remove this time zone")
                        }
                    }
                }
            }

            section {
                property: "isLocalTimeZone"
                delegate: Kirigami.ListSectionHeader {
                    label: section == "true" ? i18n("System's Local Time Zone") : i18n("Additional Time Zones")
                }
            }

            Kirigami.PlaceholderMessage {
                visible: configuredTimezoneList.count === 1
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    bottom: parent.bottom
                    bottomMargin: Kirigami.Units.gridUnit * 7
                }
                width: parent.width - (Kirigami.Units.largeSpacing * 12)
                text: i18n("Add more time zones to display all of them in the applet's pop-up, or use one of them for the clock itself")
            }
        }
    }

    QQC2.Button {
        Layout.alignment: Qt.AlignLeft // Explicitly set so it gets reversed for LTR mode
        text: i18n("Add Time Zones...")
        icon.name: "list-add"
        onClicked: timezoneSheet.open()
    }

    QQC2.Label {
        visible: configuredTimezoneList.count > 1
        Layout.fillWidth: true
        Layout.margins: Kirigami.Units.largeSpacing * 2
        text: i18n("Note that using a different time zone for the clock does not change the systemwide local time zone. When you travel, switch the local time zone instead.")
        wrapMode: Text.Wrap
    }

    Item {
        // Tighten up the layout
        Layout.fillHeight: true
    }

    Kirigami.OverlaySheet {
        id: timezoneSheet

        onSheetOpenChanged: {
            filter.text = "";
            messageWidget.visible = false;
            if (sheetOpen) {
                filter.forceActiveFocus()
            }
        }

        // Need to manually set the parent when using this in a Plasma config dialog
        parent: timeZonesPage.parent

        // It interferes with the search field in the header
        showCloseButton: false

        header: ColumnLayout {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 25

            Kirigami.Heading {
                Layout.fillWidth: true
                text: i18n("Add More Timezones")
                wrapMode: Text.Wrap
            }
            Kirigami.SearchField {
                id: filter
                Layout.fillWidth: true
            }
            Kirigami.InlineMessage {
                id: messageWidget
                Layout.fillWidth: true
                type: Kirigami.MessageType.Warning
                text: i18n("At least one time zone needs to be enabled. Your local timezone was enabled automatically.")
                showCloseButton: true
            }
        }

        footer: QQC2.DialogButtonBox {
            standardButtons: QQC2.DialogButtonBox.Ok
            onAccepted: timezoneSheet.close()
        }

        ListView {
            id: listView
            focus: true // keyboard navigation
            activeFocusOnTab: true // keyboard navigation
            implicitWidth: Kirigami.Units.gridUnit * 25

            model: TimeZoneFilterProxy {
                sourceModel: timeZones
                filterString: filter.text
            }

            delegate: QQC2.CheckDelegate {
                id: checkbox
                width: listView.width
                focus: true // keyboard navigation
                text: !city || city.indexOf("UTC") === 0 ? comment : comment ? i18n("%1, %2 (%3)", city, region, comment) : i18n("%1, %2", city, region)
                checked: model.checked
                onToggled: {
                    model.checked = checkbox.checked
                    listView.currentIndex = index // highlight
                    listView.forceActiveFocus() // keyboard navigation
                }
                highlighted: ListView.isCurrentItem
            }
        }
    }
}
