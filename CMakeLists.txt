cmake_minimum_required(VERSION 3.16)

project(Cai VERSION 1.4)

set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTORCC on)
set(TARGET_NAME appCai)

find_package(Qt6 6.5 REQUIRED COMPONENTS Quick QuickControls2 LinguistTools)

qt_standard_project_setup(REQUIRES 6.5 I18N_TRANSLATED_LANGUAGES zh)

add_compile_definitions(ZXING_READERS)
include_directories(ZXing)
file(GLOB_RECURSE ZXing ZXing/*.h ZXing/libzueci/*.c ZXing/*.cpp)

qt_add_executable(${TARGET_NAME}
    Cai.qrc
    main.cpp

)

qt_add_qml_module(${TARGET_NAME}
    URI Cai
    QML_FILES Main.qml Furnitures.qml Autos.qml Overview.qml components/List.qml components/Rounded.qml components/Touch.qml components/Popup.qml components/VFit.qml components/DatePicker.qml components/TimePicker.qml components/RoundedFurniture.qml
    SOURCES ${ZXing} qrsa.h qrsa.cpp qqrcode.h qqrcode.cpp
)


if (ANDROID)
    find_package(Qt6 REQUIRED COMPONENTS Network)
    target_link_libraries(${TARGET_NAME} PRIVATE Qt6::Network)

    if(CMAKE_BUILD_TYPE STREQUAL "Debug")
        set(SSL_ROOT_PATH D:/.projects/Cai/android_openssl/no-asm)
    else()
        set(SSL_ROOT_PATH D:/.projects/Cai/android_openssl)
    endif()
    set(OPENSSL_ROOT_DIR ${SSL_ROOT_PATH}/ssl_3/${CMAKE_ANDROID_ARCH_ABI})
    list(APPEND android_extra_libs
        ${SSL_ROOT_PATH}/ssl_3/${CMAKE_ANDROID_ARCH_ABI}/libcrypto_3.so
        ${SSL_ROOT_PATH}/ssl_3/${CMAKE_ANDROID_ARCH_ABI}/libssl_3.so)
    set_target_properties(${TARGET_NAME} PROPERTIES QT_ANDROID_EXTRA_LIBS "${android_extra_libs}")

    target_include_directories(${TARGET_NAME} PRIVATE ${SSL_ROOT_PATH}/ssl_3/include)
    target_link_libraries(${TARGET_NAME}
        PRIVATE ${SSL_ROOT_PATH}/ssl_3/${CMAKE_ANDROID_ARCH_ABI}/libcrypto_3.so
        PRIVATE ${SSL_ROOT_PATH}/ssl_3/${CMAKE_ANDROID_ARCH_ABI}/libssl_3.so
    )
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
