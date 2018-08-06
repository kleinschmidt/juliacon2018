This is going to be a little past, a little present, and a little future.  We're
still figuring out a properly "julian" way of doing this.

# Why?

Lots of data comes in **tabular form**: heterogeneously typed, often
categorical.  Need to get that into a form that's consumable by computational
models.

motivating example: lexdec? need something with multiple predictors?  or just
make something up?  like reading times for nouns/verbs/adjectives etc.

## Regression modeling

Invert design matrix...but where does design matrix come from?

## Training neural networks

# What?

**Organize** and **transform** data from tabular data sources for modeling.

## Organize

* `y ~ a` separate predictors (independent) from outcome (dependent) variables. 
* `y ~ a + b` combine multiple variables

## Transform

* change to numeric matrix/vector, convert categorical data to some kind of
  numeric representation (one-hot, contrast coding, etc.).
* `y ~ a + b + a&b` create "interaction" terms: how much does effect of `a`
  depend on `b`?
* `y ~ a*b`
* `y ~ a*b + (1+a|c)` other custom, domain-specific transformations

# (Some history)

Based on R/S-plus formulae....that's about all I know

Doug Bates, juliacon...2016? 2015?

Initial versions were in DataFrames.  Now live in StatsModels.

# How?

Starts with `@formula` macro.  This takes a "formula expression" and

1. Re-writes expression according to DSL rules,
2. Wrap symbols in `Term`s for special calls, and
3. Capture other calls as anonymous functions, wrapped in `FunctionTerm`s

Now we have a normal julia expression involving a lot of `Term`s and
`FunctionTerms`, glued together by normal julia operators.  StatsModels adds
methods to some of these functions that create other, higher-order terms.  

This means that the formula language is extensible almost entirely through the
normal julia approach of adding methods for your own methods!  I'll show you an
example of that later.

Next: we generate a schema from the combination of the resulting `Term`s and a
data source (which we abstract as a `NamedTuple` of columns).  The basic schema
is just a Dict that maps each Term to its type: categorical or continuous
Inspired by `JuliaDB.ML` you can override the defaults by providing "hints" in a
Dict.

With a schema in hand the last step is to _apply_ it to our formula.  As a
baseline this just replaces each un-typed `Term` with its entry from the
schema.

(discuss contrast coding here??)

But the default behavior is more sophisticated: it tries to detect when
the model matrix you generate is going to be less than full rank and fix it.  

# Extending

An important strength of julia is that it doesn't force you into a single way of
doing things.  Goal is to write code that's sufficiently generic to be useful in
many contexts and easily "play well" with others.

* NamedTuples (support anything that supports DataStreams/IterableTables)
* Fast anonymous functions (mix in normal julia code to formulae)
* Multiple dispatch/generic functions (Add functionality by dispatching on
  `Term`s, schema wrappers, etc.)
  
## New Terms: random effects

```julia

StatsModels.is_special(Val(:|)) = true
Base.|(lhs::TermOrTuple, rhs::Term) = RanefTerm(lhs, rhs) # placeholder


```

## MNIST (categorical response, image array data)

