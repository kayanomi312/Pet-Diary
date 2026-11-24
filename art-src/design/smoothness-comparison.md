# Animation smoothness before and after

The comparison uses the crown-registered integration base `23c5bb2`. The
[baseline](smoothness-registered-baseline.txt) and [final audit](smoothness-final.txt)
include every adjacent step. The table lists every bank with changed frames or
manifest metadata. Each metric is shown as before → after. New banks have a
dash for the baseline.

Steps and seams are mean absolute differences in alpha on a 0–255 scale
after area reduction to 192². Centroid range is horizontal in 768² pixels.
The reported last-to-first distance only affects the pass result for cyclic
loops. It is descriptive for ping-pong and one-shot clips.

## pet_01

| Bank | Cels and cadence | Median step | Max step | Seam | Centroid range | Baseline | Result | Previews |
| --- | --- | ---: | ---: | ---: | ---: | ---: | --- | --- |
| h | 10f @ 7.00 loop → 10f @ 10.00 loop | 0.54 → 1.81 | 0.67 → 2.36 | 0.53 → 1.69 | 2.27 px → 3.81 px | 690–690 → 688–688 | PASS | [Sheet](../previews/pet_01/h_clean.png) · [GIF](../previews/pet_01/h_clean.gif) |
| i | 16f @ 8.00 loop | 0.10 → 1.20 | 0.14 → 1.22 | 0.13 → 1.22 | 0.57 px → 5.79 px | 690–690 → 688–688 | PASS | [Sheet](../previews/pet_01/i_clean.png) · [GIF](../previews/pet_01/i_clean.gif) |
| ld | — → 8f @ 12.00 once | — → 9.47 | — → 17.26 | — → 40.16 | — → 22.60 px | — → 688–689 | PASS | [Sheet](../previews/pet_01/ld_clean.png) · [GIF](../previews/pet_01/ld_clean.gif) |
| m | 8f @ 7.50 loop → 8f @ 10.00 loop | 0.72 → 2.09 | 0.94 → 2.86 | 0.74 → 2.00 | 2.53 px → 4.12 px | 690–690 → 688–688 | PASS | [Sheet](../previews/pet_01/m_clean.png) · [GIF](../previews/pet_01/m_clean.gif) |
| p | 8f @ 8.50 loop → 8f @ 10.00 loop | 2.04 | 2.07 | 1.61 | 5.45 px | 690–690 | PASS | [Sheet](../previews/pet_01/p_clean.png) · [GIF](../previews/pet_01/p_clean.gif) |
| r | — → 6f @ 12.00 once | — → 44.26 | — → 53.15 | — → 1.22 | — → 120.66 px | — → 645–688 | PASS | [Sheet](../previews/pet_01/r_clean.png) · [GIF](../previews/pet_01/r_clean.gif) |
| s | 8f @ 3.20 pingpong → 8f @ 4.00 pingpong | 0.13 → 0.63 | 0.16 → 0.66 | 0.73 → 4.35 | 0.46 px → 5.13 px | 690–690 → 688–688 | PASS | [Sheet](../previews/pet_01/s_clean.png) · [GIF](../previews/pet_01/s_clean.gif) |
| tn | — → 8f @ 12.00 once | — → 12.47 | — → 20.13 | — → 44.79 | — → 6.03 px | — → 688–689 | PASS | [Sheet](../previews/pet_01/tn_clean.png) · [GIF](../previews/pet_01/tn_clean.gif) |
| w | 16f @ 9.00 loop → 16f @ 10.00 loop | 7.02 → 7.05 | 10.33 → 8.17 | 11.04 → 7.90 | 23.11 px → 0.06 px | 690–690 → 688–689 | PASS | [Sheet](../previews/pet_01/w_clean.png) · [GIF](../previews/pet_01/w_clean.gif) |
| wk | — → 8f @ 12.00 once | — → 9.47 | — → 17.26 | — → 40.16 | — → 22.60 px | — → 688–689 | PASS | [Sheet](../previews/pet_01/wk_clean.png) · [GIF](../previews/pet_01/wk_clean.gif) |
| wr | — → 12f @ 12.00 loop | — → 21.16 | — → 26.53 | — → 20.49 | — → 0.01 px | — → 688–688 | PASS | [Sheet](../previews/pet_01/wr_clean.png) · [GIF](../previews/pet_01/wr_clean.gif) |

## pet_02

| Bank | Cels and cadence | Median step | Max step | Seam | Centroid range | Baseline | Result | Previews |
| --- | --- | ---: | ---: | ---: | ---: | ---: | --- | --- |
| h | 10f @ 7.00 loop → 10f @ 10.00 loop | 0.69 → 2.45 | 0.80 → 3.39 | 0.69 → 2.30 | 2.06 px → 3.42 px | 690–690 → 688–688 | PASS | [Sheet](../previews/pet_02/h_clean.png) · [GIF](../previews/pet_02/h_clean.gif) |
| i | 16f @ 8.00 loop | 0.20 → 2.07 | 0.42 → 2.20 | 0.30 → 1.99 | 0.38 px → 6.58 px | 690–690 → 688–688 | PASS | [Sheet](../previews/pet_02/i_clean.png) · [GIF](../previews/pet_02/i_clean.gif) |
| ld | — → 8f @ 12.00 once | — → 16.99 | — → 27.02 | — → 42.60 | — → 33.33 px | — → 688–689 | PASS | [Sheet](../previews/pet_02/ld_clean.png) · [GIF](../previews/pet_02/ld_clean.gif) |
| m | 8f @ 7.50 loop → 8f @ 10.00 loop | 0.96 → 3.17 | 1.16 → 4.17 | 1.00 → 2.65 | 2.43 px → 3.35 px | 690–690 → 688–688 | PASS | [Sheet](../previews/pet_02/m_clean.png) · [GIF](../previews/pet_02/m_clean.gif) |
| p | 8f @ 8.50 loop → 8f @ 10.00 loop | 1.68 | 1.78 | 1.47 | 3.84 px | 690–690 | PASS | [Sheet](../previews/pet_02/p_clean.png) · [GIF](../previews/pet_02/p_clean.gif) |
| r | — → 6f @ 12.00 once | — → 49.30 | — → 75.83 | — → 2.03 | — → 151.04 px | — → 645–689 | PASS | [Sheet](../previews/pet_02/r_clean.png) · [GIF](../previews/pet_02/r_clean.gif) |
| s | 8f @ 3.20 pingpong → 8f @ 4.00 pingpong | 0.18 → 1.09 | 0.22 → 1.11 | 0.99 → 6.34 | 0.47 px → 7.95 px | 690–690 → 688–688 | PASS | [Sheet](../previews/pet_02/s_clean.png) · [GIF](../previews/pet_02/s_clean.gif) |
| tn | — → 8f @ 12.00 once | — → 16.47 | — → 22.32 | — → 44.09 | — → 20.97 px | — → 688–688 | PASS | [Sheet](../previews/pet_02/tn_clean.png) · [GIF](../previews/pet_02/tn_clean.gif) |
| w | 12f @ 12.00 loop | 16.13 | 27.27 | 12.30 | 38.28 px | 690–690 | side-walk centroid range > 10 px | [Sheet](../previews/pet_02/w_clean.png) · [GIF](../previews/pet_02/w_clean.gif) |
| wk | — → 8f @ 12.00 once | — → 16.99 | — → 27.02 | — → 42.60 | — → 33.33 px | — → 688–689 | PASS | [Sheet](../previews/pet_02/wk_clean.png) · [GIF](../previews/pet_02/wk_clean.gif) |
| wr | — → 12f @ 12.00 loop | — → 20.71 | — → 32.65 | — → 24.50 | — → 0.01 px | — → 688–688 | PASS | [Sheet](../previews/pet_02/wr_clean.png) · [GIF](../previews/pet_02/wr_clean.gif) |

## pet_03

| Bank | Cels and cadence | Median step | Max step | Seam | Centroid range | Baseline | Result | Previews |
| --- | --- | ---: | ---: | ---: | ---: | ---: | --- | --- |
| h | 10f @ 7.00 loop → 10f @ 10.00 loop | 0.53 → 2.18 | 0.67 → 2.89 | 0.65 → 2.09 | 2.01 px → 3.78 px | 690–690 → 688–688 | PASS | [Sheet](../previews/pet_03/h_clean.png) · [GIF](../previews/pet_03/h_clean.gif) |
| i | 16f @ 8.00 loop | 0.21 → 2.18 | 0.32 → 2.23 | 0.26 → 2.14 | 1.08 px → 5.88 px | 690–690 → 688–688 | PASS | [Sheet](../previews/pet_03/i_clean.png) · [GIF](../previews/pet_03/i_clean.gif) |
| ld | — → 8f @ 12.00 once | — → 16.77 | — → 35.66 | — → 34.26 | — → 22.84 px | — → 688–689 | PASS | [Sheet](../previews/pet_03/ld_clean.png) · [GIF](../previews/pet_03/ld_clean.gif) |
| m | 8f @ 7.50 loop → 8f @ 10.00 loop | 0.70 → 2.62 | 1.20 → 3.87 | 0.96 → 2.51 | 1.86 px → 3.61 px | 689–691 → 687–689 | PASS | [Sheet](../previews/pet_03/m_clean.png) · [GIF](../previews/pet_03/m_clean.gif) |
| p | 8f @ 8.50 loop → 8f @ 10.00 loop | 1.67 | 1.81 | 1.57 | 3.83 px | 690–690 | PASS | [Sheet](../previews/pet_03/p_clean.png) · [GIF](../previews/pet_03/p_clean.gif) |
| r | — → 6f @ 12.00 once | — → 43.50 | — → 59.28 | — → 2.16 | — → 71.24 px | — → 646–688 | PASS | [Sheet](../previews/pet_03/r_clean.png) · [GIF](../previews/pet_03/r_clean.gif) |
| s | 8f @ 3.20 pingpong → 8f @ 4.00 pingpong | 0.15 → 0.83 | 0.18 → 0.89 | 0.70 → 5.41 | 0.76 px → 6.55 px | 690–690 → 688–688 | PASS | [Sheet](../previews/pet_03/s_clean.png) · [GIF](../previews/pet_03/s_clean.gif) |
| tn | 5f @ 12.00 once → 8f @ 12.00 once | 22.22 → 21.07 | 57.25 → 43.88 | 74.28 | 86.92 px → 86.93 px | 690–690 → 688–689 | PASS | [Sheet](../previews/pet_03/tn_clean.png) · [GIF](../previews/pet_03/tn_clean.gif) |
| w | 6f @ 9.00 loop → 12f @ 12.00 loop | 10.33 → 17.26 | 18.54 → 27.77 | 18.70 → 25.51 | 10.36 px → 7.18 px | 690–690 → 688–688 | PASS | [Sheet](../previews/pet_03/w_clean.png) · [GIF](../previews/pet_03/w_clean.gif) |
| wk | — → 8f @ 12.00 once | — → 16.77 | — → 35.66 | — → 34.26 | — → 22.84 px | — → 688–689 | PASS | [Sheet](../previews/pet_03/wk_clean.png) · [GIF](../previews/pet_03/wk_clean.gif) |
| wr | 12f @ 12.00 loop | 8.99 | 14.21 | 7.71 | 11.01 px | 690–690 | side-walk centroid range > 10 px | [Sheet](../previews/pet_03/wr_clean.png) · [GIF](../previews/pet_03/wr_clean.gif) |

## pet_04

| Bank | Cels and cadence | Median step | Max step | Seam | Centroid range | Baseline | Result | Previews |
| --- | --- | ---: | ---: | ---: | ---: | ---: | --- | --- |
| h | 10f @ 7.00 loop → 10f @ 10.00 loop | 0.52 → 1.85 | 0.58 → 2.40 | 0.53 → 1.81 | 1.65 px → 5.18 px | 690–690 → 688–688 | PASS | [Sheet](../previews/pet_04/h_clean.png) · [GIF](../previews/pet_04/h_clean.gif) |
| i | 16f @ 8.00 loop | 0.17 → 1.69 | 0.28 → 1.71 | 0.21 → 1.69 | 1.08 px → 3.78 px | 690–690 → 688–688 | PASS | [Sheet](../previews/pet_04/i_clean.png) · [GIF](../previews/pet_04/i_clean.gif) |
| ld | — → 8f @ 12.00 once | — → 14.86 | — → 22.96 | — → 46.85 | — → 60.08 px | — → 688–688 | PASS | [Sheet](../previews/pet_04/ld_clean.png) · [GIF](../previews/pet_04/ld_clean.gif) |
| m | 8f @ 7.50 loop → 8f @ 10.00 loop | 0.67 → 2.18 | 0.86 → 2.93 | 0.81 → 2.15 | 1.99 px → 5.98 px | 690–690 → 688–688 | PASS | [Sheet](../previews/pet_04/m_clean.png) · [GIF](../previews/pet_04/m_clean.gif) |
| p | 8f @ 8.50 loop → 8f @ 10.00 loop | 1.92 | 2.16 | 1.62 | 4.62 px | 690–690 | PASS | [Sheet](../previews/pet_04/p_clean.png) · [GIF](../previews/pet_04/p_clean.gif) |
| r | — → 6f @ 12.00 once | — → 51.23 | — → 68.61 | — → 1.68 | — → 96.49 px | — → 646–688 | PASS | [Sheet](../previews/pet_04/r_clean.png) · [GIF](../previews/pet_04/r_clean.gif) |
| s | 8f @ 3.20 pingpong → 8f @ 4.00 pingpong | 0.17 → 0.73 | 0.20 → 0.79 | 0.85 → 4.64 | 0.95 px → 6.50 px | 690–690 → 688–688 | PASS | [Sheet](../previews/pet_04/s_clean.png) · [GIF](../previews/pet_04/s_clean.gif) |
| tn | 5f @ 12.00 once → 8f @ 12.00 once | 44.97 → 30.21 | 60.63 → 57.87 | 73.57 | 101.98 px | 690–690 → 688–688 | PASS | [Sheet](../previews/pet_04/tn_clean.png) · [GIF](../previews/pet_04/tn_clean.gif) |
| w | 12f @ 12.00 loop | 11.69 | 22.87 | 15.02 | 8.35 px | 689–690 | max step > 1.8× median | [Sheet](../previews/pet_04/w_clean.png) · [GIF](../previews/pet_04/w_clean.gif) |
| wk | — → 8f @ 12.00 once | — → 14.86 | — → 22.96 | — → 46.85 | — → 60.08 px | — → 688–688 | PASS | [Sheet](../previews/pet_04/wk_clean.png) · [GIF](../previews/pet_04/wk_clean.gif) |
| wr | 12f @ 12.00 loop | 10.13 | 22.21 | 9.48 | 17.65 px | 690–690 | max step > 1.8× median, side-walk centroid range > 10 px | [Sheet](../previews/pet_04/wr_clean.png) · [GIF](../previews/pet_04/wr_clean.gif) |

## pet_05

| Bank | Cels and cadence | Median step | Max step | Seam | Centroid range | Baseline | Result | Previews |
| --- | --- | ---: | ---: | ---: | ---: | ---: | --- | --- |
| h | 10f @ 7.00 loop → 10f @ 10.00 loop | 4.19 | 5.13 | 3.70 | 15.32 px | 690–690 | PASS | [Sheet](../previews/pet_05/h_clean.png) · [GIF](../previews/pet_05/h_clean.gif) |
| ld | — → 8f @ 12.00 once | — → 17.68 | — → 21.86 | — → 44.32 | — → 33.33 px | — → 688–689 | PASS | [Sheet](../previews/pet_05/ld_clean.png) · [GIF](../previews/pet_05/ld_clean.gif) |
| m | 8f @ 7.50 loop → 8f @ 10.00 loop | 3.65 | 4.61 | 3.23 | 5.47 px | 690–690 | PASS | [Sheet](../previews/pet_05/m_clean.png) · [GIF](../previews/pet_05/m_clean.gif) |
| p | 8f @ 8.50 loop → 8f @ 10.00 loop | 4.47 | 5.18 | 4.29 | 9.67 px | 690–690 | PASS | [Sheet](../previews/pet_05/p_clean.png) · [GIF](../previews/pet_05/p_clean.gif) |
| r | — → 6f @ 12.00 once | — → 34.65 | — → 42.02 | — → 2.38 | — → 79.75 px | — → 645–688 | PASS | [Sheet](../previews/pet_05/r_clean.png) · [GIF](../previews/pet_05/r_clean.gif) |
| s | 8f @ 3.20 pingpong → 8f @ 4.00 pingpong | 0.27 | 0.71 | 1.85 | 1.60 px | 690–690 | max step > 1.8× median | [Sheet](../previews/pet_05/s_clean.png) · [GIF](../previews/pet_05/s_clean.gif) |
| tn | — → 8f @ 12.00 once | — → 17.22 | — → 19.50 | — → 43.93 | — → 9.80 px | — → 688–689 | PASS | [Sheet](../previews/pet_05/tn_clean.png) · [GIF](../previews/pet_05/tn_clean.gif) |
| w | 6f @ 9.00 loop → 12f @ 12.00 loop | 18.23 → 21.05 | 22.66 → 28.27 | 18.22 → 26.92 | 11.82 px → 0.06 px | 690–690 → 687–688 | PASS | [Sheet](../previews/pet_05/w_clean.png) · [GIF](../previews/pet_05/w_clean.gif) |
| wk | — → 8f @ 12.00 once | — → 17.68 | — → 21.86 | — → 44.32 | — → 33.33 px | — → 688–689 | PASS | [Sheet](../previews/pet_05/wk_clean.png) · [GIF](../previews/pet_05/wk_clean.gif) |
| wr | — → 12f @ 12.00 loop | — → 18.13 | — → 25.96 | — → 22.80 | — → 0.01 px | — → 688–688 | PASS | [Sheet](../previews/pet_05/wr_clean.png) · [GIF](../previews/pet_05/wr_clean.gif) |

## pet_06

| Bank | Cels and cadence | Median step | Max step | Seam | Centroid range | Baseline | Result | Previews |
| --- | --- | ---: | ---: | ---: | ---: | ---: | --- | --- |
| h | 10f @ 7.00 loop → 10f @ 10.00 loop | 4.27 | 5.78 | 3.98 | 15.33 px | 690–690 | PASS | [Sheet](../previews/pet_06/h_clean.png) · [GIF](../previews/pet_06/h_clean.gif) |
| ld | — → 8f @ 12.00 once | — → 13.16 | — → 21.79 | — → 44.40 | — → 5.31 px | — → 688–688 | PASS | [Sheet](../previews/pet_06/ld_clean.png) · [GIF](../previews/pet_06/ld_clean.gif) |
| m | 8f @ 7.50 loop → 8f @ 10.00 loop | 4.37 | 4.78 | 2.96 | 8.20 px | 690–690 | PASS | [Sheet](../previews/pet_06/m_clean.png) · [GIF](../previews/pet_06/m_clean.gif) |
| p | 8f @ 8.50 loop → 8f @ 10.00 loop | 7.85 | 9.24 | 7.12 | 12.80 px | 690–690 | PASS | [Sheet](../previews/pet_06/p_clean.png) · [GIF](../previews/pet_06/p_clean.gif) |
| r | — → 6f @ 12.00 once | — → 38.85 | — → 49.35 | — → 2.29 | — → 87.06 px | — → 645–689 | PASS | [Sheet](../previews/pet_06/r_clean.png) · [GIF](../previews/pet_06/r_clean.gif) |
| s | 12f @ 3.20 pingpong → 12f @ 4.00 pingpong | 1.21 | 1.54 | 1.01 | 1.41 px | 690–690 | PASS | [Sheet](../previews/pet_06/s_clean.png) · [GIF](../previews/pet_06/s_clean.gif) |
| tn | — → 8f @ 12.00 once | — → 13.25 | — → 22.04 | — → 39.93 | — → 0.01 px | — → 688–689 | PASS | [Sheet](../previews/pet_06/tn_clean.png) · [GIF](../previews/pet_06/tn_clean.gif) |
| w | 12f @ 12.00 loop | 12.21 | 28.28 | 8.53 | 12.64 px | 690–690 | max step > 1.8× median, side-walk centroid range > 10 px | [Sheet](../previews/pet_06/w_clean.png) · [GIF](../previews/pet_06/w_clean.gif) |
| wk | — → 8f @ 12.00 once | — → 13.16 | — → 21.79 | — → 44.40 | — → 5.31 px | — → 688–688 | PASS | [Sheet](../previews/pet_06/wk_clean.png) · [GIF](../previews/pet_06/wk_clean.gif) |
| wr | — → 12f @ 12.00 loop | — → 22.09 | — → 38.80 | — → 23.91 | — → 0.01 px | — → 687–688 | PASS | [Sheet](../previews/pet_06/wr_clean.png) · [GIF](../previews/pet_06/wr_clean.gif) |

## pet_07

| Bank | Cels and cadence | Median step | Max step | Seam | Centroid range | Baseline | Result | Previews |
| --- | --- | ---: | ---: | ---: | ---: | ---: | --- | --- |
| h | 10f @ 7.00 loop → 10f @ 10.00 loop | 3.16 | 4.70 | 3.07 | 10.09 px | 690–690 | PASS | [Sheet](../previews/pet_07/h_clean.png) · [GIF](../previews/pet_07/h_clean.gif) |
| ld | — → 8f @ 12.00 once | — → 10.30 | — → 21.00 | — → 37.27 | — → 1.89 px | — → 688–688 | PASS | [Sheet](../previews/pet_07/ld_clean.png) · [GIF](../previews/pet_07/ld_clean.gif) |
| m | 8f @ 7.50 loop → 8f @ 10.00 loop | 4.39 | 5.53 | 4.39 | 8.81 px | 690–690 | PASS | [Sheet](../previews/pet_07/m_clean.png) · [GIF](../previews/pet_07/m_clean.gif) |
| p | 8f @ 8.50 loop → 8f @ 10.00 loop | 5.46 | 6.62 | 6.50 | 11.08 px | 690–690 | PASS | [Sheet](../previews/pet_07/p_clean.png) · [GIF](../previews/pet_07/p_clean.gif) |
| r | — → 6f @ 12.00 once | — → 31.79 | — → 42.95 | — → 1.56 | — → 91.69 px | — → 645–689 | PASS | [Sheet](../previews/pet_07/r_clean.png) · [GIF](../previews/pet_07/r_clean.gif) |
| s | 8f @ 3.20 pingpong → 8f @ 4.00 pingpong | 0.64 | 0.74 | 3.10 | 1.69 px | 690–690 | PASS | [Sheet](../previews/pet_07/s_clean.png) · [GIF](../previews/pet_07/s_clean.gif) |
| tn | — → 8f @ 12.00 once | — → 7.72 | — → 10.10 | — → 31.66 | — → 0.00 px | — → 688–689 | PASS | [Sheet](../previews/pet_07/tn_clean.png) · [GIF](../previews/pet_07/tn_clean.gif) |
| w | 16f @ 9.00 loop → 16f @ 10.00 loop | 5.28 → 5.07 | 9.70 → 5.71 | 10.32 → 5.41 | 20.02 px → 0.07 px | 690–691 → 688–689 | PASS | [Sheet](../previews/pet_07/w_clean.png) · [GIF](../previews/pet_07/w_clean.gif) |
| wk | — → 8f @ 12.00 once | — → 10.30 | — → 21.00 | — → 37.27 | — → 1.89 px | — → 688–688 | PASS | [Sheet](../previews/pet_07/wk_clean.png) · [GIF](../previews/pet_07/wk_clean.gif) |
| wr | — → 12f @ 12.00 loop | — → 11.54 | — → 19.61 | — → 13.54 | — → 0.00 px | — → 688–688 | PASS | [Sheet](../previews/pet_07/wr_clean.png) · [GIF](../previews/pet_07/wr_clean.gif) |

## pet_08

| Bank | Cels and cadence | Median step | Max step | Seam | Centroid range | Baseline | Result | Previews |
| --- | --- | ---: | ---: | ---: | ---: | ---: | --- | --- |
| h | 10f @ 7.00 loop → 10f @ 10.00 loop | 4.72 | 5.57 | 5.33 | 10.80 px | 690–690 | PASS | [Sheet](../previews/pet_08/h_clean.png) · [GIF](../previews/pet_08/h_clean.gif) |
| ld | — → 8f @ 12.00 once | — → 21.10 | — → 44.05 | — → 46.57 | — → 20.23 px | — → 688–689 | PASS | [Sheet](../previews/pet_08/ld_clean.png) · [GIF](../previews/pet_08/ld_clean.gif) |
| m | 8f @ 7.50 loop → 8f @ 10.00 loop | 3.55 | 4.49 | 3.18 | 3.19 px | 690–690 | PASS | [Sheet](../previews/pet_08/m_clean.png) · [GIF](../previews/pet_08/m_clean.gif) |
| p | 8f @ 8.50 loop → 8f @ 10.00 loop | 6.27 | 8.24 | 7.45 | 6.42 px | 690–690 | PASS | [Sheet](../previews/pet_08/p_clean.png) · [GIF](../previews/pet_08/p_clean.gif) |
| r | — → 6f @ 12.00 once | — → 38.11 | — → 48.46 | — → 2.54 | — → 114.33 px | — → 646–688 | PASS | [Sheet](../previews/pet_08/r_clean.png) · [GIF](../previews/pet_08/r_clean.gif) |
| s | 8f @ 3.20 pingpong → 8f @ 4.00 pingpong | 0.74 | 1.61 | 2.81 | 3.34 px | 690–690 | max step > 1.8× median | [Sheet](../previews/pet_08/s_clean.png) · [GIF](../previews/pet_08/s_clean.gif) |
| tn | 5f @ 12.00 once → 8f @ 12.00 once | 49.98 → 32.52 | 65.35 → 52.24 | 61.04 | 85.16 px | 689–690 → 687–688 | PASS | [Sheet](../previews/pet_08/tn_clean.png) · [GIF](../previews/pet_08/tn_clean.gif) |
| w | 16f @ 9.00 loop → 16f @ 10.00 loop | 6.73 → 5.99 | 7.35 → 6.95 | 6.28 → 6.20 | 12.47 px → 0.08 px | 690–690 → 688–688 | PASS | [Sheet](../previews/pet_08/w_clean.png) · [GIF](../previews/pet_08/w_clean.gif) |
| wk | — → 8f @ 12.00 once | — → 21.10 | — → 44.05 | — → 46.57 | — → 20.23 px | — → 688–689 | PASS | [Sheet](../previews/pet_08/wk_clean.png) · [GIF](../previews/pet_08/wk_clean.gif) |
| wr | 12f @ 12.00 loop | 13.21 | 33.24 | 11.92 | 7.15 px | 690–690 | max step > 1.8× median | [Sheet](../previews/pet_08/wr_clean.png) · [GIF](../previews/pet_08/wr_clean.gif) |
