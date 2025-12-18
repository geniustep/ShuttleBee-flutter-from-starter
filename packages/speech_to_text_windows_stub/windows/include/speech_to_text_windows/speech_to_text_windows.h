// Stub header for speech_to_text_windows
#ifndef FLUTTER_PLUGIN_SPEECH_TO_TEXT_WINDOWS_H_
#define FLUTTER_PLUGIN_SPEECH_TO_TEXT_WINDOWS_H_

#include <flutter_plugin_registrar.h>

#ifdef FLUTTER_PLUGIN_IMPL
#define FLUTTER_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FLUTTER_PLUGIN_EXPORT __declspec(dllimport)
#endif

#if defined(__cplusplus)
extern "C" {
#endif

FLUTTER_PLUGIN_EXPORT void SpeechToTextWindowsRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar);

#if defined(__cplusplus)
}
#endif

#endif  // FLUTTER_PLUGIN_SPEECH_TO_TEXT_WINDOWS_H_
