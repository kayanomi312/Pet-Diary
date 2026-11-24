# Sunroom walk stride measurements

Each clip's `strideLengthUV` is an estimate of room travel in one complete
cycle. Measurements use the shipped 768 × 768 HEIC cels. Inspect the lowest
visible same-paw silhouette across two portions of the cycle. Read its
approximate horizontal contact center in source pixels at the listed frame
indices. Divide each absolute displacement by the elapsed drawing ticks
(including any manifest holds). Use the median of the two rates times the total
cycle ticks to estimate the full-cycle travel.

At reference floor depth 0.5, the 118-point cel renders at 0.945×. Multiply the
source-pixel distance by `118 * 0.945 / 768` for rendered points, then divide
by `600 * 0.9` for room U. The nominal stage is a 400-point viewport plus the
200-point base room extension. Its projection has horizontal spread 0.9 at
mid-depth. Device pixel density cancels out of the UV calculation.

These are coarse measurements of the existing drawings. Some stances slip in
the direction of travel, and a few drawings have ambiguous contact or transfer
the baseline between legs. The magnitudes give a starting travel speed. Check
foot lock on the floor grid after each bank is redrawn and recalibrate for the
current projection, especially at other depths and with the veranda extension.

| Bank | Paw observations (frame:x) | Cycle ticks | Cel px/cycle | Rendered pt/cycle | Room UV/cycle |
| --- | --- | ---: | ---: | ---: | ---: |
| pet_01/w | 1:348 → 9:237 / 10:627 → 16:582 | 16 | 171.0 | 24.8 | 0.04598 |
| pet_01/wr | 7:627 → 9:555 / 10:459 → 12:489 | 12 | 306.0 | 44.4 | 0.08228 |
| pet_02/w | 3:285 → 5:263 / 1:724 → 5:674 | 12 | 141.0 | 20.5 | 0.03791 |
| pet_02/wr | 3:486 → 5:432 / 9:663 → 11:651 | 12 | 198.0 | 28.7 | 0.05324 |
| pet_03/w | 2:264 → 4:414 / 7:300 → 10:276 | 12 | 498.0 | 72.3 | 0.13390 |
| pet_03/wr | 2:701 → 5:646 / 6:708 → 11:605 | 12 | 233.6 | 33.9 | 0.06281 |
| pet_04/w | 3:278 → 5:274 / 1:687 → 5:592 | 12 | 154.5 | 22.4 | 0.04154 |
| pet_04/wr | 2:708 → 5:602 / 7:704 → 11:609 | 12 | 354.5 | 51.5 | 0.09532 |
| pet_05/w | 1:108 → 4:297 / 7:123 → 10:312 | 12 | 756.0 | 109.8 | 0.20327 |
| pet_05/wr | 3:453 → 5:441 / 9:657 → 10:582 | 12 | 486.0 | 70.6 | 0.13068 |
| pet_06/w | 3:312 → 5:283 / 6:405 → 8:447 | 12 | 213.0 | 30.9 | 0.05727 |
| pet_06/wr | 3:486 → 5:474 / 8:726 → 9:684 | 12 | 288.0 | 41.8 | 0.07744 |
| pet_07/w | 2:351 → 8:273 / 12:552 → 16:507 | 16 | 194.0 | 28.2 | 0.05216 |
| pet_07/wr | 7:594 → 9:555 / 10:441 → 12:450 | 12 | 144.0 | 20.9 | 0.03872 |
| pet_08/w | 2:285 → 9:201 / 9:585 → 16:528 | 16 | 161.1 | 23.4 | 0.04333 |
| pet_08/wr | 2:689 → 5:537 / 6:468 → 11:483 | 12 | 322.0 | 46.8 | 0.08658 |
