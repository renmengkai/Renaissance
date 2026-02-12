#ifndef RUNNER_WIN32_WINDOW_H_
#define RUNNER_WIN32_WINDOW_H_

#include <windows.h>

#include <functional>
#include <memory>
#include <string>

// Forward declaration
class FlutterWindow;

// A class abstraction for a high DPI-aware Win32 Window. Intended to be
// inherited from classes that wish to specialize with custom
// rendering and input handling
class Win32Window {
 public:
  struct Point {
    unsigned int x;
    unsigned int y;
    Point(unsigned int x, unsigned int y) : x(x), y(y) {}
  };

  struct Size {
    unsigned int width;
    unsigned int height;
    Size(unsigned int width, unsigned int height)
        : width(width), height(height) {}
  };

  Win32Window();
  virtual ~Win32Window();

  // Creates a win32 window with the given dimensions.
  // If |parent| is non-null the window is a child of |parent|.
  // Returns true if the window was created successfully.
  bool Create(const std::wstring &title, const Point &origin, const Size &size);

  // Show the current window. Returns true if the window was successfully shown.
  bool Show();

  // Release OS resources associated with window.
  void Destroy();

  // Returns the backing Window handle to enable clients to set icon and other
  // window properties. Returns nullptr if the window has been destroyed.
  HWND GetHandle() { return window_handle_; }

  // If true, closing this window will quit the application.
  void SetQuitOnClose(bool quit_on_close);

  // Returns a pointer to the FlutterWindow if the window is a FlutterWindow.
  // Returns nullptr otherwise.
  virtual FlutterWindow *GetFlutterWindow() { return nullptr; }

  // OS callback called by message pump. Handles the WM_NCCREATE message which
  // is passed when the non-client area is being created and enables automatic
  // non-client DPI scaling so that the non-client area automatically
  // responds to changes in DPI. All other messages are handled by
  // MessageHandler.
  static LRESULT CALLBACK WndProc(HWND const window,
                                   UINT const message,
                                   WPARAM const wparam,
                                   LPARAM const lparam) noexcept;

  // Returns the DPI for the window.
  UINT GetDpi();

 protected:
  // Registers a window class with the given name and configuration.
  // Returns true if the class was registered or if the class was already
  // registered.
  bool RegisterWindowClass(const wchar_t *name);

  // Processes and route salient window messages for mouse handling,
  // size changes and DPI. Delegates handling of these to member overloads that
  // inheriting classes can handle.
  virtual LRESULT
  MessageHandler(HWND window,
                 UINT const message,
                 WPARAM const wparam,
                 LPARAM const lparam) noexcept;

  // Called when CreateAndShow is called, allowing subclass window-related
  // setup. Subclasses should return false if setup fails.
  virtual bool OnCreate();

  // Called when Destroy is called.
  virtual void OnDestroy();

  // Set the child content of this window to the specified HWND.
  void SetChildContent(HWND content);

  // Returns the HWND of the child content.
  HWND GetChildContent() { return child_content_; }

  // Returns the client area rectangle.
  RECT GetClientArea();

  // Retrieves a class instance pointer for |window|
  static Win32Window *GetThisFromHandle(HWND const window) noexcept;

  // Update the window theme based on the system theme.
  static void UpdateTheme(HWND const window);

  // window handle for top level window.
  HWND window_handle_ = nullptr;

  // window handle for hosted content.
  HWND child_content_ = nullptr;

  // If true, closing this window will quit the application.
  bool quit_on_close_ = false;
};

#endif  // RUNNER_WIN32_WINDOW_H_
