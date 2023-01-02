declare name "Agostino Di Scipio - AUDIBLE ECOSYSTEMICS n.2";
declare author "Luca Spanedda";
declare author "Dario Sanfilippo";
declare version "alpha";
declare description " 2022 version - Realised on composer's instructions
    of the year 2017 edited in L’Aquila, Italy";


// import faust standard library
import("stdfaust.lib");
// PERFORMANCE SYSTEM VARIABLES
SampleRate = 44100;
var1 = 20;
var2 = 2000;
var3 = 0.5;
var4 = 20;


//------- ------------- ----- -----------
//-- TEST IR -------------------------------------------------------------------
//------- --------


// ------------------------------------------------------------------------
// TEST risposte :
// per tutti gli esempi: 44.1 kHz,16 bit, mono
// segnale di test
// pulse1.wav = 1 secondo di campioni = 0, poi 1 campione = 1, poi 1 secondo di campioni = 0
// ------------------------------------------------------------------------
// ------------------------------------------------------------------------
    // pulse hp1.dsp - pulse hp1.wav = hipass ordine1, cf  50 hz
// process = (1-1')@ma.SR : HPButterworthN(1, 50); 

    // pulse lp1.dsp - pulse lp1.wav = lopass ordine1, cf  6000 hz
// process = (1-1')@ma.SR : LPButterworthN(1, 6000); 

    // pulse hp2.dsp - pulse hp2.wav = hipass ordine2, cf 50 hz
// process = (1-1')@ma.SR : HPButterworthN(2, 50); 

    // pulse hp2-lp1-envF.dsp - pulse hp2-lp1-envF.wav = ...., envFoll 0.01
// process = (1-1')@ma.SR : HPButterworthN(2, 50) : 
//     LPButterworthN(1, 6000) : integrator(.01);

    // pulse hp2-lp1-envF-delFB.dsp - pulse hp2-lp1-envF-delFB.wav = ..., delFB time 0.01 fb 0.995
// process = (1-1')@ma.SR : HPButterworthN(2, 50) : 
//     LPButterworthN(1, 6000) : integrator(.01)  :
//     delayfb(.01,.995);

    // pulse lp4(0.5).dsp - pulse lp4(0.5).wav = lopass ordine4, fc 0.5 hz (mezzo hz)
// process = (1-1')@ma.SR : LPButterworthN(4, .5);

    // pulse lp4(0.04).dsp - pulse lp4(0.04).wav = ..., lopass ordine 4, cf 0.04 hz (4 centesimi di hz)
// process = (1-1')@ma.SR : LPButterworthN(4, .04);

    // pulse hp2-lp1-envF-delFB-lp4(0.5).dsp - pulse hp2-lp1-envF-delFB-lp4(0.5).wav = ..., lopass ordine 4, cf 0.5 (mezzo hz)
// process = (1-1')@ma.SR : HPButterworthN(2, 50) : 
//     LPButterworthN(1, 6000) : integrator(.01)  :
//     delayfb(.01,.995) : LPButterworthN(4, .5);

    // pulse hp2-lp1-envF-delFB-lp4(0.04).dsp - pulse hp2-lp1-envF-delFB-lp4(0.04).wav = ..., lopass ordine 4, cf 0.04 (4 centesimi di hz)
// process = (1-1')@ma.SR : HPButterworthN(2, 50) : 
//     LPButterworthN(1, 6000) : integrator(.01)  :
//     delayfb(.01,.995) : LPButterworthN(4, .04);

// ------------------------------------------------------------------------
// ------------------------------------------------------------------------
// SINE CntrlMic TEST risposte :
// sine1000.wav = 1 secondo di sinusoide a 1 kHz, -34 dB
// risposte
// sine1000-CntrlMic1(partitura).dsp - sine1000-CntrlMic1(partitura).wav = tutta la catena di cntrlMic come in partitura
// sine1000-CntrlMic1(alternativa).dsp - sine1000-CntrlMic1(alternativa).wav = tutta la catena di cntrlMic con parametri alternativi
// ovvero: hp ordine 2, delay feedback 0.995, lp ord 4 fc 0.04 hz, e con pow^2 alla fine
// ------------------------------------------------------------------------
// ------------------------------------------------------------------------
sig1ktest = os.osc(1000) * ba.db2linear(-34) * (1 - 1@ma.SR);
// process = sig1ktest;
cntrlMicOtiginal(x) =   x : HPButterworthN(1, 50) : LPButterworthN(1, 6000) : 
                        integrator(.01) : delayfb(.01,.999) : 
                        LPButterworthN(5, .5);
// process = sig1ktest : cntrlMicOtiginal;
cntrlMicModified(x) =   x : HPButterworthN(2, 50) : LPButterworthN(1, 6000) : 
                        integrator(.01) : delayfb(.01,.995) : 
                        LPButterworthN(4, .04) : \(y).(y*y);
// process = sig1ktest : cntrlMicModified;


//------- ------------- ----- -----------
//-- LIBRARY -------------------------------------------------------------------
//------- --------


//----------------------------------------------------------------- UTILITIES --
// limit function for library and system
limit(maxl,minl,x) = x : max(minl, min(maxl));
// see signal values 
inspect(i, lower, upper) = _ <: _ , 
    vbargraph("sig_%2i [style:numerical]", lower, upper) : attach;
    //process = (os.osc(.01) : inspect(1, .1, -1, 1));
diffDebug(x) = an.abs_envelope_tau(1, (x-x')) * (SampleRate/2);

//-------------------------------------------------------------------- DELAYS --
delayfb(delSec,fb,x) = loop ~ _ : mem
with{ 
    loop(z) = ( (z * fb + x) @(ba.sec2samp(delSec)-1) );
};

//---------------------------------------------------------------- SAMPLEREAD --
sampler(bufferLength, memChunk, ratio, x) = y
with {
    y = it.frwtable(3, L, .0, writePtr, x, readPtr * memChunkLock * L) * 
        trapezoidal(.95, readPtr)
    with {
        memChunkLimited = max(.100, min(1.0, memChunk));
        L = bufferLength * SampleRate; // hard-coded: change this to match your samplerate
        writePtr = ba.period(L);
        readPtr = phasor : _ , !;
        memChunkLock = phasor : ! , _;
        phasor = loop ~ si.bus(3) : _ , ! , _
        with {
            loop(phState, incrState, chunkLenState) = ph , incr , chunkLen
            with {
                ph = ba.if(phState < 1.0, phState + incrState, 0.0);
                unlock = phState < phState' + 1 - 1';
                incr = ba.if( unlock, 
                ma.T * max(.1, min(10.0, ratio)) / 
                max(ma.T, (memChunkLimited * bufferLength)), incrState);
                chunkLen = ba.if(unlock, memChunkLimited, chunkLenState);
            };
        };
        trapezoidal(width, ph) = min(1.0, abs(ma.decimal(ph + .5) * 2.0 - 1.0) / 
            max(ma.EPSILON, 1.0 - width));
    };
};
// process = sampleRead( 1, hslider("chnk",0,0,1,.001), 
// hslider("rati",1,0,2,.001), os.osc(200)) <: _,_;

//--------------------------------------------------------------- INTEGRATOR ---
integrator(seconds, x) = an.abs_envelope_tau(limit(1000,.001,seconds), x);

//----------------------------------------------------------------- LOCALMAX ---
localMax(seconds, x) = loop ~ si.bus(4) : _ , ! , ! , !
with {
    loop(yState, timerState, peakState, timeInSamplesState) = y , timer , peak , timeInSamples
    with {
        timeInSamples = ba.if(reset + 1 - 1', seconds * ma.SR, timeInSamplesState);
        reset = timerState >= (timeInSamplesState - 1);
        timer = ba.if(reset, 1, timerState + 1);
        peak = max(abs(x), peakState * (1.0 - reset));
        y = ba.if(reset, peak', yState);
    };
};
//process = os.osc(.1245) : localMax(hslider("windowlocalM",-1,-1,8,.001));
localmax(resetPeriod, x) = localMax(limit(1000,0,resetPeriod), x);

//----------------------------------------------------------------- TRIANGLE ---
triangularFunc(x) = abs(ma.frac((x - .5)) * 2.0 - 1.0);
triangleWave(f) = triangularFunc(os.phasor(1,f));

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
// TEST
// process = (-100, no.noise) : HPTPT;

SVFTPT(K, Q, CF, x) = circuitout : ! , ! , _ , _ , _ , _ , _ , _ , _ , _
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
// Outs = (lp , hp , bp, notch, apf, ubp, peak, bshelf)
// SVFTPT(K, Q, CF, x) = (Filter-K, Filter-Q, Frequency Cut)

// Filters Bank
LPSVF(Q, CF, x) = SVFTPT(0, Q, 
    limit(20000,ma.EPSILON,CF), x) : _ , ! , ! , ! , ! , ! , ! , ! ;
HPSVF(Q, CF, x) = SVFTPT(0, Q, 
    limit(20000,ma.EPSILON,CF), x) : ! , _ , ! , ! , ! , ! , ! , !;
//process = (-1, -10000, no.noise) <: LPSVF, HPSVF;
BPsvftpt(BW, CF, x) = SVFTPT(0 : ba.db2linear, ql, cfl, 
    x ) : ! , ! , ! , ! , !, _ , ! , !
with{
    cfl = limit(20000,ma.EPSILON,CF);
    bwl = limit(20000,ma.EPSILON,BW);
    ql = cfl / bwl;
};
// TEST
//process = (1, 1000, no.noise) : BPsvftpt;

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
//process = HPButterworthN(10, -1000, no.noise), 
 // LPButterworthN(10, -1000, no.noise);

//-------------------------------------------------------- GRANULAR SAMPLING ---
grain(L, position, duration, x, trigger) = hann(phase) * buffer(readPtr, x)
with {
    maxLength = 1920000;
    length = L * ma.SR;
    hann(ph) = sin(ma.PI * ph) ^ 2.0;
    lineSegment = loop ~ si.bus(2) : _ , ! , _
    with {
        loop(yState, incrementState) = y , increment , ready
        with {
            ready = ((yState == 0.0) | (yState == 1.0)) & trigger;
            y = ba.if(ready, increment, min(1.0, yState + increment));
            increment = ba.if(ready, ma.T / max(ma.T, duration), incrementState);
        };
    };
    phase = lineSegment : _ , !;
    unlocking = lineSegment : ! , _;
    lock(param) = ba.sAndH(unlocking, param); 
    grainPosition = lock(position);
    grainDuration = lock(duration);
    readPtr = grainPosition * length + phase * grainDuration * ma.SR;
    buffer(readPtr, x) = it.frwtable(3, maxLength, .0, writePtr, x, readPtrWrapped)
    with {
        writePtr = ba.period(length);
        readPtrWrapped = ma.modulo(readPtr, length);
    };
};

// works for N >= 2
triggerArray(N, rate) = loop ~ si.bus(3) : (! , ! , _) <: 
    par(i, N, == (i)) : par(i, N, \(x).(x > x'))
with {
    loop(incrState, phState, counterState) = incr , ph , counter
    with {
        init = 1 - 1';
        trigger = (phState < phState') + init;
        incr = ba.if(trigger, rate * ma.T, incrState);
        ph = ma.frac(incr + phState);
        counter = (trigger + counterState) % N;
    };
};

grainN(voices, L, position, rate, duration, x) = triggerArray(voices, rate) : 
    par(i, voices, grain(L, position, duration, x));

granular_sampling(var1, timeIndex, memWriteDel, cntrlLev, divDur, x) = 
    grainN(8, var1, position, rate, duration, x) :> /(8)
with {
    rnd = no.noise;
    memPointerJitter = rnd * (1.0 - memWriteDel) * .01;
    position = timeIndex * (1.0 - ((1.0 - memWriteDel) * .01)) + memPointerJitter;
    density = 1.0 - cntrlLev;
    rate = 50 ^ (density * 2.0 - 1.0);
    grainDuration = .023 + (1.0 - memWriteDel) / divDur;
    duration = grainDuration + grainDuration * .1 * rnd;
};