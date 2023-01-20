// import faust standard library
import("stdfaust.lib");

SpectralCentroid =   si.bus(8) :> + <: 
                vgroup("Central Spectroid",
                    ((HP3(hslider("Frequency", 1, 1, 1000, 1)) : 
                        an.rms_envelope_rect(.5)) <: 
                            attach(_, abs : ba.linear2db : hbargraph("HP",-80,20))),
                    ((LP3(hslider("Frequency", 1, 1, 1000, 1)) : 
                        an.rms_envelope_rect(.5)) <: 
                            attach(_, abs : ba.linear2db : hbargraph("LP",-80,20)))
                );
//process = SpectralCentroid;

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
process = par(i, 10, Noise( (i+1) * 469762049 ) );


//------------------------------------------------------------------ FILTERS ---
onePoleTPT(cf, x) = loop ~ _ : ! , si.bus(3)
with {
    g = tan(cf * ma.PI * (1/ma.SR));
    G = g / (1.0 + g);
    loop(s) = u , lp , hp , ap
    with {
        v = (x - s) * G;
        u = v + lp;
        lp = v + s;
        hp = x - lp;
        ap = lp - hp;
    };
};

LPTPT(cf, x) = onePoleTPT(limit(20000,ma.EPSILON,cf), x) : (_ , ! , !);
HPTPT(cf, x) = onePoleTPT(limit(20000,ma.EPSILON,cf), x) : (! , _ , !);

SVFTPT(Q, cf, x) = loop ~ si.bus(2) : (! , ! , _ , _ , _ , _ , _)
    with {
        g = tan(cf * ma.PI * (1.0/ma.SR));
        R = 1.0 / (2.0 * Q);
        G1 = 1.0 / (1.0 + 2.0 * R * g + g * g);
        G2 = 2.0 * R + g;
        loop(s1, s2) = u1 , u2 , lp , hp , bp , bp * 2.0 * R , x - bp * 4.0 * R
            with {
                hp = (x - s1 * G2 - s2) * G1;
                v1 = hp * g;
                bp = s1 + v1;
                v2 = bp * g;
                lp = s2 + v2;
                u1 = v1 + bp;
                u2 = v2 + lp;
            };
    };

BPsvftpt(bw, cf, x) = Q , CF , x : SVFTPT : (! , ! , ! , _ , !)
    with {
        CF = max(20, min(20480, LPTPT(1, cf)));
        BW = max(1, min(20480, LPTPT(1, bw)));
        Q = max(.01, min(100, BW / CF));
    };

// Order Aproximations filters - Outs
LP1(CF, x) = x : LPTPT(CF);
HP1(CF, x) = x : HPTPT(CF);
LP2(CF, x) = x : LPTPT(CF) : LPTPT(CF);
HP2(CF, x) = x : HPTPT(CF) : HPTPT(CF);
LP3(CF, x) = x : LPTPT(CF) : LPTPT(CF) : LPTPT(CF);
HP3(CF, x) = x : HPTPT(CF) : HPTPT(CF) : HPTPT(CF);
LP4(CF, x) = x : LPTPT(CF) : LPTPT(CF) : LPTPT(CF) : LPTPT(CF);
HP4(CF, x) = x : HPTPT(CF) : HPTPT(CF) : HPTPT(CF) : HPTPT(CF);
LP5(CF, x) = x : LPTPT(CF) : LPTPT(CF) : LPTPT(CF) : LPTPT(CF) : LPTPT(CF);
HP5(CF, x) = x : HPTPT(CF) : HPTPT(CF) : HPTPT(CF) : HPTPT(CF) : HPTPT(CF);