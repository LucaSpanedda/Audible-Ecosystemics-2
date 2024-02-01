declare name "Agostino Di Scipio - AUDIBLE ECOSYSTEMICS n.2";
declare author "Luca Spanedda";
declare version "alpha";
declare description " 2024 version - Realised on composer's instructions, Italy";
// import faust standard library
import("stdfaust.lib");
// import audible ecosystemics objects library
import("aelibrary.lib");

CNTRL(x) = (x : HPTPT(50) : LPTPT(6000) : integrator(.01) : delayfb(.01, 0.995) : LPTPT(25) ^ 2 : limit(1, 0));
cntrlmic0(i, x) = (x <: (HPTPT(50) : LPTPT(6000)) * (1 - CNTRL : hgroup("cntrlMic", inspect(i, -100, 100))));
process = cntrlmic0(1);