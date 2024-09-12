open Types

exception InfLoop of string
exception NeverHalts of string
exception InvalidState of string
exception InvalidInput of string

val validate_states : machine -> machine
val validate_halt : machine -> machine
val validate_input : machine -> machine
val validate : machine -> machine
val step : machine -> machine
val examine : machine -> machine
val check_bounds : machine -> machine
val run : machine -> machine
val run_and_analyze : machine -> machine
