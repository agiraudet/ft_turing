#!/bin/sh

ocamlfind ocamlopt -linkpkg -package yojson rules.ml -o rules
