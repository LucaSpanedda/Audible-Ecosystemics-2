// import faust standard library
import("stdfaust.lib");

Noise(initSeed) = LCG ~ _ : (_ / m)
with{
    // variables
    // initSeed = an initial seed value
    a = 18446744073709551557; // a large prime number, such as 18446744073709551557
    c = 12345; // a small prime number, such as 12345
    m = 2 ^ 31; // 2.1 billion
    // linear_congruential_generator
    LCG(seed) = ((a * seed + c) + (initSeed-initSeed') % m);
};

dBMeters = hgroup("8 channels dB meter", par(i, 16, vgroup("%i", vmeter(i) : null)))
with{
    null(x) = attach(0,x);
    envelop = abs : max(ba.db2linear(-70)) : ba.linear2db : min(10)  : max ~ -(80.0/ma.SR);
    vmeter(i, x) = attach(x, envelop(x) : vbargraph("chan %i[unit:dB]", -70, 10));
    hmeter(i, x) = attach(x, envelop(x) : hbargraph("chan %i[unit:dB]", -70, 10));
};
process = par(i, 16, Noise( (i+1) * 469762049)), dBMeters;