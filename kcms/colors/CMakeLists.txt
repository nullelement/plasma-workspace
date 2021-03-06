# KI18N Translation Domain for this library
add_definitions(-DTRANSLATION_DOMAIN=\"kcm_colors\")

set(kcm_colors_SRCS
    ../krdb/krdb.cpp
    colors.cpp
    colorsmodel.cpp
    filterproxymodel.cpp
)

kcmutils_generate_module_data(
    kcm_colors_SRCS
    MODULE_DATA_HEADER colorsdata.h
    MODULE_DATA_CLASS_NAME ColorsData
    SETTINGS_HEADERS colorssettings.h
    SETTINGS_CLASSES ColorsSettings
)

# needed for krdb
kconfig_add_kcfg_files(kcm_colors_SRCS colorssettings.kcfgc GENERATE_MOC)

add_library(kcm_colors MODULE ${kcm_colors_SRCS})
target_link_libraries(kcm_colors
    Qt::DBus
    KF5::KCMUtils
    KF5::CoreAddons
    KF5::Declarative
    KF5::GuiAddons
    KF5::I18n
    KF5::KIOCore
    KF5::KIOWidgets
    KF5::NewStuffCore
    KF5::QuickAddons
    KF5::WindowSystem
    PW::KWorkspace
)

if(X11_FOUND)
    target_link_libraries(kcm_colors X11::X11 Qt::X11Extras)
endif()

kcoreaddons_desktop_to_json(kcm_colors "kcm_colors.desktop")

install(FILES colorssettings.kcfg DESTINATION ${KDE_INSTALL_KCFGDIR})
install(FILES kcm_colors.desktop DESTINATION ${KDE_INSTALL_KSERVICES5DIR})
install(TARGETS kcm_colors DESTINATION ${KDE_INSTALL_PLUGINDIR}/kcms)
install(FILES colorschemes.knsrc DESTINATION ${KDE_INSTALL_KNSRCDIR})

kpackage_install_package(package kcm_colors kcms)

add_subdirectory(editor)
