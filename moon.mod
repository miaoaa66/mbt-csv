// Learn more about moon.mod configuration:
// https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html

name = "miaoaa66/mbt-csv"

version = "0.1.0"

readme = "README.mbt.md"

repository = "https://github.com/miaoaa66/mbt-csv"

license = "MIT"

keywords = ["csv", "data-processing", "table", "tsv"]

preferred_target = "wasm"

description = "Self-contained CSV toolkit for MoonBit: RFC 4180 parser and writer, header-aware Table with by-name access, filtering and column selection, typed record helpers (int/double), lenient parsing of damaged files, and a CLI."

import {
  "moonbitlang/x@0.5.5",
}
