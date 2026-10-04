#include "window_placement.h"

#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <string>
#include <vector>

namespace {

using flutter::EncodableList;
using flutter::EncodableMap;
using flutter::EncodableValue;

// Channels must outlive the handler registration (one per engine).
std::vector<std::unique_ptr<flutter::MethodChannel<EncodableValue>>> g_channels;

std::string Utf8(const wchar_t* w) {
  if (!w || !*w) return std::string();
  int len = ::WideCharToMultiByte(CP_UTF8, 0, w, -1, nullptr, 0, nullptr, nullptr);
  if (len <= 1) return std::string();
  std::string out(static_cast<size_t>(len - 1), '\0');
  ::WideCharToMultiByte(CP_UTF8, 0, w, -1, out.data(), len, nullptr, nullptr);
  return out;
}

std::wstring Wide(const std::string& s) {
  if (s.empty()) return std::wstring();
  int len = ::MultiByteToWideChar(CP_UTF8, 0, s.c_str(), -1, nullptr, 0);
  if (len <= 1) return std::wstring();
  std::wstring out(static_cast<size_t>(len - 1), L'\0');
  ::MultiByteToWideChar(CP_UTF8, 0, s.c_str(), -1, out.data(), len);
  return out;
}

double Num(const EncodableMap& args, const char* key, double fallback = 0) {
  auto it = args.find(EncodableValue(key));
  if (it == args.end()) return fallback;
  if (auto d = std::get_if<double>(&it->second)) return *d;
  if (auto i = std::get_if<int32_t>(&it->second)) return static_cast<double>(*i);
  if (auto l = std::get_if<int64_t>(&it->second)) return static_cast<double>(*l);
  return fallback;
}

bool Flag(const EncodableMap& args, const char* key, bool fallback = false) {
  auto it = args.find(EncodableValue(key));
  if (it == args.end()) return fallback;
  if (auto b = std::get_if<bool>(&it->second)) return *b;
  return fallback;
}

BOOL CALLBACK CollectMonitor(HMONITOR monitor, HDC, LPRECT, LPARAM data) {
  auto* list = reinterpret_cast<EncodableList*>(data);
  MONITORINFOEXW info{};
  info.cbSize = sizeof(info);
  if (!::GetMonitorInfoW(monitor, &info)) return TRUE;
  const RECT& r = info.rcMonitor;
  EncodableMap m;
  m[EncodableValue("id")] = EncodableValue(Utf8(info.szDevice));
  m[EncodableValue("name")] = EncodableValue(Utf8(info.szDevice));
  m[EncodableValue("x")] = EncodableValue(static_cast<int32_t>(r.left));
  m[EncodableValue("y")] = EncodableValue(static_cast<int32_t>(r.top));
  m[EncodableValue("w")] = EncodableValue(static_cast<int32_t>(r.right - r.left));
  m[EncodableValue("h")] = EncodableValue(static_cast<int32_t>(r.bottom - r.top));
  m[EncodableValue("primary")] = EncodableValue((info.dwFlags & MONITORINFOF_PRIMARY) != 0);
  list->push_back(EncodableValue(m));
  return TRUE;
}

}  // namespace

void RegisterWindowPlacementChannel(flutter::BinaryMessenger* messenger,
                                    HWND view_or_root) {
  auto channel = std::make_unique<flutter::MethodChannel<EncodableValue>>(
      messenger, "tp/window", &flutter::StandardMethodCodec::GetInstance());

  channel->SetMethodCallHandler(
      [view_or_root](const flutter::MethodCall<EncodableValue>& call,
                     std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
        HWND root = ::GetAncestor(view_or_root, GA_ROOT);
        if (!root) root = view_or_root;
        const std::string& method = call.method_name();

        if (method == "displays") {
          EncodableList list;
          ::EnumDisplayMonitors(nullptr, nullptr, CollectMonitor,
                                reinterpret_cast<LPARAM>(&list));
          result->Success(EncodableValue(list));
          return;
        }

        const auto* args = std::get_if<EncodableMap>(call.arguments());

        if (method == "place") {
          if (!args) {
            result->Error("bad_args", "place needs {x,y,w,h}");
            return;
          }
          const int x = static_cast<int>(Num(*args, "x"));
          const int y = static_cast<int>(Num(*args, "y"));
          const int w = static_cast<int>(Num(*args, "w", 1280));
          const int h = static_cast<int>(Num(*args, "h", 800));
          const bool fullscreen = Flag(*args, "fullscreen", true);
          const bool topmost = Flag(*args, "topmost", false);
          if (fullscreen) {
            LONG style = ::GetWindowLongW(root, GWL_STYLE);
            style &= ~(WS_CAPTION | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX | WS_SYSMENU);
            style |= WS_POPUP;
            ::SetWindowLongW(root, GWL_STYLE, style);
          }
          ::SetWindowPos(root, topmost ? HWND_TOPMOST : HWND_NOTOPMOST, x, y, w, h,
                         SWP_FRAMECHANGED | SWP_SHOWWINDOW | SWP_NOACTIVATE);
          result->Success(EncodableValue(true));
          return;
        }

        if (method == "setTitle") {
          std::string title;
          if (args) {
            auto it = args->find(EncodableValue("title"));
            if (it != args->end()) {
              if (auto s = std::get_if<std::string>(&it->second)) title = *s;
            }
          }
          ::SetWindowTextW(root, Wide(title).c_str());
          result->Success();
          return;
        }

        if (method == "close") {
          ::PostMessageW(root, WM_CLOSE, 0, 0);
          result->Success();
          return;
        }

        result->NotImplemented();
      });

  g_channels.push_back(std::move(channel));
}
