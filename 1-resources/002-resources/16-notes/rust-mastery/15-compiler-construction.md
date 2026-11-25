# Building Your Own Compiler: Lexer, Parser, AST, Type Checker, Borrow Checker, Backend

Prerequisite: handbook §9 (Rust's own AST→HIR→MIR→LLVM IR pipeline) and §08 (MIR/LLVM internals in more depth). This file is a practical guide to building a small language's compiler yourself, structured as the same pipeline shape applied at toy scale.

## Lexer (Tokenizer)

Converts a raw source string into a stream of **tokens** -- the smallest meaningful units (identifiers, keywords, literals, operators, punctuation) -- discarding whitespace/comments and reporting the first layer of syntax errors (an unterminated string literal, an invalid character):

```rust
enum Token { Ident(String), Number(f64), Plus, Minus, LParen, RParen, Eof /* ... */ }

fn lex(src: &str) -> Vec<Token> {
    // walk src character by character, greedily consuming the longest valid token
    // at each position (e.g., "123" is one Number token, not three separate digits)
}
```

A hand-written lexer is usually just a loop with a `match` over the current character (peeking ahead as needed for multi-character tokens like `==` vs `=`) -- genuinely one of the simpler pipeline stages, and a reasonable first thing to build to get comfortable with the overall project shape before tackling parsing.

## Parser and AST

Consumes the token stream and builds an **Abstract Syntax Tree** reflecting the language's grammar -- the classic technique for expression parsing (handling operator precedence and associativity correctly) is **Pratt parsing** (also called precedence climbing):

```rust
enum Expr {
    Number(f64),
    BinOp(Box<Expr>, Op, Box<Expr>),
    // ...
}

fn parse_expr(tokens: &mut Peekable<impl Iterator<Item=Token>>, min_bp: u8) -> Expr {
    let mut lhs = parse_primary(tokens);
    while let Some(op) = peek_binop(tokens) {
        let (l_bp, r_bp) = binding_power(op);   // precedence, encoded as two numbers
        if l_bp < min_bp { break; }               // this operator binds LOOSER than
                                                     // our caller wants -- stop, let the
                                                     // caller handle it
        tokens.next();
        let rhs = parse_expr(tokens, r_bp);         // recurse for the right-hand side,
                                                       // using r_bp to control associativity
        lhs = Expr::BinOp(Box::new(lhs), op, Box::new(rhs));
    }
    lhs
}
```

The `(l_bp, r_bp)` binding-power pair per operator is what encodes precedence *and* associativity in one mechanism: giving `*` a higher binding power than `+` makes `1 + 2 * 3` parse as `1 + (2 * 3)`; making `r_bp` slightly *less* than `l_bp` for the same operator makes it left-associative (`1 - 2 - 3` parses as `(1 - 2) - 3`), while making `r_bp` slightly *greater* makes it right-associative (needed for exponentiation, `2 ^ 3 ^ 2` conventionally parsing as `2 ^ (3 ^ 2)`) -- a small, elegant technique that handles what would otherwise require a much larger, more repetitive grammar-driven parser generator.

## Type Checker

Walks the AST assigning (or inferring) a type to every expression, and rejects programs where types don't unify as the language's rules require:

```rust
fn typecheck(expr: &Expr, env: &TypeEnv) -> Result<Type, TypeError> {
    match expr {
        Expr::Number(_) => Ok(Type::F64),
        Expr::BinOp(l, op, r) => {
            let lt = typecheck(l, env)?;
            let rt = typecheck(r, env)?;
            if lt != rt { return Err(TypeError::Mismatch(lt, rt)); }
            Ok(lt)
        }
        // ...
    }
}
```

A toy language can get away with this simple, direct recursive-descent type checking; a language with generics/polymorphism needs real **unification** (Hindley-Milner-style, handbook §03's contrast with Rust's deliberately-local inference) -- maintaining a set of type variables and constraints gathered while walking the tree, then solving them together rather than checking each expression's type in isolation.

## Borrow Checker (If Your Toy Language Has One)

Building even a minimal borrow-checking pass is genuinely the hardest piece here, and it's exactly why handbook §9.2/§01 emphasized that Rust's *own* borrow checker runs on MIR rather than the AST: you need a **control-flow-graph-shaped** intermediate representation to do the dataflow analysis correctly (§01's move-analysis/liveness material) -- attempting borrow checking directly on a tree-shaped AST runs into real difficulty representing "this branch might or might not have moved the value" cleanly. A minimal, educational version: lower your AST into a small CFG of basic blocks (even a toy one), then run a backward-liveness dataflow pass (which locals are "live," i.e. possibly used later, at each point) and a forward-initialization dataflow pass (which locals are definitely/maybe/never initialized at each point, §08's move-analysis material) -- the intersection of these two analyses is what real borrow checkers use to reject "used after move" and "still borrowed" errors.

## Interpreter (Tree-Walking, the Simplest Backend)

The simplest possible "backend": recursively evaluate the AST directly, with no compilation step at all:

```rust
fn eval(expr: &Expr, env: &mut Env) -> Value {
    match expr {
        Expr::Number(n) => Value::F64(*n),
        Expr::BinOp(l, op, r) => apply_op(*op, eval(l, env), eval(r, env)),
        // ...
    }
}
```

Slow relative to compiling to real machine code (every node re-dispatches through the `match` on every evaluation, with no reuse of prior "what does this operator do" decisions across repeated executions of the same code, e.g. inside a loop) but by far the fastest *build-your-own-language* path to something runnable, and a completely legitimate end goal for a scripting/config language that doesn't need raw performance.

## LLVM Backend (via inkwell or similar)

Rather than hand-writing your own instruction selection/register allocation (handbook §9.5's genuinely hard combinatorial problems), a toy compiler can generate **LLVM IR** directly (handbook §9.2, §08's SSA material) and let LLVM's existing, industrial-strength optimizer and code generator handle the rest -- exactly the same leverage `rustc` itself gets by targeting LLVM instead of writing its own backend from scratch:

```rust
// using inkwell (a safe-ish Rust wrapper over the LLVM C API)
let sum = builder.build_int_add(lhs, rhs, "sum");
```

This is the practical, by far most common choice for a from-scratch language project that wants genuinely competitive generated-code performance without reimplementing decades of backend engineering -- you write the front end (lexer/parser/type-checker, all of the above) and hand off to LLVM at the IR boundary, benefiting from every optimization pass §08 described (mem2reg, inlining, GVN, vectorization) for free.

## Machine Code Backend (Writing Your Own, the Hard Way)

Skipping LLVM entirely and emitting machine code directly is a legitimate learning exercise (and how simpler, faster-compiling toy/production languages sometimes work, trading LLVM's optimization power for much faster compilation, as e.g. some JIT compilers deliberately do) -- but it means reimplementing, at whatever level of sophistication you choose, the instruction selection, register allocation, and instruction scheduling handbook §9.5 described LLVM as already handling -- a genuinely large undertaking, appropriate as a dedicated learning project (implementing even a simple linear-scan register allocator and direct instruction emission for a small instruction subset teaches an enormous amount about handbook Part I's material from the *implementer's* side) rather than a first choice for a language meant to actually be used.

## Key Takeaways

- Pratt parsing's binding-power technique elegantly unifies operator precedence and associativity into two small numbers per operator, avoiding a much larger grammar-driven parser generator for expression parsing specifically.
- A real borrow checker needs a CFG-shaped IR (not a tree-shaped AST) for the same reason Rust's own borrow checker runs on MIR rather than the AST -- dataflow analysis over branching control flow is the actual hard requirement.
- Targeting LLVM IR (rather than hand-writing a machine-code backend) is the standard, high-leverage choice for a hobby/production compiler project wanting competitive performance without reimplementing register allocation and instruction selection from scratch.

## Interview Notes

- "Why is Pratt parsing preferred over a naive recursive-descent grammar for expressions with many precedence levels?" -- naive recursive descent typically needs one grammar rule (and one parsing function) per precedence level, which becomes unwieldy for languages with many operators; Pratt parsing handles arbitrary precedence/associativity via one loop parameterized by per-operator binding-power numbers.
- "Why would a from-scratch language compiler target LLVM IR instead of writing its own backend?" -- to get LLVM's existing, heavily-engineered optimization passes and multi-target instruction selection/register allocation for free, rather than reimplementing that substantial body of work from scratch for comparable performance.
