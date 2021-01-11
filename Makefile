############################################################################
#  Copyright (c) 2019-2020                                                 #
#    Thomas Bauereiss                                                      #
#    Robert Norton-Wright                                                  #
#    Jessica Clarke                                                        #
#    Prashanth Mundkur                                                     #
#    Alexander Richardson                                                  #
#                                                                          #
#  All rights reserved.                                                    #
#                                                                          #
#  This software was developed by SRI International and the University of  #
#  Cambridge Computer Laboratory (Department of Computer Science and       #
#  Technology) under DARPA/AFRL contract FA8650-18-C-7809 ("CIFV"), and    #
#  under DARPA contract HR0011-18-C-0016 ("ECATS") as part of the DARPA    #
#  SSITH research programme.                                               #
#                                                                          #
#  This software was developed within the Rigorous Engineering of          #
#  Mainstream Systems (REMS) project, partly funded by EPSRC grant         #
#  EP/K008528/1, at the Universities of Cambridge and Edinburgh.           #
#                                                                          #
#  This project has received funding from the European Research Council    #
#  (ERC) under the European Union’s Horizon 2020 research and innovation   #
#  programme (grant agreement No 789108).                                  #
#                                                                          #
#  This work was partially supported by Innovate UK Digital Security by    #
#  Design (DSbD) Technology Platform Prototype ("DSbD") 105694.            #
#                                                                          #
#  Redistribution and use in source and binary forms, with or without      #
#  modification, are permitted provided that the following conditions      #
#  are met:                                                                #
#  1. Redistributions of source code must retain the above copyright       #
#     notice, this list of conditions and the following disclaimer.        #
#  2. Redistributions in binary form must reproduce the above copyright    #
#     notice, this list of conditions and the following disclaimer in      #
#     the documentation and/or other materials provided with the           #
#     distribution.                                                        #
#                                                                          #
#  THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS''      #
#  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED       #
#  TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A         #
#  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR     #
#  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,            #
#  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT        #
#  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF        #
#  USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND     #
#  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,      #
#  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT      #
#  OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF      #
#  SUCH DAMAGE.                                                            #
############################################################################

# Simplified makefile for CHERI.
# Default architecture to build for all and non-namespaced targets
ARCH ?= RV64
ifeq ($(ARCH),32)
  override ARCH := RV32
else ifeq ($(ARCH),64)
  override ARCH := RV64
endif

SAIL_CHERI_RISCV=../sail-cheri-riscv
SAIL_RISCV_DIR=$(SAIL_CHERI_RISCV)/sail-riscv
SAIL_RISCV_MODEL_DIR=$(SAIL_RISCV_DIR)/model
SAIL_CHERI_MODEL_DIR=$(SAIL_CHERI_RISCV)/src

SAIL_RV32_XLEN := $(SAIL_RISCV_MODEL_DIR)/riscv_xlen32.sail
SAIL_RV32_FLEN := $(SAIL_RISCV_MODEL_DIR)/riscv_flen_F.sail
CHERI_CAP_RV32_IMPL := cheri_prelude_64.sail

SAIL_RV64_XLEN := $(SAIL_RISCV_MODEL_DIR)/riscv_xlen64.sail
SAIL_RV64_FLEN := $(SAIL_RISCV_MODEL_DIR)/riscv_flen_D.sail
CHERI_CAP_RV64_IMPL := cheri_prelude_128.sail

SAIL_XLEN = $(SAIL_$(ARCH)_XLEN)
SAIL_FLEN = $(SAIL_$(ARCH)_FLEN)
CHERI_CAP_IMPL = $(CHERI_CAP_$(ARCH)_IMPL)


PRELUDE = $(SAIL_RISCV_MODEL_DIR)/prelude.sail \
          $(SAIL_RISCV_MODEL_DIR)/prelude_mapping.sail \
          $(SAIL_XLEN) \
          $(SAIL_FLEN) \
          $(SAIL_CHERI_MODEL_DIR)/cheri_prelude.sail \
          $(SAIL_CHERI_MODEL_DIR)/cheri_types.sail \
          $(SAIL_CHERI_MODEL_DIR)/$(CHERI_CAP_IMPL) \
          $(SAIL_CHERI_MODEL_DIR)/cheri_mem_metadata.sail \
          $(SAIL_RISCV_MODEL_DIR)/prelude_mem.sail \
          $(SAIL_CHERI_MODEL_DIR)/cheri_cap_common.sail

PRELUDE_SRCS   = $(PRELUDE)

# Attempt to work with either sail from opam or built from repo in SAIL_DIR
ifneq ($(SAIL_DIR),)
# Use sail repo in SAIL_DIR
SAIL:=$(SAIL_DIR)/sail
export SAIL_DIR
else
# Use sail from opam package
SAIL_DIR=$(shell opam config var sail:share)
SAIL:=sail
endif

isail:
	$(SAIL) $(SAIL_FLAGS) -i $(PRELUDE_SRCS) cap_properties.sail

SMT=cvc4
SMT_FLAGS=--lang=smt2.6
smt:
	$(SAIL) $(SAIL_FLAGS) -smt $(PRELUDE_SRCS) cap_properties.sail

smt_auto:
	$(SAIL) $(SAIL_FLAGS) -smt_auto $(PRELUDE_SRCS) cap_properties.sail
