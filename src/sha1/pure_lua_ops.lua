local common = require "sha1.common"

local ops = {}

local bytes_to_uint32 = common.bytes_to_uint32
local uint32_to_bytes = common.uint32_to_bytes

function ops.uint32_lrot(a, bits)
   local power = 2 ^ bits
   local inv_power = 0x100000000 / power
   local lower_bits = a % inv_power
   return (lower_bits * power) + ((a - lower_bits) / inv_power)
end

-- Build caches for bitwise `and` and `xor` over bytes to speed up uint32 operations.

-- Returns a cache containing all values of a 8bit bitwise operator, given an operator over single bits.
-- Value of `op(a, b)` is stored in `cache[a * 256 + b]`.
local function make_op_cache(bit_op)
   local bit_op_0_0 = bit_op(0, 0)
   local bit_op_0_1 = bit_op(0, 1)
   local bit_op_1_0 = bit_op(1, 0)
   local bit_op_1_1 = bit_op(1, 1)

   local cache = {[0] = bit_op_0_0}

   -- The implementation used is an optimized version of the following reference one,
   -- with intermediate calculations reused and moved to the outermost loop possible,
   -- and with multiplications by loop counter replaced with incremental additions.

   -- for a = 0, 127 do
   --    for b = 0, 127 do
   --       -- For all pairs of 7bit numbers (a, b) (so, both a and b have their highest bit clear):
   --       -- Let v be (a op b) << 1; then the following equations hold:
   --       -- * (a << 1) op (b << 1) = v + (0 op 0);
   --       -- * (a << 1) op ((b << 1) + 1) = v + (0 op 1);
   --       -- * ((a << 1) + 1) op (b << 1) = v + (1 op 0);
   --       -- * ((a << 1) + 1) op ((b << 1) + 1) = v + (1 op 1);
   --       local v = cache[y * 256 + x] * 2
   --       cache[a * 2 * 256 + b * 2] = v + bit_op_0_0
   --       cache[a * 2 * 256 + b * 2 + 1] = v + bit_op_0_1
   --       cache[(a * 2 + 1) * 256 + b * 2] = v + bit_op_1_0
   --       cache[(a * 2 + 1) * 256 + b * 2 + 1] = v + bit_op_1_1
   --       -- a op b is cached on the step with (a', b') = (a >> 1, b >> 1),
   --       -- so that it's always defined by the time it's needed (a = 0, b = 0 is the base case).
   --    end
   -- end

   local a_by_2_by_256_plus_b_by_2 = 0

   for a_by_256 = 0, 127 * 256, 256 do
      for a_by_256_plus_b = a_by_256, a_by_256 + 127 do
         local v = cache[a_by_256_plus_b] * 2
         cache[a_by_2_by_256_plus_b_by_2] = v + bit_op_0_0
         cache[a_by_2_by_256_plus_b_by_2 + 1] = v + bit_op_0_1
         cache[a_by_2_by_256_plus_b_by_2 + 256] = v + bit_op_1_0
         cache[a_by_2_by_256_plus_b_by_2 + 257] = v + bit_op_1_1
         a_by_2_by_256_plus_b_by_2 = a_by_2_by_256_plus_b_by_2 + 2
      end

      a_by_2_by_256_plus_b_by_2 = a_by_2_by_256_plus_b_by_2 + 256
   end

   return cache
end

local byte_and_cache = make_op_cache(function(a, b) return a * b end)
local byte_xor_cache = make_op_cache(function(a, b) return a == b and 0 or 1 end)

function ops.byte_xor(a, b)
   return byte_xor_cache[a * 256 + b]
end

function ops.uint32_xor_3(a, b, c)
   local a1, a2, a3, a4 = uint32_to_bytes(a)
   local b1, b2, b3, b4 = uint32_to_bytes(b)
   local c1, c2, c3, c4 = uint32_to_bytes(c)

   return bytes_to_uint32(
      byte_xor_cache[a1 * 256 + byte_xor_cache[b1 * 256 + c1]],
      byte_xor_cache[a2 * 256 + byte_xor_cache[b2 * 256 + c2]],
      byte_xor_cache[a3 * 256 + byte_xor_cache[b3 * 256 + c3]],
      byte_xor_cache[a4 * 256 + byte_xor_cache[b4 * 256 + c4]]
   )
end

function ops.uint32_xor_4(a, b, c, d)
   local a1, a2, a3, a4 = uint32_to_bytes(a)
   local b1, b2, b3, b4 = uint32_to_bytes(b)
   local c1, c2, c3, c4 = uint32_to_bytes(c)
   local d1, d2, d3, d4 = uint32_to_bytes(d)

   return bytes_to_uint32(
      byte_xor_cache[a1 * 256 + byte_xor_cache[b1 * 256 + byte_xor_cache[c1 * 256 + d1]]],
      byte_xor_cache[a2 * 256 + byte_xor_cache[b2 * 256 + byte_xor_cache[c2 * 256 + d2]]],
      byte_xor_cache[a3 * 256 + byte_xor_cache[b3 * 256 + byte_xor_cache[c3 * 256 + d3]]],
      byte_xor_cache[a4 * 256 + byte_xor_cache[b4 * 256 + byte_xor_cache[c4 * 256 + d4]]]
   )
end

function ops.uint32_ternary(a, b, c)
   local a1, a2, a3, a4 = uint32_to_bytes(a)
   local b1, b2, b3, b4 = uint32_to_bytes(b)
   local c1, c2, c3, c4 = uint32_to_bytes(c)

   -- (a & b) + (~a & c) has less bitwise operations than (a & b) | (~a & c).
   return bytes_to_uint32(
      byte_and_cache[b1 * 256 + a1] + byte_and_cache[c1 * 256 + 255 - a1],
      byte_and_cache[b2 * 256 + a2] + byte_and_cache[c2 * 256 + 255 - a2],
      byte_and_cache[b3 * 256 + a3] + byte_and_cache[c3 * 256 + 255 - a3],
      byte_and_cache[b4 * 256 + a4] + byte_and_cache[c4 * 256 + 255 - a4]
   )
end

function ops.uint32_majority(a, b, c)
   local a1, a2, a3, a4 = uint32_to_bytes(a)
   local b1, b2, b3, b4 = uint32_to_bytes(b)
   local c1, c2, c3, c4 = uint32_to_bytes(c)

   -- (a & b) + (c & (a ~ b)) has less bitwise operations than (a & b) | (a & c) | (b & c).
   return bytes_to_uint32(
      byte_and_cache[a1 * 256 + b1] + byte_and_cache[c1 * 256 + byte_xor_cache[a1 * 256 + b1]],
      byte_and_cache[a2 * 256 + b2] + byte_and_cache[c2 * 256 + byte_xor_cache[a2 * 256 + b2]],
      byte_and_cache[a3 * 256 + b3] + byte_and_cache[c3 * 256 + byte_xor_cache[a3 * 256 + b3]],
      byte_and_cache[a4 * 256 + b4] + byte_and_cache[c4 * 256 + byte_xor_cache[a4 * 256 + b4]]
   )
end

return ops
