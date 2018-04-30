# Brining order to the table-matrix frontier

## Elevator pitch

Real-world data comes to you in tables full of strings, dates, numbers, etc.  To
do anything with this data you need to wrangle the table into a numerical array.
The "formula" DSL is a powerful tool to express these transformations, inspired
by R but supercharched with Julia's unique strengths.

## Description

In order to analyze real-world, tabular data, it needs to be transformed into a
suitable numerical format.  The `@formula` domain-specific language in
StatsModels.jl provides a way to specify table-to-numerical array
transformations.  This language was inspired by R and should be familiar to
Julia users who have experience with R, but Julia has unique strengths and
constraints.  In this talk, I'll talk about recent, ongoing, and future
developments of a distinctly Julian formula DSL.  Some of these make formulae
more flexible and useful for users, like using metaprogramming to provide
performant support arbitrary Julia code in a formula, and support for any type
of tabular data store (including streaming and out-of-core datasets), using
`NamedTuple`s as a common interchange format.  But equally important are changes
under the hood to make the formula DSL more useful and extensible for package
developers.  These changes draw on unique language features like multiple
dispatch to allow packages to extend the formula syntax at mulitple levels, from
low-level details of how the underlying formulae expressions are parsed, to
high-level specialization of the conversion from formula parts to specialized
types of model matrices (as in MixedModels.jl).  Together, this makes the
formula DSL a solid foundation for building general purpose data analysis and
modeling tools that can be applied across a variety of domains and data sources.
