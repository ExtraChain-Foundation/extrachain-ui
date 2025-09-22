set(READ_FROM_CONFIG TRUE)
message(STATUS "READ_FROM_CONFIG - ${READ_FROM_CONFIG}")
if(NOT ${READ_FROM_CONFIG})
    # Define a extrachain_core
    set(EXTRACHAIN_CORE "" CACHE STRING "Description of extrachain_core")
    set(EXTRACHAIN_CLIENT "" CACHE STRING "Description of extrachain_client")

    message(STATUS "START CHECK CMAKE_TOOLCHAIN_FILE - ${CMAKE_TOOLCHAIN_FILE}.")
    if(NOT DEFINED CMAKE_TOOLCHAIN_FILE OR CMAKE_TOOLCHAIN_FILE STREQUAL "")
        message(WARNING "Set path to vcpkg.cmake. <PATH/TO/VCPKG>/scripts/buildsystems/vcpkg.cmake")
        message(FATAL_ERROR "CMAKE_TOOLCHAIN_FILE  must be set.")
    else()
        message(STATUS "CHECK CMAKE_TOOLCHAIN_FILE - done.")
    endif()

    set(EXTRACHAIN_ROOT "" CACHE STRING "Description of root_extrachain.")

    if(NOT DEFINED EXTRACHAIN_ROOT OR EXTRACHAIN_ROOT STREQUAL "")
        # Define a extrachain_core
        set(EXTRACHAIN_CORE "" CACHE STRING "Description of extrachain_core.")
        if(NOT DEFINED EXTRACHAIN_CORE OR EXTRACHAIN_CORE STREQUAL "")
            message(FATAL_ERROR "EXTRACHAIN_CORE must be set.")
        else()
            message(STATUS "EXTRACHAIN_CORE set.")
        endif()

        # Check if the required extrachain_core is set
        if(NOT DEFINED EXTRACHAIN_CLIENT OR EXTRACHAIN_CLIENT STREQUAL "")
            message(FATAL_ERROR "EXTRACHAIN_CLIENT must be set.")
        else()
            message(STATUS "EXTRACHAIN_CLIENT set.")
        endif()

        if(NOT DEFINED EXTRACHAIN_THIRDPARTY OR EXTRACHAIN_THIRDPARTY STREQUAL "")
            message(FATAL_ERROR "EXTRACHAIN_THIRDPARTY  must be set.")
        else()
            message(STATUS "EXTRACHAIN_THIRDPARTY set.")
        endif()
    else()
        #Set EXTRACHAIN_CORE
        message(STATUS "READ_FROM_CONFIG - ${READ_FROM_CONFIG}")
        message(STATUS "START CHECK EXTRACHAIN_CORE.")
        if(NOT DEFINED EXTRACHAIN_CORE OR EXTRACHAIN_CORE STREQUAL "")
            set(EXTRACHAIN_CORE "${EXTRACHAIN_ROOT}/extrachain-core")
            message(STATUS "EXTRACHAIN_CORE path: ${EXTRACHAIN_CORE}")

            if(EXISTS ${EXTRACHAIN_CORE} AND IS_DIRECTORY ${EXTRACHAIN_CORE})
                message(STATUS "EXTRACHAIN_CORE path: ${EXTRACHAIN_CORE}")
            else()
                message(WARNING "EXTRACHAIN_CORE path: ${EXTRACHAIN_CORE}")
                message(FATAL_ERROR "EXTRACHAIN_CORE must be set.")
            endif()
        endif()

        #Set EXTRACHAIN_CLIENT
        message(STATUS "START CHECK EXTRACHAIN_CLIENT.")
        if(NOT DEFINED EXTRACHAIN_CLIENT OR EXTRACHAIN_CLIENT STREQUAL "")
            set(EXTRACHAIN_CLIENT "${EXTRACHAIN_ROOT}/extrachain-ui-client")
            if(EXISTS ${EXTRACHAIN_CLIENT} AND IS_DIRECTORY ${EXTRACHAIN_CLIENT})
                message(STATUS "EXTRACHAIN_CLIENT path: ${EXTRACHAIN_CLIENT}.")
            else()
                message(WARNING "EXTRACHAIN_CLIENT path: ${EXTRACHAIN_CLIENT}")
                message(FATAL_ERROR "EXTRACHAIN_CLIENT must be set.")
            endif()
        endif()

        #Set EXTRACHAIN_THIRDPARTY
        message(STATUS "START CHECK EXTRACHAIN_THIRDPARTY.")
        if(NOT DEFINED EXTRACHAIN_THIRDPARTY OR EXTRACHAIN_THIRDPARTY STREQUAL "")
            set(EXTRACHAIN_THIRDPARTY "${EXTRACHAIN_ROOT}/extrachain-3rdparty")
            if(EXISTS ${EXTRACHAIN_THIRDPARTY} AND IS_DIRECTORY ${EXTRACHAIN_THIRDPARTY})
                message(STATUS "EXTRACHAIN_THIRDPARTY path: ${EXTRACHAIN_THIRDPARTY}.")
            else()
                message(WARNING "EXTRACHAIN_THIRDPARTY path: ${EXTRACHAIN_THIRDPARTY}")
                message(FATAL_ERROR "EXTRACHAIN_THIRDPARTY must be set.")
            endif()
        endif()

    endif()
else()
    function(parse_json_file json_file output_var key)
        file(READ "${json_file}" json_content)

        string(REGEX MATCH "\"${key}\"[ \t]*:[ \t]*\"([^\"]*)\"" _ ${json_content})
        set(${output_var} "${CMAKE_MATCH_1}" PARENT_SCOPE)
    endfunction()

    # Usage example:
    set(JSON_FILE_PATH "${CMAKE_SOURCE_DIR}/config.json")
    parse_json_file(${JSON_FILE_PATH} VCPKG "vcpkg")

    set(CMAKE_TOOLCHAIN_FILE  ${VCPKG}/scripts/buildsystems/vcpkg.cmake)

    parse_json_file(${JSON_FILE_PATH} EXTRACHAIN_ROOT "extrachain_root")

    set(EXTRACHAIN_CORE "${EXTRACHAIN_ROOT}/extrachain-core")
    message(STATUS "START CHECK EXTRACHAIN_CORE.")

    #Set EXTRACHAIN_CLIENT
    # set(EXTRACHAIN_CLIENT "${EXTRACHAIN_ROOT}/extrachain-ui-client")

    message(STATUS "EXTRACHAIN_THIRDPARTY path: ${EXTRACHAIN_THIRDPARTY}.")
    set(EXTRACHAIN_THIRDPARTY "${EXTRACHAIN_ROOT}/extrachain-3rdparty")

    message(STATUS "START CHECK DEPLOY APP.")
    parse_json_file(${JSON_FILE_PATH} DEPLOY_APP "deploy_app")

    # if(APPLE)
    #     message(STATUS "START procesor.")
    #     parse_json_file(${JSON_FILE_PATH} ARCHITECTURE "architecture")
    #     message("ARCHITECTURE: ${ARCHITECTURE}")
    #     if(NOT "${ARCHITECTURE}" STREQUAL "")
    #         if("${ARCHITECTURE}" STREQUAL "m1")
    #             set(VCPKG_TARGET_TRIPLET "arm64-osx")
    #             message("value m1. set VCPKG_TARGET_TRIPLET ${VCPKG_TARGET_TRIPLET}")
    #         elseif("${ARCHITECTURE}" STREQUAL "intel")
    #             set(VCPKG_TARGET_TRIPLET "x64-osx")
    #             message("value intel. set VCPKG_TARGET_TRIPLET ${VCPKG_TARGET_TRIPLET}")
    #         endif()
    #     else()
    #         message("value ARCHITECTURE IS EMPTY")
    #     endif()
    # endif()



endif()
