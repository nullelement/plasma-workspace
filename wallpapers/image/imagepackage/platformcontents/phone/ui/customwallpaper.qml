/*
 *  Copyright 2015 Marco Martin <mart@kde.org>
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  2.010-1301, USA.
 */

import QtQuick 2.0
import Qt.labs.folderlistmodel 2.1
//We need units from it
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.wallpapers.image 2.0 as Wallpaper
import org.kde.kquickcontrolsaddons 2.0
import QtQuick.Controls 2.8 as QQC2

Rectangle {
    id: root
    color: syspal.window
    anchors.fill: parent

    SystemPalette {id: syspal}

    QQC2.ScrollView {
        anchors.fill: parent

        frameVisible: true

        GridView {
            id: customGrid
            model: FolderListModel {
                folder: imageWallpaper.photosPath
                nameFilters: ["*.jpg", "*.png", "*.jpeg"]
                showDirs: false
            }
            currentIndex: -1

            cellWidth: Math.floor(customGrid.width / Math.max(Math.floor(customGrid.width / (PlasmaCore.Units.gridUnit*12)), 3))
            cellHeight: cellWidth / (imageWallpaper.width / imageWallpaper.height)

            anchors.margins: 4
            boundsBehavior: Flickable.DragAndOvershootBounds

            delegate: MouseArea {
                width: customGrid.cellWidth
                height: customGrid.cellHeight

                onClicked: {
                    imageWallpaper.addUsersWallpaper(model.fileURL);
                    customWallpaperLoader.source = "";
                }
                Rectangle {
                    color: "white"
                    anchors {
                        fill: parent
                        margins: PlasmaCore.Units.smallSpacing
                    }
                    Image {
                        anchors {
                            fill: parent
                            margins: PlasmaCore.Units.smallSpacing * 2
                        }
                        source: model.fileURL
                    }
                }
            }
        }
    }
    QQC2.Button {
        anchors {
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
        }
        width: height
        iconName: "go-previous"
        onClicked: customWallpaperLoader.source = ""
    }
}
