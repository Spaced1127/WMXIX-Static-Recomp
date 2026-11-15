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

// Button layout families. SDL normalises every gamepad positionally, so an
// Xbox pad and a DualSense already agree; Nintendo pads put their labelled A/B
// and X/Y the other way round, which is what the Nintendo layout fixes.
enum class ControllerLayout { Auto, Xbox, PlayStation, Nintendo, Generic };
const char *ControllerLayoutLabel(ControllerLayout layout);

// True when the file matches one of the auto-generated bodies, i.e. safe to
// regenerate on a layout change. A hand-edited profile is left alone.
bool ControllerConfigIsGenerated(const std::filesystem::path &user_directory);
// Which generated layout the file matches, if any. Used to migrate profiles
// written before mapping-based detection landed.
bool MatchGeneratedControllerProfile(const std::filesystem::path &user_directory,
                                     ControllerLayout *layout, bool *dpad_swap);
// True when an existing auto-generated profile should be rewritten because the
// live mapping now resolves to a Nintendo layout. Custom or manually forced
// profiles are never migrated.
bool ControllerConfigNeedsMigration(const std::filesystem::path &user_directory,
                                    ControllerLayout detected);

// GUID-level identification, following SDL's gamecontrollerdb semantics: the
// SDL GUID carries the USB vendor/product, so an Edge or Elite is recognised by
// hardware id rather than by a product name.
struct ControllerIdentity {
  unsigned short vendor = 0;
  unsigned short product = 0;
  bool has_ids = false;
};
ControllerIdentity ParseControllerGuid(std::string_view guid);
ControllerLayout DetectControllerLayout(std::string_view device,
                                        std::string_view guid = {});

bool GenerateControllerConfig(const std::filesystem::path &user_directory,
                              std::span<const std::string> controllers,
                              std::span<const std::string> guids,
                              std::string *message,
                              ControllerLayout layout = ControllerLayout::Auto,
                              bool dpad_swap = false);
bool GenerateControllerConfig(const std::filesystem::path &user_directory,
                              std::span<const std::string> controllers,
                              std::string *message,
                              ControllerLayout layout = ControllerLayout::Auto,
                              bool dpad_swap = false);
bool GenerateControllerConfig(const std::filesystem::path &user_directory,
                              std::string_view controller, std::string_view guid,
                              std::string *message,
                              ControllerLayout layout = ControllerLayout::Auto,
                              bool dpad_swap = false);
bool GenerateControllerConfig(const std::filesystem::path &user_directory,
                              std::string_view controller, std::string *message,
                              ControllerLayout layout = ControllerLayout::Auto,
                              bool dpad_swap = false);
bool EnsureControllerConfig(const std::filesystem::path &user_directory,
                            std::span<const std::string> controllers,
                            std::string *message);
bool EnsureControllerConfig(const std::filesystem::path &user_directory,
                            std::string_view controller, std::string *message);
} // namespace moderngekko::frontend
