function(deploy_macos)
    if(DEFINED DEPLOY_APP)
        message(STATUS "DEPLOY_APP: ${DEPLOY_APP} ")
        message(STATUS "MACDEPLOYQT_EXECUTABLE: ${MACDEPLOYQT_EXECUTABLE}")
        if(DEPLOY_APP)
                message(STATUS "Start deploy.")

                set(POST_BUILD_SCRIPT "${CMAKE_SOURCE_DIR}/scripts/post_build.sh")
                set(RaccoonApp "${CMAKE_BINARY_DIR}/${PROJECT_NAME}.app")

                add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
                    COMMAND ${MACDEPLOYQT_EXECUTABLE} ${RaccoonApp} -qmldir=${CMAKE_SOURCE_DIR}/UI
                    COMMENT "Running macdeployqt on the built application."
                )

                if(NOT DEFINED SIGNING_IDENTITY)
                    message(WARNING "SIGNING_IDENTITY not defined. Application will not be packed.")
                else()
                    message(STATUS "PACKING STARTED...")
                    add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
                        COMMAND chmod +x ${POST_BUILD_SCRIPT}
                        COMMENT "Make post-build script executable."
                    )
                    add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
                        COMMAND ${POST_BUILD_SCRIPT} ${RaccoonApp} ${SIGNING_IDENTITY}
                        COMMENT "Running post-build script"
                    )
                endif()
        endif()
    endif()
endfunction()
