# A formula bringing data across the table-matrix divide

## Elevator pitch

Real-world data comes to you in tables full of strings, dates, numbers, etc.  To
analyze this data you often need to wrangle it into a numerical array.  The
"formula" DSL is a powerful tool to express these transformations, inspired by R
but supercharged with Julia's unique strengths.

## Description

In order to analyze real-world, tabular data, it needs to be transformed into a
suitable numerical format.  The `@formula` domain-specific language in
StatsModels.jl provides a way to specify table-to-numerical array
transformations.  This DSL was inspired by R and should be familiar to
Julia users who have experience with R, but Julia has unique strengths and
constraints.  In this talk, I'll talk about recent, ongoing, and future
developments of a distinctly Julian formula DSL.  Some of these make the formula
more flexible and useful for users, like using metaprogramming to provide
performant support for arbitrary Julia code in a formula, and support for any type
of tabular data store (including streaming and out-of-core datasets), using
`NamedTuple`s as a common interchange format.  But equally important are changes
under the hood to make the formula DSL more useful and extensible for package
developers.  These changes draw on unique language features like multiple
dispatch to allow packages to extend the formula syntax at multiple levels, from
low-level details of how the underlying formulae expressions are parsed, to
high-level specialization of the conversion from formula parts to specialized
types of model matrices (as in MixedModels.jl).  Together, this makes the
formula DSL a solid foundation for building general purpose data analysis and
modeling tools that can be applied across a variety of domains and data sources.

## Bio

Like many before and after him, Dave started hacking on Julia to procrastinate
finishing his dissertation.  Despite his best efforts he finished his PhD in
Brain and Cognitive Sciences in 2016.  In his day job as an Assistant Professor
of Psychology at Rutgers New Brunswick, he works on understanding how people
understand spoken language with such apparent ease, combining behavioral,
computational, and neural approaches.  Otherwise he's committed to promoting
open, reproducible science, and designing tools that empower researchers and
lower the barrier to entry for data analysis and statistics.
