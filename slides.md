class: middle

.slide-title[

# A `@formula` for bridging the **table-matrix** divide

## Dave Kleinschmidt — `@kleinschmidt`

### Princeton Neuroscience Institute/Rutgers University
### JuliaCon 2018 — [`tiny.cc/formula-jl`](http://tiny.cc/formula-jl)

]

---

# Why

Most data is **tabular**: heterogeneous types, named columns

Many **models** want a **numerical array**

<!-- examples?? -->

???

The basic reason that I'm here is that most data is tabular but computations
need numeric arrays of one kind or another.

---

# What

[StatsModels.jl](https://github.com/JuliaStats/StatsModels.jl) provides tools to
**organize** and **transform** tabular data for modeling

???

StatsModels provides tools to bridge this divide.  In particular

The formula DSL provides a way to compactly describe how to extract and combine
columns of tabular data...

And the ModelFrame encapsulates a formula applied to a particular data set.
This is important because how you handle tabular data depends not only on the
_types_ of the data but in some cases on it's _value_ as well.

Historically: lived in DataFrames. (new slide???)

--

The **`@formula` domain-specific language** (DSL): high-level specification of
table-to-matrix transformations

--

**Past**: 

* Part of `DataFrames`.
* Hard to extend. 
* `@formula` limited to DSL.

--

**Future**: 

* Backend-agnostic (streaming or columnar store).
* Extensible at multiple stages.
* Generic Julia code in `@formula` expressions.

--

**Present**: [JuliaStats/StatsModels.jl#71 **Terms 2.0: Son of Terms**](https://github.com/JuliaStats/StatsModels.jl/pull/71)

---

# What is a `@formula`

Compact language to describe how to **organize** and **transform** tabular data
for modeling

# .dim[How does it work]

# .dim[But I want more]

---

<h1>Organize .dim[and transform]</h1>

### Separate response and predictors

`y ~ a`

What is the effect of `a` on `y`?

---

<h1>Organize .dim[and transform]</h1>

### Combine multiple variables

`y ~ a + b`

What is the effect of `a` _and_ `b` on `y`?

---

<h1>.dim[Organize and] transform</h1>

### Interactions of terms

`y ~ a + b + a&b`

How much does the effect of `a` vary with `b`?

---

<h1>.dim[Organize and] transform</h1>

### Interactions of terms

`y ~ a + b + a&b == y ~ a*b`

How much does the effect of `a` vary with `b`?

---

# .dim[Organize and] transform

### Element-wise functions of terms .red[**(NEW!)**] 

`y ~ log(a)`

What's the effect of log-transformed `a` on y?

---

# .dim[Organize and] transform

### Other, specialzed transformations<sup>.red[*]</sup>

_Mixed-effects_ regression (effect of `a` **varies by `subject`**):

`y ~ a*b + (a | subject)`

.footnote[.red[*] Hypothetical!]

--

_B-spline_ regression (**nonlinear** effect of `a`)

`y ~ bs(a, df=7) * b`

---

# .dim[What is a `@formula`]

# How does it work

1. Macro time (surface syntax)
2. Schema time (types and some invariants)
3. Data time (a complete table or row)

# .dim[But I want more]

???

There are three distinct stages:

---

# Macro time: `@formula`

Starts with formula expression

```julia
:(y ~ 1 + a*b)
```

--

DSL rewrites

```julia
julia> parse!(:(y ~ 1 + a*b))
:(y ~ 1 + a + b + a & b)

julia> parse!(:(y ~ (a+b) & (c+d)))
:(y ~ a & c + a & d + b & c + b & d)
```

--

Wrap symbols as `Term`s

```julia
julia> terms!(parse!( :(y ~ 1 + a*b) ))
:(Term(:y) ~ InterceptTerm{true}() + Term(:a) + Term(:b) + Term(:a) & Term(:b))
```

---

# Macro time: `@formula`

A macro takes one expression and generates another:

```julia
julia> @macroexpand @formula(y ~ 1 + a*b)
:(Term(:y) ~ InterceptTerm{true}() + Term(:a) + Term(:b) + Term(:a) & Term(:b))
```

Which is immediately evaluated.

--

StatsModels.jl<sup>.red[*]</sup> defines methods for __DSL operators__ for
`AbstractTerm`s which create __higher-order terms__ out of the basics:

```julia
Term(:a) + Term(:b) == (Term(:a), Term(:b))
Term(:a) & Term(:b) == InteractionTerm((Term(:a), Term(:b)))
(Term(:y) ~ Term(:a)) == FormulaTerm(Term(:y), Term(:a))
```

.footnote[.red[*] [#71 Terms 2.0: Son of
Terms](https://github.com/JuliaStats/StatsModels.jl/pull/71)]

---

# (non-DSL calls)

Calls to non-DSL functions block DSL re-writes:

```julia
julia> parse!(:(y ~ 1 + a*b + log(a*b)))
:(y ~ 1 + a + b + a & b + log(a * b))
```

--

And lower to `capture_call` which generates a `FunctionTerm` when evaluated

```julia
julia> terms!(:(y ~ 1 + log(a*b)))
:(Term(:y) ~ 
    InterceptTerm{true}() + 
    StatsModels.capture_call($(Expr(:escape, :log)), 
                             ((a, b)->log(a * b)), 
                             (:a, :b), 
                             $(Expr(:quote, :(log(a * b))))))
```

---

# Schema time

Two basic kinds of variables: **continuous** (`<:Number`) and **categorical**
(`String`, `Symbol`, etc.)

???

A `Term` by itself is just a placeholder: a pointer to some hypothetical column
in table we haven't seen yet. It could be a vector of floats, or ints, or
strings, we don't know at this point.  And how we actually _handle_ that data is
doing to depend on the types and on some additional invariants (like the
particular levels of categorical variables)

--

**Continuous** variables are **converted** (to `Float64` etc.)

**Categorical** variables need to be **encoded** (one-hot coding, contrast coding, etc.)
which depends on the **unique values**

--

A `schema` captures all the necessary invariants to do these transformations

---

# Schema time

A schema<sup>.red[*]</sup> is a mapping from `Term`s to `CategoricalTerm`/`ContinuousTerm`s:

```julia
julia> d = (y=rand(10), a=sample(1:3, 10), b=sample([:a, :b, :c], 10));

julia> schema(d)
Dict{Any,Any} with 3 entries:
  a => a (continuous)
  b => b (categorical(2): DummyCoding)
  y => y (continuous)
```

.footnote[.red[*] ~~Inspired by~~ shamelessly stolen from [JuliaDB.ML](https://github.com/JuliaComputing/JuliaDB.jl)]

--

Override defaults with a `Dict` of _hints_

```julia
julia> schema(d, Dict(:a=>CategoricalTerm, :b=>HelmertCoding()))
Dict{Any,Any} with 3 entries:
  a => a (categorical(2): DummyCoding)
  b => b (categorical(2): HelmertCoding)
  y => y (continuous)
```

---

# Schema time

A schema applied to an `<:AbstractTerm` replaces `Term`s with their schema
entries:

```julia
julia> apply_schema(@formula(y ~ 1 + a + b), schema(d))
y (continuous) ~ 1 + a (continuous) + b (categorical(2): DummyCoding)
```

--

Schema "wrappers" allow smarter application of schemas (e.g. detect and repair
rank-deficient model matrices)

```julia
julia> apply_schema(@formula(y ~ 1 + b), FullRank(schema(d)))
y (continuous) ~ 1 + b (categorical(2): DummyCoding)

julia> apply_schema(@formula(y ~ b), FullRank(schema(d)))
y (continuous) ~ b (categorical(3): StatsModels.FullDummyCoding)
```

---

<!-- TODO: color-code terms and columns? -->
# Data time

Any `<:AbstractTerm` can general model columns from a table:

```julia
f = apply_schema(@formula(y ~ 1 + a), schema(d))
# right-hand side:
last(model_cols(f, d))
```

--

.pull-left[
```
│ Row │ y        │ a │ b │
├─────┼──────────┼───┼───┤
│ 1   │ 0.946488 │ 1 │ b │
│ 2   │ 0.658707 │ 3 │ b │
│ 3   │ 0.53838  │ 2 │ a │
│ 4   │ 0.639199 │ 3 │ c │
│ 5   │ 0.395238 │ 1 │ b │
│ 6   │ 0.212491 │ 1 │ a │
│ 7   │ 0.902297 │ 2 │ a │
│ 8   │ 0.199278 │ 2 │ a │
│ 9   │ 0.942253 │ 3 │ c │
│ 10  │ 0.953753 │ 1 │ c │
```
]

--

.pull-right[
```

10×2 Array{Float64,2}:
 1.0  1.0
 1.0  3.0
 1.0  2.0
 1.0  3.0
 1.0  1.0
 1.0  1.0
 1.0  2.0
 1.0  2.0
 1.0  3.0
 1.0  1.0
```
]

---

# Data time

Any `<:AbstractTerm` can general model columns from a table:

```julia
f = apply_schema(@formula(y ~ 1 + a + b), schema(d))
# right-hand side:
last(model_cols(f, d))
```

.pull-left[
```
│ Row │ y        │ a │ b │
├─────┼──────────┼───┼───┤
│ 1   │ 0.946488 │ 1 │ b │
│ 2   │ 0.658707 │ 3 │ b │
│ 3   │ 0.53838  │ 2 │ a │
│ 4   │ 0.639199 │ 3 │ c │
│ 5   │ 0.395238 │ 1 │ b │
│ 6   │ 0.212491 │ 1 │ a │
│ 7   │ 0.902297 │ 2 │ a │
│ 8   │ 0.199278 │ 2 │ a │
│ 9   │ 0.942253 │ 3 │ c │
│ 10  │ 0.953753 │ 1 │ c │
```
]

.pull-right[
```

10×4 Array{Float64,2}:
 1.0  1.0  0.0  0.0
 1.0  3.0  0.0  0.0
 1.0  2.0  1.0  0.0
 1.0  3.0  0.0  1.0
 1.0  1.0  0.0  0.0
 1.0  1.0  1.0  0.0
 1.0  2.0  1.0  0.0
 1.0  2.0  1.0  0.0
 1.0  3.0  0.0  1.0
 1.0  1.0  0.0  1.0
```
]


---

# Data time

Even a single `Term`

```julia
t = apply_schema(Term(:b), schema(d))
model_cols(t, d)
```

.pull-left[
```
│ Row │ y        │ a │ b │
├─────┼──────────┼───┼───┤
│ 1   │ 0.946488 │ 1 │ b │
│ 2   │ 0.658707 │ 3 │ b │
│ 3   │ 0.53838  │ 2 │ a │
│ 4   │ 0.639199 │ 3 │ c │
│ 5   │ 0.395238 │ 1 │ b │
│ 6   │ 0.212491 │ 1 │ a │
│ 7   │ 0.902297 │ 2 │ a │
│ 8   │ 0.199278 │ 2 │ a │
│ 9   │ 0.942253 │ 3 │ c │
│ 10  │ 0.953753 │ 1 │ c │
```
]

.pull-right[
```

10×2 Array{Float64,2}:
 0.0  0.0
 0.0  0.0
 1.0  0.0
 0.0  1.0
 0.0  0.0
 1.0  0.0
 1.0  0.0
 1.0  0.0
 0.0  1.0
 0.0  1.0
```
]

---

# Data time

Non-special calls are evaluated elementwise:

```julia
f = apply_schema(@formula(y ~ 1 + a + log(a) + a^2), schema(d))
# right-hand side:
last(model_cols(f, d))
```

.pull-left[
```
│ Row │ y        │ a │ b │
├─────┼──────────┼───┼───┤
│ 1   │ 0.946488 │ 1 │ b │
│ 2   │ 0.658707 │ 3 │ b │
│ 3   │ 0.53838  │ 2 │ a │
│ 4   │ 0.639199 │ 3 │ c │
│ 5   │ 0.395238 │ 1 │ b │
│ 6   │ 0.212491 │ 1 │ a │
│ 7   │ 0.902297 │ 2 │ a │
│ 8   │ 0.199278 │ 2 │ a │
│ 9   │ 0.942253 │ 3 │ c │
│ 10  │ 0.953753 │ 1 │ c │
```
]

.pull-right[
```

10×4 Array{Float64,2}:
 1.0  1.0  0.0       1.0
 1.0  3.0  1.09861   9.0
 1.0  2.0  0.693147  4.0
 1.0  3.0  1.09861   9.0
 1.0  1.0  0.0       1.0
 1.0  1.0  0.0       1.0
 1.0  2.0  0.693147  4.0
 1.0  2.0  0.693147  4.0
 1.0  3.0  1.09861   9.0
 1.0  1.0  0.0       1.0
```
]

---

# Data time

Everything works with single rows as well (just need schema)

```julia
f = apply_schema(@formula(y ~ 1 + a*b), schema(d))
model_cols(f, (y=10.0, a=2, b=:c))
```

```
(10.0, [1.0, 2.0, 0.0, 1.0, 0.0, 2.0])
```

---

# .dim[What is a `@formula`]

# .dim[How does it work]

# But I want more

Can define custom behavior at

1. Macro time (custom operators/syntax)
2. Schema time (custom data types)
3. Data time (custom outputs/transformations)

---


# Extending: Polynomial regression

```julia
mutable struct PolyTerm <: AbstractTerm
    term::AbstractTerm
    degree::Int
end
```

## Macro time

First approach: make `poly` a special function (currently does not work because
of how literal numbers are handled):

```julia
StatsModels.is_special(::Val{:poly}) = true
poly(t::Term, deg::Int) = PolyTerm(t, deg)
```

--

Second approach: use `capture_call` to intercept call expression

```julia
StatsModels.capture_call(::typeof(poly), fanon, names, ex) =
    poly(Term(ex.args[2], ex.args[3]))
```

(if function `poly` is defined!)

---

# Extending: Polynomial regression

## Schema time

```julia
StatsModels.terms(p::PolyTerm) = p.term
StatsModels.apply_schema(p::PolyTerm, sch) =
    PolyTerm(apply_schema(p.term, sch), p.degree)
```

--

## Data time

```julia
function StatsModels.model_cols(p::PolyTerm, d::NamedTuple)
    col = model_cols(p.term, d)
    hcat((col.^n for n in 1:p.degree)...)
end
```

---

# Extending: Polynomial regression

```julia
julia> f = apply_schema(@formula(y ~ 1 + poly(a, 3)), schema(d))
y (continuous) ~ 1 + PolyTerm(a (continuous), 3)

julia> model_cols(f, cols) |> last
10×4 Array{Float64,2}:
 1.0  1.0  1.0   1.0
 1.0  3.0  9.0  27.0
 1.0  2.0  4.0   8.0
 1.0  1.0  1.0   1.0
 1.0  3.0  9.0  27.0
 1.0  3.0  9.0  27.0
 1.0  1.0  1.0   1.0
 1.0  3.0  9.0  27.0
 1.0  1.0  1.0   1.0
 1.0  1.0  1.0   1.0
```

---

# Extending: Random effects terms

[MixedModels.jl](https://github.com/dmbates/MixedModels.jl) package fits
regression models that include "random effects":

`y ~ 1 + a + b + (1 + a | subject)`

Each level of `subject` has a different overall baseline (`1`) and effect for
`a`.

```julia
mutable struct RanefTerm{Ts,G} <: AbstractTerm
    terms::Ts
    group::G
end

# Generate Terms for arguments of | in @formula
StatsModels.is_special(::Val{:|}) = true
# Combine Term arguments of | into RanefTerm
Base.:|(lhs::TermOrTerms, rhs::Term) = RanefTerm(lhs, rhs)
```

```julia-repl
julia> @formula(y ~ 1 + a + (1 + a | b))
y ~ 1 + a + RanefTerm{Tuple{InterceptTerm{true},Term},Term}(1 + a, b)
```

---

# Extending: Random effects terms

## Schema time

```julia
StatsModels.terms(r::RanefTerm) = r.terms
StatsModels.apply_schema(r::RanefTerm, schema) = 
    RanefTerm(apply_schema(r.terms), r.group)
```

## Data time

Don't include ranef terms in the normal model matrix:

```julia
StatsModels.model_cols(::RanefTerm, data) = []
```

Construct `ReMat` struct from data using terms:

```julia
ReMat(r::RanefTerm, d::Data.Table) = 
    ReMat(model_cols(r.terms, d), d[r.groups.sym])
```

---

# Wrapping up

StatsModels.jl provides the `@formula` DSL to transform tabular data into
numerical matrices for modeling

Take advantage of Julia's features to be both **composable** & **performant** 

* Multiple dispatch/generic functions (Add functionality by dispatching on
  `Term`s, schema wrappers, etc.)
* Fast anonymous functions (mix in normal julia code in `@formula`)
* NamedTuples (support anything that supports DataStreams/IterableTables)

--

# Thanks

* Doug Bates + JuliaStats contributors
* Princeton Neuroscience Institute & CV Starr Foundation
