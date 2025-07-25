# This file is a part of Julia. License is MIT: https://julialang.org/license

"""
    Base.Chars = Union{AbstractChar,Tuple{Vararg{AbstractChar}},AbstractVector{<:AbstractChar},AbstractSet{<:AbstractChar}}

An alias type for either a single character or a tuple/vector/set of characters, used to describe arguments
of several string-matching functions such as [`startswith`](@ref) and [`strip`](@ref).

!!! compat "Julia 1.11"
    Julia versions prior to 1.11 only included `Set`, not `AbstractSet`, in `Base.Chars` types.
"""
const Chars = Union{AbstractChar,Tuple{Vararg{AbstractChar}},AbstractVector{<:AbstractChar},AbstractSet{<:AbstractChar}}

# starts with and ends with predicates

"""
    startswith(s::AbstractString, prefix::Union{AbstractString,Base.Chars})

Return `true` if `s` starts with `prefix`, which can be a string, a character,
or a tuple/vector/set of characters. If `prefix` is a tuple/vector/set
of characters, test whether the first character of `s` belongs to that set.

See also [`endswith`](@ref), [`contains`](@ref).

# Examples
```jldoctest
julia> startswith("JuliaLang", "Julia")
true
```
"""
function startswith(a::AbstractString, b::AbstractString)
    i, j = iterate(a), iterate(b)
    while true
        j === nothing && return true # ran out of prefix: success!
        i === nothing && return false # ran out of source: failure
        i[1] == j[1] || return false # mismatch: failure
        i, j = iterate(a, i[2]), iterate(b, j[2])
    end
end
startswith(str::AbstractString, chars::Chars) = !isempty(str) && first(str)::AbstractChar in chars

"""
    endswith(s::AbstractString, suffix::Union{AbstractString,Base.Chars})

Return `true` if `s` ends with `suffix`, which can be a string, a character,
or a tuple/vector/set of characters. If `suffix` is a tuple/vector/set
of characters, test whether the last character of `s` belongs to that set.

See also [`startswith`](@ref), [`contains`](@ref).

# Examples
```jldoctest
julia> endswith("Sunday", "day")
true
```
"""
function endswith(a::AbstractString, b::AbstractString)
    a, b = Iterators.Reverse(a), Iterators.Reverse(b)
    i, j = iterate(a), iterate(b)
    while true
        j === nothing && return true # ran out of suffix: success!
        i === nothing && return false # ran out of source: failure
        i[1] == j[1] || return false # mismatch: failure
        i, j = iterate(a, i[2]), iterate(b, j[2])
    end
end
endswith(str::AbstractString, chars::Chars) = !isempty(str) && last(str) in chars

function startswith(a::Union{String, SubString{String}},
                    b::Union{String, SubString{String}})
    cub = ncodeunits(b)
    if ncodeunits(a) < cub
        false
    elseif _memcmp(a, b, sizeof(b)) == 0
        nextind(a, cub) == cub + 1 # check that end of `b` doesn't match a partial character in `a`
    else
        false
    end
end

"""
    startswith(io::IO, prefix::Union{AbstractString,Base.Chars})

Check if an `IO` object starts with a prefix, which can be either a string, a
character, or a tuple/vector/set of characters.  See also [`peek`](@ref).
"""
function Base.startswith(io::IO, prefix::Base.Chars)
    mark(io)
    c = read(io, Char)
    reset(io)
    return c in prefix
end
function Base.startswith(io::IO, prefix::Union{String,SubString{String}})
    mark(io)
    s = read(io, ncodeunits(prefix))
    reset(io)
    return s == codeunits(prefix)
end
Base.startswith(io::IO, prefix::AbstractString) = startswith(io, String(prefix))

function endswith(a::Union{String, SubString{String}},
                  b::Union{String, SubString{String}})
    astart = ncodeunits(a) - ncodeunits(b) + 1
    if astart < 1
        false
    elseif GC.@preserve(a, _memcmp(pointer(a, astart), b, sizeof(b))) == 0
        thisind(a, astart) == astart # check that end of `b` doesn't match a partial character in `a`
    else
        false
    end
end

"""
    contains(haystack::AbstractString, needle)

Return `true` if `haystack` contains `needle`.
This is the same as `occursin(needle, haystack)`, but is provided for consistency with
`startswith(haystack, needle)` and `endswith(haystack, needle)`.

See also [`occursin`](@ref), [`in`](@ref), [`issubset`](@ref).

# Examples
```jldoctest
julia> contains("JuliaLang is pretty cool!", "Julia")
true

julia> contains("JuliaLang is pretty cool!", 'a')
true

julia> contains("aba", r"a.a")
true

julia> contains("abba", r"a.a")
false
```

!!! compat "Julia 1.5"
    The `contains` function requires at least Julia 1.5.
"""
contains(haystack::AbstractString, needle) = occursin(needle, haystack)

"""
    endswith(suffix)

Create a function that checks whether its argument ends with `suffix`, i.e.
a function equivalent to `y -> endswith(y, suffix)`.

The returned function is of type `Base.Fix2{typeof(endswith)}`, which can be
used to implement specialized methods.

!!! compat "Julia 1.5"
    The single argument `endswith(suffix)` requires at least Julia 1.5.

# Examples
```jldoctest
julia> endswith("Julia")("Ends with Julia")
true

julia> endswith("Julia")("JuliaLang")
false
```
"""
endswith(s) = Base.Fix2(endswith, s)

"""
    startswith(prefix)

Create a function that checks whether its argument starts with `prefix`, i.e.
a function equivalent to `y -> startswith(y, prefix)`.

The returned function is of type `Base.Fix2{typeof(startswith)}`, which can be
used to implement specialized methods.

!!! compat "Julia 1.5"
    The single argument `startswith(prefix)` requires at least Julia 1.5.

# Examples
```jldoctest
julia> startswith("Julia")("JuliaLang")
true

julia> startswith("Julia")("Ends with Julia")
false
```
"""
startswith(s) = Base.Fix2(startswith, s)

"""
    contains(needle)

Create a function that checks whether its argument contains `needle`, i.e.
a function equivalent to `haystack -> contains(haystack, needle)`.

The returned function is of type `Base.Fix2{typeof(contains)}`, which can be
used to implement specialized methods.
"""
contains(needle) = Base.Fix2(contains, needle)

"""
    chop(s::AbstractString; head::Integer = 0, tail::Integer = 1)

Remove the first `head` and the last `tail` characters from `s`.
The call `chop(s)` removes the last character from `s`.
If it is requested to remove more characters than `length(s)`
then an empty string is returned.

See also [`chomp`](@ref), [`startswith`](@ref), [`first`](@ref).

# Examples
```jldoctest
julia> a = "March"
"March"

julia> chop(a)
"Marc"

julia> chop(a, head = 1, tail = 2)
"ar"

julia> chop(a, head = 5, tail = 5)
""
```
"""
function chop(s::AbstractString; head::Integer = 0, tail::Integer = 1)
    if isempty(s)
        return SubString(s)
    end
    SubString(s, nextind(s, firstindex(s), head), prevind(s, lastindex(s), tail))
end

# TODO: optimization for the default case based on
# chop(s::AbstractString) = SubString(s, firstindex(s), prevind(s, lastindex(s)))

"""
    chopprefix(s::AbstractString, prefix::Union{AbstractString,Regex})::SubString

Remove the prefix `prefix` from `s`. If `s` does not start with `prefix`, a string equal to `s` is returned.

See also [`chopsuffix`](@ref).

!!! compat "Julia 1.8"
    This function is available as of Julia 1.8.

# Examples
```jldoctest
julia> chopprefix("Hamburger", "Ham")
"burger"

julia> chopprefix("Hamburger", "hotdog")
"Hamburger"
```
"""
function chopprefix(s::AbstractString, prefix::AbstractString)
    k = firstindex(s)
    i, j = iterate(s), iterate(prefix)
    while true
        j === nothing && i === nothing && return SubString(s, 1, 0) # s == prefix: empty result
        j === nothing && return @inbounds SubString(s, k) # ran out of prefix: success!
        i === nothing && return SubString(s) # ran out of source: failure
        i[1] == j[1] || return SubString(s) # mismatch: failure
        k = i[2]
        i, j = iterate(s, k), iterate(prefix, j[2])
    end
end

function chopprefix(s::Union{String, SubString{String}},
                    prefix::Union{String, SubString{String}})
    if startswith(s, prefix)
        SubString(s, 1 + ncodeunits(prefix))
    else
        SubString(s)
    end
end

"""
    chopsuffix(s::AbstractString, suffix::Union{AbstractString,Regex})::SubString

Remove the suffix `suffix` from `s`. If `s` does not end with `suffix`, a string equal to `s` is returned.

See also [`chopprefix`](@ref).

!!! compat "Julia 1.8"
    This function is available as of Julia 1.8.

# Examples
```jldoctest
julia> chopsuffix("Hamburger", "er")
"Hamburg"

julia> chopsuffix("Hamburger", "hotdog")
"Hamburger"
```
"""
function chopsuffix(s::AbstractString, suffix::AbstractString)
    a, b = Iterators.Reverse(s), Iterators.Reverse(suffix)
    k = lastindex(s)
    i, j = iterate(a), iterate(b)
    while true
        j === nothing && i === nothing && return SubString(s, 1, 0) # s == suffix: empty result
        j === nothing && return @inbounds SubString(s, firstindex(s), k) # ran out of suffix: success!
        i === nothing && return SubString(s) # ran out of source: failure
        i[1] == j[1] || return SubString(s) # mismatch: failure
        k = i[2]
        i, j = iterate(a, k), iterate(b, j[2])
    end
end

function chopsuffix(s::Union{String, SubString{String}},
                    suffix::Union{String, SubString{String}})
    if !isempty(suffix) && endswith(s, suffix)
        astart = ncodeunits(s) - ncodeunits(suffix) + 1
        @inbounds SubString(s, firstindex(s), prevind(s, astart))
    else
        SubString(s)
    end
end


"""
    chomp(s::AbstractString)::SubString

Remove a single trailing newline (i.e. "\\r\\n" or "\\n") from a string.

See also [`chop`](@ref).

# Examples
```jldoctest
julia> chomp("Hello\\n")
"Hello"

julia> chomp("World\\r\\n")
"World"

julia> chomp("Julia\\r\\n\\n")
"Julia\\r\\n"
```
"""
function chomp(s::AbstractString)
    i = lastindex(s)
    (i < 1 || s[i] != '\n') && (return SubString(s, 1, i))
    j = prevind(s,i)
    (j < 1 || s[j] != '\r') && (return SubString(s, 1, j))
    return SubString(s, 1, prevind(s,j))
end

@assume_effects :removable :foldable function chomp(s::Union{String, SubString{String}})
    cu = codeunits(s)
    ncu = length(cu)
    len = if iszero(ncu)
        0
    else
        has_lf = @inbounds(cu[ncu]) == 0x0a
        two_bytes = ncu > 1
        has_cr = has_lf & two_bytes & (@inbounds(cu[ncu - two_bytes]) == 0x0d)
        ncu - (has_lf + has_cr)
    end
    off = s isa String ? 0 : s.offset
    par = s isa String ? s : s.string
    @inbounds @inline SubString{String}(par, off, len, Val{:noshift}())
end
"""
    lstrip([pred=isspace,] str::AbstractString)::SubString
    lstrip(str::AbstractString, chars)::SubString

Remove leading characters from `str`, either those specified by `chars` or those for
which the function `pred` returns `true`.

The default behaviour is to remove leading whitespace and delimiters: see
[`isspace`](@ref) for precise details.

The optional `chars` argument specifies which characters to remove: it can be a single
character, or a vector or set of characters.

See also [`strip`](@ref) and [`rstrip`](@ref).

# Examples
```jldoctest
julia> a = lpad("March", 20)
"               March"

julia> lstrip(a)
"March"
```
"""
function lstrip(f, s::AbstractString)
    e = lastindex(s)
    for (i::Int, c::AbstractChar) in pairs(s)
        !f(c) && return @inbounds SubString(s, i, e)
    end
    SubString(s, e+1, e)
end
lstrip(s::AbstractString) = lstrip(isspace, s)
lstrip(s::AbstractString, chars::Chars) = lstrip(in(chars), s)
lstrip(::AbstractString, ::AbstractString) = throw(ArgumentError("Both arguments are strings. The second argument should be a `Char` or collection of `Char`s"))

"""
    rstrip([pred=isspace,] str::AbstractString)::SubString
    rstrip(str::AbstractString, chars)::SubString

Remove trailing characters from `str`, either those specified by `chars` or those for
which the function `pred` returns `true`.

The default behaviour is to remove trailing whitespace and delimiters: see
[`isspace`](@ref) for precise details.

The optional `chars` argument specifies which characters to remove: it can be a single
character, or a vector or set of characters.

See also [`strip`](@ref) and [`lstrip`](@ref).

# Examples
```jldoctest
julia> a = rpad("March", 20)
"March               "

julia> rstrip(a)
"March"
```
"""
function rstrip(f, s::AbstractString)
    for (i, c) in Iterators.reverse(pairs(s))
        f(c::AbstractChar) || return @inbounds SubString(s, 1, i::Int)
    end
    SubString(s, 1, 0)
end
rstrip(s::AbstractString) = rstrip(isspace, s)
rstrip(s::AbstractString, chars::Chars) = rstrip(in(chars), s)
rstrip(::AbstractString, ::AbstractString) = throw(ArgumentError("Both arguments are strings. The second argument should be a `Char` or collection of `Char`s"))


"""
    strip([pred=isspace,] str::AbstractString)::SubString
    strip(str::AbstractString, chars)::SubString

Remove leading and trailing characters from `str`, either those specified by `chars` or
those for which the function `pred` returns `true`.

The default behaviour is to remove leading and trailing whitespace and delimiters: see
[`isspace`](@ref) for precise details.

The optional `chars` argument specifies which characters to remove: it can be a single
character, vector or set of characters.

See also [`lstrip`](@ref) and [`rstrip`](@ref).

!!! compat "Julia 1.2"
    The method which accepts a predicate function requires Julia 1.2 or later.

# Examples
```jldoctest
julia> strip("{3, 5}\\n", ['{', '}', '\\n'])
"3, 5"
```
"""
strip(s::AbstractString) = lstrip(rstrip(s))
strip(s::AbstractString, chars::Chars) = lstrip(rstrip(s, chars), chars)
strip(::AbstractString, ::AbstractString) = throw(ArgumentError("Both arguments are strings. The second argument should be a `Char` or collection of `Char`s"))
strip(f, s::AbstractString) = lstrip(f, rstrip(f, s))

## string padding functions ##

"""
    lpad(s, n::Integer, p::Union{AbstractChar,AbstractString}=' ')::String

Stringify `s` and pad the resulting string on the left with `p` to make it `n`
characters (in [`textwidth`](@ref)) long. If `s` is already `n` characters long, an equal
string is returned. Pad with spaces by default.

# Examples
```jldoctest
julia> lpad("March", 10)
"     March"
```
!!! compat "Julia 1.7"
    In Julia 1.7, this function was changed to use `textwidth` rather than a raw character (codepoint) count.
"""
lpad(s, n::Integer, p::Union{AbstractChar,AbstractString}=' ') = lpad(string(s)::AbstractString, n, string(p))

function lpad(
    s::Union{AbstractChar,AbstractString},
    n::Integer,
    p::Union{AbstractChar,AbstractString}=' ',
)
    stringfn = if _isannotated(s) || _isannotated(p)
        annotatedstring else string end
    n = Int(n)::Int
    m = signed(n) - Int(textwidth(s))::Int
    m ≤ 0 && return stringfn(s)
    l = Int(textwidth(p))::Int
    if l == 0
        throw(ArgumentError("$(repr(p)) has zero textwidth" * (ncodeunits(p) != 1 ? "" :
            "; maybe you want pad^max(0, npad - ncodeunits(str)) * str to pad by codeunits" *
            (s isa AbstractString && codeunit(s) != UInt8 ? "?" : " (bytes)?"))))
    end
    q, r = divrem(m, l)
    r == 0 ? stringfn(p^q, s) : stringfn(p^q, first(p, r), s)
end

"""
    rpad(s, n::Integer, p::Union{AbstractChar,AbstractString}=' ')::String

Stringify `s` and pad the resulting string on the right with `p` to make it `n`
characters (in [`textwidth`](@ref)) long. If `s` is already `n` characters long, an equal
string is returned. Pad with spaces by default.

# Examples
```jldoctest
julia> rpad("March", 20)
"March               "
```
!!! compat "Julia 1.7"
    In Julia 1.7, this function was changed to use `textwidth` rather than a raw character (codepoint) count.
"""
rpad(s, n::Integer, p::Union{AbstractChar,AbstractString}=' ') = rpad(string(s)::AbstractString, n, string(p))

function rpad(
    s::Union{AbstractChar,AbstractString},
    n::Integer,
    p::Union{AbstractChar,AbstractString}=' ',
)
    stringfn = if _isannotated(s) || _isannotated(p)
        annotatedstring else string end
    n = Int(n)::Int
    m = signed(n) - Int(textwidth(s))::Int
    m ≤ 0 && return stringfn(s)
    l = Int(textwidth(p))::Int
    if l == 0
        throw(ArgumentError("$(repr(p)) has zero textwidth" * (ncodeunits(p) != 1 ? "" :
            "; maybe you want str * pad^max(0, npad - ncodeunits(str)) to pad by codeunits" *
            (s isa AbstractString && codeunit(s) != UInt8 ? "?" : " (bytes)?"))))
    end
    q, r = divrem(m, l)
    r == 0 ? stringfn(s, p^q) : stringfn(s, p^q, first(p, r))
end

"""
    rtruncate(str::AbstractString, maxwidth::Integer, replacement::Union{AbstractString,AbstractChar} = '…')

Truncate `str` to at most `maxwidth` columns (as estimated by [`textwidth`](@ref)), replacing the last characters
with `replacement` if necessary. The default replacement string is "…".

# Examples
```jldoctest
julia> s = rtruncate("🍕🍕 I love 🍕", 10)
"🍕🍕 I lo…"

julia> textwidth(s)
10

julia> rtruncate("foo", 3)
"foo"
```

!!! compat "Julia 1.12"
    This function was added in Julia 1.12.

See also [`ltruncate`](@ref) and [`ctruncate`](@ref).
"""
function rtruncate(str::AbstractString, maxwidth::Integer, replacement::Union{AbstractString,AbstractChar} = '…')
    ret = string_truncate_boundaries(str, Int(maxwidth), replacement, Val(:right))
    if isnothing(ret)
        return string(str)
    else
        left, _ = ret::Tuple{Int,Int}
        @views return str[begin:left] * replacement
    end
end

"""
    ltruncate(str::AbstractString, maxwidth::Integer, replacement::Union{AbstractString,AbstractChar} = '…')

Truncate `str` to at most `maxwidth` columns (as estimated by [`textwidth`](@ref)), replacing the first characters
with `replacement` if necessary. The default replacement string is "…".

# Examples
```jldoctest
julia> s = ltruncate("🍕🍕 I love 🍕", 10)
"…I love 🍕"

julia> textwidth(s)
10

julia> ltruncate("foo", 3)
"foo"
```

!!! compat "Julia 1.12"
    This function was added in Julia 1.12.

See also [`rtruncate`](@ref) and [`ctruncate`](@ref).
"""
function ltruncate(str::AbstractString, maxwidth::Integer, replacement::Union{AbstractString,AbstractChar} = '…')
    ret = string_truncate_boundaries(str, Int(maxwidth), replacement, Val(:left))
    if isnothing(ret)
        return string(str)
    else
        _, right = ret::Tuple{Int,Int}
        @views return replacement * str[right:end]
    end
end

"""
    ctruncate(str::AbstractString, maxwidth::Integer, replacement::Union{AbstractString,AbstractChar} = '…'; prefer_left::Bool = true)

Truncate `str` to at most `maxwidth` columns (as estimated by [`textwidth`](@ref)), replacing the middle characters
with `replacement` if necessary. The default replacement string is "…". By default, the truncation
prefers keeping chars on the left, but this can be changed by setting `prefer_left` to `false`.

# Examples
```jldoctest
julia> s = ctruncate("🍕🍕 I love 🍕", 10)
"🍕🍕 …e 🍕"

julia> textwidth(s)
10

julia> ctruncate("foo", 3)
"foo"
```

!!! compat "Julia 1.12"
    This function was added in Julia 1.12.

See also [`ltruncate`](@ref) and [`rtruncate`](@ref).
"""
function ctruncate(str::AbstractString, maxwidth::Integer, replacement::Union{AbstractString,AbstractChar} = '…'; prefer_left::Bool = true)
    ret = string_truncate_boundaries(str, Int(maxwidth), replacement, Val(:center), prefer_left)
    if isnothing(ret)
        return string(str)
    else
        left, right = ret::Tuple{Int,Int}
        @views return str[begin:left] * replacement * str[right:end]
    end
end

# return whether textwidth(str) <= maxwidth
function check_textwidth(str::AbstractString, maxwidth::Integer)
    # check efficiently for early return if str is wider than maxwidth
    total_width = 0
    for c in str
        total_width += textwidth(c)
        total_width > maxwidth && return false
    end
    return true
end

function string_truncate_boundaries(
            str::AbstractString,
            maxwidth::Integer,
            replacement::Union{AbstractString,AbstractChar},
            ::Val{mode},
            prefer_left::Bool = true) where {mode}
    maxwidth >= 0 || throw(ArgumentError("maxwidth $maxwidth should be non-negative"))
    check_textwidth(str, maxwidth) && return nothing

    l0, _ = left, right = firstindex(str), lastindex(str)
    width = textwidth(replacement)
    # used to balance the truncated width on either side
    rm_width_left, rm_width_right, force_other = 0, 0, false
    @inbounds while true
        if mode === :left || (mode === :center && (!prefer_left || left > l0))
            rm_width = textwidth(str[right])
            if mode === :left || (rm_width_right <= rm_width_left || force_other)
                force_other = false
                (width += rm_width) <= maxwidth || break
                rm_width_right += rm_width
                right = prevind(str, right)
            else
                force_other = true
            end
        end
        if mode ∈ (:right, :center)
            rm_width = textwidth(str[left])
            if mode === :left || (rm_width_left <= rm_width_right || force_other)
                force_other = false
                (width += textwidth(str[left])) <= maxwidth || break
                rm_width_left += rm_width
                left = nextind(str, left)
            else
                force_other = true
            end
        end
    end
    return prevind(str, left), nextind(str, right)
end

"""
    eachsplit(str::AbstractString, dlm; limit::Integer=0, keepempty::Bool=true)
    eachsplit(str::AbstractString; limit::Integer=0, keepempty::Bool=false)

Split `str` on occurrences of the delimiter(s) `dlm` and return an iterator over the
substrings.  `dlm` can be any of the formats allowed by [`findnext`](@ref)'s first argument
(i.e. as a string, regular expression or a function), or as a single character or collection
of characters.

If `dlm` is omitted, it defaults to [`isspace`](@ref).

The optional keyword arguments are:
 - `limit`: the maximum size of the result. `limit=0` implies no maximum (default)
 - `keepempty`: whether empty fields should be kept in the result. Default is `false` without
   a `dlm` argument, `true` with a `dlm` argument.

See also [`split`](@ref).

!!! compat "Julia 1.8"
    The `eachsplit` function requires at least Julia 1.8.

# Examples
```jldoctest
julia> a = "Ma.rch"
"Ma.rch"

julia> b = eachsplit(a, ".")
Base.SplitIterator{String, String}("Ma.rch", ".", 0, true)

julia> collect(b)
2-element Vector{SubString{String}}:
 "Ma"
 "rch"
```
"""
function eachsplit end

# Forcing specialization on `splitter` improves performance (roughly 30% decrease in runtime)
# and prevents a major invalidation risk (1550 MethodInstances)
struct SplitIterator{S<:AbstractString,F}
    str::S
    splitter::F
    limit::Int
    keepempty::Bool
end

eltype(::Type{<:SplitIterator{T}}) where T = SubString{T}
eltype(::Type{<:SplitIterator{<:SubString{T}}}) where T = SubString{T}

IteratorSize(::Type{<:SplitIterator}) = SizeUnknown()

# i: the starting index of the substring to be extracted
# k: the starting index of the next substring to be extracted
# n: the number of splits returned so far; always less than iter.limit - 1 (1 for the rest)
function iterate(iter::SplitIterator, (i, k, n)=(firstindex(iter.str), firstindex(iter.str), 0))
    i - 1 > ncodeunits(iter.str)::Int && return nothing
    r = findnext(iter.splitter, iter.str, k)::Union{Nothing,Int,UnitRange{Int}}
    while r !== nothing && n != iter.limit - 1 && first(r) <= ncodeunits(iter.str)
        j, k = first(r), nextind(iter.str, last(r))::Int
        k_ = k <= j ? nextind(iter.str, j)::Int : k
        if i < k
            substr = @inbounds SubString(iter.str, i, prevind(iter.str, j)::Int)
            (iter.keepempty || i < j) && return (substr, (k, k_, n + 1))
            i = k
        end
        k = k_
        r = findnext(iter.splitter, iter.str, k)::Union{Nothing,Int,UnitRange{Int}}
    end
    iter.keepempty || i <= ncodeunits(iter.str) || return nothing
    @inbounds SubString(iter.str, i), (ncodeunits(iter.str) + 2, k, n + 1)
end

# Specialization for partition(s,n) to return a SubString
eltype(::Type{PartitionIterator{T}}) where {T<:AbstractString} = SubString{T}
# SubStrings do not nest
eltype(::Type{PartitionIterator{T}}) where {T<:SubString} = T

function iterate(itr::PartitionIterator{<:AbstractString}, state = firstindex(itr.c))
    state > ncodeunits(itr.c) && return nothing
    r = min(nextind(itr.c, state, itr.n - 1), lastindex(itr.c))
    return SubString(itr.c, state, r), nextind(itr.c, r)
end

eachsplit(str::T, splitter; limit::Integer=0, keepempty::Bool=true) where {T<:AbstractString} =
    SplitIterator(str, splitter, limit, keepempty)

eachsplit(str::T, splitter::Union{Tuple{Vararg{AbstractChar}},AbstractVector{<:AbstractChar},Set{<:AbstractChar}};
          limit::Integer=0, keepempty=true) where {T<:AbstractString} =
    eachsplit(str, in(splitter); limit, keepempty)

eachsplit(str::T, splitter::AbstractChar; limit::Integer=0, keepempty=true) where {T<:AbstractString} =
    eachsplit(str, isequal(splitter); limit, keepempty)

# a bit oddball, but standard behavior in Perl, Ruby & Python:
eachsplit(str::AbstractString; limit::Integer=0, keepempty=false) =
    eachsplit(str, isspace; limit, keepempty)

"""
    eachrsplit(str::AbstractString, dlm; limit::Integer=0, keepempty::Bool=true)
    eachrsplit(str::AbstractString; limit::Integer=0, keepempty::Bool=false)

Return an iterator over `SubString`s of `str`, produced when splitting on
the delimiter(s) `dlm`, and yielded in reverse order (from right to left).
`dlm` can be any of the formats allowed by [`findprev`](@ref)'s first argument
(i.e. a string, a single character or a function), or a collection of characters.

If `dlm` is omitted, it defaults to [`isspace`](@ref), and `keepempty` default to `false`.

The optional keyword arguments are:
 - If `limit > 0`, the iterator will split at most `limit - 1` times before returning
   the rest of the string unsplit. `limit < 1` implies no cap to splits (default).
 - `keepempty`: whether empty fields should be returned when iterating
   Default is `false` without a `dlm` argument, `true` with a `dlm` argument.

Note that unlike [`split`](@ref), [`rsplit`](@ref) and [`eachsplit`](@ref), this
function iterates the substrings right to left as they occur in the input.

See also [`eachsplit`](@ref), [`rsplit`](@ref).

!!! compat "Julia 1.11"
    This function requires Julia 1.11 or later.

# Examples
```jldoctest
julia> a = "Ma.r.ch";

julia> collect(eachrsplit(a, ".")) == ["ch", "r", "Ma"]
true

julia> collect(eachrsplit(a, "."; limit=2)) == ["ch", "Ma.r"]
true
```
"""
function eachrsplit end

struct RSplitIterator{S <: AbstractString, F}
    str::S
    splitter::F
    limit::Int
    keepempty::Bool
end

eltype(::Type{<:RSplitIterator{T}}) where T = SubString{T}
eltype(::Type{<:RSplitIterator{<:SubString{T}}}) where T = SubString{T}

IteratorSize(::Type{<:RSplitIterator}) = SizeUnknown()

eachrsplit(str::T, splitter; limit::Integer=0, keepempty::Bool=true) where {T<:AbstractString} =
    RSplitIterator(str, splitter, limit, keepempty)

eachrsplit(str::T, splitter::Union{Tuple{Vararg{AbstractChar}},AbstractVector{<:AbstractChar},Set{<:AbstractChar}};
          limit::Integer=0, keepempty=true) where {T<:AbstractString} =
    eachrsplit(str, in(splitter); limit, keepempty)

eachrsplit(str::T, splitter::AbstractChar; limit::Integer=0, keepempty=true) where {T<:AbstractString} =
    eachrsplit(str, isequal(splitter); limit, keepempty)

# a bit oddball, but standard behavior in Perl, Ruby & Python:
eachrsplit(str::AbstractString; limit::Integer=0, keepempty=false) =
    eachrsplit(str, isspace; limit, keepempty)

function Base.iterate(it::RSplitIterator, (to, remaining_splits)=(lastindex(it.str), it.limit-1))
    to < 0 && return nothing
    from = 1
    next_to = -1
    while !iszero(remaining_splits)
        pos = findprev(it.splitter, it.str, to)
        # If no matches: It returns the rest of the string, then the iterator stops.
        if pos === nothing
            from = 1
            next_to = -1
            break
        else
            from = nextind(it.str, last(pos))
            # pos can be empty if we search for a zero-width delimiter, in which
            # case pos is to:to-1.
            # In this case, next_to must be to - 1, except if to is 0 or 1, in
            # which case, we must stop iteration for some reason.
            next_to = (isempty(pos) & (to < 2)) ? -1 : prevind(it.str, first(pos))

            # If the element we emit is empty, discard it based on keepempty
            if from > to && !(it.keepempty)
                to = next_to
                continue
            end
            break
        end
    end
    from > to && !(it.keepempty) && return nothing
    return (SubString(it.str, from, to), (next_to, remaining_splits-1))
end

"""
    split(str::AbstractString, dlm; limit::Integer=0, keepempty::Bool=true)
    split(str::AbstractString; limit::Integer=0, keepempty::Bool=false)

Split `str` into an array of substrings on occurrences of the delimiter(s) `dlm`.  `dlm`
can be any of the formats allowed by [`findnext`](@ref)'s first argument (i.e. as a
string, regular expression or a function), or as a single character or collection of
characters.

If `dlm` is omitted, it defaults to [`isspace`](@ref).

The optional keyword arguments are:
 - `limit`: the maximum size of the result. `limit=0` implies no maximum (default)
 - `keepempty`: whether empty fields should be kept in the result. Default is `false` without
   a `dlm` argument, `true` with a `dlm` argument.

See also [`rsplit`](@ref), [`eachsplit`](@ref).

# Examples
```jldoctest
julia> a = "Ma.rch"
"Ma.rch"

julia> split(a, ".")
2-element Vector{SubString{String}}:
 "Ma"
 "rch"
```
"""
function split(str::T, splitter;
               limit::Integer=0, keepempty::Bool=true) where {T<:AbstractString}
    collect(eachsplit(str, splitter; limit, keepempty))
end

# a bit oddball, but standard behavior in Perl, Ruby & Python:
split(str::AbstractString;
      limit::Integer=0, keepempty::Bool=false) =
    split(str, isspace; limit, keepempty)

"""
    rsplit(s::AbstractString; limit::Integer=0, keepempty::Bool=false)
    rsplit(s::AbstractString, chars; limit::Integer=0, keepempty::Bool=true)

Similar to [`split`](@ref), but starting from the end of the string.

# Examples
```jldoctest
julia> a = "M.a.r.c.h"
"M.a.r.c.h"

julia> rsplit(a, ".")
5-element Vector{SubString{String}}:
 "M"
 "a"
 "r"
 "c"
 "h"

julia> rsplit(a, "."; limit=1)
1-element Vector{SubString{String}}:
 "M.a.r.c.h"

julia> rsplit(a, "."; limit=2)
2-element Vector{SubString{String}}:
 "M.a.r.c"
 "h"
```
"""
function rsplit(str::T, splitter;
               limit::Integer=0, keepempty::Bool=true) where {T<:AbstractString}
    reverse!(collect(eachrsplit(str, splitter; limit, keepempty)))
end

# a bit oddball, but standard behavior in Perl, Ruby & Python:
rsplit(str::AbstractString;
      limit::Integer=0, keepempty::Bool=false) =
    rsplit(str, isspace; limit, keepempty)

_replace(io, repl, str, r, pattern) = print(io, repl)
_replace(io, repl::Function, str, r, pattern) =
    print(io, repl(SubString(str, first(r), last(r))))
_replace(io, repl::Function, str, r, pattern::Function) =
    print(io, repl(str[first(r)]))

_pat_replacer(x) = x
_free_pat_replacer(x) = nothing

_pat_replacer(x::AbstractChar) = isequal(x)
_pat_replacer(x::Union{Tuple{Vararg{AbstractChar}},AbstractVector{<:AbstractChar},Set{<:AbstractChar}}) = in(x)

# note: leave str untyped here to make it easier for packages like StringViews to hook in
function _replace_init(str, pat_repl::NTuple{N, Pair}, count::Int) where N
    count < 0 && throw(DomainError(count, "`count` must be non-negative."))
    e1 = nextind(str, lastindex(str)) # sizeof(str)+1
    a = firstindex(str)
    patterns = map(p -> _pat_replacer(first(p)), pat_repl)
    replaces = map(last, pat_repl)
    rs = map(patterns) do p
        r = findnext(p, str, a)
        if r === nothing || first(r) == 0
            return e1+1:0
        end
        r isa Int && (r = r:r) # findnext / performance fix
        return r
    end
    return e1, patterns, replaces, rs, all(>(e1), map(first, rs))
end

# note: leave str untyped here to make it easier for packages like StringViews to hook in
function _replace_finish(io::IO, str, count::Int,
                         e1::Int, patterns::Tuple, replaces::Tuple, rs::Tuple)
    n = 1
    i = a = firstindex(str)
    while true
        p = argmin(map(first, rs)) # TODO: or argmin(rs), to pick the shortest first match ?
        r = rs[p]
        j, k = first(r), last(r)
        j > e1 && break
        if i == a || i <= k
            # copy out preserved portion
            GC.@preserve str unsafe_write(io, pointer(str, i), UInt(j-i))
            # copy out replacement string
            _replace(io, replaces[p], str, r, patterns[p])
        end
        if k < j
            i = j
            j == e1 && break
            k = nextind(str, j)
        else
            i = k = nextind(str, k)
        end
        n == count && break
        let k = k
            rs = map(patterns, rs) do p, r
                if first(r) < k
                    r = findnext(p, str, k)
                    if r === nothing || first(r) == 0
                        return e1+1:0
                    end
                    r isa Int && (r = r:r) # findnext / performance fix
                end
                return r
            end
        end
        n += 1
    end
    foreach(_free_pat_replacer, patterns)
    write(io, SubString(str, i))
    return io
end

# note: leave str untyped here to make it easier for packages like StringViews to hook in
function _replace_(io::IO, str, pat_repl::NTuple{N, Pair}, count::Int) where N
    if count == 0
        write(io, str)
        return io
    end
    e1, patterns, replaces, rs, notfound = _replace_init(str, pat_repl, count)
    if notfound
        foreach(_free_pat_replacer, patterns)
        write(io, str)
        return io
    end
    return _replace_finish(io, str, count, e1, patterns, replaces, rs)
end

# note: leave str untyped here to make it easier for packages like StringViews to hook in
function _replace_(str, pat_repl::NTuple{N, Pair}, count::Int) where N
    count == 0 && return String(str)
    e1, patterns, replaces, rs, notfound = _replace_init(str, pat_repl, count)
    if notfound
        foreach(_free_pat_replacer, patterns)
        return String(str)
    end
    out = IOBuffer(sizehint=floor(Int, 1.2sizeof(str)))
    return takestring!(_replace_finish(out, str, count, e1, patterns, replaces, rs))
end

"""
    replace([io::IO], s::AbstractString, pat=>r, [pat2=>r2, ...]; [count::Integer])

Search for the given pattern `pat` in `s`, and replace each occurrence with `r`.
If `count` is provided, replace at most `count` occurrences.
`pat` may be a single character, a vector or a set of characters, a string,
or a regular expression.
If `r` is a function, each occurrence is replaced with `r(s)`
where `s` is the matched substring (when `pat` is a `AbstractPattern` or `AbstractString`) or
character (when `pat` is an `AbstractChar` or a collection of `AbstractChar`).
If `pat` is a regular expression and `r` is a [`SubstitutionString`](@ref), then capture group
references in `r` are replaced with the corresponding matched text.
To remove instances of `pat` from `string`, set `r` to the empty `String` (`""`).

The return value is a new string after the replacements.  If the `io::IO` argument
is supplied, the transformed string is instead written to `io` (returning `io`).
(For example, this can be used in conjunction with an [`IOBuffer`](@ref) to re-use
a pre-allocated buffer array in-place.)

Multiple patterns can be specified: The input string will be scanned only once
from start (left) to end (right), and the first matching replacement
will be applied to each substring. Replacements are applied in the order of
the arguments provided if they match substrings starting at the same
input string position. Thus, only one pattern will be applied to any character, and the
patterns will only be applied to the input text, not the replacements.

!!! compat "Julia 1.7"
    Support for multiple patterns requires version 1.7.

!!! compat "Julia 1.10"
    The `io::IO` argument requires version 1.10.

# Examples
```jldoctest
julia> replace("Python is a programming language.", "Python" => "Julia")
"Julia is a programming language."

julia> replace("The quick foxes run quickly.", "quick" => "slow", count=1)
"The slow foxes run quickly."

julia> replace("The quick foxes run quickly.", "quick" => "", count=1)
"The  foxes run quickly."

julia> replace("The quick foxes run quickly.", r"fox(es)?" => s"bus\\1")
"The quick buses run quickly."

julia> replace("abcabc", "a" => "b", "b" => "c", r".+" => "a")
"bca"
```
"""
replace(io::IO, s::AbstractString, pat_f::Pair...; count=typemax(Int)) =
    _replace_(io, String(s), pat_f, Int(count))

replace(s::AbstractString, pat_f::Pair...; count=typemax(Int)) =
    _replace_(String(s), pat_f, Int(count))


# TODO: allow transform as the first argument to replace?

# hex <-> bytes conversion

"""
    hex2bytes(itr)

Given an iterable `itr` of ASCII codes for a sequence of hexadecimal digits, returns a
`Vector{UInt8}` of bytes  corresponding to the binary representation: each successive pair
of hexadecimal digits in `itr` gives the value of one byte in the return vector.

The length of `itr` must be even, and the returned array has half of the length of `itr`.
See also [`hex2bytes!`](@ref) for an in-place version, and [`bytes2hex`](@ref) for the inverse.

!!! compat "Julia 1.7"
    Calling `hex2bytes` with iterators producing `UInt8` values requires
    Julia 1.7 or later. In earlier versions, you can `collect` the iterator
    before calling `hex2bytes`.

# Examples
```jldoctest
julia> s = string(12345, base = 16)
"3039"

julia> hex2bytes(s)
2-element Vector{UInt8}:
 0x30
 0x39

julia> a = b"01abEF"
6-element Base.CodeUnits{UInt8, String}:
 0x30
 0x31
 0x61
 0x62
 0x45
 0x46

julia> hex2bytes(a)
3-element Vector{UInt8}:
 0x01
 0xab
 0xef
```
"""
function hex2bytes end

hex2bytes(s) = hex2bytes!(Vector{UInt8}(undef, length(s)::Int >> 1), s)

# special case - valid bytes are checked in the generic implementation
function hex2bytes!(dest::AbstractArray{UInt8}, s::String)
    sizeof(s) != length(s) && throw(ArgumentError("input string must consist of hexadecimal characters only"))

    hex2bytes!(dest, transcode(UInt8, s))
end

"""
    hex2bytes!(dest::AbstractVector{UInt8}, itr)

Convert an iterable `itr` of bytes representing a hexadecimal string to its binary
representation, similar to [`hex2bytes`](@ref) except that the output is written in-place
to `dest`. The length of `dest` must be half the length of `itr`.

!!! compat "Julia 1.7"
    Calling hex2bytes! with iterators producing UInt8 requires
    version 1.7. In earlier versions, you can collect the iterable
    before calling instead.
"""
function hex2bytes!(dest::AbstractArray{UInt8}, itr)
    isodd(length(itr)) && throw(ArgumentError("length of iterable must be even"))
    @boundscheck 2*length(dest) != length(itr) && throw(ArgumentError("length of output array must be half of the length of input iterable"))
    iszero(length(itr)) && return dest

    next = iterate(itr)
    @inbounds for i in eachindex(dest)
        x,state = next::NTuple{2,Any}
        y,state = iterate(itr, state)::NTuple{2,Any}
        next = iterate(itr, state)
        dest[i] = number_from_hex(x) << 4 + number_from_hex(y)
    end

    return dest
end

@inline number_from_hex(c::AbstractChar) = number_from_hex(Char(c))
@inline number_from_hex(c::Char) = number_from_hex(UInt8(c))
@inline function number_from_hex(c::UInt8)
    UInt8('0') <= c <= UInt8('9') && return c - UInt8('0')
    c |= 0b0100000
    UInt8('a') <= c <= UInt8('f') && return c - UInt8('a') + 0x0a
    throw(ArgumentError("byte is not an ASCII hexadecimal digit"))
end

"""
    bytes2hex(itr)::String
    bytes2hex(io::IO, itr)::Nothing

Convert an iterator `itr` of bytes to its hexadecimal string representation, either
returning a `String` via `bytes2hex(itr)` or writing the string to an `io` stream
via `bytes2hex(io, itr)`.  The hexadecimal characters are all lowercase.

!!! compat "Julia 1.7"
    Calling `bytes2hex` with arbitrary iterators producing `UInt8` values requires
    Julia 1.7 or later. In earlier versions, you can `collect` the iterator
    before calling `bytes2hex`.

# Examples
```jldoctest
julia> a = string(12345, base = 16)
"3039"

julia> b = hex2bytes(a)
2-element Vector{UInt8}:
 0x30
 0x39

julia> bytes2hex(b)
"3039"
```
"""
function bytes2hex end

function bytes2hex(itr)
    eltype(itr) === UInt8 || throw(ArgumentError("eltype of iterator not UInt8"))
    b = Base.StringMemory(2*length(itr))
    @inbounds for (i, x) in enumerate(itr)
        b[2i - 1] = hex_chars[1 + x >> 4]
        b[2i    ] = hex_chars[1 + x & 0xf]
    end
    return unsafe_takestring(b)
end

function bytes2hex(io::IO, itr)
    eltype(itr) === UInt8 || throw(ArgumentError("eltype of iterator not UInt8"))
    for x in itr
        print(io, Char(hex_chars[1 + x >> 4]), Char(hex_chars[1 + x & 0xf]))
    end
end

# check for pure ASCII-ness
function ascii(s::String)
    for i in 1:sizeof(s)
        @inbounds codeunit(s, i) < 0x80 || __throw_invalid_ascii(s, i)
    end
    return s
end
@noinline __throw_invalid_ascii(s::String, i::Int) = throw(ArgumentError("invalid ASCII at index $i in $(repr(s))"))

"""
    ascii(s::AbstractString)

Convert a string to `String` type and check that it contains only ASCII data, otherwise
throwing an `ArgumentError` indicating the position of the first non-ASCII byte.

See also the [`isascii`](@ref) predicate to filter or replace non-ASCII characters.

# Examples
```jldoctest
julia> ascii("abcdeγfgh")
ERROR: ArgumentError: invalid ASCII at index 6 in "abcdeγfgh"
Stacktrace:
[...]

julia> ascii("abcdefgh")
"abcdefgh"
```
"""
ascii(x::AbstractString) = ascii(String(x))

Base.rest(s::Union{String,SubString{String}}, i=1) = SubString(s, i)
function Base.rest(s::AbstractString, st...)
    io = IOBuffer()
    for c in Iterators.rest(s, st...)
        print(io, c)
    end
    return takestring!(io)
end
