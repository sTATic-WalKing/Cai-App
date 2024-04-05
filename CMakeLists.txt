﻿cmake_minimum_required(VERSION 3.16)

project(Cai VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTORCC on)

find_package(Qt6 6.5 REQUIRED COMPONENTS Quick QuickControls2 LinguistTools)

qt_standard_project_setup(REQUIRES 6.5 I18N_TRANSLATED_LANGUAGES zh)

qt_add_executable(appCai
    Cai.qrc
    main.cpp
)

qt_add_qml_module(appCai
    URI Cai
    QML_FILES Main.qml Furnitures.qml Views.qml Autos.qml
)

qt_add_translations(appCai
    RESOURCE_PREFIX /qt/qml/Cai/i18n
    TS_FILE_BASE qml
    TS_FILE_DIR i18n
    SOURCE_TARGETS appCai
)

# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(appCai PROPERTIES
#    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.appCai
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appCai
    PRIVATE Qt6::Quick
    PRIVATE Qt6::QuickControls2
)

include(GNUInstallDirs)
install(TARGETS appCai
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)