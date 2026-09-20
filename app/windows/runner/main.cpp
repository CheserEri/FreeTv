#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include <string>

#include "flutter_window.h"
#include "utils.h"

namespace {

// 让官方播放器打开即有声音。
//
// Chromium 的自动播放策略要求「带声音的媒体」必须由用户手势触发，否则官方
// 播放器会降级为静音自动播放。承载插件创建 WebView2 环境时把
// ICoreWebView2EnvironmentOptions 传成了 nullptr，Dart 侧没有注入浏览器
// 参数的入口，因此在进程启动时用 WebView2 官方支持的
// WEBVIEW2_ADDITIONAL_BROWSER_ARGUMENTS 环境变量补上。
//
// 该变量由 WebView2 加载器在创建环境时读取，必须早于任何 WebView 创建。
// 这里追加而非覆盖，以保留外部已设置的其他参数（例如排查问题用的
// --remote-debugging-port）。
void EnableAutoplayWithSound() {
  constexpr wchar_t kKey[] = L"WEBVIEW2_ADDITIONAL_BROWSER_ARGUMENTS";
  constexpr wchar_t kFlag[] = L"--autoplay-policy=no-user-gesture-required";

  wchar_t buffer[4096] = {};
  const DWORD length = ::GetEnvironmentVariableW(kKey, buffer, 4096);
  std::wstring value =
      (length > 0 && length < 4096) ? std::wstring(buffer) : std::wstring();

  if (value.find(kFlag) != std::wstring::npos) {
    return;
  }
  if (!value.empty()) {
    value += L' ';
  }
  value += kFlag;

  ::SetEnvironmentVariableW(kKey, value.c_str());
}

}  // namespace

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // 必须早于任何 WebView 创建，否则参数不会生效。
  EnableAutoplayWithSound();

  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"FreeTv", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
