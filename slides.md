class: center, middle
tilte: title

# A `@formula` for Bridging the Table-Matrix Divide

## Dave Kleinschmidt

---

# Why

Most data is **tabular**: heterogeneous types, named columns

Many **models** want a **numerical array**

<!-- examples?? -->

???

The basic reason that I'm here is that most data is tabular but computations
need numeric arrays of one kind or another.

---

# Why

???

An example: regression modeling

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

The **`@formula`** domain-specific language (DSL): high-level specification of
table-to-matrix transformations

--

A **`ModelFrame`** encapsulates a formula applied to a particular tabular dataset.

--

**Past**: Part of `DataFrames`.  Hard to extend.  `@formula` limited to DSL.

--

**Future**: Backend-agnostic (streaming or columnar store).  Extensible at
multiple stages.  `@formula` supports generic Julia code expressions.

---

# Today

## What is a `@formula`

## How do they work

## How to extend

---

## Organize

### Separate response and predictors

`y ~ a`

What is the effect of `a` on `y`?

---

## Organize

### Combine multiple variables

`y ~ a + b`

What is the effect of `a` _and_ `b` on `y`?

---

## Transform

### Interactions of terms

`y ~ a + b + a&b`

How much does the effect of `a` vary with `b`?

---

## Transform

### Interactions of terms

`y ~ a + b + a&b` ← `y ~ a*b`

How much does the effect of `a` vary with `b`?

---

## Transform

### Other, specialzed transformations

_Mixed-effects_ regression:

`y ~ a*b + (a | subject)`

Effect of `a` varies by `subject`

---

# What

## Example

```julia

```

---

# How

1. Macro time (surface syntax)
2. Schema time (types and some invariants)
3. Data time (a complete table or row)

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

StatsModels.jl defines methods for **DSL operators** for `AbstractTerm`s which
create **higher-order terms** out of the basics:

```julia
Term(:a) + Term(:b) == (Term(:a), Term(:b))
Term(:a) & Term(:b) == InteractionTerm((Term(:a), Term(:b)))
(Term(:y) ~ Term(:a)) == FormulaTerm(Term(:y), Term(:a))
```

---

# (non-DSL calls)

Calls to non-DSL functions block DSL re-writes:

```julia
julia> parse!(:(y ~ 1 + a*b + log(a*b)))
:(y ~ 1 + a + b + a & b + log(a * b))
```

--

And lower to `capture_call`:

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

A schema is a mapping from `Term`s to `CategoricalTerm`/`ContinuousTerm`s:

```julia
julia> d = (y=rand(10), a=sample(1:3, 10), b=sample([:a, :b, :c], 10));

julia> schema(d)
Dict{Any,Any} with 3 entries:
  a => a (continuous)
  b => b (categorical(2): DummyCoding)
  y => y (continuous)
```

.footnote[Inspired by [JuliaDB.ML](https://github.com/JuliaComputing/JuliaDB.jl)]

--

```julia
julia> schema(d, Dict(:a=>CategoricalTerm, :b=>HelmertCoding()))
Dict{Any,Any} with 3 entries:
  a => a (categorical(2): DummyCoding)
  b => b (categorical(2): HelmertCoding)
  y => y (continuous)
```

--



---

## Apply schema

A schema applied to a formula replaces `Term`s with 

```julia

```

---

## Generate model matrix
