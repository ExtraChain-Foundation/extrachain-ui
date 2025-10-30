set(SEARCH_PATH "${CMAKE_CURRENT_SOURCE_DIR}/../")
file(GLOB FOLDER_LIST RELATIVE ${SEARCH_PATH} "${SEARCH_PATH}*/")

foreach(FOLDER ${FOLDER_LIST})
    set(FULL_PATH "${SEARCH_PATH}${FOLDER}")

    if(IS_DIRECTORY "${FULL_PATH}" AND ${FOLDER} STREQUAL "extrachain-core")
        message(STATUS "Found [extrachain-core] by path: ${FULL_PATH}")
        set(EXTRACHAIN_CORE ${FULL_PATH} CACHE STRING "Description of extrachain_core.")
    endif()
endforeach()
