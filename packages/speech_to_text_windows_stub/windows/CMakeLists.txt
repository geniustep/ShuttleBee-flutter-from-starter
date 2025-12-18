# Stub CMakeLists.txt for speech_to_text_windows
# This is a workaround for Windows build issues with the original plugin

cmake_minimum_required(VERSION 3.14)
set(PROJECT_NAME "speech_to_text_windows")
project(${PROJECT_NAME} LANGUAGES CXX)

set(PLUGIN_NAME "speech_to_text_windows_plugin")

add_library(${PLUGIN_NAME} SHARED
  "speech_to_text_windows.cpp"
)

apply_standard_settings(${PLUGIN_NAME})

set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden
)

target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include"
)

target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin)

set(speech_to_text_windows_bundled_libraries "" PARENT_SCOPE)
