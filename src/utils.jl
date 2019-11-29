import Pkg
import UUIDs

function _strip(s::AbstractString)::String
    result::String = convert(String, strip(s))::String
    return result
end

function _strip(v::AbstractVector{<:AbstractString})::Vector{String}
    result::Vector{String} = Vector{String}(undef, 0)
    for i = 1:length(v)
        v_i_stripped = _strip(v[i])::String
        if length(v_i_stripped) > 0
            push!(result, v_i_stripped)
        end
    end
    return result
end

@inline function is_stdlib(name::AbstractString)::Bool
    return strip(name) in values(Pkg.Types.stdlib())
end

@inline function is_jll(name::AbstractString)::Bool
    return endswith(lowercase(strip(name)), "_jll")
end

function with_temp_dir(f::Function)
    original_dir = pwd()
    tmp_dir = mktempdir()
    atexit(() -> rm(tmp_dir; force = true, recursive = true))
    cd(tmp_dir)

    result = f(tmp_dir)

    cd(original_dir)
    rm(tmp_dir; force = true, recursive = true)
    return result
end

function _get_latest_version(versions::AbstractVector{VersionNumber})
    return maximum(versions)
end

function _get_latest_zero_version(versions::AbstractVector{VersionNumber})
    all_zero_versions = filter((x) -> (x < v"1"), versions)
    push!(all_zero_versions, v"0.0.1")
    return maximum(all_zero_versions)
end
