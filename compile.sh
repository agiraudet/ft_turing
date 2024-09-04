#!/bin/sh

ocamlfind ocamlopt -linkpkg -package yojson turing.ml -o tm
