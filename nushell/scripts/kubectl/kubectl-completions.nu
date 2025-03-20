def available_namespaces [] {
    ^kubectl get namespaces -o yaml
    | from yaml
    | get items.metadata.name
}

def "nu-complete kubectl" [] {
    ^kubectl --help
    | lines
    | filter { str starts-with "  " }
    | drop 1
    | parse --regex '\s*(?<value>\w+)\s+(?<description>.+)'
}

export extern "kubectl" [
    command?: string@"nu-complete kubectl"
    --help(-h)
    --namespace(-n): string@available_namespaces
    --all-namespaces(-A)
    ...rest
]

def "nu-complete kubectl get" [] {
    let api_resources = ^kubectl api-resources | from ssv -a
    mut get_resources = []
    for api_res in $api_resources {
        let name = $api_res | get NAME
        let kind = $api_res | get KIND
        let namespaced = $api_res | get NAMESPACED
        let api_version = $api_res | get APIVERSION
        let shortnames = $api_res | get SHORTNAMES | split row ","
        if ($shortnames | length) > 1 {
            for short_name in $shortnames {
                let get_resource = [["value", "description"]; [$short_name, $kind]]
                $get_resources = $get_resources ++ $get_resource
            }
        }
        let get_resource = [["value", "description"]; [$name, $kind]]
        $get_resources = $get_resources ++ $get_resource
    }
    return $get_resources
}

export extern "kubectl get" [
    command?: string@"nu-complete kubectl get"
    --help(-h)
    --namespace(-n): string@available_namespaces
    --all-namespaces(-A)
    --watch(-w)
    --output(-o): string@kubectl_outputs
    ...rest
]

def pods_in_namespace [
    namespace: string
] {
    kubectl get pods -n $namespace | from ssv | get name
}

def kubectl_outputs [] {
    return ["json","yaml","name","go-template","go-template-file","template","templatefile","jsonpath","jsonpath-as-json","jsonpath-file","custom-columns","custom-columns-file","wide"]
}

def "nu-complete kubectl get pods" [] {
    if (commandline | str contains "-n") or (commandline | str contains "--namespace") {
        print $"namespace flag found (commandline)"
        let cmd_enum = (commandline | split words | enumerate)
        let namespace_index = 0
        if (commandline | str contains "-n") {
            let namespace_index = ($cmd_enum | where item == "n" | get index | into int)
        } else {
            let namespace_index = ($cmd_enum | where item == "namespace" | get index | into int)
        }
        print $namespace_index
        let namespace = ($cmd_enum | range ($namespace_index + 1)..($namespace_index + 1) | get item)
        let pods = ^kubectl get pods -n $namespace | from ssv -a
        return ($pods | get name)
    }
    print $"no namespace flag found (commandline)"
    let pods = ^kubectl get pods | from ssv -a
    let pod_names = $pods | get name
    return $pod_names
}

export extern "kubectl get pods" [
    name?: string@"nu-complete kubectl get pods",  # the name of the remote
    --namespace(-n): string@available_namespaces # the branch / refspec
    --output(-o): string@kubectl_outputs
    --all-namespaces(-A)
    ...rest
]

# export extern "kgp" [
#     name?: string@pods_in_namespace,  # the name of the remote
#     --namespace: string@available_namespaces # the branch / refspec
# ]
