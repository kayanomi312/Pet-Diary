# Pawprint Days cel sources

Put transparent sRGB 768 × 768 PNGs in `petframes/pet_XX/<bank>/01.png` through
`NN.png`. Use Git LFS for these PNGs. Run `git lfs install` for your checkout
and `git lfs pull` to fetch any missing source images.

Import [guide_768.png](templates/guide_768.png) as a separate guide layer.
Red marks the y=690 ground line, and blue marks the y=170 head line.
Center the body at x=384 in stationary poses. Hide the guide layer before
export. Check the alpha edges on white and black.

From a macOS checkout with Xcode command-line tools:

```sh
tools/frames/build pet_03 w
tools/frames/lint pet_03 w
tools/frames/preview pet_03 w
```

Omit the bank to work on all source banks for the pet, or omit both arguments
to work on all source pets. Build converts to quality-0.8 HEIC with alpha,
updates the per-pet manifest, and removes obsolete higher-numbered HEICs for
the selected banks. Review the generated changes before committing them.
Use `tools/frames/build --guide` to regenerate the template.

The [schema](../PawprintDays/Resources/PetFrames/manifests/schema.json) and
[example](../PawprintDays/Resources/PetFrames/manifests/pet_03.example.json)
show the manifest format. Each source bank has one clip. If the number of
drawings changes, update `frames` and any affected holds and event indices
before rebuilding. Frame indices start at 1. A hold of 3 means the drawing
occupies three frame intervals in total. Record holds in JSON and export each
drawing once. `strideLengthUV` is distance in room UV per full cycle and can
be provided per locomotion clip or as a pet-wide default.
