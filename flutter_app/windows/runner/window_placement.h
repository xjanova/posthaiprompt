// Thai Prompt POS — native window placement for the customer-facing second
// screen (Windows). Exposes a "tp/window" method channel on an engine:
//   displays          → [{id, name, x, y, w, h, primary}]  (physical pixels)
//   place {x,y,w,h, fullscreen, topmost}  → moves/resizes this engine's window
//   setTitle {title}  · close
// Registered for the main window and for every desktop_multi_window window.
#ifndef RUNNER_WINDOW_PLACEMENT_H_
#define RUNNER_WINDOW_PLACEMENT_H_

#include <flutter/binary_messenger.h>
#include <windows.h>

// |view_or_root| may be the Flutter view (child) HWND or the top-level HWND;
// the handler resolves the top-level window at call time.
void RegisterWindowPlacementChannel(flutter::BinaryMessenger* messenger,
                                    HWND view_or_root);

#endif  // RUNNER_WINDOW_PLACEMENT_H_
