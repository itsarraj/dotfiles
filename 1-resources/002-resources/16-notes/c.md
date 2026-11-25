# C Notes

Complete reference on C -- syntax, memory model, the standard library, and the systems-level details that make C different from higher-level languages. C gives you almost no safety net (no garbage collector, no bounds checking, no ownership checker) in exchange for direct control over memory and predictable performance. Every section below assumes a C11/C17-capable compiler (gcc or clang) on a POSIX-ish system unless noted.

---

## 1. Compilation Model

C source goes through four distinct stages before you get a running program. Understanding this pipeline explains most "why does this error happen" questions.

1. **Preprocessing** -- textual substitution. Expands `#include`, `#define`, `#if`/`#ifdef`, strips comments. Output is still C source (see it with `gcc -E file.c`).
2. **Compilation** -- preprocessed source -> assembly for the target architecture (`gcc -S file.c` -> `file.s`).
3. **Assembly** -- assembly -> machine code in an object file (`gcc -c file.c` -> `file.o`). Object files contain machine code plus an unresolved symbol table.
4. **Linking** -- the linker resolves symbols across object files and libraries into a single executable (or shared library). Undefined reference errors happen here, not at compile time.

```sh
gcc -E main.c > main.i     # stage 1 only
gcc -S main.c              # stage 1-2, produces main.s
gcc -c main.c              # stage 1-3, produces main.o
gcc main.o -o main         # stage 4, produces executable
gcc main.c -o main         # all four stages at once
```

Each `.c` file is a **translation unit**: the preprocessor output of that file plus everything it `#include`s. The compiler works one translation unit at a time -- it has no knowledge of other `.c` files unless declarations are shared via headers.

### Common compiler flags (gcc/clang)

```sh
gcc -std=c17 -Wall -Wextra -Wpedantic -O2 -g -o prog main.c
```

- `-std=c17` / `-std=c11` / `-std=c99` -- pick a language standard
- `-Wall -Wextra` -- enable the vast majority of useful warnings (always use these)
- `-Wpedantic` -- warn on non-standard extensions
- `-Werror` -- treat warnings as errors
- `-O0/-O1/-O2/-O3/-Os` -- optimization level (`-O0` for debugging, `-O2` typical release)
- `-g` -- include debug symbols (for gdb)
- `-fsanitize=address,undefined` -- instrument with ASan/UBSan (see §33)
- `-Iinclude/` -- add an include search path
- `-Ldir -lfoo` -- link against `libfoo.a`/`libfoo.so` found in `dir`

---

## 2. Getting Started

```c
#include <stdio.h>

int main(void) {
    printf("Hello, world!\n");
    return 0;
}
```

- `#include <stdio.h>` pulls in declarations for the standard I/O functions.
- `int main(void)` -- the entry point. Returns an exit status to the OS; `0` means success. `(void)` explicitly means "no arguments" -- `int main()` in old-style C means "unspecified arguments," which is different and best avoided.
- `main` can also be declared `int main(int argc, char *argv[])` to receive command-line arguments: `argc` is the argument count, `argv` is an array of C strings, `argv[0]` is the program name.
- Returning from `main` without a `return` statement implicitly returns `0` (C99+ only).

```sh
gcc -std=c17 -Wall -Wextra -o hello hello.c
./hello
```

---

## 3. Basic Syntax & Structure

- Statements end with `;`. Blocks are delimited by `{ }`.
- C is case-sensitive, free-form (whitespace/newlines mostly don't matter syntactically).
- Comments: `// line comment` (C99+) and `/* block comment */` (all versions, cannot nest).
- Identifiers: letters, digits, underscore; cannot start with a digit. Names starting with `_` followed by a capital letter, or `__`, are reserved for the implementation -- don't use them.
- Every variable and function must be **declared** before use in the current translation unit. A declaration introduces a name and type; a **definition** also allocates storage / provides a function body. `extern int x;` is a declaration; `int x;` at file scope is (usually) a definition.

---

## 4. Data Types

### 4.1 Basic (integer) types

| Type | Typical size (LP64) | Notes |
|---|---|---|
| `char` | 1 byte | signedness of plain `char` is implementation-defined |
| `signed char` / `unsigned char` | 1 byte | explicit signedness |
| `short` | 2 bytes | at least 16 bits |
| `int` | 4 bytes | at least 16 bits, "natural" word size |
| `long` | 8 bytes (Linux/macOS), 4 bytes (Windows) | at least 32 bits |
| `long long` | 8 bytes | at least 64 bits (C99+) |
| `_Bool` / `bool` (`<stdbool.h>`) | 1 byte | C99+, values `0`/`1` |

C only guarantees **minimum** sizes and orderings (`char <= short <= int <= long <= long long`); exact sizes are platform/ABI-dependent. Never assume `int` is 32 bits -- use `sizeof` or fixed-width types when it matters.

```c
#include <stdio.h>
printf("%zu\n", sizeof(int));   // %zu for size_t
```

### 4.2 Fixed-width types (`<stdint.h>`, C99+)

Use these whenever exact width matters (protocol parsing, binary formats, bit-twiddling):

```c
#include <stdint.h>

int8_t   a;   uint8_t   b;   // exactly 8 bits
int16_t  c;   uint16_t  d;   // exactly 16 bits
int32_t  e;   uint32_t  f;   // exactly 32 bits
int64_t  g;   uint64_t  h;   // exactly 64 bits

intptr_t  p;   // integer wide enough to hold a pointer
uintptr_t q;
size_t    n;   // unsigned, result type of sizeof, array indices
ssize_t   m;   // POSIX signed equivalent (for error returns of -1)
ptrdiff_t d;   // result of pointer subtraction
```

### 4.3 Floating point

```c
float  f = 3.14f;   // typically 32-bit IEEE 754
double d = 3.14;     // typically 64-bit IEEE 754, default for literals
long double ld = 3.14L;  // extended precision, platform-dependent (often 80-bit on x86)
```

### 4.4 `void`

`void` means "no type." Used for: functions returning nothing (`void f(void)`), generic pointers (`void *`), and functions taking no arguments (`f(void)`).

### 4.5 Type qualifiers & conversions

- Implicit conversions ("usual arithmetic conversions") happen in mixed-type expressions -- smaller types promote to `int` first ("integer promotion"), then to the widest type present. This causes classic bugs:

```c
unsigned int u = 1;
int i = -1;
if (i < u) { /* never true! */ }   // i is converted to unsigned, becomes UINT_MAX
```

- `signed`/`unsigned` overflow: unsigned overflow **wraps** (well-defined, mod 2^n). Signed integer overflow is **undefined behavior** -- the compiler is allowed to assume it never happens and optimize accordingly.
- Explicit casts: `(int)x`, `(double)y`. Casting a pointer type is common with `void *` and low-level code but bypasses type safety -- use sparingly and deliberately.

---

## 5. Variables, Constants, and Literals

```c
int x = 5;                 // definition + initialization
int y;                     // uninitialized -- indeterminate value, reading it is UB
const int MAX = 100;       // read-only after initialization
#define LIMIT 100          // preprocessor macro, textual substitution, no type
enum { RED, GREEN, BLUE }; // enum constants (see §14)

int a = 0x1F;   // hex
int b = 017;    // octal (leading 0)
int c = 0b101;  // binary (GNU extension / C23)
long l = 100L;
unsigned u = 100U;
double d = 1.5e10;
char ch = 'A';
char *s = "hello";   // string literal -- type char[6], read-only in practice
```

String literals are stored in read-only memory; writing through a `char *` pointing at one is undefined behavior. Use `char buf[] = "hello";` when you need a mutable copy (it copies into a stack array).

---

## 6. Operators

- Arithmetic: `+ - * / %` (`%` only on integers)
- Comparison: `== != < > <= >=`
- Logical: `&& || !` (short-circuit evaluation)
- Bitwise: `& | ^ ~ << >>`
- Assignment: `= += -= *= /= %= &= |= ^= <<= >>=`
- Increment/decrement: `++x` (pre), `x++` (post) -- prefer separating from other expressions; `x = x++ + ++x;` is undefined behavior (unsequenced modification).
- Ternary: `cond ? a : b`
- `sizeof(expr)` / `sizeof(type)` -- compile-time (usually) size in bytes, type `size_t`
- `,` comma operator -- evaluates left, discards, evaluates right, yields right's value (mostly seen in `for` loop headers)
- `&x` address-of, `*p` dereference (see §11)

Integer division truncates toward zero (`7 / 2 == 3`, `-7 / 2 == -3`, since C99). `%` result has the sign of the dividend.

Operator precedence tables exist but relying on memorizing them is a bug magnet -- parenthesize non-obvious mixes, especially bitwise vs. comparison: `if ((flags & MASK) == 0)` not `if (flags & MASK == 0)` (the latter binds `==` tighter than `&`, and is a very common real bug).

---

## 7. Control Flow

```c
// if / else
if (x > 0) {
    // ...
} else if (x < 0) {
    // ...
} else {
    // ...
}

// switch -- falls through by default, needs explicit break
switch (grade) {
    case 'A':
        printf("Excellent\n");
        break;
    case 'B':
    case 'C':               // fallthrough intentional: multiple labels, one body
        printf("Good\n");
        break;
    default:
        printf("Unknown\n");
}

// while
while (n > 0) {
    n--;
}

// do-while -- body runs at least once
do {
    process();
} while (more_data());

// for
for (int i = 0; i < 10; i++) {
    if (i == 5) continue;   // skip to next iteration
    if (i == 8) break;      // exit loop
    printf("%d\n", i);
}

// goto -- rarely justified; common legitimate use is single-exit cleanup
int f(void) {
    FILE *fp = fopen("x", "r");
    if (!fp) goto fail;
    int *buf = malloc(100);
    if (!buf) goto cleanup_fp;
    // ... use buf ...
    free(buf);
cleanup_fp:
    fclose(fp);
    return 0;
fail:
    return -1;
}
```

`switch` operates on integer types (including `char`, `enum`); `case` labels must be compile-time constants. Missing `break` is one of the most common real-world C bugs -- compile with `-Wimplicit-fallthrough` and mark intentional fallthrough with `/* fallthrough */` or the C2x `[[fallthrough]]` attribute.

---

## 8. Functions

```c
// declaration (prototype) -- goes in a header
int add(int a, int b);

// definition
int add(int a, int b) {
    return a + b;
}

// no return value
void log_message(const char *msg) {
    printf("%s\n", msg);
}

// no parameters
int get_random(void);
```

- Arguments are passed **by value** -- the callee gets a copy. To let a function modify a caller's variable, pass a pointer to it (`void inc(int *p) { (*p)++; }`).
- Arrays "decay" to a pointer to their first element when passed to a function -- `sizeof` inside the callee will not give the array's size (see §12).
- Functions can't be overloaded (no two functions with the same name) and can't return arrays. To "return" an array, return a pointer (usually to heap-allocated or `static` storage -- never to a local array, see §27) or pass an output pointer as a parameter.
- Recursion works normally; each call gets its own stack frame. Deep recursion can overflow the stack (no automatic detection -- it typically crashes with SIGSEGV).
- `inline` (C99+) is a hint to the compiler, not a guarantee.
- Variadic functions: see §24.

### Function pointers

```c
int add(int a, int b) { return a + b; }
int sub(int a, int b) { return a - b; }

int (*op)(int, int) = add;      // op is a pointer to a function(int,int)->int
int result = op(3, 4);          // calls add(3, 4)
op = sub;
result = op(3, 4);              // calls sub(3, 4)

// common use: callbacks / dispatch tables
typedef int (*BinOp)(int, int);
void apply(BinOp f, int a, int b) {
    printf("%d\n", f(a, b));
}
apply(add, 1, 2);

// array of function pointers as a dispatch table
BinOp table[] = { add, sub };
table[0](5, 3);
```

Reading function pointer declarations right-to-left from the identifier is the trick: `int (*op)(int, int)` -- `op` is a pointer to a function taking `(int, int)` returning `int`.

---

## 9. Arrays

```c
int arr[5];                        // uninitialized, indeterminate values
int arr2[5] = {1, 2, 3};           // rest zero-initialized: {1,2,3,0,0}
int arr3[] = {1, 2, 3, 4};         // size inferred: 4
int matrix[3][4];                  // 2D array, row-major layout
int matrix2[2][2] = {{1,2},{3,4}};

arr[0] = 10;
int x = arr[2];

size_t len = sizeof(arr) / sizeof(arr[0]);   // element count (only works on real arrays, not decayed pointers)
```

- Arrays are fixed-size and their size must be a compile-time constant (except VLAs, see below) -- there's no built-in resizable array; that's what dynamic allocation (§13) or a hand-rolled/growable buffer is for.
- No bounds checking, at all, ever. `arr[10]` on a 5-element array reads/writes out of bounds -- undefined behavior, not a caught error. This is the root cause of a huge fraction of C security bugs (buffer overflows).
- 2D arrays are stored contiguously in row-major order: `matrix[i][j]` is at `matrix + i*ncols + j` conceptually.
- **Variable-length arrays (VLAs)** (C99, optional in C11+): `int arr[n];` where `n` is a runtime value. Allocated on the stack -- dangerous with large or attacker-controlled `n` (stack overflow, no error). Many codebases ban them (`-Wvla`).

---

## 10. Strings

C has no string type -- a "string" is just a `char` array terminated by a `'\0'` (NUL) byte. Nothing enforces this convention; every string function trusts it's there.

```c
char s1[] = "hello";              // 6 bytes: 'h','e','l','l','o','\0'
char s2[20] = "hi";               // buffer of 20, first 3 bytes used
const char *s3 = "hello";         // pointer to a string literal (read-only!)

#include <string.h>
size_t len = strlen(s1);          // 5 (does NOT count the NUL)
strcpy(s2, "world");              // UNSAFE: no bounds check, can overflow s2
strncpy(s2, "world", sizeof(s2)); // safer, but may not NUL-terminate if src is too long!
strcat(s2, "!");                  // UNSAFE: append, no bounds check
strncat(s2, "!", sizeof(s2) - strlen(s2) - 1);
int cmp = strcmp(s1, s2);         // 0 if equal, <0 / >0 otherwise (lexicographic)
char *p = strchr(s1, 'l');        // find first occurrence, NULL if absent
char *p2 = strstr(s1, "ll");      // find substring
char *tok = strtok(s2, ",");      // tokenize (mutates input, stateful/not thread-safe -- use strtok_r)

// snprintf is the safe, general workhorse for building strings
char buf[64];
snprintf(buf, sizeof(buf), "x=%d, y=%s", 42, "ok");   // always NUL-terminates, truncates safely
```

- **`strcpy`/`strcat`/`gets`/`sprintf` (unbounded) are considered unsafe** in modern code -- they have no way to know the destination buffer's size. Prefer `snprintf`, `strncpy`/`strncat` with the size explicitly passed, or the `_s` bounds-checked variants (C11 Annex K, optional, not universally implemented). `gets` was removed from the standard entirely in C11 -- never use it.
- String literals are `const` in practice even though older C lets you write `char *p = "abc"` without a warning in some configs -- always prefer `const char *` for read-only strings.
- Converting strings to numbers: `strtol`, `strtoul`, `strtod` (preferred, detect errors via `errno`/end pointer) over `atoi`/`atof` (no error detection, UB on overflow).

```c
char *end;
errno = 0;
long v = strtol("123abc", &end, 10);   // v=123, end points at 'a'
if (errno == ERANGE) { /* overflow */ }
```

---

## 11. Pointers

A pointer is a variable holding a memory address. This is C's central, defining feature.

```c
int x = 42;
int *p = &x;      // p holds the address of x
int y = *p;        // dereference: y = 42
*p = 100;           // writes through the pointer: x is now 100

int **pp = &p;      // pointer to pointer to int
int z = **pp;        // double dereference

int *null_ptr = NULL;   // NULL is a null pointer constant -- points nowhere valid
if (p != NULL) { /* safe to dereference */ }
```

- Declaring `int *p, q;` -- only `p` is a pointer; `q` is a plain `int`. The `*` binds to the declarator, not the type. Prefer `int *p; int q;` on separate lines to avoid this trap.
- Dereferencing a `NULL` or otherwise invalid pointer is undefined behavior -- typically a segfault, but not guaranteed (could silently corrupt memory).
- `void *` is a generic pointer -- can point to anything, cannot be dereferenced directly (no type to know the size/layout), must be cast first. Used for generic APIs (`malloc` returns `void *`, `memcpy` takes `void *`).
- `const` with pointers -- read right to left:

```c
const int *p1;        // pointer to const int -- can't modify *p1, can reassign p1
int * const p2 = &x;  // const pointer to int -- can modify *p2, can't reassign p2
const int * const p3 = &x;  // const pointer to const int -- neither
```

- Pointers are not integers, even though they can be cast to/from `uintptr_t`. Comparing pointers with `<`/`>` is only well-defined within the same array/object.

---

## 12. Pointer Arithmetic & Arrays

Array indexing is literally defined in terms of pointer arithmetic: `arr[i]` means `*(arr + i)`. This is why `3[arr]` also compiles and works (equivalent to `arr[3]`) -- a fun but useless fact.

```c
int arr[5] = {10, 20, 30, 40, 50};
int *p = arr;          // array decays to pointer to first element

p++;                     // now points to arr[1] -- advances by sizeof(int), not 1 byte
printf("%d\n", *p);      // 20
printf("%d\n", *(p+2));  // 40 (== arr[3])
printf("%d\n", p[2]);    // same as above -- pointer indexing works too

ptrdiff_t diff = (&arr[4]) - (&arr[0]);   // 4 -- pointer subtraction gives element count
```

**Array decay**: whenever an array is used in most expressions (passed to a function, assigned to a pointer), it decays to a pointer to its first element -- the size information is lost.

```c
void f(int arr[10]) {          // this is EXACTLY equivalent to int *arr --
    printf("%zu\n", sizeof(arr));   // prints sizeof(int*), e.g. 8, NOT 40!
}
```

To pass array size info, pass it explicitly (`void f(int *arr, size_t n)`) -- there's no way around this in C. Multi-dimensional array parameters are trickier: `void f(int arr[][4])` -- all dimensions except the first must be specified, because the compiler needs them to compute offsets.

Pointer arithmetic is only well-defined within a single array (including one-past-the-end, used as a loop sentinel) -- going further out of bounds, or arithmetic between pointers into different objects, is undefined behavior.

---

## 13. Dynamic Memory Management

The stack (automatic storage) is fixed-size and scoped to function calls; the heap gives you memory that outlives the function that allocated it, at the cost of manual management. This is the source of two entire bug classes (leaks, use-after-free) that don't exist in garbage-collected languages.

```c
#include <stdlib.h>

int *p = malloc(sizeof(int));          // allocate raw, uninitialized memory
if (p == NULL) { /* allocation failed -- ALWAYS check */ }
*p = 42;
free(p);                                 // release back to the allocator
p = NULL;                                // good practice: avoid dangling pointer reuse

int *arr = calloc(10, sizeof(int));     // 10 ints, ZERO-initialized (unlike malloc)
int *arr2 = malloc(10 * sizeof(int));   // 10 ints, uninitialized -- prefer calloc when zeroing needed
                                          // (calloc also guards against the multiplication overflowing)

int *bigger = realloc(arr, 20 * sizeof(int));  // resize (may move the block!)
if (bigger == NULL) {
    // realloc failed -- the ORIGINAL `arr` pointer is still valid and must still be freed
    free(arr);
} else {
    arr = bigger;   // never do `arr = realloc(arr, ...)` directly -- leaks on failure
}
```

### Rules that prevent most heap bugs

1. **Every `malloc`/`calloc`/`realloc` needs exactly one matching `free`.** Not zero (leak), not two (double-free -- undefined behavior, often exploitable).
2. **Check the return value for `NULL`** before using it -- allocation can fail (though on Linux with overcommit, it often "succeeds" and fails later via the OOM killer).
3. **Never use a pointer after `free`ing it** ("use-after-free") -- set it to `NULL` after freeing so accidental reuse crashes predictably instead of corrupting memory silently.
4. **Never `free` the same pointer twice**, and never `free` a pointer that wasn't returned by `malloc`/`calloc`/`realloc` (e.g. don't `free(&x)` on a stack variable, don't `free` a pointer into the middle of an allocation).
5. **`free(NULL)` is explicitly a documented no-op** -- safe to call, no need to guard it with an `if`.
6. `malloc` does not zero memory; `calloc` does. `realloc` does not zero the new tail when growing.
7. `sizeof` allocation idiom: prefer `p = malloc(n * sizeof *p)` (sizeof the pointee, via dereference) over `malloc(n * sizeof(int))` -- if the type of `p` changes later, the allocation size updates automatically and stays correct.

### Common heap bugs (all undefined behavior, all real-world exploit primitives)

- **Memory leak** -- forgetting to `free`, or losing the only pointer to a block (overwriting it before freeing).
- **Dangling pointer / use-after-free** -- using memory after it's been freed.
- **Double free** -- freeing the same block twice, corrupts allocator metadata.
- **Buffer overflow** -- writing past the end of an allocation (heap or stack).
- **Uninitialized read** -- reading `malloc`'d (not `calloc`'d) memory before writing it.

Valgrind and AddressSanitizer (§33) catch essentially all of these at runtime during testing -- running them routinely is standard practice, not optional polish.

---

## 14. Structs, Unions, Enums

### 14.1 Structs

```c
struct Point {
    int x;
    int y;
};

struct Point p1 = {10, 20};          // positional init
struct Point p2 = {.x = 5, .y = 15}; // designated init (C99+), order-independent
p1.x = 100;                            // member access

struct Point *pp = &p1;
pp->x = 200;                          // arrow operator: (*pp).x, shorthand for pointer access

// nested / composed
struct Rect {
    struct Point top_left;
    struct Point bottom_right;
};

// typedef to drop the `struct` keyword everywhere
typedef struct Point {
    int x, y;
} Point;
Point p3 = {1, 2};                    // no `struct` needed now
```

- Struct assignment (`p2 = p1`) copies all members (shallow copy -- if a member is a pointer, only the pointer is copied, not what it points to).
- Structs can be passed and returned by value (copies the whole thing) -- fine for small structs, wasteful for large ones (pass a pointer instead).
- **Padding**: the compiler inserts padding bytes between members to satisfy alignment requirements (e.g. a `struct { char a; int b; }` is usually 8 bytes, not 5, because `b` must be 4-byte aligned). `sizeof(struct)` includes this padding. Reorder members largest-to-smallest to minimize padding when it matters (cache density, network structs).
- **Flexible array member** (C99): a struct's last member can be an array with no size, used for variable-length trailing data in one allocation:

```c
struct Buffer {
    size_t len;
    char data[];              // flexible array member, must be last
};
struct Buffer *b = malloc(sizeof(struct Buffer) + 100);   // room for 100 bytes of data
b->len = 100;
```

### 14.2 Unions

All members share the same memory -- the union's size is that of its largest member. Only one member is "active" (holds a meaningful value) at a time; the language doesn't track which.

```c
union Value {
    int i;
    float f;
    char bytes[4];
};

union Value v;
v.i = 65;
printf("%f\n", v.f);   // reads the same bits as a float -- reinterpretation, "type punning"
```

Type-punning through a union (writing one member, reading another) is technically undefined behavior in strict C++ but explicitly permitted in C (C11 6.5.2.3p3 footnote / common practice) -- widely relied on for e.g. examining a `float`'s raw bits. A tagged union pattern (union + an enum discriminant) is the idiomatic way to build a C "variant"/"sum type":

```c
enum Tag { INT, FLOAT };
struct Variant {
    enum Tag tag;
    union { int i; float f; } value;
};
```

### 14.3 Enums

```c
enum Color { RED, GREEN, BLUE };        // RED=0, GREEN=1, BLUE=2 by default
enum Status { OK = 200, NOT_FOUND = 404, ERROR = 500 };

enum Color c = GREEN;
```

Enum constants are just `int`s under the hood with no runtime type safety -- you can assign any `int` to an `enum Color` variable, and the compiler mostly won't stop you (some warn with `-Wswitch` on missing `switch` cases). C23 adds the ability to specify the underlying type (`enum Color : uint8_t { ... }`) and typed enum constants.

---

## 15. `typedef`

`typedef` creates an alias for an existing type -- it does not create a new type, just a new name.

```c
typedef unsigned long ulong_t;
typedef int (*BinOp)(int, int);           // function pointer alias, see §8
typedef struct Point { int x, y; } Point;  // struct alias, see §14
typedef char Buffer[256];                   // array type alias

ulong_t n = 100;
Buffer buf;   // equivalent to char buf[256];
```

Convention: many codebases suffix typedef'd types with `_t` (matches the standard library's own convention: `size_t`, `time_t`, `pid_t`). Opaque typedef'd structs (`typedef struct Foo Foo;` with the struct body hidden in a `.c` file) are C's closest approximation to encapsulation/information hiding.

---

## 16. The Preprocessor

Runs before compilation; pure text substitution, has no knowledge of C syntax or types.

```c
#include <stdio.h>       // system header, searched in compiler's include paths
#include "myheader.h"    // local header, searched relative to current file first

#define PI 3.14159                  // object-like macro
#define SQUARE(x) ((x) * (x))       // function-like macro -- ALWAYS parenthesize params and the whole expansion
#define MAX(a, b) ((a) > (b) ? (a) : (b))

int area = SQUARE(5);               // expands to ((5) * (5))
int bad = SQUARE(1 + 2);            // if unparenthesized: 1 + 2 * 1 + 2 = 5, NOT 9 -- this is why parens matter

#ifdef DEBUG
    printf("debug info\n");
#endif

#if defined(__linux__)
    // linux-specific code
#elif defined(_WIN32)
    // windows-specific code
#else
    #error "Unsupported platform"
#endif

#undef PI                            // remove a definition

// include guard -- prevents double-inclusion of a header in one translation unit
#ifndef MYHEADER_H
#define MYHEADER_H
// ... header content ...
#endif

#pragma once   // non-standard but nearly universally supported alternative to include guards
```

### Macro pitfalls

- Function-like macros do textual substitution with **no type checking and no scoping** -- `MAX(a++, b)` double-evaluates `a++`, a classic bug (macros re-evaluate arguments each time they appear in the expansion).
- Multi-statement macros need the `do { ... } while(0)` wrapper so they behave like a single statement when followed by a semicolon and used inside an `if` without braces:

```c
#define LOG_AND_EXIT(msg) do { fprintf(stderr, "%s\n", msg); exit(1); } while (0)
```

- `#` (stringizing) turns a macro argument into a string literal; `##` (token pasting) concatenates tokens:

```c
#define STR(x) #x               // STR(hello) -> "hello"
#define CONCAT(a, b) a##b       // CONCAT(foo, bar) -> foobar
```

- Prefer `const`/`enum`/`static inline` functions over macros where possible -- they're type-checked and debuggable; reach for macros only for things that genuinely require text substitution (conditional compilation, stringizing, generating repetitive code).
- Predefined macros: `__FILE__`, `__LINE__`, `__func__` (not a macro, actually a compiler-provided identifier), `__DATE__`, `__TIME__`, `__STDC_VERSION__`.

---

## 17. Storage Classes, Scope & Linkage

```c
void f(void) {
    int a = 1;              // automatic storage -- lives on the stack, scope = block, destroyed at end of block
    static int b = 1;       // static storage -- persists across calls, initialized ONCE, scope = block
    register int c = 1;     // hint to keep in a register (mostly obsolete, compilers ignore it)
    // ...
}

int global = 1;              // external linkage -- visible to other translation units (via `extern` decl)
static int file_local = 1;   // internal linkage -- visible only within THIS translation unit
extern int global;           // declares (doesn't define) a variable defined elsewhere

static void helper(void) { }  // internal linkage function -- not visible outside this .c file
```

- **Storage duration**: how long the object lives. `automatic` (function-local, no `static`) -- stack, per-call. `static` -- entire program run, one instance, initialized once (default-zeroed if no initializer). `allocated` -- heap, from `malloc` to `free`. `thread` (`_Thread_local` / `thread_local`, C11+) -- one instance per thread.
- **Scope**: where a name is visible -- block, file, function-prototype, or the whole program.
- **Linkage**: whether the same name in different translation units refers to the same object. `external` (default for file-scope non-`static`) -- shared across files. `internal` (`static` at file scope) -- private to this file. `none` (block-scope, non-`static`) -- purely local.
- A function-local `static` variable is the idiomatic way to keep state between calls without global variables (e.g., a call counter, a memoization cache) -- but it makes the function non-reentrant/non-thread-safe.
- Best practice: mark file-scope helper functions and variables `static` unless they're deliberately part of the module's public API -- minimizes namespace pollution and link-time symbol clashes across a multi-file project.

---

## 18. `const` and `volatile`

- `const` -- promises the compiler this value won't be modified through this name; enables compiler optimizations and communicates intent. Enforced at compile time (you can bypass it with a cast, but writing through a cast-away `const` on an object that was truly `const` is undefined behavior).
- `volatile` -- tells the compiler this value can change outside the program's control (memory-mapped hardware registers, a variable modified by a signal handler, or by another thread without synchronization primitives visible to the compiler) -- disables caching the value in a register and disables reordering/eliminating accesses to it. **`volatile` is not a substitute for proper thread synchronization** (mutexes/atomics) -- it doesn't provide atomicity or memory ordering guarantees across threads, only prevents compiler-level caching/reordering of that one access.

```c
volatile sig_atomic_t stop_flag = 0;   // correct pattern for a signal-handler-set flag

void handler(int sig) { stop_flag = 1; }

while (!stop_flag) {
    // do work -- without volatile, the compiler could hoist the read of stop_flag
    // out of the loop entirely since it "never changes" from the loop's point of view
}
```

---

## 19. Bit Manipulation & Bit Fields

```c
unsigned int flags = 0;
#define FLAG_A (1u << 0)
#define FLAG_B (1u << 1)
#define FLAG_C (1u << 2)

flags |= FLAG_A;              // set a bit
flags &= ~FLAG_B;             // clear a bit
flags ^= FLAG_C;              // toggle a bit
bool has_a = (flags & FLAG_A) != 0;   // test a bit

unsigned int x = 0b1010;
x <<= 2;    // shift left, multiply by 4 (well-defined for unsigned; UB for signed if it overflows)
x >>= 1;    // shift right -- logical (fills 0) for unsigned, implementation-defined for signed (usually arithmetic/sign-extending)
```

**Bit fields** let a struct pack sub-byte-width members, typically used to mirror a hardware register or wire format:

```c
struct Flags {
    unsigned int is_active : 1;
    unsigned int priority  : 3;
    unsigned int reserved  : 4;
};   // total 8 bits -> likely packed into 1 byte, but layout/padding/bit order is implementation-defined
```

Bit field memory layout (bit order, padding across the underlying storage unit) is **not portable across compilers/platforms** -- fine for in-process flags, risky for anything serialized to disk or network (use explicit shifting/masking there instead).

Useful bit tricks: `x & (x - 1)` clears the lowest set bit; `x & -x` isolates the lowest set bit; `__builtin_popcount(x)` (GCC/clang builtin) counts set bits; `<stdbit.h>` (C23) standardizes bit-counting operations (`stdc_count_ones`, `stdc_leading_zeros`, etc.).

---

## 20. Multi-File Programs

A typical project splits declarations (headers, `.h`) from definitions (source, `.c`), compiles each `.c` independently, then links the object files.

```c
// point.h
#ifndef POINT_H
#define POINT_H

typedef struct {
    int x, y;
} Point;

Point point_new(int x, int y);
int   point_distance_sq(Point a, Point b);

#endif
```

```c
// point.c
#include "point.h"

Point point_new(int x, int y) {
    return (Point){.x = x, .y = y};   // compound literal
}

int point_distance_sq(Point a, Point b) {
    int dx = a.x - b.x, dy = a.y - b.y;
    return dx*dx + dy*dy;
}
```

```c
// main.c
#include <stdio.h>
#include "point.h"

int main(void) {
    Point p1 = point_new(0, 0);
    Point p2 = point_new(3, 4);
    printf("%d\n", point_distance_sq(p1, p2));
    return 0;
}
```

```sh
gcc -c point.c -o point.o
gcc -c main.c -o main.o
gcc point.o main.o -o app
# or, equivalently, in one step:
gcc point.c main.c -o app
```

Rules of thumb:
- Headers contain declarations (`extern` variables, function prototypes, `typedef`s, `struct`/`enum` definitions, `#define`s, `static inline` functions) -- never define non-`static`/non-`inline` functions or non-`extern` variables with an initializer in a header, or you'll get "multiple definition" linker errors when the header is included in more than one `.c` file.
- Always guard headers against multiple inclusion (`#ifndef`/`#define` or `#pragma once`, §16).
- `static` functions/variables at file scope are private to that translation unit -- put implementation details there, not in the header.

---

## 21. Standard Library Tour

The C standard library is small compared to modern languages -- most "batteries" (JSON, HTTP, containers) are third-party. Core headers:

| Header | Contents |
|---|---|
| `<stdio.h>` | I/O: `printf`, `scanf`, `fopen`, `fread`, etc. (§22) |
| `<stdlib.h>` | `malloc`/`free`, `exit`, `atoi`/`strtol`, `rand`/`srand`, `qsort`, `bsearch`, `abs` |
| `<string.h>` | `strlen`, `strcpy`, `memcpy`, `memset`, `memcmp`, `strstr`, ... (§10) |
| `<ctype.h>` | `isalpha`, `isdigit`, `isspace`, `toupper`, `tolower`, ... |
| `<math.h>` | `sqrt`, `pow`, `sin`/`cos`, `floor`/`ceil`, `fabs`, `NAN`/`INFINITY` (link with `-lm` on Linux) |
| `<time.h>` | `time`, `clock`, `struct tm`, `strftime`, `difftime` |
| `<stdint.h>` | fixed-width integer types (§4.2) |
| `<stdbool.h>` | `bool`, `true`, `false` (C99+) |
| `<stddef.h>` | `size_t`, `ptrdiff_t`, `NULL`, `offsetof` |
| `<limits.h>` / `<float.h>` | `INT_MAX`, `CHAR_BIT`, `DBL_EPSILON`, etc. -- type range/precision constants |
| `<errno.h>` | `errno`, `EINVAL`, `ENOMEM`, etc. (§23) |
| `<assert.h>` | `assert(cond)` -- aborts if false (compiled out entirely when `NDEBUG` is defined) |
| `<stdarg.h>` | variadic function support (§24) |
| `<setjmp.h>` | `setjmp`/`longjmp` (§29) |
| `<signal.h>` | `signal`, `raise`, signal handling (§29) |
| `<threads.h>` | C11 threads (rarely implemented; most code uses POSIX `<pthread.h>` instead, §30) |
| `<stdatomic.h>` | C11 atomic types/operations for lock-free code |

```c
#include <stdlib.h>

int cmp_int(const void *a, const void *b) {
    int ia = *(const int *)a, ib = *(const int *)b;
    return (ia > ib) - (ia < ib);     // avoids overflow vs. `ia - ib`
}

int arr[] = {5, 3, 1, 4, 2};
qsort(arr, 5, sizeof(int), cmp_int);   // generic sort via function pointer + void*

int key = 3;
int *found = bsearch(&key, arr, 5, sizeof(int), cmp_int);  // requires sorted array
```

```c
#include <string.h>
char dst[10];
memcpy(dst, "hello", 6);         // raw byte copy, doesn't stop at NUL, fastest bulk copy
memset(dst, 0, sizeof(dst));      // fill with a byte value (commonly 0)
int c = memcmp(dst, "other", 5);  // raw byte comparison
memmove(dst, dst + 1, 5);         // like memcpy but safe for OVERLAPPING regions
```

`memcpy` has undefined behavior if source and destination overlap -- use `memmove` when overlap is possible.

---

## 22. File I/O

```c
#include <stdio.h>

FILE *fp = fopen("data.txt", "r");   // modes: "r" read, "w" write(truncate), "a" append,
if (fp == NULL) {                     // "r+"/"w+"/"a+" read+write variants, add "b" for binary on some platforms
    perror("fopen failed");           // prints errno's message with a prefix
    return 1;
}

char line[256];
while (fgets(line, sizeof(line), fp) != NULL) {   // reads a line, keeps the '\n', NUL-terminates, bounds-safe
    printf("%s", line);
}

int ch;
while ((ch = fgetc(fp)) != EOF) {     // ch MUST be int, not char -- EOF (-1) must be distinguishable from a valid byte
    putchar(ch);
}

fprintf(fp, "x=%d\n", 42);            // formatted write
fscanf(fp, "%d", &x);                  // formatted read -- fragile, prefer fgets + sscanf/strtol for robust parsing

size_t n = fwrite(buf, sizeof(char), len, fp);   // raw binary write, returns items actually written
size_t m = fread(buf, sizeof(char), len, fp);     // raw binary read, returns items actually read (< len on EOF/error)

fseek(fp, 0, SEEK_END);    // seek to end
long size = ftell(fp);      // current position = file size (after seeking to end)
fseek(fp, 0, SEEK_SET);    // rewind to start
rewind(fp);                  // equivalent shortcut for the line above (also clears error indicator)

if (ferror(fp)) { /* an I/O error occurred */ }
if (feof(fp))   { /* hit end of file */ }

fclose(fp);   // ALWAYS close -- flushes buffered writes, releases the fd
```

`stdin`, `stdout`, `stderr` are pre-opened `FILE *` streams. `stdout` is typically line-buffered when attached to a terminal and fully buffered otherwise (e.g. piped) -- `stderr` is unbuffered, which is why it's used for diagnostics that must appear immediately/in order relative to a crash. `fflush(stdout)` forces buffered output out.

`printf` format specifiers (the ones you'll use constantly): `%d`/`%i` int, `%u` unsigned, `%ld`/`%lld` long/long long, `%f`/`%lf` double, `%s` string, `%c` char, `%p` pointer, `%x`/`%X` hex, `%%` literal percent, `%zu` for `size_t`. Mismatched format specifiers vs. argument types are undefined behavior -- always compile with `-Wformat` (included in `-Wall`).

---

## 23. Error Handling

C has no exceptions. The conventions are:

1. **Return codes** -- a function returns a sentinel value (`-1`, `NULL`, nonzero) on failure, and the caller must check every single call site. This is by far the most common pattern, and its biggest weakness: nothing forces you to check.

```c
FILE *fp = fopen("x", "r");
if (fp == NULL) {
    // handle error
}
```

2. **`errno`** (`<errno.h>`) -- a thread-local integer that many library/syscall functions set on failure (they do NOT clear it on success, so check the function's own return value first, then consult `errno` only if it indicates failure). `perror(prefix)` and `strerror(errno)` turn it into a human-readable message.

```c
#include <errno.h>
#include <string.h>

errno = 0;   // clear before a call whose success can't otherwise be detected (e.g. strtol edge cases)
long v = strtol(str, NULL, 10);
if (errno == ERANGE) {
    fprintf(stderr, "out of range: %s\n", strerror(errno));
}
```

3. **`assert`** (`<assert.h>`) -- for catching programmer errors / broken invariants during development; `assert(cond)` aborts (via `abort()`) if `cond` is false, printing file/line. Entirely compiled out if `NDEBUG` is defined (typically in release builds) -- never put code with side effects inside `assert()`, since it may vanish entirely: `assert(x = compute())` is a real bug pattern.
4. **`exit(code)` / `abort()`** -- terminate the whole program. `exit` runs registered `atexit` handlers and flushes stdio buffers; `abort` does not (raises `SIGABRT`, typically used after detecting corruption, pairs well with core dumps for postmortem debugging).
5. There is no built-in "result type"/exceptions -- larger C codebases often hand-roll an error-code enum + `const char *` message convention, or an out-parameter for detailed errors, precisely because return-code checking is easy to skip by accident.

---

## 24. Variadic Functions

Functions that take a variable number of arguments, like `printf`. Built with `<stdarg.h>`.

```c
#include <stdarg.h>
#include <stdio.h>

int sum(int count, ...) {
    va_list args;
    va_start(args, count);       // count is the last NAMED parameter before the ...

    int total = 0;
    for (int i = 0; i < count; i++) {
        total += va_arg(args, int);   // must know the type at each call site -- no runtime type info
    }

    va_end(args);                 // required cleanup
    return total;
}

sum(3, 10, 20, 30);   // 60
```

There's no way to know how many arguments were actually passed or their types from inside the function -- the caller and callee must agree out-of-band (an explicit count parameter, like above, or a sentinel value, or a format-string like `printf`'s `%d`/`%s` that encodes the types). Mismatches here are a classic and dangerous bug class (format string vulnerabilities) -- never pass user-controlled data as a `printf` format string: `printf(user_input)` is a vulnerability; `printf("%s", user_input)` is correct.

---

## 25. Function Pointers & Callbacks Recap

(Full syntax in §8.) The main real-world uses:

- **Callbacks**: passing behavior into a generic algorithm (`qsort`'s comparator, event handler registration).
- **Dispatch tables / "poor man's polymorphism"**: an array or struct of function pointers selected by an enum tag, simulating virtual dispatch without a language-level `class`/`vtable` (this is in fact how C++ implements virtual functions under the hood).

```c
struct Shape {
    enum { CIRCLE, SQUARE } kind;
    double (*area)(const struct Shape *);
    union { double radius; double side; } data;
};

double circle_area(const struct Shape *s) { return 3.14159 * s->data.radius * s->data.radius; }
double square_area(const struct Shape *s) { return s->data.side * s->data.side; }

struct Shape c = {.kind = CIRCLE, .area = circle_area, .data.radius = 2.0};
printf("%f\n", c.area(&c));   // dispatches through the function pointer
```

---

## 26. Data Structures in C

C has no built-in dynamic containers -- you build them from structs and pointers. The two workhorse patterns:

### 26.1 Singly linked list

```c
typedef struct Node {
    int data;
    struct Node *next;     // self-referential struct -- must use `struct Node`, not the not-yet-complete typedef, inside its own body
} Node;

Node *push_front(Node *head, int value) {
    Node *n = malloc(sizeof(Node));
    if (!n) return head;    // allocation failed, list unchanged
    n->data = value;
    n->next = head;
    return n;                 // new head
}

void free_list(Node *head) {
    while (head) {
        Node *next = head->next;   // save next BEFORE freeing head
        free(head);
        head = next;
    }
}

void print_list(const Node *head) {
    for (const Node *n = head; n != NULL; n = n->next) {
        printf("%d -> ", n->data);
    }
    printf("NULL\n");
}
```

### 26.2 Dynamic array ("growable vector")

```c
typedef struct {
    int *data;
    size_t len;
    size_t cap;
} IntVec;

void vec_init(IntVec *v) { v->data = NULL; v->len = 0; v->cap = 0; }

void vec_push(IntVec *v, int value) {
    if (v->len == v->cap) {
        size_t new_cap = v->cap == 0 ? 4 : v->cap * 2;   // amortized doubling growth
        int *new_data = realloc(v->data, new_cap * sizeof *v->data);
        if (!new_data) { /* handle OOM */ return; }
        v->data = new_data;
        v->cap = new_cap;
    }
    v->data[v->len++] = value;
}

void vec_free(IntVec *v) { free(v->data); v->data = NULL; v->len = v->cap = 0; }
```

### 26.3 Binary tree

```c
typedef struct TreeNode {
    int value;
    struct TreeNode *left, *right;
} TreeNode;

TreeNode *insert(TreeNode *root, int value) {
    if (root == NULL) {
        TreeNode *n = malloc(sizeof(TreeNode));
        n->value = value; n->left = n->right = NULL;
        return n;
    }
    if (value < root->value) root->left  = insert(root->left, value);
    else                     root->right = insert(root->right, value);
    return root;
}
```

### 26.4 Stack / queue

Implement a stack with a dynamic array (push/pop at the end, O(1) amortized) or a linked list (push/pop at head, O(1)). Implement a queue with a linked list keeping head+tail pointers, or a circular buffer (fixed-size array with wraparound indices) for a bounded, allocation-free queue.

Every one of these hand-rolled structures inherits all of C's manual-memory rules (§13) -- freeing a linked list node-by-node, freeing a vector's backing array once, no double-frees, no use-after-free on removed nodes.

---

## 27. Undefined Behavior & Common Pitfalls

"Undefined behavior" (UB) means the standard places **no requirement whatsoever** on what happens -- not "probably crashes," but "the compiler is allowed to assume it never happens" and optimize on that assumption, which can produce results far stranger than a crash (code before the UB can be reordered/deleted, security checks can vanish). This is the single most important C-specific mental model to internalize.

Common sources of UB:

- **Signed integer overflow** (`INT_MAX + 1`). Unsigned overflow is well-defined (wraps); signed is not.
- **Out-of-bounds array/pointer access** -- reading or writing past an array's bounds, including one-past-the-end pointers used for anything but comparison.
- **Dereferencing NULL or a dangling/uninitialized pointer.**
- **Use-after-free, double-free.**
- **Returning a pointer to a local (stack) variable** -- the storage is gone the moment the function returns:

```c
int *bad(void) {
    int local = 42;
    return &local;    // UB: local's storage doesn't exist after return
}
```

- **Reading an uninitialized variable** before it's assigned.
- **Modifying a variable twice without a sequence point between the modifications**, or modifying and reading it unsequenced (`i = i++ + 1;`, `arr[i] = i++;`).
- **Strict aliasing violations** -- accessing an object through a pointer of an incompatible type (e.g. reinterpreting a `float *` as an `int *` and dereferencing it, other than via `memcpy`/a `union` for type punning) lets the compiler assume the two pointers never alias and reorder accordingly, producing wrong results.
- **Misaligned access** -- casting a `char *` to a pointer of a stricter-alignment type and dereferencing it when the address isn't actually aligned for that type (some architectures fault; x86 usually tolerates it but it's still UB and can break on other targets).
- **Format string mismatches** in `printf`/`scanf` family functions.
- **Calling a function through an incompatible function pointer type.**
- **Division by zero** (integer -- traps/crashes on most platforms; float division by zero is well-defined, produces `INF`/`NAN`).
- **Modifying a string literal.**
- **Missing `return` from a non-void function** in a path that's actually reached -- the returned value is indeterminate.

Compile with `-Wall -Wextra -Wpedantic -fsanitize=address,undefined` during development (§33) -- it turns a large fraction of silent UB into loud, immediate crashes with a diagnosis, which is enormously better than debugging a corrupted-memory heisenbug in production.

---

## 28. Memory Layout of a Process

Understanding where things live clarifies lifetime and the stack/heap distinction concretely.

```
High addresses
+------------------------+
| Command-line args, env |
+------------------------+
| Stack (grows down)     |   <- local variables, function call frames, return addresses
|          |             |
|          v              |
|                          |
|          ^             |
|          |             |
| Heap (grows up)        |   <- malloc/free
+------------------------+
| BSS  (uninitialized globals/statics, zero-filled) |
+------------------------+
| Data (initialized globals/statics)                |
+------------------------+
| Text/Code (the program's instructions, read-only) |
+------------------------+
Low addresses
```

- **Text/code** -- the compiled machine instructions, typically read-only + executable.
- **Data** -- global/`static` variables with a non-zero initializer.
- **BSS** ("block started by symbol") -- global/`static` variables that are zero-initialized (or have no initializer) -- doesn't take space in the binary file, just a size the loader zero-fills at startup.
- **Heap** -- grows via `malloc`/`brk`/`mmap`, managed by the allocator.
- **Stack** -- grows automatically with function calls, one frame per active call, freed automatically on return; this is what makes stack allocation ("automatic storage") essentially free compared to heap allocation.
- Stack overflow (too much recursion, or a huge VLA/local array) typically crashes with `SIGSEGV` when the stack pointer runs into the region below it (often a guard page).

`asm.md` and `asm-mastery/` (also in this notes tree) cover this territory -- registers, calling conventions, the linker, ELF layout -- in much greater depth if you want the machine-level view underneath all of this.

---

## 29. `setjmp`/`longjmp` and Signals

### `setjmp`/`longjmp` -- C's only form of non-local control flow

```c
#include <setjmp.h>

jmp_buf env;

void might_fail(int fail) {
    if (fail) longjmp(env, 1);   // jumps back to the setjmp call, which then "returns" 1
}

int main(void) {
    if (setjmp(env) == 0) {
        // first time through, setjmp returned 0
        might_fail(1);
        printf("not reached\n");
    } else {
        // landed here via longjmp
        printf("recovered from failure\n");
    }
}
```

This is a crude approximation of exceptions -- it unwinds the C call stack without running any cleanup (no destructors exist in C, and any `malloc`'d memory or open files between the `setjmp` and the `longjmp` are simply leaked/left open unless you clean them up manually before jumping). Used sparingly, mostly in error-recovery in things like parsers or `libpng`-style C libraries.

### Signals

```c
#include <signal.h>
#include <stdio.h>

volatile sig_atomic_t got_sigint = 0;

void handler(int sig) {
    got_sigint = 1;    // signal handlers should do the absolute minimum -- most stdlib functions
}                        // (including printf/malloc) are NOT async-signal-safe to call from inside one

int main(void) {
    signal(SIGINT, handler);   // or the more robust/POSIX sigaction() for finer control
    while (!got_sigint) {
        // work
    }
    printf("interrupted, cleaning up\n");
}
```

`sigaction` is preferred over `signal` in real code -- it gives control over signal masking during the handler and avoids some historically inconsistent `signal` semantics across platforms.

---

## 30. Concurrency (POSIX threads)

C11 defines `<threads.h>`, but it's inconsistently implemented (glibc only added it in 2.28+); POSIX `<pthread.h>` is the de facto standard on Linux/macOS.

```c
#include <pthread.h>
#include <stdio.h>

void *worker(void *arg) {
    int id = *(int *)arg;
    printf("thread %d running\n", id);
    return NULL;
}

int main(void) {
    pthread_t threads[4];
    int ids[4];

    for (int i = 0; i < 4; i++) {
        ids[i] = i;
        pthread_create(&threads[i], NULL, worker, &ids[i]);
    }
    for (int i = 0; i < 4; i++) {
        pthread_join(threads[i], NULL);   // wait for each thread to finish
    }
    return 0;
}
// compile with: gcc -pthread main.c -o main
```

Synchronization primitives:

```c
pthread_mutex_t lock = PTHREAD_MUTEX_INITIALIZER;

pthread_mutex_lock(&lock);
// critical section -- exactly one thread here at a time
pthread_mutex_unlock(&lock);

pthread_cond_t cond = PTHREAD_COND_INITIALIZER;   // condition variable, for wait/signal patterns
```

- A **data race** (two threads accessing the same memory without synchronization, at least one a write) is undefined behavior -- not just "might give a stale value," genuinely UB, and ThreadSanitizer (`-fsanitize=thread`) is the standard tool for catching these.
- `<stdatomic.h>` (C11) provides atomic types (`atomic_int`, etc.) and operations (`atomic_fetch_add`, `atomic_load`/`store` with explicit memory-order arguments) for lock-free code -- correct usage requires understanding memory ordering (`memory_order_relaxed/acquire/release/seq_cst`), which is one of the harder topics in the language; default to mutexes unless you specifically need lock-free performance and have measured that it matters.
- `volatile` (§18) is not sufficient for thread safety -- it addresses compiler reordering/caching of a single access, not cross-thread memory visibility or atomicity, both of which require real synchronization primitives or `<stdatomic.h>`.

---

## 31. C Standards, Version by Version

| Standard | Year | Notable additions |
|---|---|---|
| K&R C | 1978 | The original, pre-standardization C (no prototypes) |
| C89/C90 (ANSI C) | 1989/1990 | First standardized C -- function prototypes, `void`, `const`/`volatile` |
| C99 | 1999 | `//` comments, `bool` (`<stdbool.h>`), variable declarations anywhere in a block, VLAs, designated initializers, compound literals, `long long`, `<stdint.h>`, `restrict` |
| C11 | 2011 | `_Generic` (type-generic macros), `_Static_assert`, `_Thread_local`, `<stdatomic.h>`, anonymous structs/unions, optional bounds-checked functions (Annex K) |
| C17/C18 | 2017/2018 | Bugfix release, no new language features |
| C23 | 2024 | `nullptr`, `true`/`false`/`bool` as keywords (no header needed), `[[attributes]]`, binary literals (`0b101`), typed enums, `#embed`, `<stdbit.h>` |

`restrict` (C99) on a pointer parameter is a promise to the compiler that, for the pointer's lifetime, no other pointer will be used to access the same memory -- it enables optimizations (mainly avoiding reloads/enabling vectorization) that aliasing would otherwise forbid; violating the promise is undefined behavior. Standard library functions like `memcpy` use it in their prototypes to declare that source and destination must not overlap.

`_Generic` (C11) enables a limited form of compile-time function overloading:

```c
#define abs_generic(x) _Generic((x), \
    int: abs, \
    long: labs, \
    float: fabsf, \
    double: fabs \
)(x)
```

---

## 32. Build Tools -- Make

For anything beyond a single file, a build tool avoids re-typing/re-running the full compile command and avoids recompiling unchanged files. `make` is the traditional, still-common choice for C.

```makefile
CC = gcc
CFLAGS = -std=c17 -Wall -Wextra -g
LDFLAGS = -lm

SRCS = main.c point.c
OBJS = $(SRCS:.c=.o)
TARGET = app

$(TARGET): $(OBJS)
	$(CC) $(OBJS) -o $(TARGET) $(LDFLAGS)

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(OBJS) $(TARGET)

.PHONY: clean
```

```sh
make            # builds only what's changed (based on file mtimes)
make clean       # remove build artifacts
```

Recipe lines **must** be indented with a literal tab character, not spaces -- the single most common reason a Makefile mysteriously fails. For larger/portable projects, CMake (generates Makefiles/Ninja files/IDE projects from a higher-level `CMakeLists.txt`) is the more common modern choice; `pkg-config` helps discover compiler/linker flags for installed libraries (`pkg-config --cflags --libs libfoo`).

---

## 33. Debugging & Tooling

### gdb -- interactive debugger

```sh
gcc -g -O0 -o prog prog.c    # -g for debug symbols, -O0 so optimizations don't scramble the mapping to source
gdb ./prog
```

```
(gdb) break main          # set a breakpoint
(gdb) run                  # start execution
(gdb) next                 # step over (source line)
(gdb) step                 # step into
(gdb) print x               # inspect a variable
(gdb) backtrace             # show the call stack (essential after a crash)
(gdb) continue              # resume until next breakpoint
(gdb) watch x                # break when x's value changes
```

For a crash, `gdb ./prog core` (with a core dump) or `gdb -ex run -ex backtrace --args ./prog args` gets you a stack trace immediately.

### Valgrind (memcheck) -- runtime memory error detector

```sh
valgrind --leak-check=full --show-leak-kinds=all ./prog
```

Catches use-after-free, invalid reads/writes, memory leaks, use of uninitialized values -- at the cost of running the program 10-50x slower under emulation. Standard practice to run your test suite through it periodically.

### Sanitizers -- compiled-in instrumentation, much faster than Valgrind

```sh
gcc -g -fsanitize=address,undefined -o prog prog.c
./prog        # crashes immediately with a detailed report the instant a bug is triggered
```

- **AddressSanitizer (ASan)** (`-fsanitize=address`) -- catches buffer overflows (stack, heap, global), use-after-free, use-after-return, double-free. ~2x slowdown, far cheaper than Valgrind, ideal for CI/routine testing.
- **UndefinedBehaviorSanitizer (UBSan)** (`-fsanitize=undefined`) -- catches signed overflow, misaligned access, null pointer misuse, invalid shifts, and more.
- **ThreadSanitizer (TSan)** (`-fsanitize=thread`) -- catches data races (§30). Can't be combined with ASan in one build; run separately.
- **MemorySanitizer (MSan)** (clang only) -- catches reads of uninitialized memory.

Combining `-Wall -Wextra -Wpedantic` (compile-time) with ASan+UBSan (runtime) during development catches the overwhelming majority of real-world C bugs before they ever reach production.

### Static analysis

`clang --analyze`, `cppcheck`, and clang-tidy find bugs (leaks, null derefs, logic errors) without even running the program -- useful as an additional CI gate alongside sanitizers.

---

## 34. Best Practices & Style Summary

- Always check return values from `malloc`/`calloc`/`realloc`, `fopen`, and any function whose failure is representable in its return type.
- Initialize variables at declaration where possible; avoid depending on indeterminate values.
- One `free` per allocation, exactly once; set freed pointers to `NULL`.
- Prefer `snprintf`/bounded string functions over `strcpy`/`strcat`/`sprintf`/`gets`.
- Turn on `-Wall -Wextra -Wpedantic` (and treat as errors in CI) plus sanitizers in development builds -- always.
- Mark file-scope names `static` unless they're deliberately public API.
- Use `const` liberally on parameters/pointers that shouldn't be modified -- it documents intent and lets the compiler catch mistakes.
- Prefer fixed-width types (`<stdint.h>`) when exact size matters; prefer `size_t` for sizes/counts/indices, never a signed type, to avoid a whole class of comparison bugs.
- Parenthesize macro parameters and whole macro expansions; prefer `static inline` functions or `enum`/`const` over object-like macros where you have the choice.
- Keep functions small and single-purpose; a function that's hard to fit on one screen is a function that's hard to verify for memory-safety by inspection, which matters more in C than almost any other language.
- When in doubt about a construct's behavior under edge cases, assume it's undefined rather than assuming it's "probably fine" -- and check the sanitizers, which are cheap and authoritative.

---

## See Also

- [`asm.md`](asm.md) and [`asm-mastery/`](asm-mastery/00-index.md) in this notes tree -- the machine model underneath C: registers, the stack, calling conventions, linking, and the compiler pipeline in much greater depth.
- [`cpp.md`](cpp.md) -- C++ builds directly on this material (RAII, templates, and the STL are largely "solve C's manual-memory and generics gaps in the language").
