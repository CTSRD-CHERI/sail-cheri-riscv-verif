# CHERI-RISC-V formal verification artifacts

This repository currently contains a file `cap_properties.sail` with properties
of the compressed capability helper functions of [sail-cheri-riscv], checked
using the SMT backend of [Sail].  Work on proving whole-ISA properties
corresponding to those proved for CHERI-MIPS [1] is under way.

The Makefile assumes that [sail-cheri-riscv] is checked out next to this
repository (or at `$SAIL_CHERI_RISCV`) and that Sail has been installed via
`opam` (or manually at `$SAIL_DIR`).  The `smt` Makefile target produces one
SMT-LIB file per property that can be handed to an SMT solver (asking whether
the negation of the property is satisfiable, i.e., whether there are any
counterexamples), while the `isail` target loads the properties into the Sail
interpreter and starts an interactive session.

The `check_properties` Makefile target can be used to check the properties
using the [Isla] tool, instead of Sail's SMT backend.

The properties have last been checked against commit `929cf11` of
[sail-cheri-riscv] using commit `63343363` of [Sail].

[1] Rigorous engineering for hardware security: Formal modelling and proof in
the CHERI design and implementation process. Kyndylan Nienhuis, Alexandre
Joannou, Thomas Bauereiss, Anthony Fox, Michael Roe, Brian Campbell, Matthew
Naylor, Robert M. Norton, Simon W. Moore, Peter G. Neumann, Ian Stark, Robert
N. M. Watson, and Peter Sewell. In Security and Privacy 2020.
( [DOI](http://dx.doi.org/10.1109/SP40000.2020.00055) |
[PDF](https://www.cl.cam.ac.uk/users/pes20/cheri-formal.pdf) )

[sail-cheri-riscv]: https://github.com/CTSRD-CHERI/sail-cheri-riscv
[Sail]: https://github.com/rems-project/sail
[Isla]: https://github.com/rems-project/isla
