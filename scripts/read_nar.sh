#!/bin/bash

set -o errexit -o nounset -o pipefail

archive="$1"

pad_len=8
pos_file=$(mktemp)
echo 0 > $pos_file

function get_pos() { cat $pos_file; }
function move_pos () { local pos=$(get_pos); echo $((pos + $1)) > $pos_file; }
function u64 () { od -t u8 -An -v | awk '{print $1}'; }
function assert_eq() {
    if [[ "$1" != "$2" ]]; then
        echo "assertion failed($BASH_LINENO): '$1' != '$2'";
        exit 1
    fi
}

function read_bytes () {
    local len=$1
    if [[ $len -eq 0 ]]; then
        return 0
    fi
    local pos=$(get_pos)
    move_pos $len
    # echo "reading from $pos, $len bytes" >&2
    tail -c +"$((pos+1))" "$archive" | head -c "$len" || true
}


function read_bytes_padded() {
    local content_len=$(read_bytes $pad_len | u64)
    # echo "content_len $content_len" >&2
    read_bytes $content_len
    local remainder=$((content_len % pad_len))
    if [[ $remainder -gt 0 ]]; then
        # echo "remainder $header_len $remainder" >&2
        read_bytes $((pad_len - remainder)) > /dev/null
    fi
}

trap 'echo $LINENO' ERR

magic="$(read_bytes_padded)"

if [[ $magic != "nix-archive-1" ]]; then
    echo "wrong nar $magic";
    exit 1
fi

function read_entry () {
    assert_eq "$(read_bytes_padded)" "("
    assert_eq $(read_bytes_padded) "type"
    local type=$(read_bytes_padded)
    case "$type" in
        "regular")
            local executable=0
            local tag=$(read_bytes_padded)
            if [[ "$tag" == "executable" ]]; then
                executable=1;
                read_bytes_padded
                tag=$(read_bytes_padded)
            fi
            assert_eq "$tag" "contents"
            local startpos=$(get_pos)
            startpos=$((startpos+8))

            local data=$(mktemp)
            read_bytes_padded > $data

            local len=$(cat $data | wc -c | tr -d "")
            if [[ "$name" == "bsdtar" ]]; then
                echo "($startpos,$len)"
                exit 0
            fi

            assert_eq "$(read_bytes_padded)" ")"
        ;;
        "symlink")
            echo "symlink"
            exit
        ;;
        "directory")
            while [ true ]; do
                case "$(read_bytes_padded)" in
                    "entry")
                        assert_eq "$(read_bytes_padded)" "("
                        assert_eq "$(read_bytes_padded)" "name"
                        local name=$(read_bytes_padded)
                        assert_eq "$(read_bytes_padded)" "node"
                        read_entry
                        local endpos=$(get_pos)
                        assert_eq "$(read_bytes_padded)" ")"
                    ;;
                    ")")
                        break
                    ;;
                    *)
                    ;;
                esac
            done
        ;;
        *)
            echo "illegal value"
            exit 1
        ;;
    esac
}

read_entry

exit 1
