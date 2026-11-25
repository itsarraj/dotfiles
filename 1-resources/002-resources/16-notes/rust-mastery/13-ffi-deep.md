# FFI Deep Dive: bindgen, cbindgen, libloading, and Cross-Language Bindings

Prerequisite: handbook §6 (calling conventions/ABI in full), §31.4 (`extern "C"`, `libc`, `bindgen` basics). This file covers the remaining direction (Rust exposed *to* other languages) and the specific binding layers for JNI, Python, Node, and WebAssembly.

## bindgen vs. cbindgen -- Opposite Directions

**`bindgen`** (handbook §20.4) generates Rust `extern "C"` declarations *from* a C/C++ header -- for calling *into* an existing C/C++ library from Rust.

**`cbindgen`** does the reverse: generates a C/C++ header *from* your Rust crate's `#[no_mangle] pub extern "C" fn` declarations and `#[repr(C)]` types -- for exposing a Rust library *to* C/C++ callers. This is the standard toolchain when Rust is the library being embedded into a larger C/C++ codebase (rather than the other way around), which is an increasingly common pattern for performance- or safety-critical components (a codec, a parser, a cryptographic routine) being incrementally introduced into an existing C/C++ project without rewriting the whole thing.

```rust
#[no_mangle]                              // prevents rustc from mangling the symbol name
pub extern "C" fn add(a: i32, b: i32) -> i32 { a + b }   // extern "C": the stable ABI, §6
```

`#[no_mangle]` matters because ordinary Rust functions have compiler- and version-specific *mangled* names (encoding the function's full path and generic parameters into the symbol name) -- a C caller has no way to predict or reference that mangled name, so exposing a function to C requires disabling mangling and committing to the plain, stable symbol name instead.

## libloading -- Dynamic Loading at Runtime

Rather than linking against a shared library at build time (handbook §8.3's ordinary dynamic linking, resolved by the loader at process start, §8.4), `libloading` calls `dlopen`/`dlsym` (or the Windows equivalents) at **runtime**, to load a library whose identity isn't known until the program is actually running -- the mechanism behind plugin systems (loading a `.so`/`.dll` chosen by user configuration or discovered at startup) where the set of libraries to load isn't fixed at compile time at all.

```rust
unsafe {
    let lib = libloading::Library::new("libplugin.so")?;
    let func: libloading::Symbol<unsafe extern "C" fn(i32) -> i32> = lib.get(b"process")?;
    let result = func(42);
}
```

Every step here is genuinely `unsafe` in a way ordinary static FFI isn't: the compiler has *zero* static knowledge that `libplugin.so` actually exports a symbol named `process` with that exact signature -- if it doesn't, or the signature doesn't actually match, this is undefined behavior with no compile-time check to catch it, which is a meaningfully larger trust burden than `bindgen`-generated bindings (which at least reflect an actual header at build time) or ordinary static/dynamic linking (which the linker verifies symbol *existence*, if not full signature correctness, for).

## JNI (Java Native Interface)

Calling Rust from Java/Kotlin (Android, or JVM-hosted server code wanting a native-performance component) goes through **JNI**, which defines its own calling convention and type-mapping layer distinct from the plain C ABI (handbook §6) -- Java's garbage-collected object references aren't raw pointers a C-ABI function could use directly, so JNI functions receive an opaque `JNIEnv*` pointer providing a *function table* of callbacks for interacting with the JVM (looking up classes, calling Java methods, converting between Java and native strings) rather than direct memory access to Java objects. The `jni` crate wraps this JNI function-table protocol in a more idiomatic Rust API, but the underlying model (indirect, JVM-mediated access rather than direct memory sharing) is a genuinely different, more constrained shape than ordinary `extern "C"` FFI, precisely because the JVM needs to retain control over its own managed heap (for garbage collection to remain correct) rather than letting foreign code hold raw pointers into it indefinitely.

## Python Bindings (PyO3)

**`PyO3`** lets Rust code be compiled into a native Python extension module (`#[pyfunction]`, `#[pyclass]`) or, in the other direction, lets Rust code embed and call into a Python interpreter. The core complexity PyO3 manages: Python's own reference-counting garbage collector expects every object access to go through its C API correctly (incrementing/decrementing refcounts at the right points) and, critically, the **GIL (Global Interpreter Lock)** -- PyO3's types (`Python<'py>` acting as a compile-time-checked proof token that the GIL is currently held) encode "is the GIL held right now" into the type system, so code that needs GIL-protected access to Python objects can't accidentally compile without actually holding it -- a direct, Rust-flavored application of the same "encode an invariant into the type system rather than trusting runtime discipline" philosophy (handbook §34.1) applied to a foreign runtime's own locking requirement rather than Rust's own memory model.

## Node.js Bindings (napi-rs / neon)

Similar goal (native-speed Rust code callable from JavaScript/TypeScript running under Node) via N-API (Node's stable ABI for native addons, designed specifically to remain binary-compatible across Node versions, unlike the older V8-API-direct addon approach that broke on every V8/Node upgrade) -- `napi-rs` and `neon` both wrap N-API in idiomatic Rust, handling the JavaScript engine's own garbage-collected-value marshaling (converting between JS values and Rust types) and, for async Rust code, bridging between a tokio runtime and Node's own single-threaded event loop (typically via N-API's thread-safe function mechanism, letting a background Rust thread safely schedule a callback back onto Node's main JS thread).

## WebAssembly

Compiling Rust to WebAssembly (`wasm32-unknown-unknown` or `wasm32-wasi` targets) is a fundamentally different kind of "FFI" -- not calling into an existing ABI, but targeting an entirely different, sandboxed **virtual instruction set** with its own linear-memory model (a single, contiguous, bounds-checked memory region the Wasm module operates within, isolated from the host's own memory entirely by construction, not merely by convention). **`wasm-bindgen`** generates the glue code needed to pass richer types (strings, structs, JS objects) across the Wasm/JavaScript boundary, since Wasm's own function-call ABI natively only supports plain numeric types (integers and floats) -- anything else (a `String`, a `Vec<T>`) has to be marshaled manually (typically: write the data into the module's linear memory, pass a pointer and length as plain numbers, and have the JS side read back out of that memory region) which is exactly what `wasm-bindgen`'s generated code automates. This sandboxing property (genuine memory isolation from the host, enforced by the Wasm runtime itself, not just by the guest code's own good behavior) is precisely why Wasm is also increasingly used as a **plugin sandboxing** mechanism outside the browser entirely (server-side plugin systems that want to run untrusted or semi-trusted third-party code without giving it access to the host process's memory) -- a genuinely different use case than "compile Rust to run in a web page," using the identical underlying technology.

## Key Takeaways

- `bindgen` and `cbindgen` are exact mirror images -- consuming vs. producing a C header -- and picking the right one depends entirely on which language is calling which.
- `libloading`'s runtime `dlopen`/`dlsym` trades away the linker's build-time symbol-existence check that ordinary static/dynamic linking gives you for free -- a genuinely larger unsafe-correctness burden the programmer has to carry manually.
- JNI, PyO3, and napi-rs all solve the same underlying problem (bridging Rust's ownership model against a foreign runtime's own garbage collector/locking requirements) with runtime-specific mechanisms -- PyO3's GIL-token-as-type-parameter is a particularly clean example of encoding a foreign invariant into Rust's own type system.
- WebAssembly's linear-memory sandboxing is a genuine security property enforced by the runtime, which is why it's used as a general untrusted-code sandbox well beyond its original browser use case.

## Interview Notes

- "Why is `libloading`-based dynamic loading considered a bigger unsafe liability than ordinary `extern \"C\"` FFI against a linked library?" -- the linker verifies a linked-against symbol actually exists (and, with a proper header, that its signature matches) at build time; `dlopen`/`dlsym` defer symbol resolution to runtime with zero static verification that the symbol exists or that the assumed function signature is actually correct.
- "What specific problem does PyO3's `Python<'py>` GIL token solve?" -- it encodes "the GIL is currently held" as a compile-time-checked type-level fact, so code requiring GIL-protected access to Python objects can't be written (and compiled) without actually proving, via holding that token, that the GIL is held at that point.
