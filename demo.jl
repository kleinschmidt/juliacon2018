
using StatsModels, StatsBase, DataStreams, DataFrames, Random

Random.seed!(1);

# a random data table:
d = DataFrame(y=rand(10), a=sample(1:3, 10), b=sample([:a, :b, :c], 10))

cols = Data.stream!(d, Data.Table)
rows = Data.stream!(d, Data.RowTable)

f = @formula(y ~ 1 + a + b)
apply_schema(f, schema(d))

model_cols(apply_schema(f, schema(d)), cols) |> last

model_cols(apply_schema(@formula(y ~ 1 + a + log(a)), schema(d)), cols) |> last




# polynomial regression ########################################################
mutable struct PolyTerm <: AbstractTerm
    term::AbstractTerm
    degree::Int
end

# Macro time #################
# first approach: (DOESN'T WORK currently because of numbers)
is_special(::Val{:poly}) = true
poly(t::Term, n::Int) = PolyTerm(t, n)

# second approach: 
function poly end
StatsModels.capture_call(::typeof(poly), fanon, names, ex) =
    poly(Term(ex.args[2]), ex.args[3])

# Schema time ################
StatsModels.terms(p::PolyTerm) = p.term
StatsModels.apply_schema(p::PolyTerm, sch) =
    PolyTerm(apply_schema(p.term, sch), p.degree)

# Data time ##################
function StatsModels.model_cols(p::PolyTerm, d::NamedTuple)
    col = model_cols(p.term, d)
    hcat((col.^n for n in 1:p.degree)...)
end

import StatsModels: termnames
termnames(p::PolyTerm) = [termnames(p.term) * "^$n" for n in 1:p.degree]

f = apply_schema(@formula(y ~ 1 + poly(a, 3)), schema(d))
# y (continuous) ~ 1 + PolyTerm(a (continuous), 3)

model_cols(f, cols) |> last
# 10×4 Array{Float64,2}:
#  1.0  1.0  1.0   1.0
#  1.0  3.0  9.0  27.0
#  1.0  2.0  4.0   8.0
#  1.0  1.0  1.0   1.0
#  1.0  3.0  9.0  27.0
#  1.0  3.0  9.0  27.0
#  1.0  1.0  1.0   1.0
#  1.0  3.0  9.0  27.0
#  1.0  1.0  1.0   1.0
#  1.0  1.0  1.0   1.0
