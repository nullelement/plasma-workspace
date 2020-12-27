/*
 * Copyright 2018 Kai Uwe Broulik <kde@privat.broulik.de>
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
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.7
import QtQuick.Layouts 1.1
import QtQuick.Window 2.2
import QtQuick.Dialogs 1.0 as QtDialogs
import QtQuick.Controls 2.3 as QtControls
import org.kde.kirigami 2.4 as Kirigami
import org.kde.kquickcontrolsaddons 2.0 as KQCAddons
import org.kde.newstuff 1.62 as NewStuff
import org.kde.kcm 1.3 as KCM

import org.kde.private.kcms.icons 1.0 as Private

KCM.GridViewKCM {
    id: root
    KCM.ConfigModule.quickHelp: i18n("This module allows you to choose the icons for your desktop.")

    view.model: kcm.iconsModel
    view.currentIndex: kcm.pluginIndex(kcm.iconsSettings.theme)
    enabled: !kcm.downloadingFile

    KCM.SettingStateBinding {
        configObject: kcm.iconsSettings
        settingName: "Theme"
    }

    DropArea {
        enabled: view.enabled
        anchors.fill: parent
        onEntered: {
            if (!drag.hasUrls) {
                drag.accepted = false;
            }
        }
        onDropped: kcm.installThemeFromFile(drop.urls[0])
    }

    view.delegate: KCM.GridDelegate {
        id: delegate

        text: model.display
        toolTip: model.description

        thumbnailAvailable: typeof thumbFlow.previews === "undefined" || thumbFlow.previews.length > 0
        thumbnail: MouseArea {
            id: thumbArea

            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            hoverEnabled: true
            clip: thumbFlow.y < 0

            opacity: model.pendingDeletion ? 0.3 : 1
            Behavior on opacity {
                NumberAnimation { duration: Kirigami.Units.longDuration }
            }

            Timer {
                interval: 1000
                repeat: true
                running: thumbArea.containsMouse
                onRunningChanged: {
                    if (!running) {
                        thumbFlow.currentPage = 0;
                    }
                }
                onTriggered: {
                    if (!thumbFlow.allPreviesLoaded) {
                        thumbFlow.loadPreviews(-1 /*no limit*/);
                        thumbFlow.allPreviesLoaded = true;
                    }

                    ++thumbFlow.currentPage;
                    if (thumbFlow.currentPage >= thumbFlow.pageCount) {
                        stop();
                    }
                }
            }

            Flow {
                id: thumbFlow

                // undefined is "didn't load preview yet"
                // empty array is "no preview available"
                property var previews
                // initially we only load 6 and when the animation starts we'll load the rest
                property bool allPreviesLoaded: false

                property int currentPage
                readonly property int pageCount: Math.ceil(thumbRepeater.count / (thumbFlow.columns * thumbFlow.rows))

                readonly property int iconWidth: Math.floor(thumbArea.width / thumbFlow.columns)
                readonly property int iconHeight: Math.floor(thumbArea.height / thumbFlow.rows)

                readonly property int columns: 3
                readonly property int rows: 2

                function loadPreviews(limit) {
                    previews = kcm.previewIcons(model.themeName, Math.min(thumbFlow.iconWidth, thumbFlow.iconHeight), Screen.devicePixelRatio, limit);
                }

                width: parent.width
                y: -currentPage * iconHeight * rows

                Behavior on y {
                    NumberAnimation { duration: Kirigami.Units.longDuration }
                }

                Repeater {
                    id: thumbRepeater
                    model: thumbFlow.previews

                    Item {
                        width: thumbFlow.iconWidth
                        height: thumbFlow.iconHeight

                        KQCAddons.QPixmapItem {
                            anchors.centerIn: parent
                            width: Math.min(parent.width, nativeWidth)
                            height: Math.min(parent.height, nativeHeight)
                            // load on demand and avoid leaking a tiny corner of the icon
                            pixmap: thumbFlow.y < 0 || index < (thumbFlow.columns * thumbFlow.rows) ? modelData : undefined
                            smooth: true
                            fillMode: KQCAddons.QPixmapItem.PreserveAspectFit
                        }
                    }
                }

                Component.onCompleted: {
                    // avoid reloading it when icon sizes or dpr changes on startup
                    Qt.callLater(function() {
                        // We show 6 icons initially (3x2 grid), only load those
                        thumbFlow.loadPreviews(6 /*limit*/);
                    });
                }
            }
        }

        actions: [
            Kirigami.Action {
                iconName: "edit-delete"
                tooltip: i18n("Remove Icon Theme")
                enabled: model.removable
                visible: !model.pendingDeletion
                onTriggered: model.pendingDeletion = true
            },
            Kirigami.Action {
                iconName: "edit-undo"
                tooltip: i18n("Restore Icon Theme")
                visible: model.pendingDeletion
                onTriggered: model.pendingDeletion = false
            }
        ]
        onClicked: {
            if (!model.pendingDeletion) {
                kcm.iconsSettings.theme = model.themeName;
            }
            view.forceActiveFocus();
        }
    }

    footer: ColumnLayout {
        Kirigami.InlineMessage {
            id: infoLabel
            Layout.fillWidth: true

            showCloseButton: true

            Connections {
                target: kcm
                function onShowSuccessMessage(message) {
                    infoLabel.type = Kirigami.MessageType.Positive;
                    infoLabel.text = message;
                    infoLabel.visible = true;
                }
                function onShowErrorMessage(message) {
                    infoLabel.type = Kirigami.MessageType.Error;
                    infoLabel.text = message;
                    infoLabel.visible = true;
                }
            }
        }

        RowLayout {
            id: progressRow
            visible: false

            QtControls.BusyIndicator {
                id: progressBusy
            }

            QtControls.Label {
                id: progressLabel
                Layout.fillWidth: true
                textFormat: Text.PlainText
                wrapMode: Text.WordWrap
            }

            Connections {
                target: kcm
                onShowProgress: {
                    progressLabel.text = message;
                    progressBusy.running = true;
                    progressRow.visible = true;
                }
                onHideProgress: {
                    progressBusy.running = false;
                    progressRow.visible = false;
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true

            QtControls.Button {
                id: iconSizesButton
                text: i18n("Configure Icon Sizes")
                icon.name: "transform-scale" // proper icon?
                checkable: true
                checked: iconSizePopupLoader.item && iconSizePopupLoader.item.opened
                onClicked: {
                    iconSizePopupLoader.active = true;
                    iconSizePopupLoader.item.open();
                }
            }

            Item {
                Layout.fillWidth: true
            }

            QtControls.Button {
                id: installFromFileButton
                enabled: root.view.enabled
                text: i18n("Install from File...")
                icon.name: "document-import"
                onClicked: fileDialogLoader.active = true
            }

            NewStuff.Button {
                id: newStuffButton
                enabled: root.view.enabled
                text: i18n("Get New Icons...")
                configFile: "icons.knsrc"
                viewMode: NewStuff.Page.ViewMode.Preview
                Connections {
                    target: newStuffButton.engine.engine
                    function onSignalEntryEvent(entry, event) {
                        kcm.ghnsEntriesChanged();
                    }
                }
            }
        }
    }

    Loader {
        id: iconSizePopupLoader
        active: false
        sourceComponent: IconSizePopup {
            parent: iconSizesButton
            y: -height
        }
    }

    Loader {
        id: fileDialogLoader
        active: false
        sourceComponent: QtDialogs.FileDialog {
            title: i18n("Open Theme")
            folder: shortcuts.home
            nameFilters: [ i18n("Theme Files (*.tar.gz *.tar.bz2)") ]
            Component.onCompleted: open()
            onAccepted: {
                kcm.installThemeFromFile(fileUrls[0])
                fileDialogLoader.active = false
            }
            onRejected: {
                fileDialogLoader.active = false
            }
        }
    }
}
