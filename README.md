# Shrinkler 6502 Decompressor Acorn BeebAsm Port

This is a BeebAsm 6502 port of https://github.com/atari8xxl/unShrinkler which in itself is a port of the original 68000 version here: https://github.com/askeksa/Shrinkler

This is a [Shrinkler](https://github.com/askeksa/Shrinkler) decompressor in 6502 assembly language.

The routine is compiled conditionally to support one of two Shrinkler variants:

* `unshrinkler_PARITY=0` is the recommended "no parity context" variant that
  is almost sure to perform better with the data you have on an 8-bit machine
* `unshrinkler_PARITY=1` is the original variant for Amiga

The routine is slow. `unshrinkler_FAST=1` makes it about twice faster
at the cost of increased memory usage.

Three memory areas are used:

* `unshrinkler` - code
* `unshrinkler_data` - uninitialized data
* `unshrinkler_zp` - zero-page variables

`unshrinkler_FAST=1` requires `unshrinkler_data` to be aligned on page boundary.
With `unshrinkler_FAST=0` it can be unaligned, at the cost of two extra code bytes
and slightly degraded performance.

Usage
-----

The decompressor assumes that the compressed and the uncompressed data fit
in the memory. Before calling `unshrinkler`, set the locations in the zero-page
variables:

    lda #<packed_data
    sta unshrinkler_zp
    lda #>packed_data
    sta unshrinkler_zp+1
    lda #<unpacked_data
    sta unshrinkler_zp+2
    lda #>unpacked_data
    sta unshrinkler_zp+3
    jsr unshrinkler

As the compressed data is read sequentially and only once, it is possible
to overlap the compressed and uncompressed data. That is, the data being
uncompressed can be stored in place of some compressed data which has been
already read.

Compression
-----------

Download the compressor from https://github.com/askeksa/Shrinkler

Use as follows:

    Shrinkler -d -p -9 -b INPUT_FILE OUTPUT_FILE

Include `-b` for `unshrinkler_PARITY=0`, omit it for `unshrinkler_PARITY=1`.

License
-------

This code is licensed under the standard zlib license.

Copyright (C) 2021 Krzysztof 'XXL' Dudek, Piotr '0xF' Fusik

This software is provided 'as-is', without any express or implied
warranty.  In no event will the authors be held liable for any damages
arising from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it
freely, subject to the following restrictions:

1. The origin of this software must not be misrepresented; you must not
   claim that you wrote the original software. If you use this software
   in a product, an acknowledgment in the product documentation would be
   appreciated but is not required.

2. Altered source versions must be plainly marked as such, and must not be
   misrepresented as being the original software.

3. This notice may not be removed or altered from any source distribution.