default:
    @zdmck --list

config target config="config" west="west.yml":
    #!/bin/bash
    west config manifest.file {{ west }}
    west config manifest.path {{ target }}/{{ config }}
    west update && west zephyr-export

draw target draw="draw.yaml" config="config" info="info.json" keymap="keymap.keymap":
    #!/bin/bash
    pipx install keymap-drawer

    config="{{ target }}/{{ config }}"
    output="output/{{ target }}"; mkdir -p "$output"

    [[ -f "{{ draw }}" ]] && c="{{ draw }}"
    [[ -f "$config/{{ info }}" ]] && j="$config/{{ info }}"
    [[ -f "$config/{{ keymap }}" ]] && z="$config/{{ keymap }}"

    [[ -z "$j" ]] && j="$(find "$config" -name '*.json' | head -1)"
    [[ -z "$z" ]] && z="$(find "$config" -name '*.keymap' | head -1)"

    /root/.local/bin/keymap ${c:+-c "$c"} parse ${z:+-z "$z"} > "$output"/keymap.yaml
    /root/.local/bin/keymap ${c:+-c "$c"} draw "$output"/keymap.yaml ${j:+-j "$j"} > "$output"/keymap.svg

build target config="config" west="west.yml" build="build.yaml" zephyr="zephyr/module.yml":
    #!/bin/bash
    [[ "$(west config manifest.file)" != "{{ west }}" ||
       "$(west config manifest.path)" != "{{ target }}/{{ config }}"
    ]] && zdmck config "{{ target }}" "{{ config }}" "{{ west }}" || true

    while IFS=$'\t' read board shield snippet aname cargs; do

        [[ -z $board || -z $shield ]] && continue
        name=${aname:-${shield:+$shield-}${board//\//_}-zmk}

        [[ -e {{ target }}/{{ zephyr }} ]] \
            && cargs="$cargs -DSHIELD="$shield" -DZMK_EXTRA_MODULES="$(pwd)/{{ target }}"" \
            || cargs="$cargs -DSHIELD="$shield" -DZMK_CONFIG="$(pwd)/{{ target }}/{{ config }}""

        (
            echo build start $name
            output=output/{{ target }}
            build=.build/{{ target }}/$name

            rm -rf "$output"; mkdir -p "$output"
            west build -p always -d "$build" -s zmk/app -b "$board" ${snippet:+-S "$snippet"} -- $cargs &> "$output/$name.log"
            [[ $? -eq 0 ]] && echo build success $name || echo build faild $name
                
            cat -s "$build/zephyr/zephyr.dts" &> "$output/$name.dts"
            cat -s "$build/zephyr/zephyr.dts.pre" &> "$output/$name.dts.pre"
            grep -v -e "^#" -e "^$" "$build/zephyr/.config" | sort &> "$output/$name.config"
            for zmk in "$build/zephyr"/zmk.*; do cp "$zmk" "$output/$name${zmk##*/zmk}"; done
        ) &
    done < <(yq -r '.include[] | [.board, .shield, .snippet, ."artifact-name", ."cmake-args"] | @tsv' {{ target }}/{{ build }}); wait
