# esp32-c3-nix-rust-test

**NOTE**: This repo contains mostly information about the debugging process to get Rust cross-compilation for esp32c3 (`riscv32imc-unknown-none-elf`) to work with Nix, following [an issue in nixpkgs](https://github.com/NixOS/nixpkgs/issues/281527) - for an actual working example [with minimal workarounds](https://github.com/SFrijters/nix-qemu-esp32c3-rust-example/blob/5a12cffec42d58c92f03563d229ea07a8a2e2885/blinky/default.nix#L14-L23) you may want to check out https://github.com/SFrijters/nix-qemu-esp32c3-rust-example .

---

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

## Environment

Linking step fails with this environment:

```
CC_RISCV32IMC_UNKNOWN_NONE_ELF=/nix/store/2931shdx5hk6x1fm1agzj48g8qyvz4gs-x86_64-unknown-linux-gnu-gcc-wrapper-13.2.0/bin/x86_64-unknown-linux-gnu-cc
CXX_RISCV32IMC_UNKNOWN_NONE_ELF=/nix/store/2931shdx5hk6x1fm1agzj48g8qyvz4gs-x86_64-unknown-linux-gnu-gcc-wrapper-13.2.0/bin/x86_64-unknown-linux-gnu-c++
CARGO_TARGET_RISCV32IMC_UNKNOWN_NONE_ELF_LINKER=/nix/store/2931shdx5hk6x1fm1agzj48g8qyvz4gs-x86_64-unknown-linux-gnu-gcc-wrapper-13.2.0/bin/x86_64-unknown-linux-gnu-cc
CC_X86_64_UNKNOWN_LINUX_GNU=/nix/store/xq8920m5mbd83vdlydwli7qsh67gfm5v-gcc-wrapper-13.2.0/bin/cc
CXX_X86_64_UNKNOWN_LINUX_GNU=/nix/store/xq8920m5mbd83vdlydwli7qsh67gfm5v-gcc-wrapper-13.2.0/bin/c++
CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER=/nix/store/xq8920m5mbd83vdlydwli7qsh67gfm5v-gcc-wrapper-13.2.0/bin/cc
CARGO_BUILD_TARGET=x86_64-unknown-linux-gnu HOST_CC=/nix/store/xq8920m5mbd83vdlydwli7qsh67gfm5v-gcc-wrapper-13.2.0/bin/cc
HOST_CXX=/nix/store/xq8920m5mbd83vdlydwli7qsh67gfm5v-gcc-wrapper-13.2.0/bin/c++
cargo build -j 12 --target riscv32imc-unknown-none-elf --frozen --profile release
```

Works before (`nixpkgs@6980e6b35aacccd4e75a76a384f9dec30f31fa55`) with this environment:

```
CC_x86_64-unknown-linux-gnu=/nix/store/rzhpy402dbc2kpk3xz87csnm0xiaw53b-gcc-wrapper-12.3.0/bin/cc
CXX_x86_64-unknown-linux-gnu=/nix/store/rzhpy402dbc2kpk3xz87csnm0xiaw53b-gcc-wrapper-12.3.0/bin/c++
CC_riscv32imc-unknown-none-elf=/nix/store/jgqy1fd352i0n88q54jy2dmy6x6rbr3m-x86_64-unknown-linux-gnu-stage-final-gcc-wrapper-12.3.0/bin/x86_64-unknown-linux-gnu-cc
CXX_riscv32imc-unknown-none-elf=/nix/store/jgqy1fd352i0n88q54jy2dmy6x6rbr3m-x86_64-unknown-linux-gnu-stage-final-gcc-wrapper-12.3.0/bin/x86_64-unknown-linux-gnu-c++
cargo build -j 12 --target riscv32imc-unknown-none-elf --frozen --release
```

## Linker flag fixes

* Remove `"CARGO_TARGET_${stdenv.hostPlatform.rust.cargoEnvVarTarget}_LINKER=${linkerForHost}"`: Works
* Set `cc` explicitly: Fails
```
       > error: linking with `/nix/store/52zpqb06asjd6i5j624hgnh86idhjf1w-x86_64-unknown-linux-gnu-gcc-wrapper-13.2.0/bin/x86_64-unknown-linux-gnu-cc` failed: exit status: 1
       >   |
       >   = note: LC_ALL="C" PATH="/nix/store/hca7lla5l3hjc2gzkxj03abzgynyjsha-rust-default-1.77.0-nightly-2024-01-24/lib/rustlib/x86_64-unknown-linux-gnu/bin:/nix/store/khkhbch4p1wjfl1g89gw1mszvvr7bzv0-gcc-wrapper-13.2.0/bin:/nix/store/j00nb8s5mwaxgi77h21i1ycb91yxxqck-gcc-13.2.0/bin:/nix/store/dvvb6frpdnimidx1f51zjgi3af8rlny1-glibc-2.38-27-bin/bin:/nix/store/5idwbbv23b6vnqdicx97s3hsgrwwnj7j-coreutils-9.4/bin:/nix/store/6zhs433c4cyaih7l65c11zm743sava5a-binutils-wrapper-2.40/bin:/nix/store/0gi4vbw1qfjncdl95a9ply43ymd6aprm-binutils-2.40/bin:/nix/store/hca7lla5l3hjc2gzkxj03abzgynyjsha-rust-default-1.77.0-nightly-2024-01-24/bin:/nix/store/44pqwx8bjngjpkbk1y2dd8pzs49s14w9-patchelf-0.15.0/bin:/nix/store/52zpqb06asjd6i5j624hgnh86idhjf1w-x86_64-unknown-linux-gnu-gcc-wrapper-13.2.0/bin:/nix/store/2s19fbp9540zcijq7g3i09facw1cm079-x86_64-unknown-linux-gnu-gcc-13.2.0/bin:/nix/store/698ff0f9ywzjwkk9vg4kjrqzl3d13shm-glibc-x86_64-unknown-linux-gnu-2.38-27-bin/bin:/nix/store/80383akaif1hcn1xj38kpc2plha5n9ck-x86_64-unknown-linux-gnu-binutils-wrapper-2.40/bin:/nix/store/549j8hyajr63kbcnpq50yh9p5qdiq6pi-x86_64-unknown-linux-gnu-binutils-2.40/bin:/nix/store/5idwbbv23b6vnqdicx97s3hsgrwwnj7j-coreutils-9.4/bin:/nix/store/4ajik70nplhkb8ndn3gqh7v0b09hmvg9-findutils-4.9.0/bin:/nix/store/y4m3b33d240amsyd50d6mn0m9pyf987p-diffutils-3.10/bin:/nix/store/9zial3lqry9f7rsw31r7vs5p1mnb7lan-gnused-4.9/bin:/nix/store/6i00hdmzlj56qy500p5gb5v88wfj6nhg-gnugrep-3.11/bin:/nix/store/w48cndp5bwz4x4l49yr2gbz09g6f91dq-gawk-5.2.2/bin:/nix/store/msavqbm59r0q4wv54s4smp0ixwl6y3dz-gnutar-1.35/bin:/nix/store/6z1ssks5dbmc9zs5cczn9qgx28yl8j8y-gzip-1.13/bin:/nix/store/zd07lalq650lv09xkkp2yc9ahx66lm25-bzip2-1.0.8-bin/bin:/nix/store/05sqpqfnha0pmb5aia3gz968im7n806v-gnumake-4.4.1/bin:/nix/store/cjbyb45nxiqidj95c4k1mh65azn1x896-bash-5.2-p21/bin:/nix/store/mmfzn2r4rq6ljlikmpgk7y1i914g40xi-patch-2.7.6/bin:/nix/store/fp49ki5fbhsq744ljmffcc646yczhw9m-xz-5.4.5-bin/bin:/nix/store/8rk7cyqxf7mdvwjnnvlh5kw7zvvnv3y0-file-5.45/bin" VSLANG="1033" "/nix/store/52zpqb06asjd6i5j624hgnh86idhjf1w-x86_64-unknown-linux-gnu-gcc-wrapper-13.2.0/bin/x86_64-unknown-linux-gnu-cc" "-flavor" "gnu" "/build/rustcYrXocb/symbols.o" "/build/source/target/riscv32imc-unknown-none-elf/release/deps/http_client-ac11b84ea23a5767.http_client.9f7159c39aacdfb4-cgu.0.rcgu.o" "/build/source/target/riscv32imc-unknown-none-elf/release/deps/http_client-ac11b84ea23a5767.http_client.9f7159c39aacdfb4-cgu.1.rcgu.o" "--as-needed" "-L" "/build/source/target/riscv32imc-unknown-none-elf/release/deps" "-L" "/build/source/target/release/deps" "-L" "/build/source/target/riscv32imc-unknown-none-elf/release/build/esp-wifi-sys-5225c3dbc8310c84/out" "-L" "/build/source/target/riscv32imc-unknown-none-elf/release/build/esp32c3-hal-0c5aed28e6482def/out" "-L" "/build/source/target/riscv32imc-unknown-none-elf/release/build/esp32c3-hal-0c5aed28e6482def/out" "-L" "/build/source/target/riscv32imc-unknown-none-elf/release/build/esp-hal-common-39f37cd08fb3d7a5/out" "-L" "/build/source/target/riscv32imc-unknown-none-elf/release/build/esp-riscv-rt-04d40817cc700dbb/out" "-L" "/build/source/target/riscv32imc-unknown-none-elf/release/build/esp32c3-38eacff651c20e02/out" "-L" "/nix/store/hca7lla5l3hjc2gzkxj03abzgynyjsha-rust-default-1.77.0-nightly-2024-01-24/lib/rustlib/riscv32imc-unknown-none-elf/lib" "-Bstatic" "/build/source/target/riscv32imc-unknown-none-elf/release/deps/libesp_wifi-5382a5feefebb679.rlib" "/build/source/target/riscv32imc-unknown-none-elf/release/deps/libsmoltcp-3d476d33b1359432.rlib" "/build/source/target/riscv32imc-unknown-none-elf/release/deps/libbitflags-202fc6784e33a81f.rlib" "/build/source/target/riscv32imc-unknown-none-elf/release/deps/libmanaged-38e0b39431c4abe1.rlib" "/build/source/target/riscv32imc-unknown-none-elf/release/deps/libnum_traits-8d36580bf0571068.rlib" "/build/source/target/riscv32imc-unknown-none-elf/release/deps/libesp_wifi_sys-607964ce98a93983.rlib" "/build/source/target/riscv32imc-unknown-none-elf/release/deps/liblinked_list_allocator-57cfd46bab04234b.rlib" "/build/source/target/riscv32imc-unknown-none-elf/release/deps/libesp_backtrace-5ba6cb617a28fd78.rlib" "/build/source/target/riscv32imc-unknown-none-elf/release/deps/libesp_println-605c1c79af82cf31.rlib" "/build/source/target/riscv32imc-unknown-none-elf/release/deps/liblog-83d1f68b69ef4aec.rlib" "/build/source/target/riscv32imc-unknown-none-elf/release/deps/libembedded_svc-71a51867fb1dd92d.rlib" "/build/source/target/riscv32imc-unknown-none-elf/release/deps/libheapless-b2e4ac38d468a5bc.rlib" "/build/source/target/riscv32imc-unknown-none-elf/release/deps/libatomic_polyfill-283dba1395d4f134.rlib" "/build/source/target/riscv32imc-unknown-none-elf/release/deps/libhash32-688729e11942bb2c.rlib" "/build/source/target/riscv32imc-unknown-none-elf/release/deps/libbyteorder-42c5ec8741676daa.rlib" "/build/source/target/riscv32imc-unknown-none-elf/release/deps/libenumset-a969bf0f20b00f4f.rlib" "/build/source/target/riscv32imc-unknown-none-elf/release/deps/libserde-96ff8100fb0ada47.rlib" "/build/source/target/riscv32imc-unknown-none-elf/release/deps/libno_std_net-700e509b171bd115.rlib" "/build/source/target/riscv32imc-unknown-none-elf/release/deps/libembedded_io-c6b228a498525b8a.rlib" "/build/source/target/riscv32imc-unknown-none-elf/release/deps/libesp32c3_hal-3bf30a13b1df26b5.rlib" "/build/source/target/riscv32imc-unknown-none-elf/release/deps/libesp_hal_common-fe9a2f60c56533fd.rlib" "/build/source/target/riscv32imc-unknown-none-elf/release/deps/libembedded_io-f9ed31aaa1a841e2.rlib" "/build/source/target/riscv32imc-unknown-none-elf/release/deps/libriscv_atomic_emulation_trap-fb13a7a1d51927e0.rlib" "/build/source/target/riscv32imc-unknown-none-elf/release/deps/libbitflags-545edb760913d621.rlib" "/build/source/target/riscv32imc-unknown-none-elf/release/deps/libcfg_if-490d6610dbf2173b.rlib" "/build/source/target/riscv32imc-unknown-none-elf/release/deps/libesp32c3-cde6b027ede2238f.rlib" "/build/source/target/riscv32imc-unknown-none-elf/release/deps/libvcell-d98a990a4b9971dd.rlib" "/build/source/target/riscv32imc-unknown-none-elf/release/deps/libstrum-123bc75e16d55b44.rlib" "/build/source/target/riscv32imc-unknown-none-elf/release/deps/libembedded_dma-5de3388e15e8c56a.rlib" "/build/source/target/riscv32imc-unknown-none-elf/release/deps/libstable_deref_trait-0d436770b7ee220c.rlib" "/build/source/target/riscv32imc-unknown-none-elf/release/deps/libfugit-1de8320630165ba6.rlib" "/build/source/target/riscv32imc-unknown-none-elf/release/deps/libgcd-c8ded18d855aecc5.rlib" "/build/source/target/riscv32imc-unknown-none-elf/release/deps/libesp_riscv_rt-915497c3ab764d44.rlib" "/build/source/target/riscv32imc-unknown-none-elf/release/deps/libriscv-b03ae0e2b56c5974.rlib" "/build/source/target/riscv32imc-unknown-none-elf/release/deps/libcritical_section-2156469018d0dff1.rlib" "/build/source/target/riscv32imc-unknown-none-elf/release/deps/libbit_field-877b3c012578a6db.rlib" "/build/source/target/riscv32imc-unknown-none-elf/release/deps/libembedded_hal-0ae840eca54eed27.rlib" "/build/source/target/riscv32imc-unknown-none-elf/release/deps/libvoid-9fa54f90c9e4de05.rlib" "/build/source/target/riscv32imc-unknown-none-elf/release/deps/libnb-6717805c7c363222.rlib" "/build/source/target/riscv32imc-unknown-none-elf/release/deps/libnb-707460443632abab.rlib" "/build/source/target/riscv32imc-unknown-none-elf/release/deps/librustc_std_workspace_core-6703ffa68ec4695d.rlib" "/build/source/target/riscv32imc-unknown-none-elf/release/deps/libcore-dd7802342d54d7f6.rlib" "/build/source/target/riscv32imc-unknown-none-elf/release/deps/libcompiler_builtins-c631d4eacd967a82.rlib" "-Bdynamic" "-lbtbb" "-lbtdm_app" "-lcoexist" "-lcore" "-lespnow" "-lmesh" "-lnet80211" "-lphy" "-lpp" "-lsmartconfig" "-lwapi" "-lwpa_supplicant" "-z" "noexecstack" "-L" "/nix/store/hca7lla5l3hjc2gzkxj03abzgynyjsha-rust-default-1.77.0-nightly-2024-01-24/lib/rustlib/riscv32imc-unknown-none-elf/lib" "-o" "/build/source/target/riscv32imc-unknown-none-elf/release/deps/http_client-ac11b84ea23a5767" "--gc-sections" "-O1" "-Tlinkall.x" "-Trom_functions.x"
       >   = note: x86_64-unknown-linux-gnu-gcc: error: unrecognized command-line option '-flavor'
       >           x86_64-unknown-linux-gnu-gcc: error: unrecognized command-line option '--as-needed'; did you mean '-mno-needed'?
       >           x86_64-unknown-linux-gnu-gcc: error: unrecognized command-line option '--gc-sections'; did you mean '--data-sections'?
       >
       >
       > error: could not compile `http-client` (bin "http-client") due to 1 previous error
```
* Set `ld` explicitly: Fails
```
/nix/store/0gi4vbw1qfjncdl95a9ply43ymd6aprm-binutils-2.40/bin/ld: cannot find -lgcc_s: No such file or directory
```
* Set `ld.gold` explicitly: Fails
```
/nix/store/0gi4vbw1qfjncdl95a9ply43ymd6aprm-binutils-2.40/bin/ld.gold: error: cannot find -lgcc_s
[ various other errors ]
```
* Set `ld.bfd` explicity: Fails
```
/nix/store/0gi4vbw1qfjncdl95a9ply43ymd6aprm-binutils-2.40/bin/ld.bfd: cannot find -lgcc_s: No such file or directory
```
* Use `lld` if isRiscV: Fails: host system is not recognized as RiscV:
```
trace: { aesSupport = false; avx2Support = false; avx512Support = false; avxSupport = false; canExecute = <LAMBDA>; config = "x86_64-unknown-linux-gnu"; darwinArch = "x86_64"; darwinMinVersion = "10.12"; darwinMinVersionVariable = null; darwinPlatform = null; darwinSdkVersion = "10.12"; efiArch = "x64"; emulator = <LAMBDA>; emulatorAvailable = <LAMBDA>; extensions = { executable = <CODE>; library = <CODE>; sharedLibrary = <CODE>; staticLibrary = <CODE>; }; fma4Support = false; fmaSupport = false; gcc = { }; hasSharedLibraries = true; is32bit = false; is64bit = true; isAarch = false; isAarch32 = false; isAarch64 = false; isAbiElfv2 = false; isAlpha = false; isAndroid = false; isArmv7 = false; isAvr = false; isBSD = false; isBigEndian = false; isCompatible = <LAMBDA>; isCygwin = false; isDarwin = false; isEfi = true; isElf = true; isFreeBSD = false; isGenode = false; isGhcjs = false; isGnu = true; isILP32 = false; isJavaScript = false; isLinux = true; isLittleEndian = true; isLoongArch64 = false; isM68k = false; isMacOS = false; isMacho = false; isMicroBlaze = false; isMinGW = false; isMips = false; isMips32 = false; isMips64 = false; isMips64n32 = false; isMips64n64 = false; isMmix = false; isMsp430 = false; isMusl = false; isNetBSD = false; isNone = false; isOpenBSD = false; isOr1k = false; isPower = false; isPower64 = false; isRedox = false; isRiscV = false; isRiscV32 = false; isRiscV64 = false; isRx = false; isS390 = false; isS390x = false; isSparc = false; isStatic = false; isSunOS = false; isUClibc = false; isUnix = true; isVc4 = false; isWasi = false; isWasm = false; isWindows = false; isi686 = false; isiOS = false; isx86 = true; isx86_32 = false; isx86_64 = true; libDir = "lib64"; libc = "glibc"; linker = "bfd"; linux-kernel = { autoModules = true; baseConfig = "defconfig"; name = "pc"; target = "bzImage"; }; linuxArch = "x86_64"; parsed = { _type = "system"; abi = { _type = "abi"; assertions = [ { assertion = <LAMBDA>; message = "The \"gnu\" ABI is ambiguous on 32-bit ARM. Use \"gnueabi\" or \"gnueabihf\" instead.\n"; } { assertion = <LAMBDA>; message = "The \"gnu\" ABI is ambiguous on big-endian 64-bit PowerPC. Use \"gnuabielfv2\" or \"gnuabielfv1\" instead.\n"; } ]; name = "gnu"; }; cpu = { _type = "cpu-type"; arch = "x86-64"; bits = 64; family = "x86"; name = "x86_64"; significantByte = { _type = "significant-byte"; name = "littleEndian"; }; }; kernel = { _type = "kernel"; execFormat = { _type = "exec-format"; name = "elf"; }; families = { }; name = "linux"; }; vendor = { _type = "vendor"; name = "unknown"; }; }; qemuArch = "x86_64"; rust = { cargoEnvVarTarget = "RISCV32IMC_UNKNOWN_NONE_ELF"; cargoShortTarget = "riscv32imc-unknown-none-elf"; config = "riscv32imc-unknown-none-elf"; isNoStdTarget = <CODE>; platform = <CODE>; rustcTarget = "riscv32imc-unknown-none-elf"; rustcTargetSpec = "riscv32imc-unknown-none-elf"; }; rustc = { config = "riscv32imc-unknown-none-elf"; }; sse3Support = false; sse4_1Support = false; sse4_2Support = false; sse4_aSupport = false; ssse3Support = false; system = "x86_64-linux"; ubootArch = "x86_64"; uname = { processor = "x86_64"; release = null; system = "Linux"; }; useAndroidPrebuilt = false; useiOSPrebuilt = false; }
```

* Force the use of `lld`: Works

## Build logs with different cross

* `http-client-riscv32-none-elf`: Fails, `.cargo/config.toml` is not respected.
```
http-client-riscv32-none-elf>    Compiling atomic-waker v1.1.2
http-client-riscv32-none-elf>
Running `CARGO=/nix/store/l3a4ihxkl7fgj3h7sz9cvi9v4wxkjzda-cargo-1.77.0-nightly-2024-01-24-x86_64-unknown-linux-gnu/bin/cargo CARGO_CRATE_NAME=atomic_waker
CARGO_MANIFEST_DIR=/build/cargo-vendor-dir/atomic-waker-1.1.2
CARGO_PKG_AUTHORS='Stjepan Glavina <stjepang@gmail.com>:Contributors to futures-rs'
CARGO_PKG_DESCRIPTION='A synchronization primitive for task wakeup'
CARGO_PKG_HOMEPAGE=''
CARGO_PKG_LICENSE='Apache-2.0 OR MIT' CARGO_PKG_LICENSE_FILE=''
CARGO_PKG_NAME=atomic-waker
CARGO_PKG_README=README.md
CARGO_PKG_REPOSITORY='https://github.com/smol-rs/atomic-waker'
CARGO_PKG_RUST_VERSION=1.36
CARGO_PKG_VERSION=1.1.2
CARGO_PKG_VERSION_MAJOR=1
CARGO_PKG_VERSION_MINOR=1
CARGO_PKG_VERSION_PATCH=2
CARGO_PKG_VERSION_PRE=''
CARGO_RUSTC_CURRENT_DIR=/build/cargo-vendor-dir/atomic-waker-1.1.2
LD_LIBRARY_PATH='/build/source/target/release/deps:/nix/store/hca7lla5l3hjc2gzkxj03abzgynyjsha-rust-default-1.77.0-nightly-2024-01-24/lib'
rustc
--crate-name atomic_waker
--edition=2018
/build/cargo-vendor-dir/atomic-waker-1.1.2/src/lib.rs
--error-format=json
--json=diagnostic-rendered-ansi,artifacts,future-incompat
--crate-type lib
--emit=dep-info,metadata,link -C opt-level=3 -C lto=off -C embed-bitcode=no -C metadata=874e6f4a481835d7 -C extra-filename=-874e6f4a481835d7
--out-dir /build/source/target/riscv32imc-unknown-none-elf/release/deps
--target riscv32imc-unknown-none-elf
-C linker=/nix/store/h14lx5an7mzwmdc1drvanbawyld90h3v-riscv32-none-elf-llvm-binutils-wrapper-17.0.6/bin/riscv32-none-elf-ld.lld
-L dependency=/build/source/target/riscv32imc-unknown-none-elf/release/deps
-L dependency=/build/source/target/release/deps
--extern 'noprelude:compiler_builtins=/build/source/target/riscv32imc-unknown-none-elf/release/deps/libcompiler_builtins-c631d4eacd967a82.rmeta'
--extern 'noprelude:core=/build/source/target/riscv32imc-unknown-none-elf/release/deps/libcore-dd7802342d54d7f6.rmeta'
-Z unstable-options
--cap-lints warn
-C target-feature=-crt-static`
```

* `http-client-x86_64-unknown-linux-gnu`: Works
```
http-client-x86_64-unknown-linux-gnu>    Compiling atomic-waker v1.1.2
http-client-x86_64-unknown-linux-gnu>
Running `CARGO=/nix/store/l3a4ihxkl7fgj3h7sz9cvi9v4wxkjzda-cargo-1.77.0-nightly-2024-01-24-x86_64-unknown-linux-gnu/bin/cargo CARGO_CRATE_NAME=atomic_waker
CARGO_MANIFEST_DIR=/build/cargo-vendor-dir/atomic-waker-1.1.2
CARGO_PKG_AUTHORS='Stjepan Glavina <stjepang@gmail.com>:Contributors to futures-rs'
CARGO_PKG_DESCRIPTION='A synchronization primitive for task wakeup'
CARGO_PKG_HOMEPAGE=''
CARGO_PKG_LICENSE='Apache-2.0 OR MIT'
CARGO_PKG_LICENSE_FILE=''
CARGO_PKG_NAME=atomic-waker
CARGO_PKG_README=README.md
CARGO_PKG_REPOSITORY='https://github.com/smol-rs/atomic-waker'
CARGO_PKG_RUST_VERSION=1.36
CARGO_PKG_VERSION=1.1.2
CARGO_PKG_VERSION_MAJOR=1
CARGO_PKG_VERSION_MINOR=1
CARGO_PKG_VERSION_PATCH=2
CARGO_PKG_VERSION_PRE=''
CARGO_RUSTC_CURRENT_DIR=/build/cargo-vendor-dir/atomic-waker-1.1.2
LD_LIBRARY_PATH='/build/source/target/release/deps:/nix/store/hca7lla5l3hjc2gzkxj03abzgynyjsha-rust-default-1.77.0-nightly-2024-01-24/lib'
rustc
--crate-name atomic_waker
--edition=2018
/build/cargo-vendor-dir/atomic-waker-1.1.2/src/lib.rs
--error-format=json
--json=diagnostic-rendered-ansi,artifacts,future-incompat
--crate-type lib
--emit=dep-info,metadata,link -C opt-level=3 -C lto=off -C embed-bitcode=no -C metadata=874e6f4a481835d7 -C extra-filename=-874e6f4a481835d7
--out-dir /build/source/target/riscv32imc-unknown-none-elf/release/deps
--target riscv32imc-unknown-none-elf
-C linker=/nix/store/zakn8i3f6chbhg0dp99cfl4nafwlrzql-x86_64-unknown-linux-gnu-llvm-binutils-wrapper-16.0.6/bin/x86_64-unknown-linux-gnu-ld.lld
-L dependency=/build/source/target/riscv32imc-unknown-none-elf/release/deps
-L dependency=/build/source/target/release/deps
--extern 'noprelude:compiler_builtins=/build/source/target/riscv32imc-unknown-none-elf/release/deps/libcompiler_builtins-c631d4eacd967a82.rmeta'
--extern 'noprelude:core=/build/source/target/riscv32imc-unknown-none-elf/release/deps/libcore-dd7802342d54d7f6.rmeta'
-Z unstable-options
--cap-lints warn
-C link-arg=-Tlinkall.x
-C link-arg=-Trom_functions.x
-C force-frame-pointers
-C target-feature=+a --cfg target_has_atomic_load_store --cfg 'target_has_atomic_load_store="8"' --cfg 'target_has_atomic_load_store="16"' --cfg 'target_has_atomic_load_store="32"' --cfg 'target_has_atomic_load_store="ptr"' --cfg target_has_atomic --cfg 'target_has_atomic="8"' --cfg 'target_has_atomic="16"' --cfg 'target_has_atomic="32"' --cfg 'target_has_atomic="ptr"'`
```
