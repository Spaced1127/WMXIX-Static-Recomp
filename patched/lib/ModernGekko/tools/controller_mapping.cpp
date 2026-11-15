#include "controller_mapping.hpp"

#include <SDL3/SDL.h>

#include <cctype>
#include <cstdlib>

namespace {

// Value of a "key:value" token, e.g. "b1" -> 1, "h0.2" -> -1.
int ButtonIndex(std::string_view token)
{
  if (token.empty() || (token[0] != 'b' && token[0] != 'B'))
    return -1;
  int value = 0;
  bool digits = false;
  for (std::size_t i = 1; i < token.size(); ++i)
  {
    if (!std::isdigit(static_cast<unsigned char>(token[i])))
      break;
    value = value * 10 + (token[i] - '0');
    digits = true;
  }
  return digits ? value : -1;
}

// SDL hat direction bits: 1 up, 2 right, 4 down, 8 left.
int HatDirection(std::string_view token)
{
  const std::size_t dot = token.rfind('.');
  if (dot == std::string_view::npos || dot + 1 >= token.size())
    return 0;
  int value = 0;
  for (std::size_t i = dot + 1; i < token.size(); ++i)
  {
    if (!std::isdigit(static_cast<unsigned char>(token[i])))
      break;
    value = value * 10 + (token[i] - '0');
  }
  return value;
}

std::string_view FindToken(std::string_view mapping, std::string_view key)
{
  const std::string needle = std::string(key) + ":";
  std::size_t pos = 0;
  while ((pos = mapping.find(needle, pos)) != std::string_view::npos)
  {
    const bool at_start = pos == 0 || mapping[pos - 1] == ',';
    if (at_start)
    {
      const std::size_t comma = mapping.find(',', pos);
      const std::size_t end = comma == std::string_view::npos ? mapping.size() : comma;
      return mapping.substr(pos + needle.size(), end - pos - needle.size());
    }
    pos += needle.size();
  }
  return {};
}

} // namespace

ControllerMappingInfo ParseControllerMapping(std::string_view mapping)
{
  ControllerMappingInfo info;
  if (mapping.empty())
    return info;
  info.has_mapping = true;
  info.mapping = std::string(mapping);

  const int a = ButtonIndex(FindToken(mapping, "a"));
  const int b = ButtonIndex(FindToken(mapping, "b"));
  if (a >= 0 && b >= 0 && a != b)
    info.nintendo_style = a > b;

  const int left = HatDirection(FindToken(mapping, "dpleft"));
  const int right = HatDirection(FindToken(mapping, "dpright"));
  if (left != 0 && right != 0)
    info.dpad_reversed = left == 2 && right == 8;

  return info;
}

ControllerMappingInfo DetectControllerMapping(std::string_view guid)
{
  if (guid.size() != 32)
    return {};
  const SDL_GUID sdl_guid = SDL_StringToGUID(std::string(guid).c_str());
  char *mapping = SDL_GetGamepadMappingForGUID(sdl_guid);
  if (!mapping)
    return {};
  const ControllerMappingInfo info = ParseControllerMapping(mapping);
  SDL_free(mapping);
  return info;
}
