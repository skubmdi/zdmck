default:
    @just --list

clone *args:
    @git clone {{ args }}

config target config="config" west="west.yml":
    #!/bin/bash
    west config manifest.file {{ west }}
    west config manifest.path {{ target }}/{{ config }}
    west update && west zephyr-export

build target config="config" west="west.yml" build="build.yaml" zephyr="zephyr/module.yml":
    #!/bin/bash
    [[ "$(west config manifest.file)" != "{{ west }}" ||
       "$(west config manifest.path)" != "{{ target }}/{{ config }}"
    ]] && just config "{{ target }}" "{{ config }}" "{{ west }}" || exit $?

    while IFS=$'\t' read board shield snippet aname cargs; do

        [[ -z $board || -z $shield ]] && continue
        name=${aname:-${shield:+$shield-}${board//\//_}-zmk}

        [[ -e {{ target }}/{{ zephyr }} ]] \
            && cargs="$cargs -DSHIELD="$shield" -DZMK_EXTRA_MODULES="$(pwd)/{{ target }}"" \
            || cargs="$cargs -DSHIELD="$shield" -DZMK_CONFIG="$(pwd)/{{ target }}/{{ config }}""

        # TODO 出力フォルダ構成未確定
        
        build=.build/{{ target }}/$name
        output=output/{{ target }}/$name
        (
            echo build start $name
            rm -rf "$build" "$output"; mkdir -p "$build" "$output"
            west build -p always -d "$build" -s zmk/app -b "$board" ${snippet:+-S "$snippet"} -- $cargs &> "$output.log"
            [[ $? -eq 0 ]] && {
                
                echo build success $name
                cat -s "$build/zephyr/zephyr.dts" &> "$output.dts"
                cat -s "$build/zephyr/zephyr.dts.pre" &> "$output.dts.pre"
                grep -v -e "^#" -e "^$" "$build/zephyr/.config" | sort &> "$output.config"
                for zmk in "$build/zephyr"/zmk.*; do cp "$zmk" "$output${zmk##*/zmk}"; done
            } || echo build faild $name
        ) &
    done < <(yq -r '.include[] | [.board, .shield, .snippet, ."artifact-name", ."cmake-args"] | @tsv' {{ target }}/{{ build }}); wait
