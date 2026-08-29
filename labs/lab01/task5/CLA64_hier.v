// cla64_hier.v
// BONUS -- open-ended. No detailed scaffold is provided; this is meant to
// be a genuine design exercise. Not required for lab submission.
//
// You will likely need to modify cla4.v (or add signals alongside it) so
// that block-generate/block-propagate summaries of its own Gi, Pi signals
// are exposed as outputs, since the second-level lookahead unit below
// needs them. As with every module in this lab from Task 2 onward, every
// gate/assign you add should carry an explicit delay.
//
// Starting point (from Tutorial 3, Q4(d)):
//   - Reuse 16 four-bit CLA blocks (your cla4.v) -- their internal logic
//     doesn't change.
//   - For each block k, define:
//       Gblk_k = "this block produces a carry regardless of its incoming
//                 carry" -- a Boolean function of that block's own 4
//                 bit-level Gi, Pi signals.
//       Pblk_k = "an incoming carry sails straight through this whole
//                 block" -- likewise a function of its own Gi, Pi.
//   - Build a second-level lookahead unit -- structurally identical to
//     cla4.v, just one level up -- that computes each block's carry-in
//     directly from Gblk_0..Gblk_15, Pblk_0..Pblk_15, and cin, instead of
//     rippling block to block.
//
// To test this, wire it into dut.v as a fourth option (copy the pattern
// used for the other three) and run it through the same tb.v. Compare
// your final delay to cla64_blocked.v from Task 4.

module cla64_hier(
  input  [63:0] a,
  input  [63:0] b,
  input         cin,
  output [63:0] sum,
  output        cout
);

 wire p0, p1, p2, p3;
  wire g0, g1, g2, g3;
  wire c1, c2, c3;
 
  wire t1_0;
  wire t2_0, t2_1;
  wire t3_0, t3_1, t3_2;
  wire tG_0, tG_1, tG_2;

   // ---- generate/propagate (identical to cla4.v) ----
  xor #(2) (p0, a[0], b[0]);
  xor #(2) (p1, a[1], b[1]);
  xor #(2) (p2, a[2], b[2]);
  xor #(2) (p3, a[3], b[3]);
 
  and #(2) (g0, a[0], b[0]);
  and #(2) (g1, a[1], b[1]);
  and #(2) (g2, a[2], b[2]);
  and #(2) (g3, a[3], b[3]);

   // ---- internal carries c1..c3 (identical to cla4.v) ----
  and #(2) (t1_0, p0, cin);
  or  #(2) (c1, g0, t1_0);
 
  and #(2) (t2_0, p1, g0);
  and #(2) (t2_1, p1, p0, cin);
  or  #(2) (c2, g1, t2_0, t2_1);
 
  and #(2) (t3_0, p2, g1);
  and #(2) (t3_1, p2, p1, g0);
  and #(2) (t3_2, p2, p1, p0, cin);
  or  #(2) (c3, g2, t3_0, t3_1, t3_2);


   // ---- sum bits (identical to cla4.v) ----
  xor #(2) (sum[0], p0, cin);
  xor #(2) (sum[1], p1, c1);
  xor #(2) (sum[2], p2, c2);
  xor #(2) (sum[3], p3, c3);


  // ---- block-level Gblk/Pblk (new: this bonus's addition) ----
  and #(2) (Pblk, p3, p2, p1, p0);
 
  and #(2) (tG_0, p3, g2);
  and #(2) (tG_1, p3, p2, g1);
  and #(2) (tG_2, p3, p2, p1, g0);
  or  #(2) (Gblk, g3, tG_0, tG_1, tG_2);


  module cla64_hier(
  input  [63:0] a,
  input  [63:0] b,
  input         cin,
  output [63:0] sum,
  output        cout
);
 
  wire [15:0] Gblk, Pblk;
  wire [16:0] BC;   // BC[0] = cin; BC[1]..BC[15] = inter-block carries;
                     // BC[16] = final cout
 
  assign BC[0] = cin;
 
  // ---- level 1: sixteen 4-bit CLA blocks, run in parallel ----
  genvar k;
  generate
    for (k = 0; k < 16; k = k + 1) begin : gen_blk
      cla4_hier_block U (
        .a    (a[4*k+3 : 4*k]),
        .b    (b[4*k+3 : 4*k]),
        .cin  (BC[k]),
        .sum  (sum[4*k+3 : 4*k]),
        .Gblk (Gblk[k]),
        .Pblk (Pblk[k])
      );
    end
  endgenerate
 
  // ---- level 2: second-level lookahead over the 16 blocks ----
  // Structurally identical to cla4.v's c1..c4 equations, scaled to 16
  // "bits" (Gblk[k]/Pblk[k] standing in for g[k]/p[k]).
  // Verified: BC[1] = Gblk[0] | (Pblk[0]&cin) matches cla4.v's c1 pattern
  // exactly with Gblk/Pblk substituted for g/p.
  // Spot-checked by hand: BC[10] has 11 OR'd terms (Gblk9 down to Gblk0,
  // plus the cin term), each term one factor longer than the last --
  // matches the recursive definition BCk = Gblk[k-1] + Pblk[k-1].BC[k-1].
  assign #(2) BC[1] = Gblk[0] | (Pblk[0]&cin);
  assign #(2) BC[2] = Gblk[1] | (Pblk[1]&Gblk[0]) | (Pblk[1]&Pblk[0]&cin);
  assign #(2) BC[3] = Gblk[2] | (Pblk[2]&Gblk[1]) | (Pblk[2]&Pblk[1]&Gblk[0]) | (Pblk[2]&Pblk[1]&Pblk[0]&cin);
  assign #(2) BC[4] = Gblk[3] | (Pblk[3]&Gblk[2]) | (Pblk[3]&Pblk[2]&Gblk[1]) | (Pblk[3]&Pblk[2]&Pblk[1]&Gblk[0]) | (Pblk[3]&Pblk[2]&Pblk[1]&Pblk[0]&cin);
  assign #(2) BC[5] = Gblk[4] | (Pblk[4]&Gblk[3]) | (Pblk[4]&Pblk[3]&Gblk[2]) | (Pblk[4]&Pblk[3]&Pblk[2]&Gblk[1]) | (Pblk[4]&Pblk[3]&Pblk[2]&Pblk[1]&Gblk[0]) | (Pblk[4]&Pblk[3]&Pblk[2]&Pblk[1]&Pblk[0]&cin);
  assign #(2) BC[6] = Gblk[5] | (Pblk[5]&Gblk[4]) | (Pblk[5]&Pblk[4]&Gblk[3]) | (Pblk[5]&Pblk[4]&Pblk[3]&Gblk[2]) | (Pblk[5]&Pblk[4]&Pblk[3]&Pblk[2]&Gblk[1]) | (Pblk[5]&Pblk[4]&Pblk[3]&Pblk[2]&Pblk[1]&Gblk[0]) | (Pblk[5]&Pblk[4]&Pblk[3]&Pblk[2]&Pblk[1]&Pblk[0]&cin);
  assign #(2) BC[7] = Gblk[6] | (Pblk[6]&Gblk[5]) | (Pblk[6]&Pblk[5]&Gblk[4]) | (Pblk[6]&Pblk[5]&Pblk[4]&Gblk[3]) | (Pblk[6]&Pblk[5]&Pblk[4]&Pblk[3]&Gblk[2]) | (Pblk[6]&Pblk[5]&Pblk[4]&Pblk[3]&Pblk[2]&Gblk[1]) | (Pblk[6]&Pblk[5]&Pblk[4]&Pblk[3]&Pblk[2]&Pblk[1]&Gblk[0]) | (Pblk[6]&Pblk[5]&Pblk[4]&Pblk[3]&Pblk[2]&Pblk[1]&Pblk[0]&cin);
  assign #(2) BC[8] = Gblk[7] | (Pblk[7]&Gblk[6]) | (Pblk[7]&Pblk[6]&Gblk[5]) | (Pblk[7]&Pblk[6]&Pblk[5]&Gblk[4]) | (Pblk[7]&Pblk[6]&Pblk[5]&Pblk[4]&Gblk[3]) | (Pblk[7]&Pblk[6]&Pblk[5]&Pblk[4]&Pblk[3]&Gblk[2]) | (Pblk[7]&Pblk[6]&Pblk[5]&Pblk[4]&Pblk[3]&Pblk[2]&Gblk[1]) | (Pblk[7]&Pblk[6]&Pblk[5]&Pblk[4]&Pblk[3]&Pblk[2]&Pblk[1]&Gblk[0]) | (Pblk[7]&Pblk[6]&Pblk[5]&Pblk[4]&Pblk[3]&Pblk[2]&Pblk[1]&Pblk[0]&cin);
  assign #(2) BC[9] = Gblk[8] | (Pblk[8]&Gblk[7]) | (Pblk[8]&Pblk[7]&Gblk[6]) | (Pblk[8]&Pblk[7]&Pblk[6]&Gblk[5]) | (Pblk[8]&Pblk[7]&Pblk[6]&Pblk[5]&Gblk[4]) | (Pblk[8]&Pblk[7]&Pblk[6]&Pblk[5]&Pblk[4]&Gblk[3]) | (Pblk[8]&Pblk[7]&Pblk[6]&Pblk[5]&Pblk[4]&Pblk[3]&Gblk[2]) | (Pblk[8]&Pblk[7]&Pblk[6]&Pblk[5]&Pblk[4]&Pblk[3]&Pblk[2]&Gblk[1]) | (Pblk[8]&Pblk[7]&Pblk[6]&Pblk[5]&Pblk[4]&Pblk[3]&Pblk[2]&Pblk[1]&Gblk[0]) | (Pblk[8]&Pblk[7]&Pblk[6]&Pblk[5]&Pblk[4]&Pblk[3]&Pblk[2]&Pblk[1]&Pblk[0]&cin);
  assign #(2) BC[10] = Gblk[9] | (Pblk[9]&Gblk[8]) | (Pblk[9]&Pblk[8]&Gblk[7]) | (Pblk[9]&Pblk[8]&Pblk[7]&Gblk[6]) | (Pblk[9]&Pblk[8]&Pblk[7]&Pblk[6]&Gblk[5]) | (Pblk[9]&Pblk[8]&Pblk[7]&Pblk[6]&Pblk[5]&Gblk[4]) | (Pblk[9]&Pblk[8]&Pblk[7]&Pblk[6]&Pblk[5]&Pblk[4]&Gblk[3]) | (Pblk[9]&Pblk[8]&Pblk[7]&Pblk[6]&Pblk[5]&Pblk[4]&Pblk[3]&Gblk[2]) | (Pblk[9]&Pblk[8]&Pblk[7]&Pblk[6]&Pblk[5]&Pblk[4]&Pblk[3]&Pblk[2]&Gblk[1]) | (Pblk[9]&Pblk[8]&Pblk[7]&Pblk[6]&Pblk[5]&Pblk[4]&Pblk[3]&Pblk[2]&Pblk[1]&Gblk[0]) | (Pblk[9]&Pblk[8]&Pblk[7]&Pblk[6]&Pblk[5]&Pblk[4]&Pblk[3]&Pblk[2]&Pblk[1]&Pblk[0]&cin);
  assign #(2) BC[11] = Gblk[10] | (Pblk[10]&Gblk[9]) | (Pblk[10]&Pblk[9]&Gblk[8]) | (Pblk[10]&Pblk[9]&Pblk[8]&Gblk[7]) | (Pblk[10]&Pblk[9]&Pblk[8]&Pblk[7]&Gblk[6]) | (Pblk[10]&Pblk[9]&Pblk[8]&Pblk[7]&Pblk[6]&Gblk[5]) | (Pblk[10]&Pblk[9]&Pblk[8]&Pblk[7]&Pblk[6]&Pblk[5]&Gblk[4]) | (Pblk[10]&Pblk[9]&Pblk[8]&Pblk[7]&Pblk[6]&Pblk[5]&Pblk[4]&Gblk[3]) | (Pblk[10]&Pblk[9]&Pblk[8]&Pblk[7]&Pblk[6]&Pblk[5]&Pblk[4]&Pblk[3]&Gblk[2]) | (Pblk[10]&Pblk[9]&Pblk[8]&Pblk[7]&Pblk[6]&Pblk[5]&Pblk[4]&Pblk[3]&Pblk[2]&Gblk[1]) | (Pblk[10]&Pblk[9]&Pblk[8]&Pblk[7]&Pblk[6]&Pblk[5]&Pblk[4]&Pblk[3]&Pblk[2]&Pblk[1]&Gblk[0]) | (Pblk[10]&Pblk[9]&Pblk[8]&Pblk[7]&Pblk[6]&Pblk[5]&Pblk[4]&Pblk[3]&Pblk[2]&Pblk[1]&Pblk[0]&cin);
  assign #(2) BC[12] = Gblk[11] | (Pblk[11]&Gblk[10]) | (Pblk[11]&Pblk[10]&Gblk[9]) | (Pblk[11]&Pblk[10]&Pblk[9]&Gblk[8]) | (Pblk[11]&Pblk[10]&Pblk[9]&Pblk[8]&Gblk[7]) | (Pblk[11]&Pblk[10]&Pblk[9]&Pblk[8]&Pblk[7]&Gblk[6]) | (Pblk[11]&Pblk[10]&Pblk[9]&Pblk[8]&Pblk[7]&Pblk[6]&Gblk[5]) | (Pblk[11]&Pblk[10]&Pblk[9]&Pblk[8]&Pblk[7]&Pblk[6]&Pblk[5]&Gblk[4]) | (Pblk[11]&Pblk[10]&Pblk[9]&Pblk[8]&Pblk[7]&Pblk[6]&Pblk[5]&Pblk[4]&Gblk[3]) | (Pblk[11]&Pblk[10]&Pblk[9]&Pblk[8]&Pblk[7]&Pblk[6]&Pblk[5]&Pblk[4]&Pblk[3]&Gblk[2]) | (Pblk[11]&Pblk[10]&Pblk[9]&Pblk[8]&Pblk[7]&Pblk[6]&Pblk[5]&Pblk[4]&Pblk[3]&Pblk[2]&Gblk[1]) | (Pblk[11]&Pblk[10]&Pblk[9]&Pblk[8]&Pblk[7]&Pblk[6]&Pblk[5]&Pblk[4]&Pblk[3]&Pblk[2]&Pblk[1]&Gblk[0]) | (Pblk[11]&Pblk[10]&Pblk[9]&Pblk[8]&Pblk[7]&Pblk[6]&Pblk[5]&Pblk[4]&Pblk[3]&Pblk[2]&Pblk[1]&Pblk[0]&cin);
  assign #(2) BC[13] = Gblk[12] | (Pblk[12]&Gblk[11]) | (Pblk[12]&Pblk[11]&Gblk[10]) | (Pblk[12]&Pblk[11]&Pblk[10]&Gblk[9]) | (Pblk[12]&Pblk[11]&Pblk[10]&Pblk[9]&Gblk[8]) | (Pblk[12]&Pblk[11]&Pblk[10]&Pblk[9]&Pblk[8]&Gblk[7]) | (Pblk[12]&Pblk[11]&Pblk[10]&Pblk[9]&Pblk[8]&Pblk[7]&Gblk[6]) | (Pblk[12]&Pblk[11]&Pblk[10]&Pblk[9]&Pblk[8]&Pblk[7]&Pblk[6]&Gblk[5]) | (Pblk[12]&Pblk[11]&Pblk[10]&Pblk[9]&Pblk[8]&Pblk[7]&Pblk[6]&Pblk[5]&Gblk[4]) | (Pblk[12]&Pblk[11]&Pblk[10]&Pblk[9]&Pblk[8]&Pblk[7]&Pblk[6]&Pblk[5]&Pblk[4]&Gblk[3]) | (Pblk[12]&Pblk[11]&Pblk[10]&Pblk[9]&Pblk[8]&Pblk[7]&Pblk[6]&Pblk[5]&Pblk[4]&Pblk[3]&Gblk[2]) | (Pblk[12]&Pblk[11]&Pblk[10]&Pblk[9]&Pblk[8]&Pblk[7]&Pblk[6]&Pblk[5]&Pblk[4]&Pblk[3]&Pblk[2]&Gblk[1]) | (Pblk[12]&Pblk[11]&Pblk[10]&Pblk[9]&Pblk[8]&Pblk[7]&Pblk[6]&Pblk[5]&Pblk[4]&Pblk[3]&Pblk[2]&Pblk[1]&Gblk[0]) | (Pblk[12]&Pblk[11]&Pblk[10]&Pblk[9]&Pblk[8]&Pblk[7]&Pblk[6]&Pblk[5]&Pblk[4]&Pblk[3]&Pblk[2]&Pblk[1]&Pblk[0]&cin);
  assign #(2) BC[14] = Gblk[13] | (Pblk[13]&Gblk[12]) | (Pblk[13]&Pblk[12]&Gblk[11]) | (Pblk[13]&Pblk[12]&Pblk[11]&Gblk[10]) | (Pblk[13]&Pblk[12]&Pblk[11]&Pblk[10]&Gblk[9]) | (Pblk[13]&Pblk[12]&Pblk[11]&Pblk[10]&Pblk[9]&Gblk[8]) | (Pblk[13]&Pblk[12]&Pblk[11]&Pblk[10]&Pblk[9]&Pblk[8]&Gblk[7]) | (Pblk[13]&Pblk[12]&Pblk[11]&Pblk[10]&Pblk[9]&Pblk[8]&Pblk[7]&Gblk[6]) | (Pblk[13]&Pblk[12]&Pblk[11]&Pblk[10]&Pblk[9]&Pblk[8]&Pblk[7]&Pblk[6]&Gblk[5]) | (Pblk[13]&Pblk[12]&Pblk[11]&Pblk[10]&Pblk[9]&Pblk[8]&Pblk[7]&Pblk[6]&Pblk[5]&Gblk[4]) | (Pblk[13]&Pblk[12]&Pblk[11]&Pblk[10]&Pblk[9]&Pblk[8]&Pblk[7]&Pblk[6]&Pblk[5]&Pblk[4]&Gblk[3]) | (Pblk[13]&Pblk[12]&Pblk[11]&Pblk[10]&Pblk[9]&Pblk[8]&Pblk[7]&Pblk[6]&Pblk[5]&Pblk[4]&Pblk[3]&Gblk[2]) | (Pblk[13]&Pblk[12]&Pblk[11]&Pblk[10]&Pblk[9]&Pblk[8]&Pblk[7]&Pblk[6]&Pblk[5]&Pblk[4]&Pblk[3]&Pblk[2]&Gblk[1]) | (Pblk[13]&Pblk[12]&Pblk[11]&Pblk[10]&Pblk[9]&Pblk[8]&Pblk[7]&Pblk[6]&Pblk[5]&Pblk[4]&Pblk[3]&Pblk[2]&Pblk[1]&Gblk[0]) | (Pblk[13]&Pblk[12]&Pblk[11]&Pblk[10]&Pblk[9]&Pblk[8]&Pblk[7]&Pblk[6]&Pblk[5]&Pblk[4]&Pblk[3]&Pblk[2]&Pblk[1]&Pblk[0]&cin);
  assign #(2) BC[15] = Gblk[14] | (Pblk[14]&Gblk[13]) | (Pblk[14]&Pblk[13]&Gblk[12]) | (Pblk[14]&Pblk[13]&Pblk[12]&Gblk[11]) | (Pblk[14]&Pblk[13]&Pblk[12]&Pblk[11]&Gblk[10]) | (Pblk[14]&Pblk[13]&Pblk[12]&Pblk[11]&Pblk[10]&Gblk[9]) | (Pblk[14]&Pblk[13]&Pblk[12]&Pblk[11]&Pblk[10]&Pblk[9]&Gblk[8]) | (Pblk[14]&Pblk[13]&Pblk[12]&Pblk[11]&Pblk[10]&Pblk[9]&Pblk[8]&Gblk[7]) | (Pblk[14]&Pblk[13]&Pblk[12]&Pblk[11]&Pblk[10]&Pblk[9]&Pblk[8]&Pblk[7]&Gblk[6]) | (Pblk[14]&Pblk[13]&Pblk[12]&Pblk[11]&Pblk[10]&Pblk[9]&Pblk[8]&Pblk[7]&Pblk[6]&Gblk[5]) | (Pblk[14]&Pblk[13]&Pblk[12]&Pblk[11]&Pblk[10]&Pblk[9]&Pblk[8]&Pblk[7]&Pblk[6]&Pblk[5]&Gblk[4]) | (Pblk[14]&Pblk[13]&Pblk[12]&Pblk[11]&Pblk[10]&Pblk[9]&Pblk[8]&Pblk[7]&Pblk[6]&Pblk[5]&Pblk[4]&Gblk[3]) | (Pblk[14]&Pblk[13]&Pblk[12]&Pblk[11]&Pblk[10]&Pblk[9]&Pblk[8]&Pblk[7]&Pblk[6]&Pblk[5]&Pblk[4]&Pblk[3]&Gblk[2]) | (Pblk[14]&Pblk[13]&Pblk[12]&Pblk[11]&Pblk[10]&Pblk[9]&Pblk[8]&Pblk[7]&Pblk[6]&Pblk[5]&Pblk[4]&Pblk[3]&Pblk[2]&Gblk[1]) | (Pblk[14]&Pblk[13]&Pblk[12]&Pblk[11]&Pblk[10]&Pblk[9]&Pblk[8]&Pblk[7]&Pblk[6]&Pblk[5]&Pblk[4]&Pblk[3]&Pblk[2]&Pblk[1]&Gblk[0]) | (Pblk[14]&Pblk[13]&Pblk[12]&Pblk[11]&Pblk[10]&Pblk[9]&Pblk[8]&Pblk[7]&Pblk[6]&Pblk[5]&Pblk[4]&Pblk[3]&Pblk[2]&Pblk[1]&Pblk[0]&cin);
  assign #(2) BC[16] = Gblk[15] | (Pblk[15]&Gblk[14]) | (Pblk[15]&Pblk[14]&Gblk[13]) | (Pblk[15]&Pblk[14]&Pblk[13]&Gblk[12]) | (Pblk[15]&Pblk[14]&Pblk[13]&Pblk[12]&Gblk[11]) | (Pblk[15]&Pblk[14]&Pblk[13]&Pblk[12]&Pblk[11]&Gblk[10]) | (Pblk[15]&Pblk[14]&Pblk[13]&Pblk[12]&Pblk[11]&Pblk[10]&Gblk[9]) | (Pblk[15]&Pblk[14]&Pblk[13]&Pblk[12]&Pblk[11]&Pblk[10]&Pblk[9]&Gblk[8]) | (Pblk[15]&Pblk[14]&Pblk[13]&Pblk[12]&Pblk[11]&Pblk[10]&Pblk[9]&Pblk[8]&Gblk[7]) | (Pblk[15]&Pblk[14]&Pblk[13]&Pblk[12]&Pblk[11]&Pblk[10]&Pblk[9]&Pblk[8]&Pblk[7]&Gblk[6]) | (Pblk[15]&Pblk[14]&Pblk[13]&Pblk[12]&Pblk[11]&Pblk[10]&Pblk[9]&Pblk[8]&Pblk[7]&Pblk[6]&Gblk[5]) | (Pblk[15]&Pblk[14]&Pblk[13]&Pblk[12]&Pblk[11]&Pblk[10]&Pblk[9]&Pblk[8]&Pblk[7]&Pblk[6]&Pblk[5]&Gblk[4]) | (Pblk[15]&Pblk[14]&Pblk[13]&Pblk[12]&Pblk[11]&Pblk[10]&Pblk[9]&Pblk[8]&Pblk[7]&Pblk[6]&Pblk[5]&Pblk[4]&Gblk[3]) | (Pblk[15]&Pblk[14]&Pblk[13]&Pblk[12]&Pblk[11]&Pblk[10]&Pblk[9]&Pblk[8]&Pblk[7]&Pblk[6]&Pblk[5]&Pblk[4]&Pblk[3]&Gblk[2]) | (Pblk[15]&Pblk[14]&Pblk[13]&Pblk[12]&Pblk[11]&Pblk[10]&Pblk[9]&Pblk[8]&Pblk[7]&Pblk[6]&Pblk[5]&Pblk[4]&Pblk[3]&Pblk[2]&Gblk[1]) | (Pblk[15]&Pblk[14]&Pblk[13]&Pblk[12]&Pblk[11]&Pblk[10]&Pblk[9]&Pblk[8]&Pblk[7]&Pblk[6]&Pblk[5]&Pblk[4]&Pblk[3]&Pblk[2]&Pblk[1]&Gblk[0]) | (Pblk[15]&Pblk[14]&Pblk[13]&Pblk[12]&Pblk[11]&Pblk[10]&Pblk[9]&Pblk[8]&Pblk[7]&Pblk[6]&Pblk[5]&Pblk[4]&Pblk[3]&Pblk[2]&Pblk[1]&Pblk[0]&cin);
 
  assign cout = BC[16];
  // TODO: your hierarchical design goes here.

endmodule
