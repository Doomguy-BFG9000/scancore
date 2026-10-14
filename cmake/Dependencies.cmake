include(FetchContent)

# lexbor: HTML parser with CSS selectors, used by every scraping adapter.
set(LEXBOR_BUILD_SHARED OFF CACHE BOOL "" FORCE)
set(LEXBOR_BUILD_STATIC ON CACHE BOOL "" FORCE)
set(LEXBOR_BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(LEXBOR_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(LEXBOR_BUILD_UTILS OFF CACHE BOOL "" FORCE)
FetchContent_Declare(lexbor
    GIT_REPOSITORY https://github.com/lexbor/lexbor.git
    GIT_TAG v2.7.0
    GIT_SHALLOW TRUE
    SYSTEM
    EXCLUDE_FROM_ALL)
FetchContent_MakeAvailable(lexbor)
add_library(scancore_lexbor INTERFACE)
target_link_libraries(scancore_lexbor INTERFACE lexbor_static)
target_include_directories(scancore_lexbor SYSTEM INTERFACE ${lexbor_SOURCE_DIR}/source)
target_compile_definitions(scancore_lexbor INTERFACE LEXBOR_STATIC)

# libmpv: optional native video player. Found through pkg-config on Linux and
# macOS, or MPV_DIR (include/ + lib/) on Windows.
set(SCANCORE_HAVE_MPV OFF)
if(SCANCORE_WITH_MPV)
    if(DEFINED ENV{MPV_DIR} OR DEFINED MPV_DIR)
        if(NOT DEFINED MPV_DIR)
            set(MPV_DIR $ENV{MPV_DIR})
        endif()
        find_path(MPV_INCLUDE_DIR mpv/client.h HINTS ${MPV_DIR}/include NO_DEFAULT_PATH)
        find_library(MPV_LIBRARY NAMES mpv libmpv libmpv.dll.a HINTS ${MPV_DIR} ${MPV_DIR}/lib NO_DEFAULT_PATH)
        if(MPV_INCLUDE_DIR AND MPV_LIBRARY)
            add_library(scancore_mpv INTERFACE)
            target_include_directories(scancore_mpv INTERFACE ${MPV_INCLUDE_DIR})
            target_link_libraries(scancore_mpv INTERFACE ${MPV_LIBRARY})
            set(SCANCORE_HAVE_MPV ON)
        endif()
    else()
        find_package(PkgConfig QUIET)
        if(PkgConfig_FOUND)
            pkg_check_modules(MPV QUIET IMPORTED_TARGET mpv)
            if(MPV_FOUND)
                add_library(scancore_mpv INTERFACE)
                target_link_libraries(scancore_mpv INTERFACE PkgConfig::MPV)
                set(SCANCORE_HAVE_MPV ON)
            endif()
        endif()
    endif()
    if(NOT SCANCORE_HAVE_MPV)
        message(WARNING "libmpv not found; native video playback is disabled")
    endif()
endif()
