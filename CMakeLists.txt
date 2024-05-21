cmake_minimum_required(VERSION 3.16)

project(Cai VERSION 1.3 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTORCC on)
set(TARGET_NAME appCai)

find_package(Qt6 6.5 REQUIRED COMPONENTS Quick QuickControls2 LinguistTools Network)

qt_standard_project_setup(REQUIRES 6.5 I18N_TRANSLATED_LANGUAGES zh)

qt_add_executable(${TARGET_NAME}
    Cai.qrc
    main.cpp
    qrsa.h
    qrsa.cpp
    qqrcode.h
    qqrcode.cpp
)

qt_add_qml_module(${TARGET_NAME}
    URI Cai
    QML_FILES Main.qml Furnitures.qml Autos.qml Overview.qml components/List.qml components/Rounded.qml components/Touch.qml components/Popup.qml components/VFit.qml components/DatePicker.qml components/TimePicker.qml components/RoundedFurniture.qml
    SOURCES include/DynamsoftBarcodeReader.h include/DynamsoftCommon.h
)

include_directories("${PROJECT_SOURCE_DIR}/include/")
# Platform-specific configurations
if(WIN32)
    if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
        target_link_libraries(${TARGET_NAME} PRIVATE "${PROJECT_SOURCE_DIR}/libs/windows/DynamsoftBarcodeReaderx64.dll")
    else() # Assuming MSVC or other non-GNU compilers
        target_link_libraries(${TARGET_NAME} PRIVATE "DBRx64")
    endif()

    # Copy DLLs to build directory after build
    add_custom_command(TARGET ${TARGET_NAME} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_directory
        "${PROJECT_SOURCE_DIR}/libs/windows/"
        $<TARGET_FILE_DIR:${TARGET_NAME}>)
elseif(ANDROID)
    add_library(native-lib SHARED IMPORTED)
    set_target_properties(native-lib PROPERTIES IMPORTED_LOCATION "${PROJECT_SOURCE_DIR}/libs/android/libDynamsoftBarcodeReaderAndroid.so")
    target_link_libraries(${TARGET_NAME} PRIVATE native-lib)
elseif(APPLE)
    set_target_properties(${TARGET_NAME} PROPERTIES
        XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY "iPhone Developer"
        MACOSX_BUNDLE TRUE
        XCODE_ATTRIBUTE_LD_RUNPATH_SEARCH_PATHS "@executable_path/Frameworks"
    )

    # target_link_libraries(${TARGET_NAME} PRIVATE "${PROJECT_SOURCE_DIR}/libs/ios/libcryptoarm64.a" "${PROJECT_SOURCE_DIR}/libs/ios/libsslarm64.a" "${PROJECT_SOURCE_DIR}/libs/ios/libdbrarm64.a")
    target_link_libraries(${TARGET_NAME} PRIVATE "${PROJECT_SOURCE_DIR}/libs/ios/bridge.framework/bridge" PUBLIC "${PROJECT_SOURCE_DIR}/libs/ios/DynamsoftBarcodeReader.framework/DynamsoftBarcodeReader")
    # target_link_libraries(${TARGET_NAME} PRIVATE "${PROJECT_SOURCE_DIR}/libs/ios/libBridgeProject.dylib" PUBLIC "${PROJECT_SOURCE_DIR}/libs/ios/DynamsoftBarcodeReader.framework/DynamsoftBarcodeReader")

    # System frameworks
    find_library(UIKIT_FRAMEWORK UIKit)
    if(NOT UIKIT_FRAMEWORK)
        message(FATAL_ERROR "UIKit framework not found")
    endif()

    target_link_libraries(${TARGET_NAME} PRIVATE "${UIKIT_FRAMEWORK}")

    add_custom_command(TARGET ${TARGET_NAME} POST_BUILD
        # COMMAND ${CMAKE_COMMAND} -E make_directory "$<TARGET_FILE_DIR:${TARGET_NAME}>/Frameworks/"
        COMMAND ${CMAKE_COMMAND} -E copy_directory
        "${PROJECT_SOURCE_DIR}/libs/ios/DynamsoftBarcodeReader.framework"
        "$<TARGET_FILE_DIR:${TARGET_NAME}>/Frameworks/DynamsoftBarcodeReader.framework"
        COMMAND ls "$<TARGET_FILE_DIR:${TARGET_NAME}>/Frameworks/DynamsoftBarcodeReader.framework"
    )

    add_custom_command(TARGET ${TARGET_NAME} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_directory
        "${PROJECT_SOURCE_DIR}/libs/ios/bridge.framework"
        "$<TARGET_FILE_DIR:${TARGET_NAME}>/Frameworks/bridge.framework"
    )
endif()

if (ANDROID)
    include(FetchContent)
    FetchContent_Declare(
        android_openssl
        DOWNLOAD_EXTRACT_TIMESTAMP true
        URL https://github.com/KDAB/android_openssl/archive/refs/heads/master.zip
    )
    FetchContent_MakeAvailable(android_openssl)
    include(${android_openssl_SOURCE_DIR}/android_openssl.cmake)
    add_android_openssl_libraries(${TARGET_NAME})
elseif (WIN32)
    target_include_directories(${TARGET_NAME} PRIVATE D:/Qt/Tools/OpenSSLv3/Win_x64/include)
    target_link_libraries(${TARGET_NAME}
        PRIVATE D:/Qt/Tools/OpenSSLv3/Win_x64/lib/libssl.lib
        PRIVATE D:/Qt/Tools/OpenSSLv3/Win_x64/lib/libcrypto.lib
    )
endif()

qt_add_translations(${TARGET_NAME}
    RESOURCE_PREFIX /qt/qml/Cai/i18n
    TS_FILE_BASE qml
    TS_FILE_DIR i18n
)
add_dependencies(${TARGET_NAME} update_translations)
add_dependencies(${TARGET_NAME} release_translations)

# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(${TARGET_NAME} PROPERTIES
#    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.appCai
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

string(TIMESTAMP COMPILE_TIMESTAMP "%s")
set_property(TARGET ${TARGET_NAME} PROPERTY QT_ANDROID_VERSION_CODE ${COMPILE_TIMESTAMP})
set_property(TARGET ${TARGET_NAME} PROPERTY QT_ANDROID_VERSION_NAME ${CMAKE_PROJECT_VERSION})
set_property(TARGET ${TARGET_NAME} APPEND PROPERTY
    QT_ANDROID_PACKAGE_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/android
)

target_link_libraries(${TARGET_NAME}
    PRIVATE Qt6::Quick
    PRIVATE Qt6::QuickControls2
)

include(GNUInstallDirs)
install(TARGETS ${TARGET_NAME}
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
