#Based upon the existing Find module for mpg123, but for Matroska
#[=======================================================================[.rst:
FindMatroska
------------

Finds the libmatroska library and its libebml dependency.

Imported Targets
^^^^^^^^^^^^^^^^

This module provides the following imported target, if found:

``Matroska::matroska``
  Combined libmatroska + libebml link/include target. Matches the
  target name expected by modules/import-export/mod-mka.

Result Variables
^^^^^^^^^^^^^^^^

This will define the following variables:

``Matroska_FOUND``
  True if the system has both libmatroska and libebml.
``Matroska_VERSION``
  The version of libmatroska found on the system.

Cache Variables
^^^^^^^^^^^^^^^

The following cache variables may also be set:

``Matroska_INCLUDE_DIR``
  The directory containing ``matroska/KaxVersion.h``.
``Matroska_LIBRARY``
  The path to the libmatroska library.
``EBML_INCLUDE_DIR``
  The directory containing ``ebml/EbmlVersion.h``.
``EBML_LIBRARY``
  The path to the libebml library.

#]=======================================================================]

if (Matroska_INCLUDE_DIR AND EBML_INCLUDE_DIR)
    # Already in cache, be silent
    set(Matroska_FIND_QUIETLY TRUE)
endif ()

find_package(PkgConfig QUIET)
# 1.4.6 is the oldest version whose features mod-mka references 
# see modules/import-export/mod-mka/ExportMka.cpp
pkg_check_modules(PC_MATROSKA QUIET libmatroska>=1.4.6)
pkg_check_modules(PC_EBML     QUIET libebml)

find_path(Matroska_INCLUDE_DIR matroska/KaxVersion.h
    HINTS
        ${PC_MATROSKA_INCLUDEDIR}
        ${PC_MATROSKA_INCLUDE_DIRS}
        ${Matroska_ROOT}
)

find_path(EBML_INCLUDE_DIR ebml/EbmlVersion.h
    HINTS
        ${PC_EBML_INCLUDEDIR}
        ${PC_EBML_INCLUDE_DIRS}
        ${Matroska_ROOT}
)

find_library(Matroska_LIBRARY
    NAMES matroska libmatroska
    HINTS
        ${PC_MATROSKA_LIBDIR}
        ${PC_MATROSKA_LIBRARY_DIRS}
        ${Matroska_ROOT}
)

find_library(EBML_LIBRARY
    NAMES ebml libebml
    HINTS
        ${PC_EBML_LIBDIR}
        ${PC_EBML_LIBRARY_DIRS}
        ${Matroska_ROOT}
)

if (PC_MATROSKA_VERSION)
    set(Matroska_VERSION ${PC_MATROSKA_VERSION})
elseif (Matroska_INCLUDE_DIR AND EXISTS "${Matroska_INCLUDE_DIR}/matroska/KaxVersion.h")
    file(READ "${Matroska_INCLUDE_DIR}/matroska/KaxVersion.h" _matroska_h)
    string(REGEX MATCH "LIBMATROSKA_VERSION[ \t]+0x([0-9A-Fa-f]+)" _match "${_matroska_h}")
    if (CMAKE_MATCH_1)
        # Version is encoded as 0xMMmmpp — pull out the digits for a readable form.
        string(SUBSTRING "${CMAKE_MATCH_1}" 0 2 _mm_hex)
        string(SUBSTRING "${CMAKE_MATCH_1}" 2 2 _mn_hex)
        string(SUBSTRING "${CMAKE_MATCH_1}" 4 2 _pp_hex)
        math(EXPR _mm "0x${_mm_hex}")
        math(EXPR _mn "0x${_mn_hex}")
        math(EXPR _pp "0x${_pp_hex}")
        set(Matroska_VERSION "${_mm}.${_mn}.${_pp}")
    endif ()
endif ()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Matroska
    REQUIRED_VARS
        Matroska_LIBRARY
        Matroska_INCLUDE_DIR
        EBML_LIBRARY
        EBML_INCLUDE_DIR
    VERSION_VAR
        Matroska_VERSION
)

if (Matroska_FOUND AND NOT TARGET Matroska::matroska)
    add_library(Matroska::matroska UNKNOWN IMPORTED)
    set_target_properties(Matroska::matroska
        PROPERTIES
            IMPORTED_LOCATION "${Matroska_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${Matroska_INCLUDE_DIR};${EBML_INCLUDE_DIR}"
            INTERFACE_LINK_LIBRARIES "${EBML_LIBRARY}"
    )
endif ()

mark_as_advanced(Matroska_INCLUDE_DIR Matroska_LIBRARY EBML_INCLUDE_DIR EBML_LIBRARY)
