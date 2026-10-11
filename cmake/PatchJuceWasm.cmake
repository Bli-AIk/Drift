# JUCE 8 has wasm branches in juce_core but its thread-priority table has no wasm row, so the
# static_assert on the table's size fails. This adds JUCE_WASM to the Linux/BSD row.
#
# drift_patch_juce_wasm(<modules_dir>) edits the header in place and is idempotent, so it must only
# be pointed at a tree this build owns (a copy or a FetchContent download), never a user's checkout.
# Also usable as a script, which is how FetchContent's PATCH_COMMAND runs it:
#   cmake -DDRIFT_JUCE_MODULES_DIR=<modules> -P PatchJuceWasm.cmake
function(drift_patch_juce_wasm modules_dir)
    set(_header "${modules_dir}/juce_core/native/juce_ThreadPriorities_native.h")
    file(READ "${_header}" _text)
    if(_text MATCHES "#if JUCE_LINUX \\|\\| JUCE_BSD \\|\\| JUCE_WASM")
        return()
    endif()
    string(FIND "${_text}" "#if JUCE_LINUX || JUCE_BSD" _at)
    if(_at EQUAL -1)
        message(FATAL_ERROR "JUCE thread priority table changed; revisit the wasm fix-up (${_header})")
    endif()
    string(REPLACE "#if JUCE_LINUX || JUCE_BSD" "#if JUCE_LINUX || JUCE_BSD || JUCE_WASM" _text "${_text}")
    file(WRITE "${_header}" "${_text}")
endfunction()

if(CMAKE_SCRIPT_MODE_FILE AND DRIFT_JUCE_MODULES_DIR)
    drift_patch_juce_wasm("${DRIFT_JUCE_MODULES_DIR}")
endif()
