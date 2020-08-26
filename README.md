# CHERI-RISC-V formal verification artifacts

This repository currently contains a file with properties of the compressed
capability helper functions of [sail-cheri-riscv], checked using the SMT
backend of [Sail].  Work on proving whole-ISA properties corresponding to
those proved for CHERI-MIPS [1] is under way.

[1] Rigorous engineering for hardware security: Formal modelling and proof in
the CHERI design and implementation process. Kyndylan Nienhuis, Alexandre
Joannou, Thomas Bauereiss, Anthony Fox, Michael Roe, Brian Campbell, Matthew
Naylor, Robert M. Norton, Simon W. Moore, Peter G. Neumann, Ian Stark, Robert
N. M. Watson, and Peter Sewell. In Security and Privacy 2020.
( [DOI](http://dx.doi.org/10.1109/SP40000.2020.00055) |
[PDF](https://www.cl.cam.ac.uk/users/pes20/cheri-formal.pdf) )

[sail-cheri-riscv]: https://github.com/CTSRD-CHERI/sail-cheri-riscv
[Sail]: https://github.com/rems-project/sail
