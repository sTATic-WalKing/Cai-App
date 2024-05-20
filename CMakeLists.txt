cmake_minimum_required(VERSION 3.16)

project(Cai VERSION 1.2 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTORCC on)

find_package(Qt6 6.5 REQUIRED COMPONENTS Quick QuickControls2 LinguistTools Network)

qt_standard_project_setup(REQUIRES 6.5 I18N_TRANSLATED_LANGUAGES zh)

qt_add_executable(appCai
    Cai.qrc
    main.cpp
    qrsa.h
    qrsa.cpp
)

qt_add_qml_module(appCai
    URI Cai
    QML_FILES Main.qml Furnitures.qml Autos.qml Overview.qml components/List.qml components/Rounded.qml components/Touch.qml components/Popup.qml components/VFit.qml components/DatePicker.qml components/TimePicker.qml components/RoundedFurniture.qml
)

if (ANDROID)
    include(FetchContent)
    FetchContent_Declare(
        android_openssl
        DOWNLOAD_EXTRACT_TIMESTAMP true
        URL https://github.com/KDAB/android_openssl/archive/refs/heads/master.zip
    )
    FetchContent_MakeAvailable(android_openssl)
    include(${android_openssl_SOURCE_DIR}/android_openssl.cmake)
    add_android_openssl_libraries(appCai)
endif()

if (WIN32)
    target_include_directories(appCai PRIVATE D:/Qt/Tools/OpenSSLv3/Win_x64/include)
    target_link_libraries(appCai
        PRIVATE D:/Qt/Tools/OpenSSLv3/Win_x64/lib/libssl.lib
        PRIVATE D:/Qt/Tools/OpenSSLv3/Win_x64/lib/libcrypto.lib
    )
endif()

qt_add_translations(appCai
    RESOURCE_PREFIX /qt/qml/Cai/i18n
    TS_FILE_BASE qml
    TS_FILE_DIR i18n
)
add_dependencies(appCai update_translations)
add_dependencies(appCai release_translations)

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

string(TIMESTAMP COMPILE_TIMESTAMP "%s")
set_property(TARGET appCai PROPERTY QT_ANDROID_VERSION_CODE ${COMPILE_TIMESTAMP})
set_property(TARGET appCai PROPERTY QT_ANDROID_VERSION_NAME ${CMAKE_PROJECT_VERSION})
set_property(TARGET appCai APPEND PROPERTY
    QT_ANDROID_PACKAGE_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/android
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
