# Audible Ecosystemics n.2 — Faust porting

Faust porting of *Audible Ecosystemics n.2* (Feedback Study, 2003) by Agostino Di Scipio, originally realised in Kyma.
Porting by Dario Sanfilippo and Luca Spanedda, carried out on the composer's instructions.

## Status

Reference version, including the corrections made with the composer on 23 May 2025.
It was used for the rehearsal at Auditorium Shigeru Ban, L'Aquila (24 May 2025) and for the performance at EMS 2025, Université Gustave Eiffel, Paris (21 November 2025).

## Files

- `Audible_Ecosystemics_2.dsp` — the system
- `aelibrary.lib` — the functions used by the system

## Usage

Compile with [Faust](https://faust.grame.fr), for example as a standalone application:

```
faust2caqt Audible_Ecosystemics_2.dsp
```

The system has 4 inputs (microphones) and 6 outputs.
The sample rate is set to 44100 Hz in `aelibrary.lib` (`SampleRate`).

## Score

The score is not included in this repository. Performers interested in the piece should request it directly from the composer, Agostino Di Scipio.

## Reference

D. Sanfilippo, L. Spanedda, "The realisation of Di Scipio's *Audible Ecosystemics n.2*: strengths and challenges in the interpretation and notation of machine-independent computer music", *Electroacoustic Music as Interdisciplinary Practices* (EMS 2025), Paris, 2025. https://zenodo.org/records/18898899

## License

The code of this porting is released under the MIT License (see `LICENSE.md`).
*Audible Ecosystemics n.2* is a work by Agostino Di Scipio; all rights to the composition remain with the composer.
