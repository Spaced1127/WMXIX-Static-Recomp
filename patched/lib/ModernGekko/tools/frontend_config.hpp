#pragma once

#include <cstdint>
#include <filesystem>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace moderngekko::frontend {
struct ResolutionOption {
  const char *text;
  int dolphin_scale;
};

struct GraphicsBackendOption {
  const char *text;
  const char *value;
};

struct ConfigResult {
  int dolphin_scale = 0;
  std::string resolution;
  std::string graphics_backend = "Vulkan";
  std::string controller;
  std::vector<std::string> controllers;
  // Canonical layout class: "auto", "positional" or "nintendo". Applied in the
  // input layer; it never selects or rewrites a profile file.
  std::string controller_class = "auto";
  bool show_fps_in_title = true;
  bool fullscreen = false;
  int msaa = 1;
  bool ssaa = false;
  int anisotropy = 0;
  bool vsync = false;
  int aspect = 0;
  bool widescreen_hack = false;
  bool efb_access = true;
  bool mute = false;
  int volume = 100;
  float emulation_speed = 1.0f;
  // "static" runs the shipped DolRecomp module (the default for this port).
  // "jit" is the Dolphin JIT fallback and ignores the module.
  std::string cpu_core = "static";
  std::string netplay_nickname = "Player";
  std::string netplay_address = "127.0.0.1";
  std::uint16_t netplay_port = 2626;
  std::string netplay_buffer = "auto";
  std::string error;

  explicit operator bool() const { return error.empty(); }
};

const std::vector<ResolutionOption> &SupportedResolutions();
const std::vector<GraphicsBackendOption> &SupportedGraphicsBackends();
ConfigResult LoadConfig(const std::filesystem::path &user_directory,
                        bool create_if_missing);
ConfigResult ParseConfig(std::string_view text);
bool SaveConfig(const std::filesystem::path &user_directory,
                const ConfigResult &config, std::string *error);
bool SaveConfig(const std::filesystem::path &user_directory,
                std::string_view resolution, bool show_fps_in_title,
                std::string_view controller, std::string *error);
std::string
ReadConfiguredController(const std::filesystem::path &user_directory);
std::vector<std::string>
ReadConfiguredControllers(const std::filesystem::path &user_directory);
bool ControllerConfigExists(const std::filesystem::path &user_directory);
// Forces the GameCube EXI memory-card layout in Config/Dolphin.ini:
//   [Core] SlotA = 1   (raw memory card)
//          SlotB = 255 (None - empty slot)
// Dolphin's default SlotA is the GCI folder (8), which makes the game's
// CARDProbeEx hang on "checking memory card in slot A", and SlotB = 0 is the
// Dummy device, which the game rejects as unsupported. Runs on every start so
// existing installs are repaired; other ini keys are preserved.
bool EnsureMemoryCardSlotSettings(const std::filesystem::path &user_directory,
                                  std::string *message = nullptr);

// Canonical controller layout class. One static profile (positional SDL
// bindings) is copied only when missing and never rewritten; the class is
// applied in the input layer. Nintendo swaps A<->B and X<->Y only.
enum class ControllerClass { Auto, Positional, Nintendo };
const char *ControllerClassName(ControllerClass controller_class);
// "auto", "positional"/"standard"/"default"/"xbox"/"playstation",
// "nintendo"/"switch". Returns false for anything else.
bool ParseControllerClass(std::string_view text, ControllerClass *out);

// The canonical profile text for a device string (keyboard or GameCube pad).
std::string CanonicalPadProfile(std::string_view device);
// Writes the canonical profile only when the file is absent. Never rewrites an
// existing profile, generated or hand-edited.
bool EnsureCanonicalPadProfile(const std::filesystem::path &user_directory,
                               std::string_view device,
                               std::string *message = nullptr);
} // namespace moderngekko::frontend
