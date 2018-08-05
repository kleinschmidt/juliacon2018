# Why?

What's the reason this exists? Lots of data comes in **tabular form**:
heterogeneously typed, often categorical.

motivating example:

## Regression modeling

Invert design matrix...but where does design matrix come from?

## Training neural networks

# What?

**Organization** and **transformation** of data from tabular data sources for
modeling.

Organization: separate predictors (independent) from outcome (dependent)
variables.

Transform: change to numeric matrix, convert categorical data to some kind of
numeric representation (one-hot, contrast coding, etc.).

# How?

Start with `@formula` macro.  This takes a "formula expression" and

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
is just a Dict mapping each Term to a continuous or categorical term type.
Inspired by `JuliaDB.ML` you can override the defaults by providing a Dict of
"hints".

With a schema in hand the last step is to _apply_ it to our formula.  As a
baseline this just replaces each un-typed `Term` with its entry from the
schema.

(discuss contrast coding here??)

But the default behavior is more sophisticated: it tries to detect when
the model matrix you generate is going to be less than full rank and fix it.



## Syntactic transformations of formula expression

Apply special syntax rules (* expansion) and create anonymous functions for
un-handled function calls.

## Generating **Term**s from data schema

Need types and other summaries (unique values)

# Extending

So how do you build on this?  
