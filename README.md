# sha1

[![Build status](https://travis-ci.org/mpeterv/sha1.png?branch=master)](https://travis-ci.org/mpeterv/sha1)
[![Test coverage](https://codecov.io/gh/mpeterv/sha1/branch/master/graph/badge.svg)](https://codecov.io/gh/mpeterv/sha1)
[![License](https://img.shields.io/badge/License-MIT-brightgreen.svg)](LICENSE)

This module implements SHA-1 and HMAC-SHA1 in pure Lua. For better performance it uses different bitwise operation implementations depending on environment:

* On Lua 5.1:
  - Uses `bit` module provided by [luabitop](https://luarocks.org/modules/luarocks/luabitop) rock if it is available.
  - Otherwise, uses `bit32` module provided by [bit32](https://luarocks.org/modules/siffiejoe/bit32) if rock if it is available.
  - Otherwise, uses an implementation written in Lua.
* On Lua 5.2: uses built-in `bit32` module.
* On Lua 5.3: uses built-in bitwise operators.
* On LuaJIT 2.x: uses built-in `bit` module.

## Installation

For installation using [LuaRocks](https://luarocks.org/) run `luarocks install sha1`.

For manual installation copy `src/sha1` into a directory within `package.path`.

## Usage

```lua
local sha1 = require "sha1"

-- Prints module version in MAJOR.MINOR.PATCH format.
print(sha1.version)

-- Returns a hex string of length 40. sha1(message) also works.
local hash_as_hex = sha1.sha1(message)

-- Returns raw bytes as a string of length 20.
local hash_as_data = sha1.binary(message)

-- Returns a hex string of length 40.
local hmac_as_hex = sha1.hmac(key, message)

-- Returns raw bytes as a string of length 20.
local hmac_as_data = sha1.hmac_binary(key, message)
```

## Testing

To run the test suite ensure that [busted](http://olivinelabs.com/busted/) testing framework is installed and run `busted`.

## Credits

`sha1` module is built upon an implementation by Eike Decker, based on original work by Jeffrey Friedl and cleaned up by [Enrique García Cota](https://github.com/kikito).

## License

This version of the module, as well as all the previous ones on which it is based, are implemented under the MIT license (see LICENSE file for details).
