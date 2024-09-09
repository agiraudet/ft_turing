NAME				= tm
SRC_DIR			=	src

# OCaml compiler and flags
OCAMLC 			=	ocamlfind ocamlc
OCAMLOPT 		=	ocamlfind ocamlopt
FLAGS 			=	-package yojson -linkpkg -I $(SRC_DIR)

# Source files
ML_FILES 		=	types.ml \
							utils.ml \
							tape.ml \
							machine.ml \
							parser.ml \
							main.ml

MLI_FILES		=	types.mli \
							utils.mli \
							tape.mli \
							machine.mli \
							parser.mli

ML_SRC			=	$(addprefix $(SRC_DIR)/, $(ML_FILES))
MLI_SRC			=	$(addprefix $(SRC_DIR)/, $(MLO_FILES))

# Object files
CMI_FILES = $(MLI_SRC:%.mli=%.cmi)
CMO_FILES = $(ML_SRC:%.ml=%.cmo)
CMX_FILES = $(ML_SRC:%.ml=%.cmx)

# Executable names
BYTE_EXE 		=	$(NAME).byte
NATIVE_EXE	=	$(NAME)

all: $(NATIVE_EXE)

# Byte-code compilation
$(BYTE_EXE): $(CMI_FILES) $(CMO_FILES)
	$(OCAMLC) $(FLAGS) -o $@ $(CMX_FILES)

# Native compilation
$(NATIVE_EXE): $(CMI_FILES) $(CMX_FILES)
	$(OCAMLOPT) $(FLAGS) -o $@ $(CMX_FILES)

# Generic rules for byte-code compilation
%.cmo: %.ml %.cmi
	$(OCAMLC) $(FLAGS) -c $<

# Generic rules for native compilation
%.cmx: %.ml %.cmi
	$(OCAMLOPT) $(FLAGS) -c $<

# Compile interface files
%.cmi: %.mli
	$(OCAMLC) $(FLAGS) -c $<

# For modules without .mli files
%.cmi: %.ml
	$(OCAMLC) $(FLAGS) -c $<

# Clean up
clean:
	rm -f $(SRC_DIR)/*.cmo \
				$(SRC_DIR)/*.cmi \
				$(SRC_DIR)/*.cmx \
				$(SRC_DIR)/*.o

fclean: clean
	$(BYTE_EXE) $(NATIVE_EXE)

re: clean all

# Dependencies
depend:
	ocamldep $(SRC_DIR)/$(ML_FILES) $(SRC_DIR)/$(MLI_FILES) > $(SRC_DIR)/.depend

-include $(SRC_DIR)/.depend

.PHONY: all clean fclean re
