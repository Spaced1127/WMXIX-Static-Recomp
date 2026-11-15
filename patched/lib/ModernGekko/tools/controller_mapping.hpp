#pragma once

#include <string>
#include <string_view>

// Reads the live SDL gamecontrollerdb mapping for a device GUID and works out
// how that pad actually lays its buttons out.
//
// SDL standardises buttons by POSITION (south = "a", east = "b"). Pads that
// print Nintendo labels on those positions therefore report a:b1,b:b0, and a
// positional binding puts GameCube A on the physical B. 8BitDo ships both
// layouts under the same vendor and even the same product line, so the mapping
// is the only reliable signal - not the device name.
struct ControllerMappingInfo
{
  bool has_mapping = false;
  bool nintendo_style = false;   // a/b (and x/y) are swapped vs. positional
  bool dpad_reversed = false;    // firmware reports dpleft/dpright the wrong way
  std::string mapping;
};

ControllerMappingInfo DetectControllerMapping(std::string_view guid);

// Parses a mapping string directly (used by tests and by --pad-info --mapping).
ControllerMappingInfo ParseControllerMapping(std::string_view mapping);
