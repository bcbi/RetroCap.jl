import Pkg
import UUIDs

function add_caps(strategy::CapStrategy, registry_path::AbstractString)
    _registry_path = convert(String, registry_path)::String
    add_caps(strategy, _registry_path)
    return nothing
end

function add_caps(strategy::CapStrategy, registry_path::String)
    pkg_to_path, pkg_to_num_versions, pkg_to_latest_version = parse_registry(registry_path)
    add_caps(strategy,
             registry_path,
             pkg_to_path,
             pkg_to_num_versions,
             pkg_to_latest_version)
    return nothing
end

function add_caps(strategy::CapStrategy,
                  registry_path::String,
                  pkg_to_path::AbstractDict{Package, String},
                  pkg_to_num_versions::AbstractDict{Package, Int},
                  pkg_to_latest_version::AbstractDict{Package, VersionNumber})
    for pkg in keys(pkg_to_path)
        pkg_path = pkg_to_path[pkg]::String
        num_versions = pkg_to_num_versions[pkg]::Int
        latest_version = pkg_to_latest_version[pkg]::VersionNumber
        if num_versions > 1
            add_caps(strategy,
                     registry_path,
                     pkg_to_latest_version,
                     pkg,
                     pkg_path)
        end
    end
    return nothing
end

function add_caps(strategy::CapStrategy,
                  registry_path::String,
                  pkg_to_latest_version::AbstractDict{Package, VersionNumber},
                  pkg::Package,
                  pkg_path::String)
    all_versions = get_all_versions(registry_path, pkg_path)
    latest_version = maximum(all_versions)

    compat_toml = joinpath(registry_path, pkg_path, "Compat.toml")
    deps_toml = joinpath(registry_path, pkg_path, "Deps.toml")

    if isfile(compat_toml) && isfile(deps_toml)
        compat = Compress.load(compat_toml)
        deps = Compress.load(deps_toml)
        for version in all_versions
            if version != latest_version
                add_caps!(compat,
                          deps,
                          strategy,
                          registry_path,
                          pkg_to_latest_version,
                          pkg,
                          pkg_path,
                          version)
            end
        end
        Compress.save(compat_toml, compat)
    end
    return nothing
end

function add_caps!(compat::AbstractDict{VersionNumber, <:Any},
                   deps::AbstractDict{VersionNumber, <:Any},
                   strategy::CapStrategy,
                   registry_path::String,
                   pkg_to_latest_version::AbstractDict{Package, VersionNumber},
                   pkg::Package,
                   pkg_path::String,
                   version::VersionNumber)
    if haskey(deps, version)
        if !haskey(compat, version)
            compat[version] = Dict{Any, Any}()
        end
        for dep in keys(deps[version])
            if !is_stdlib(dep)
                latest_dep_version = pkg_to_latest_version[Package(dep)]
                current_compat_for_dep = _strip(get(compat[version], dep, ""))
                new_compat_for_dep = generate_compat_entry(strategy, current_compat_for_dep, latest_dep_version)
                compat[version][dep] = new_compat_for_dep
            end
        end
    end
    return nothing
end