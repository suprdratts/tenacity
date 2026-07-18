# This CPack script is invoked to build the Inno Setup installer for Tenacity.
# It requires CPACK_EXTERNAL_ENABLE_STAGING to be set, and you must check for
# the Inno Setup compiler yourself via find_program() and pass it to
# CPACK_TENACITY_INNO_SETUP_COMPILER.
#
# Internal variables:
#   * BUILD_DIR - should be set to CMAKE_BINARY_DIR by the caller
#   * OUTPUT_DIR - directory, where installer will be built
#
# Require variables:
#   * CPACK_TENACITY_INNO_SETUP_COMPILER - The INNO_SETUP compiler executable
#   * CPACK_TENACITY_INNO_SETUP_BUILD_CONFIG - The current build config if
#     using a single-config generator. For multi-config generators, the script
#     sets this to CPACK_BUILD_CONFIG.
#
# Optional parameters:
#   * CPACK_TENACITY_INNO_SETUP_SIGN - Whether or not to sign the installer.
#     * CPACK_TENACITY_INNO_SETUP_CERTIFICATE - Path to PFX file. If not
#       present, env:WINDOWS_CERTIFICATE will be used.
#     * CPACK_TENACITY_INNO_SETUP_CERTIFICATE_PASSWORD - Password for the PFX
#       file. If not present, env:WINDOWS_CERTIFICATE_PASSWORD will be used.
#   * CPACK_TENACITY_INNO_SETUP_EMBED_MANUAL - Whether or not to embed a fresh
#     copy of the manual.

# Allow if statements to use the new IN_LIST operator (compatibility override for CMake <3.3)
cmake_policy( SET CMP0057 NEW )

if (NOT CPACK_EXTERNAL_ENABLE_STAGING)
    message(FATAL_ERROR "CPack external staging is not enabled. This is a build bug")
endif()

if (NOT CPACK_TENACITY_INNO_SETUP_BUILD_CONFIG)
    set(CPACK_TENACITY_INNO_SETUP_BUILD_CONFIG ${CPACK_BUILD_CONFIG})
endif()

set(OUTPUT_DIR "${CPACK_TEMPORARY_DIRECTORY}")

# The .iss discovers exe, version, arch, and sign config on its own.
# Point it at the config subdir; the filename mirrors the .iss formula.
set(TENACITY_BUILD_DIR "${OUTPUT_DIR}/${CPACK_TENACITY_INNO_SETUP_BUILD_CONFIG}")

if( CMAKE_SYSTEM_PROCESSOR MATCHES "AMD64|ARM64" )
    set( _INSTALLER_ARCH "x64" )
else()
    set( _INSTALLER_ARCH "x86" )
endif()
# .iss uses the exe's PE FILEVERSION (X.Y.Z); strip any pre-release suffix here.
string(REGEX MATCH "^[0-9]+\\.[0-9]+\\.[0-9]+" _INSTALLER_VERSION "${CPACK_PACKAGE_VERSION}")
set(CPACK_EXTERNAL_BUILT_PACKAGES
    "${OUTPUT_DIR}/Output/tenacity-win-${_INSTALLER_VERSION}-${_INSTALLER_ARCH}.exe")

# Signing: opt-in via env vars read by the .iss.
if( CPACK_TENACITY_INNO_SETUP_SIGN )
    if( CPACK_TENACITY_INNO_SETUP_CERTIFICATE )
        set( ENV{WINDOWS_CERTIFICATE} "${CPACK_TENACITY_INNO_SETUP_CERTIFICATE}")
    endif()

    if( CPACK_TENACITY_INNO_SETUP_CERTIFICATE_PASSWORD )
        message("Setting env:WINDOWS_CERTIFICATE_PASSWORD...")
        set( ENV{WINDOWS_CERTIFICATE_PASSWORD}
             "${CPACK_TENACITY_INNO_SETUP_CERTIFICATE_PASSWORD}")
    endif()

    set( ENV{TENACITY_SIGN_SCRIPT}
         "${CPACK_TENACITY_SOURCE_DIR}/scripts/build/windows/PfxSign.ps1")
endif()

# Stage the .iss and auxiliary files next to the build tree
file(COPY "${CPACK_TENACITY_SOURCE_DIR}/win/Inno_Setup_Wizard/" DESTINATION "${OUTPUT_DIR}")

file(COPY "${CPACK_TENACITY_SOURCE_DIR}/resources" DESTINATION "${OUTPUT_DIR}/Additional")

file(COPY
        "${CPACK_TENACITY_SOURCE_DIR}/LICENSE.txt"
        "${CPACK_TENACITY_SOURCE_DIR}/win/tenacity.ico"
    DESTINATION
        "${OUTPUT_DIR}/Additional"
)

execute_process(
    COMMAND
        ${CPACK_TENACITY_INNO_SETUP_COMPILER}
            /Sbyparam=$p
            "/DBuildDir=${TENACITY_BUILD_DIR}"
            "/DTargetArch=${_INSTALLER_ARCH}"
            "tenacity.iss" /Qp
    WORKING_DIRECTORY
        ${OUTPUT_DIR}
    # When we upgrade to CMake min version 3.19 we can use this
    # COMMAND_ERROR_IS_FATAL ANY
)
