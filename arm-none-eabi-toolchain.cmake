################################################################################
# BRIEF:
#
# CMake toolchain file configurable for arm-none-eabi-gcc 
#
################################################################################
# Author: Carl Mattatall
# Maintainer: Carl Mattatall (cmattatall2@gmail.com)
# Github: cmattatall
################################################################################
cmake_minimum_required(VERSION 3.20)


# TODO: Refactor the target-specific stuff into an abstract and injectible
# configuration file at some point in the future
set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR arm)
set(TOOLCHAIN_PREFIX arm-none-eabi)
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)
set(CMAKE_CROSSCOMPILING ON)

set(TARGET_ARCH_OPTIONS "-mlittle-endian -mthumb -mcpu=cortex-m4 -mfloat-abi=hard -mfpu=fpv4-sp-d16")
set(TARGET_LINKER_OPTIONS "-mthumb-interwork -ffreestanding -ffunction-sections -fdata-sections --specs=nosys.specs")
set(TOOLCHAIN_LINKER_SCRIPT "${CMAKE_CURRENT_SOURCE_DIR}/stm32f411-flash.ld")

# BINUTILS NAMES (files with these names in PATH may not necessarily be true paths - could be links, aliases, etc.)
set(TOOLCHAIN_C_COMPILER_NAME ${TOOLCHAIN_PREFIX}-gcc${CMAKE_EXECUTABLE_SUFFIX})
set(TOOLCHAIN_ASM_COMPILER_NAME ${TOOLCHAIN_C_COMPILER_NAME}) # use same ASM compiler as C compiler for ABI compat
set(TOOLCHAIN_CXX_COMPILER_NAME ${TOOLCHAIN_PREFIX}-g++${CMAKE_EXECUTABLE_SUFFIX})
set(TOOLCHAIN_OBJCOPY_NAME ${TOOLCHAIN_PREFIX}-objcopy${CMAKE_EXECUTABLE_SUFFIX})
set(TOOLCHAIN_OBJDUMP_NAME ${TOOLCHAIN_PREFIX}-objdump${CMAKE_EXECUTABLE_SUFFIX})
set(TOOLCHAIN_SIZE_NAME ${TOOLCHAIN_PREFIX}-size${CMAKE_EXECUTABLE_SUFFIX})
set(TOOLCHAIN_GDB_NAME ${TOOLCHAIN_PREFIX}-gdb${CMAKE_EXECUTABLE_SUFFIX})
set(TOOLCHAIN_STRIP_NAME ${TOOLCHAIN_PREFIX}-strip${CMAKE_EXECUTABLE_SUFFIX})

# Print configuration info to callee
if(NOT DEFINED ENV{TOOLCHAIN_PROCESSED})

    # cmake can process the toolchain file multiple times but we only want
    # to emit the configuration info to the caller the very first time it is
    # processed so that stdout doens't get flooded. 
    #
    # To do this, we use (an admittedly hacky) environment variable to maintain
    # the statefulness of the cache population, try_compile() and try_run()
    # stages
    #
    # Hopefully in the future, cmake will provide a better or standard way
    # to issue diagnostics when processing a toolchain file
    message("") 
    message("Configured toolchain binutils: ")
    message("TOOLCHAIN_C_COMPILER_NAME ......... ${TOOLCHAIN_C_COMPILER_NAME}")
    message("TOOLCHAIN_ASM_COMPILER_NAME ....... ${TOOLCHAIN_ASM_COMPILER_NAME}")
    message("TOOLCHAIN_CXX_COMPILER_NAME ....... ${TOOLCHAIN_CXX_COMPILER_NAME}")
    message("TOOLCHAIN_OBJCOPY_NAME ............ ${TOOLCHAIN_OBJCOPY_NAME}")
    message("TOOLCHAIN_OBJDUMP_NAME ............ ${TOOLCHAIN_OBJDUMP_NAME}")
    message("TOOLCHAIN_SIZE_NAME ............... ${TOOLCHAIN_SIZE_NAME}")
    message("TOOLCHAIN_GDB_NAME ................ ${TOOLCHAIN_GDB_NAME}")
    message("TOOLCHAIN_STRIP_NAME .............. ${TOOLCHAIN_STRIP_NAME}")
    message("") 

    mark_as_advanced(TOOLCHAIN_PREFIX)
    mark_as_advanced(TOOLCHAIN_C_COMPILER_NAME)
    mark_as_advanced(TOOLCHAIN_ASM_COMPILER_NAME)
    mark_as_advanced(TOOLCHAIN_CXX_COMPILER_NAME)
    mark_as_advanced(TOOLCHAIN_OBJCOPY_NAME)
    mark_as_advanced(TOOLCHAIN_OBJDUMP_NAME)
    mark_as_advanced(TOOLCHAIN_SIZE_NAME)
    mark_as_advanced(TOOLCHAIN_GDB_NAME)
    mark_as_advanced(TOOLCHAIN_STRIP_NAME)

endif(NOT DEFINED ENV{TOOLCHAIN_PROCESSED})


if(MINGW OR CYGWIN OR WIN32)
    set(UTIL_SEARCH_COMMAND where)
elseif(UNIX AND NOT APPLE)
    set(UTIL_SEARCH_COMMAND which)
elseif(APPLE)
    set(UTIL_SEARCH_COMMAND which)
else()
    message(FATAL_ERROR "SYSTEM : ${CMAKE_HOST_SYSTEM_NAME} not supported")
endif()
mark_as_advanced(UTIL_SEARCH_COMMAND)

execute_process(
    COMMAND ${UTIL_SEARCH_COMMAND} ${TOOLCHAIN_C_COMPILER_NAME}
    OUTPUT_VARIABLE TOOLCHAIN_GCC_FOUND_PATH
    RESULT_VARIABLE TOOLCHAIN_GCC_NOT_FOUND
    OUTPUT_STRIP_TRAILING_WHITESPACE
)
mark_as_advanced(TOOLCHAIN_GCC_FOUND_PATH)
mark_as_advanced(TOOLCHAIN_GCC_NOT_FOUND)

if(TOOLCHAIN_GCC_NOT_FOUND)
    message(FATAL_ERROR "Could not find ${TOOLCHAIN_C_COMPILER_NAME}")
else()
    message("Found gcc executable at ${TOOLCHAIN_GCC_FOUND_PATH}")
endif(TOOLCHAIN_GCC_NOT_FOUND)

################################################################################
# The found binary could be a link so we will try 
# to infer the toolchain directory from it.
# 
# If we can't follow a link the process to determine 
# the target sysroot becomes much more complicated....
################################################################################

if(MINGW OR CYGWIN OR WIN32)

    # TODO: on windows, we SHOULD follow links but this functionality isn't implemented yet
    # because an accessible tool like readlink isn't easily available on that platform
    #
    # In general, Windows users don't tend to have a 
    # deep understand how filesystems work anyways...
    # 
    # ¯\_(ツ)_/¯
    #     \/
    #     xx
    #     xx
    #    _/\_
    #     
    # For now we will just assume the binary in PATH is not a link
    set(TOOLCHAIN_GCC_PATH ${TOOLCHAIN_GCC_FOUND_PATH}) 

elseif(UNIX AND NOT APPLE)
    if(IS_SYMLINK TOOLCHAIN_GCC_FOUND_PATH)
        execute_process(
            COMMAND readlink -f ${TOOLCHAIN_GCC_FOUND_PATH}
            OUTPUT_VARIABLE TOOLCHAIN_GCC_PATH
            RESULT_VARIABLE TOOLCHAIN_GCC_PATH_NOT_FOUND
            OUTPUT_STRIP_TRAILING_WHITESPACE
        )
    else()
        # The path we found for the GCC binary is in PATH is indeed a true path
        set(TOOLCHAIN_GCC_PATH ${TOOLCHAIN_GCC_FOUND_PATH})
    endif(IS_SYMLINK TOOLCHAIN_GCC_FOUND_PATH)
else()
    message(FATAL_ERROR "${CMAKE_HOST_SYSTEM_NAME} not supported")
endif()


if(NOT TOOLCHAIN_GCC_PATH)
    message(FATAL_ERROR "Could not infer directory for toolchain:${TOOLCHAIN_PREFIX} from ${TOOLCHAIN_GCC_FOUND_PATH}")
elseif(TOOLCHAIN_GCC_PATH_NOT_FOUND)
    message(FATAL_ERROR "Could not infer directory for toolchain:${TOOLCHAIN_PREFIX} from ${TOOLCHAIN_GCC_FOUND_PATH}")
endif()

get_filename_component(TOOLCHAIN_BINUTILS_DIR ${TOOLCHAIN_GCC_PATH} DIRECTORY)
get_filename_component(TOOLCHAIN_ROOT_DIR ${TOOLCHAIN_BINUTILS_DIR} DIRECTORY)
set(TOOLCHAIN_SYSROOT_DIR ${TOOLCHAIN_ROOT_DIR}/${TOOLCHAIN_PREFIX}) # TODO: check if sysroot is indeed a directory
list(APPEND TOOLCHAIN_BINUTILS_SEARCH_HINTS "${TOOLCHAIN_BINUTILS_DIR}")
set(TOOLCHAIN_USR_DIR ${TOOLCHAIN_SYSROOT_DIR}/usr)

# Configure search mode for toolchain binutils on HOST (operate on target binaries but executed on host)
set(CMAKE_PREFIX_PATH "" CACHE STRING "" FORCE)
set(CMAKE_PREFIX_PATH "${CMAKE_PREFIX_PATH};${TOOLCHAIN_SYSROOT_DIR}" CACHE STRING "" FORCE)
set(CMAKE_PREFIX_PATH "${CMAKE_PREFIX_PATH};${TOOLCHAIN_USR_DIR}" CACHE STRING "" FORCE)
set(CMAKE_PREFIX_PATH "${CMAKE_PREFIX_PATH};${TOOLCHAIN_USR_DIR}/local" CACHE STRING "" FORCE)
set(CMAKE_FIND_ROOT_PATH ${TOOLCHAIN_ROOT_DIR})
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)


find_program(
    CMAKE_C_COMPILER 
    NAMES ${TOOLCHAIN_C_COMPILER_NAME}
    HINTS ${TOOLCHAIN_BINUTILS_SEARCH_HINTS}
    REQUIRED
)

find_program(
    CMAKE_ASM_COMPILER 
    NAMES ${TOOLCHAIN_ASM_COMPILER_NAME}
    HINTS ${TOOLCHAIN_BINUTILS_SEARCH_HINTS}
    REQUIRED
)

find_program(
    CMAKE_CXX_COMPILER 
    NAMES ${TOOLCHAIN_CXX_COMPILER_NAME}
    HINTS ${TOOLCHAIN_BINUTILS_SEARCH_HINTS}
    REQUIRED
)

find_program(
    CMAKE_OBJCOPY 
    NAMES ${TOOLCHAIN_OBJCOPY_NAME}
    HINTS ${TOOLCHAIN_BINUTILS_SEARCH_HINTS}
    REQUIRED
)

find_program(
    CMAKE_OBJDUMP 
    NAMES ${TOOLCHAIN_OBJDUMP_NAME}
    HINTS ${TOOLCHAIN_BINUTILS_SEARCH_HINTS}
    REQUIRED
)

find_program(
    CMAKE_SIZE 
    NAMES ${TOOLCHAIN_SIZE_NAME}
    HINTS ${TOOLCHAIN_BINUTILS_SEARCH_HINTS}
    REQUIRED
)

find_program(
    CMAKE_STRIP 
    NAMES ${TOOLCHAIN_STRIP_NAME}
    HINTS ${TOOLCHAIN_BINUTILS_SEARCH_HINTS} 
    REQUIRED
)

# Note that GDB may not necessarily be required because we could be semihosting
# (or maybe we just don't care about debugging on our platform or something)
find_program(
    CMAKE_GDB 
    NAMES ${TOOLCHAIN_GDB_NAME}
    HINTS ${TOOLCHAIN_BINUTILS_SEARCH_HINTS} 
)

# Configure initial compiler flags
set(CMAKE_ASM_FLAGS_INIT "${TARGET_ARCH_OPTIONS} ${TARGET_LINKER_OPTIONS}")
set(CMAKE_C_FLAGS_INIT "${TARGET_ARCH_OPTIONS} ${TARGET_LINKER_OPTIONS}")
set(CMAKE_CXX_FLAGS_INIT "${TARGET_ARCH_OPTIONS} ${TARGET_LINKER_OPTIONS} -fno-rtti -fno-exceptions")
set(CMAKE_EXE_LINKER_FLAGS_INIT "-Wl,--relax,--gc-sections,-T,${TOOLCHAIN_LINKER_SCRIPT}")

mark_as_advanced(CMAKE_ASM_FLAGS_INIT)
mark_as_advanced(CMAKE_C_FLAGS_INIT)
mark_as_advanced(CMAKE_CXX_FLAGS_INIT)

if(UNIX AND NOT APPLE)

    # Add include sysroot/include to IDIRS if exists
    set(TOOLCHAIN_ROOT_INCLUDE_DIR ${TOOLCHAIN_SYSROOT_DIR}/include)
    if(EXISTS ${TOOLCHAIN_ROOT_INCLUDE_DIR})
        if(IS_DIRECTORY ${TOOLCHAIN_ROOT_INCLUDE_DIR})
            include_directories(${TOOLCHAIN_ROOT_INCLUDE_DIR})
        endif(IS_DIRECTORY ${TOOLCHAIN_ROOT_INCLUDE_DIR})
    endif(EXISTS ${TOOLCHAIN_ROOT_INCLUDE_DIR})
    mark_as_advanced(TOOLCHAIN_ROOT_INCLUDE_DIR)

    # Add sysroot/usr/include to IDIRS if exists
    set(TOOLCHAIN_USR_INCLUDE_DIR ${TOOLCHAIN_USR_DIR}/include)
    if(EXISTS ${TOOLCHAIN_USR_INCLUDE_DIR})
        if(IS_DIRECTORY ${TOOLCHAIN_USR_INCLUDE_DIR})
            include_directories(${TOOLCHAIN_USR_INCLUDE_DIR})
        endif(IS_DIRECTORY ${TOOLCHAIN_USR_INCLUDE_DIR})
    endif(EXISTS ${TOOLCHAIN_USR_INCLUDE_DIR})
    mark_as_advanced(TOOLCHAIN_USR_INCLUDE_DIR)


    # Add sysroot/usr/local/include to IDIRS if exists
    set(TOOLCHAIN_USR_LOCAL_INCLUDE_DIR ${TOOLCHAIN_USR_DIR}/local/include)
    if(EXISTS ${TOOLCHAIN_USR_LOCAL_INCLUDE_DIR})
        if(IS_DIRECTORY ${TOOLCHAIN_USR_LOCAL_INCLUDE_DIR})
            include_directories(${TOOLCHAIN_USR_LOCAL_INCLUDE_DIR})
        endif(IS_DIRECTORY ${TOOLCHAIN_USR_LOCAL_INCLUDE_DIR})
    endif(EXISTS ${TOOLCHAIN_USR_LOCAL_INCLUDE_DIR})
    mark_as_advanced(TOOLCHAIN_USR_LOCAL_INCLUDE_DIR)

    # Add sysroot/lib to link LDIRS if exists
    set(TOOLCHAIN_LIB_DIR ${TOOLCHAIN_SYSROOT_DIR}/lib/)
    if(EXISTS ${TOOLCHAIN_LIB_DIR})
        if(IS_DIRECTORY ${TOOLCHAIN_LIB_DIR})
            link_directories(${TOOLCHAIN_LIB_DIR})
        endif(IS_DIRECTORY ${TOOLCHAIN_LIB_DIR})
    endif(EXISTS ${TOOLCHAIN_LIB_DIR})

    # Add sysroot/usr/lib to link LDIRS if exists
    set(TOOLCHAIN_USR_LIB_DIR ${TOOLCHAIN_USR_DIR}/lib/)
    if(EXISTS ${TOOLCHAIN_USR_LIB_DIR})
        if(IS_DIRECTORY ${TOOLCHAIN_USR_LIB_DIR})
            link_directories(${TOOLCHAIN_USR_LIB_DIR})
        endif(IS_DIRECTORY ${TOOLCHAIN_USR_LIB_DIR})
    endif(EXISTS ${TOOLCHAIN_USR_LIB_DIR})

    # Add sysroot/usr/local/lib to link LDIRS if exists
    set(TOOLCHAIN_USR_LOCAL_LIB_DIR ${TOOLCHAIN_USR_DIR}/local/lib/)
    if(EXISTS ${TOOLCHAIN_USR_LOCAL_LIB_DIR})
        if(IS_DIRECTORY ${TOOLCHAIN_USR_LOCAL_LIB_DIR})
            link_directories(${TOOLCHAIN_USR_LOCAL_LIB_DIR})
        endif(IS_DIRECTORY ${TOOLCHAIN_USR_LOCAL_LIB_DIR})
    endif(EXISTS ${TOOLCHAIN_USR_LOCAL_LIB_DIR})

endif(UNIX AND NOT APPLE)

# This supports custom builds of gcc that may not use the default values 
# provided by autotools when it was built. 
#
# Examples: Yocto, OE, Alpine toolchains, or anything built using chroot
set(CMAKE_INSTALL_RPATH ${TOOLCHAIN_USR_DIR})
set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)


# The hacky workaround so that we only issue diagnostics on the first pass of
# the toolchain file and not on subsequent passes. This prevents the 
# cmake parser from flooding stdout every time it parses a call to project()
set(ENV{TOOLCHAIN_PROCESSED} 1)