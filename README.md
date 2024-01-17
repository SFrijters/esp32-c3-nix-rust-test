# http_client

Based on https://n8henrie.com/2023/09/compiling-rust-for-the-esp32-with-nix/ and https://github.com/esp-rs/no_std-training .

## Usage

Set correct values in `wifi-settings.nix`.
Attach the XIAO_ESP32C3 to a USB port.

To build the code on the fly:

```console
$ nix develop
...
$ cargo build
```

To build the code and flash it onto the device:

```console
$ nix run
```

Expected behaviour: the device gets flashed tries to access a website over WiFi, writing output to the serial port.

## Update blockers


* Updating `nixpkgs` in `flake.nix` to `release-23.11`:

```console
$ nix build
[...]
       >   = note: x86_64-unknown-linux-gnu-gcc: error: unrecognized command-line option '-flavor'
       >           x86_64-unknown-linux-gnu-gcc: error: unrecognized command-line option '--as-needed'; did you mean '-mno-needed'?
       >           x86_64-unknown-linux-gnu-gcc: error: unrecognized command-line option '--gc-sections'; did you mean '--data-sections'?
       >
       > error: could not compile `http-client` (bin "http-client") due to 1 previous error
```

* Updating the toolchain in `rust-toolchain.toml` to `1.75.0`:

```console
$ cargo build
[...]
error[E0432]: unresolved import `std::sync::atomic::AtomicUsize`
   --> /<redacted>/cargo/registry/src/index.crates.io-6f17d22bba15001f/log-0.4.20/src/lib.rs:352:25
    |
352 | use std::sync::atomic::{AtomicUsize, Ordering};
    |                         ^^^^^^^^^^^ no `AtomicUsize` in `sync::atomic`

error[E0432]: unresolved import `core::sync::atomic::AtomicUsize`
  --> /<redacted>/cargo/registry/src/index.crates.io-6f17d22bba15001f/atomic-waker-1.1.2/src/lib.rs:27:5
   |
27 | use core::sync::atomic::AtomicUsize;
   |     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ no `AtomicUsize` in `sync::atomic`

For more information about this error, try `rustc --explain E0432`.
error: could not compile `atomic-waker` (lib) due to previous error
warning: build failed, waiting for other jobs to finish...
error: could not compile `log` (lib) due to previous error
```

* Updating `esp-wifi` in `Cargo.toml` to 0.2.0 (`b6b10f8f9960cf3fd4147a62a04d81e88cbf2163`):

```console
$ cargo build
[...]
362 | / compile_error!(
363 | |     "cfg(portable_atomic_unsafe_assume_single_core) does not compatible with this target;\n\
364 | |      if you need cfg(portable_atomic_unsafe_assume_single_core) support for this target,\n\
365 | |      please submit an issue at <https://github.com/taiki-e/portable-atomic>"
366 | | );
    | |_^
[...and more...]
```

