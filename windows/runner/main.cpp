#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
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
  // Initialize to fullscreen at 0,0
  Win32Window::Point origin(0, 0);
  Win32Window::Size size(GetSystemMetrics(SM_CXSCREEN), GetSystemMetrics(SM_CYSCREEN));
  if (!window.Create(L"flutter_windows_android_app", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  HWND hwnd = ::FindWindowW(nullptr, L"flutter_windows_android_app");
  if (hwnd != nullptr) {
    LONG_PTR style = ::GetWindowLongPtrW(hwnd, GWL_STYLE);
    style &= ~(WS_CAPTION | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX | WS_SYSMENU);
    ::SetWindowLongPtrW(hwnd, GWL_STYLE, style);
    ::SetWindowPos(hwnd, nullptr, 0, 0, GetSystemMetrics(SM_CXSCREEN), GetSystemMetrics(SM_CYSCREEN), SWP_NOZORDER | SWP_FRAMECHANGED);
  }

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {

    if (msg.message == WM_KEYDOWN && msg.wParam == VK_F11) {
      HWND hwndWindow = msg.hwnd;
      if (hwndWindow != nullptr) {
        LONG_PTR style = ::GetWindowLongPtrW(hwndWindow, GWL_STYLE);
        bool isFullscreen = (style & WS_CAPTION) == 0;
        if (isFullscreen) {
          style |= WS_CAPTION | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX | WS_SYSMENU;
          ::SetWindowLongPtrW(hwndWindow, GWL_STYLE, style);
          ::SetWindowPos(hwndWindow, nullptr, 100, 100, 800, 600, SWP_NOZORDER | SWP_FRAMECHANGED);
        } else {
          style &= ~(WS_CAPTION | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX | WS_SYSMENU);
          ::SetWindowLongPtrW(hwndWindow, GWL_STYLE, style);
          ::SetWindowPos(hwndWindow, nullptr, 0, 0, GetSystemMetrics(SM_CXSCREEN), GetSystemMetrics(SM_CYSCREEN), SWP_NOZORDER | SWP_FRAMECHANGED);
        }
        continue;
      }
    }

    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
