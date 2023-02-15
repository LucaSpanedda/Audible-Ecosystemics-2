// import faust standard library
import("stdfaust.lib");

SpectralCentroid = tgroup("Spectral Centroid Test",
    par(i, 8, _ <: 
        vgroup("Mic %i[2]",
            ((HP3(nentry("Frequency", 1, 1, 20000, 1)) : 
                an.rms_envelope_rect(.5)) <: 
                    attach(_, abs : ba.linear2db : hbargraph("HP",-80,20))),
            ((LP3(nentry("Frequency", 1, 1, 20000, 1)) : 
                an.rms_envelope_rect(.5)) <: 
                    attach(_, abs : ba.linear2db : hbargraph("LP",-80,20)))
            )
        )
    );

process = SpectralCentroid;

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

SVFTPT2(K, Q, CF, x) = circuitout : ! , ! , _ , _ , _ , _ , _ , _ , _ , _
with{
    g = tan(CF * ma.PI / ma.SR);
    R = 1.0 / (2.0 * Q);
    G1 = 1.0 / (1.0 + 2.0 * R * g + g * g);
    G2 = 2.0 * R + g;
    circuit(s1, s2) = u1 , u2 , lp , hp , bp, notch, apf, ubp, peak, bshelf
        with{
            hp = (x - s1 * G2 - s2) * G1;
            v1 = hp * g;
            bp = s1 + v1;
            v2 = bp * g;
            lp = s2 + v2;
            u1 = v1 + bp;
            u2 = v2 + lp;
            notch = x - ((2*R)*bp);
            apf = x - ((4*R)*bp);
            ubp = ((2*R)*bp);
            peak = lp -hp;
            bshelf = x + (((2*K)*R)*bp);
        };
    // choose the output from the SVF Filter (ex. bshelf)
    circuitout = circuit ~ si.bus(2);
};

LPTPT(CF, x) = onePoleTPT(max(ma.EPSILON, min(20480, CF)), x) : (_ , ! , !);
HPTPT(CF, x) = onePoleTPT(max(ma.EPSILON, min(20480, CF)), x) : (! , _ , !);

LPSVF(Q, CF, x) = SVFTPT2(0, Q, max(ma.EPSILON, min(20480, CF)), x) : _ , ! , ! , ! , ! , ! , ! , ! ;
HPSVF(Q, CF, x) = SVFTPT2(0, Q, max(ma.EPSILON, min(20480, CF)), x) : ! , _ , ! , ! , ! , ! , ! , !;

BPsvftpt(bw, cf, x) = Q , CF , x : SVFTPT : (! , ! , ! , _ , !)
    with {
        CF = max(20, min(20480, LPTPT(1, cf)));
        BW = max(1, min(20480, LPTPT(1, bw)));
        Q = max(.01, min(100, BW / CF));
    };

// Butterworth
butterworthQ(order, stage) = qFactor(order % 2)
with {
    qFactor(0) = 1.0 / (2.0 * cos(((2.0 * stage + 1) *
    (ma.PI / (order * 2.0)))));
    qFactor(1) = 1.0 / (2.0 * cos(((stage + 1) * (ma.PI / order))));
};

LPButterworthN(1, cf, x) = LPTPT(cf, x);
LPButterworthN(N, cf, x) = cascade(N % 2)
with {
    cascade(0) = x : seq(i, N / 2, LPSVF(butterworthQ(N, i), cf));
    cascade(1) = x : LPTPT(cf) : seq(i, (N - 1) / 2,
    LPSVF(butterworthQ(N, i), cf));
};

HPButterworthN(1, cf, x) = HPTPT(cf, x);
HPButterworthN(N, cf, x) = cascade(N % 2)
with {
    cascade(0) = x : seq(i, N / 2, HPSVF(butterworthQ(N, i), cf));
    cascade(1) = x : HPTPT(cf) : seq(i, (N - 1) /
    2, HPSVF(butterworthQ(N, i), cf));
};

// Filters Order Butterworth
LP1(CF, x) = x : LPButterworthN(1, CF);
HP1(CF, x) = x : HPButterworthN(1, CF);
LP2(CF, x) = x : LPButterworthN(2, CF); 
HP2(CF, x) = x : HPButterworthN(2, CF); 
LP3(CF, x) = x : LPButterworthN(3, CF); 
HP3(CF, x) = x : HPButterworthN(3, CF); 
LP4(CF, x) = x : LPButterworthN(4, CF);
HP4(CF, x) = x : HPButterworthN(4, CF); 
LP5(CF, x) = x : LPButterworthN(5, CF); 
HP5(CF, x) = x : HPButterworthN(5, CF); 

// Filters Order in series
// LP1(CF, x) = x : LPTPT(CF);
// HP1(CF, x) = x : HPTPT(CF);
// LP2(CF, x) = x : LPTPT(CF) : LPTPT(CF);
// HP2(CF, x) = x : HPTPT(CF) : HPTPT(CF);
// LP3(CF, x) = x : LPTPT(CF) : LPTPT(CF) : LPTPT(CF);
// HP3(CF, x) = x : HPTPT(CF) : HPTPT(CF) : HPTPT(CF);
// LP4(CF, x) = x : LPTPT(CF) : LPTPT(CF) : LPTPT(CF) : LPTPT(CF);
// HP4(CF, x) = x : HPTPT(CF) : HPTPT(CF) : HPTPT(CF) : HPTPT(CF);
// LP5(CF, x) = x : LPTPT(CF) : LPTPT(CF) : LPTPT(CF) : LPTPT(CF) : LPTPT(CF);
// HP5(CF, x) = x : HPTPT(CF) : HPTPT(CF) : HPTPT(CF) : HPTPT(CF) : HPTPT(CF);