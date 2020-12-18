/****************************************************************************/
/*  Copyright (c) 2019-2020                                                 */
/*    Thomas Bauereiss                                                      */
/*    Robert Norton-Wright                                                  */
/*    Jessica Clarke                                                        */
/*                                                                          */
/*  All rights reserved.                                                    */
/*                                                                          */
/*  This software was developed by SRI International and the University of  */
/*  Cambridge Computer Laboratory (Department of Computer Science and       */
/*  Technology) under DARPA/AFRL contract FA8650-18-C-7809 ("CIFV"), and    */
/*  under DARPA contract HR0011-18-C-0016 ("ECATS") as part of the DARPA    */
/*  SSITH research programme.                                               */
/*                                                                          */
/*  This software was developed within the Rigorous Engineering of          */
/*  Mainstream Systems (REMS) project, partly funded by EPSRC grant         */
/*  EP/K008528/1, at the Universities of Cambridge and Edinburgh.           */
/*                                                                          */
/*  This project has received funding from the European Research Council    */
/*  (ERC) under the European Union’s Horizon 2020 research and innovation   */
/*  programme (grant agreement No 789108).                                  */
/*                                                                          */
/*  This work was partially supported by Innovate UK Digital Security by    */
/*  Design (DSbD) Technology Platform Prototype ("DSbD") 105694.            */
/*                                                                          */
/*  Redistribution and use in source and binary forms, with or without      */
/*  modification, are permitted provided that the following conditions      */
/*  are met:                                                                */
/*  1. Redistributions of source code must retain the above copyright       */
/*     notice, this list of conditions and the following disclaimer.        */
/*  2. Redistributions in binary form must reproduce the above copyright    */
/*     notice, this list of conditions and the following disclaimer in      */
/*     the documentation and/or other materials provided with the           */
/*     distribution.                                                        */
/*                                                                          */
/*  THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS''      */
/*  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED       */
/*  TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A         */
/*  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR     */
/*  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,            */
/*  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT        */
/*  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF        */
/*  USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND     */
/*  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,      */
/*  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT      */
/*  OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF      */
/*  SUCH DAMAGE.                                                            */
/****************************************************************************/

/*
 * Properties of compressed capability functions
 */

$suppress_warnings

/* Syntactic sugar */

infixr 1 -->

type operator -->('p: Bool, 'q: Bool) -> Bool = not('p) | 'q
val operator --> : forall ('p 'q: Bool). (bool('p), bool('q)) -> bool('p --> 'q)
function operator --> (p, q) = not_bool(p) | q

infix 1 <-->

type operator <-->('p: Bool, 'q: Bool) -> Bool = ('p --> 'q) & ('q --> 'p)
val operator <--> : forall ('p 'q: Bool). (bool('p), bool('q)) -> bool('p <--> 'q)
function operator <--> (p, q) = (p --> q) & (q --> p)

/*****************************************************************************/

/* Encodability of capabilities

   This specification uses a record type "Capability" and only converts
   to/from the in-memory bit representation when loading from/storing to
   memory.  A value of the "Capability" record is not fully decompressed
   (it still only has the mantissas of base and top instead of their
   decoded values), but it adds a few bits compared to the in-memory
   representation:

     - the two MSBs of T, inferred from the base
     - a separate exponent field (with the low bits of B and T set to zero
       if the exponent was taken from there)

   We define a notion of "encodable" Capability records, where these values
   are computed correctly, and show that this is suitably preserved by
   capability manipulation functions.  If the specification always
   used the in-memory representation, this would not be an issue.
 */

function encodableCap(c) : Capability -> bool =
  let Bbot = truncate(c.B, cap_mantissa_width - 2) in
  let Tbot = truncate(c.T, cap_mantissa_width - 2) in
  let Btop2 = truncateLSB(c.B, 2) in
  let Ttop2 = truncateLSB(c.T, 2) in
  let Ltop2 = if c.internal_E then 0b01 else 0b00 in
  let carry_out = if Tbot <_u Bbot then 0b01 else 0b00 in
  let top_correct = (Ttop2 == Btop2 + Ltop2 + carry_out) in
  let ie_correct = (c.internal_E | (unsigned(c.E) == 0)) in
  let Bie = truncate(c.B, internal_E_take_bits) in
  let Tie = truncate(c.T, internal_E_take_bits) in
  let Zie = zeros(internal_E_take_bits) in
  let bot_correct = (if c.internal_E then Bie == Zie & Tie == Zie else true) in
  top_correct & bot_correct & ie_correct

/* A Capability is encodable iff the back-and-forth conversion to and
   from the in-memory represenation is the identity. */
$property
function propEncodableCorrect(c) : Capability -> bool =
  encodableCap(c) <--> (memBitsToCapability(c.tag, capToMemBits(c)) == c)

/* The decoding of a bit pattern is encodable */
$property
function propDecodeEncodable(capBits, tag) : (CapBits, bool) -> bool =
  encodableCap(memBitsToCapability(tag, capBits))

/* Initial and null capabilites are encodable. */
$property
function propDefaultCapEncodable() : unit -> bool = encodableCap(default_cap)

$property
function propNullCapEncodable() : unit -> bool = encodableCap(null_cap)

/* Setting bounds with a non-negative length preserves encodability. */
$property
function propSetBoundsEncodable(c, reqBase, reqTop) : (Capability, CapAddrBits, CapLenBits) -> bool =
  let (_, c') = setCapBounds(c, reqBase, reqTop) in
  let sensibleRequest = unsigned(reqBase) <= unsigned(reqTop) in
  (encodableCap(c) & sensibleRequest) --> encodableCap(c')

/* Sealing with a valid object type preserves encodability */
$property
function propSealEncodable(c, otype) : (Capability, bits(cap_otype_width)) -> bool =
  let c' = sealCap(c, otype) in
  let validType = (unsigned(otype) <= cap_max_otype) in
  (encodableCap(c) & validType) --> encodableCap(c')

/* Unsealing preserves encodability */
$property
function propUnsealEncodable(c) : Capability -> bool =
  encodableCap(c) --> encodableCap(unsealCap(c))

/* Other capability manipulations do not change the bounds or the object type,
   and therefore trivially preserve encodability. */

/*****************************************************************************/

/* The decoding of bounds normally ensures that base <= top.  However, the
   implementation currently assumes that, in case of high exponents, the most
   significant bits of B/T that would end up above 64/65 bits are zero.  We
   show that setCapBounds does not generate capabilities that violate this,
   if the requested top is at or below 2^64, which is the top of the initial
   capability.  Hence, for any (encodable) capability ultimately derived from
   the initial capability in a monotonic way, base <= top should hold. */

function validBounds(c) : Capability -> bool =
  let Bmsb  = c.B[cap_mantissa_width - 1] in
  let Bmsb2 = c.B[cap_mantissa_width - 1 .. cap_mantissa_width - 2] in
  let Tmsb  = c.T[cap_mantissa_width - 1] in
  if (unsigned(c.E) > cap_max_E) then {
    false
  } else if (unsigned(c.E) == cap_max_E) then {
    Tmsb == bitzero & Bmsb2 == 0b00
  } else if (unsigned(c.E) == cap_max_E - 1) then {
    Bmsb == bitzero
  } else true

/* setCapBounds produces valid bounds if base <= top <= 2^64 */

$property
function propSetBoundsValid(c, reqBase, reqTop) : (Capability, CapAddrBits, CapLenBits) -> bool =
  let (_, c') = setCapBounds(c, reqBase, reqTop) in
  let sensibleReq = unsigned(reqBase) <= unsigned(reqTop) & unsigned(reqTop) <= pow2(cap_addr_width) in
  sensibleReq --> validBounds(c')

/* In instructions, setCapBounds is used in a way that guarantees base <= top,
   and therefore it produces valid bounds if top <= 2^64; this should be
   implied by the fact that top is checked against the original top, which
   should be at most 2^64 for reachable capabilities */

$property
function propSetBoundsInstrValid(c, len) : (Capability, CapAddrBits) -> bool =
  let newBase = c.address in
  let newTop : CapLenBits = EXTZ(newBase) + EXTZ(len) in
  let (_, c') = setCapBounds(c, newBase, newTop) in
  let sensibleReq = unsigned(newTop) <= pow2(cap_addr_width) in
  sensibleReq --> validBounds(c')

$property
function propBaseLeqTop(c) : Capability -> bool =
  let (base, top) = getCapBounds(c) in
  (encodableCap(c) & validBounds(c)) --> (base <= top)

/* For capability bit patterns with a valid bounds encoding, the re-derivation
   sequence of CBuildCap recreates the expected bit pattern (modulo reserved
   bits). */

$property
function propBuildCapValidEq(c, auth) : (Capability, Capability) -> bool =
  let (base, top) = getCapBoundsBits(c) in
  let (_, c1) = setCapBounds(auth, base, top) in
  let (_, c2) = setCapOffset(c1, getCapOffsetBits(c)) in
  let c3 = setCapPerms(c2, getCapPerms(c)) in
  let result = setCapFlags(c3, getCapFlags(c)) in
  let expected_result = {unsealCap(c) with tag = true, reserved = auth.reserved} in
  (encodableCap(c) & encodableCap(auth) & validBounds(c) & auth.tag & not(isCapSealed(auth))) --> (result == expected_result)

/*****************************************************************************/

/* Monotonicity of setCapBounds, under preconditions corresponding to the
   checks performed by the CSetBounds instructions (and assuming reachable
   capabilities, in particular with top <= 2^64). */
$property
function propSetBounds(c, reqBase, reqTop) : (Capability, CapAddrBits, CapLenBits) -> bool = {
  let (origBase, origTop) = getCapBounds(c);
  let (exact, newCap) = setCapBounds(c, reqBase, reqTop);
  let (newBase, newTop) = getCapBounds(newCap);
  let reqBasei = unsigned(reqBase);
  let reqTopi = unsigned(reqTop);
  // exclude invalid bounds requests
  let requestSensible = reqBasei <= reqTopi & reqTopi <= pow2(cap_addr_width);
  // exclude non-monotonic bounds requests
  let requestMonotonic = origBase <= reqBasei & reqTopi <= origTop;
  // check that returned region includes requested
  let requestSatisfied = newBase <= reqBasei & reqTopi <= newTop;
  // check that returned region does not exceed original
  let boundsMonotonic = origBase <= newBase & newTop <= origTop;
  // check that exponent does not increase
  let expMonotonic = unsigned(newCap.E) <= unsigned(c.E);
  // check that exact is true iff the returned bounds are exactly as requested
  let exactCorrect = ((reqBasei == newBase) & (reqTopi == newTop)) == exact;
  (encodableCap(c) & requestSensible & requestMonotonic)
  --> (requestSatisfied & boundsMonotonic & exactCorrect & (validBounds(c) --> expMonotonic))
}

/* set/incCapOffset do not change the bounds of capabilities, if the
   representability check succeeds. */
$property
function propSetOffset(c, offset) : (Capability, CapAddrBits) -> bool = {
  let (origBase, origTop) = getCapBounds(c);
  let (representable, c') = setCapOffset(c, offset);
  let (newBase, newTop) = getCapBounds(c');
  representable --> (newBase == origBase & newTop == origTop)
}

$property
function propIncOffset(c, offset) : (Capability, CapAddrBits) -> bool = {
  let (origBase, origTop) = getCapBounds(c);
  let (representable, c') = incCapOffset(c, offset);
  let (newBase, newTop) = getCapBounds(c');
  representable --> (newBase == origBase & newTop == origTop)
}

/* Modifying the low MW-3 bits of the address is always representable */

$property
function propSetLSBs(c, bits) : (Capability, bits(cap_mantissa_width - 3)) -> bool = {
  let addr' = [c.address with (cap_mantissa_width - 4) .. 0 = bits];
  let c' = {c with address = addr'};
  let (origBase, origTop) = getCapBounds(c);
  let (newBase, newTop) = getCapBounds(c');
  (newBase == origBase & newTop == origTop)
}

/* Setting bounds to a length smaller than 2^(MW-2) is always exact. */

$property
function propSetBoundsSmallExact(c, len) : (Capability, CapAddrBits) -> bool = {
  let newBase = c.address;
  let newTop : CapLenBits = EXTZ(newBase) + EXTZ(len);
  let (exact, c') = setCapBounds(c, newBase, newTop);
  let lenSmall = (unsigned(len) < pow2(cap_mantissa_width - 2));
  lenSmall --> exact
}

/* If the requested base is aligned w.r.t. the mask given by CRAM, and the
 * requested length is rounded up via CRRL, then bounds setting is guaranteed
 * to be exact. */

$property
function propRepresentableSetBoundsExact(c, len) : (Capability, CapAddrBits) -> bool = {
  let repMask = getRepresentableAlignmentMask(len);
  let repLen = getRepresentableLength(len);
  let newTop : CapLenBits = EXTZ(c.address) + EXTZ(len);
  let (exact, c') = setCapBounds(c, c.address, newTop);
  let (newBase', newTop') = getCapBoundsBits(c');
  let boundsExact = exact & (c.address == newBase') & (newTop == newTop');
  let addressAligned = ((c.address & repMask) == c.address);
  let lenPadded = (len == repLen);
  (addressAligned & lenPadded) --> boundsExact
}

/* Naturally aligned bounds with power of 2 length are always representable */

$property
function propPowerOfTwoRepresentable(c, n) : (Capability, int) -> bool = {
  let len : CapLenBits = (EXTZ(0b1) << n);
  let alignmentMask = ~(len - 1);
  let base : CapAddrBits = c.address;
  let top : CapLenBits = EXTZ(base) + len;
  let baseAligned = (((0b0 @ base) & alignmentMask) == (0b0 @ base));
  let (exact, c') = setCapBounds(c, base, top);
  let (newBase, newTop) = getCapBoundsBits(c');
  let boundsExact = exact & (c.address == newBase) & (top == newTop);
  baseAligned --> boundsExact
}

/* Zero-length bounds are representable for any base */

$property
function propZeroLenRepresentable(c) : Capability -> bool = {
  let (exact, c') = setCapBounds(c, c.address, EXTZ(c.address));
  let (newBase, newTop) = getCapBoundsBits(c');
  exact & (newBase == c.address) & (newTop == EXTZ(c.address))
}

/* Setting bounds that have been aligned via CRAM / CRRL is monotonic if the
 * original (unaligned) bounds request is monotonic, unless there is a length overflow
 * (CRRL returns 0 if the representable length were rounded up to 2^64). */

$property
function propRepresentableBoundsMono(c, reqBase, reqLen) : (Capability, CapAddrBits, CapAddrBits) -> bool = {
  let repMask = getRepresentableAlignmentMask(reqLen);
  let repLen = getRepresentableLength(reqLen);
  let repBase = reqBase & repMask;
  let repTop : CapLenBits = EXTZ(repBase) + EXTZ(repLen);
  let reqTop : CapLenBits = EXTZ(reqBase) + EXTZ(reqLen);
  let (origBase, origTop) = getCapBounds(c);
  let requestMonotonic = (origBase <= unsigned(reqBase) & unsigned(reqTop) <= origTop);
  let boundsMonotonic = (origBase <= unsigned(repBase) & unsigned(repTop) <= origTop);
  let noLenOverflow = (unsigned(repLen) == 0 --> unsigned(reqLen) == 0);
  (requestMonotonic & noLenOverflow & encodableCap(c)) --> boundsMonotonic
}

/* getRepresentableLength is idempotent */

$property
function propRepresentableLengthIdempotent(len) : CapAddrBits -> bool =
  let repLen = getRepresentableLength(len) in
  getRepresentableLength(repLen) == repLen

/* CRAM(CRRL(len)) == CRAM(len), unless len is so large that rounding it to the
 * representable length wraps around to zero. */

$property
function propRepresentableMaskLengthAbsorb(len) : CapAddrBits -> bool =
  let repLen = getRepresentableLength(len) in
  let noLenOverflow = (unsigned(repLen) == 0 --> unsigned(len) == 0) in
  noLenOverflow --> (getRepresentableAlignmentMask(repLen) == getRepresentableAlignmentMask(len))

/* Setting the bounds of a capability to its current bounds does not change the
 * capability, with one caveat: CSetBounds uses the address of the capability
 * as the requested base, so we have to make sure that it points to the rounded
 * base (hence the setCapOffset to 0 below).  We also assume that the original
 * bounds have a canonical encoding to rule out negative lengths. */

$property
function propSetCurrentBoundsExact(c0) : Capability -> bool = {
  // CSetOffset c1, c0, 0
  let (representable, c1) = setCapOffset(c0, EXTZ(0b0));

  // CGetLen newLen2, c1
  let newLen2 : CapLenBits = {
    // fixme: the integer modulo used in getCapLength is not implemented in the
    // SMT backend, so calculate the length in bitvector rather than integer
    // arithmetic
    let (base1, top1) = getCapBoundsBits(c0);
    top1 - EXTZ(base1)
  };

  // CSetBoundsExact c2, c1, newLen2
  let newBase2 = c1.address;
  let newTop2 : CapLenBits = EXTZ(newBase2) + newLen2;
  let (exact, c2) = setCapBounds(c1, newBase2, newTop2);

  (encodableCap(c0) & validBounds(c0)) --> (c1 == c2 & representable & exact)
}

/* TODO: Elaborate on the representable range, as in this earlier attempt: */
/*
$counterexample
function propSetOffset(base, top, offset) : (CapAddrBits, CapLenBits, CapAddrBits) -> bool = {
  let (exact, cap) = setCapBounds(default_cap, base, top);
  let (representable, cap') = setCapOffset(cap, offset);
  let (origBase, origTop) = getCapBounds(cap);
  let (newBase, newTop)   = getCapBounds(cap');
  let sensibleCap = ((0b0 @ base) <=_u top) & (unsigned(top) <= pow2(cap_addr_width));
  let len = max(pow2(cap_mantissa_width - 2), origTop - origBase);
  let lowerRepOff = 0 - len;
  let upperRepOff = 6 * len;
  let signedOff = 4 * signed(offset);
  let inRepBounds = (lowerRepOff < signedOff) & (signedOff < upperRepOff);
  let representableCorrect = ((origBase == newBase) & (origTop == newTop)) == representable;
  not(sensibleCap) | (representableCorrect & (inRepBounds == representable))
}
*/
