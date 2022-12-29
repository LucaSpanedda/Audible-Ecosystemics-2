declare name "Agostino Di Scipio - AUDIBLE ECOSYSTEMICS n.2";
declare author "Luca Spanedda";
declare author "Dario Sanfilippo";
declare version "alpha";
declare description " 2022 version - Realised on composer's instructions
    of the year 2017 edited in L’Aquila, Italy";
// import faust standard library
import("stdfaust.lib");


//------- ------------- ----- -----------
//-- AE2 -----------------------------------------------------------------------
//------- --------

// PERFORMANCE SYSTEM VARIABLES
SampleRate = 44100;
var1 = 10;
var2 = 2000;
var3 = 0.5;
var4 = 10;

// GUI
GM1 = si.smoo( ba.db2linear( hslider("MIC 1 [unit:db]", -80, -80, 0, .001) ) );
GM2 = si.smoo( ba.db2linear( hslider("MIC 2 [unit:db]", -80, -80, 0, .001) ) );
GM3 = si.smoo( ba.db2linear( hslider("MIC 3 [unit:db]", -80, -80, 0, .001) ) );
GM4 = si.smoo( ba.db2linear( hslider("MIC 4 [unit:db]", -80, -80, 0, .001) ) );
// MAIN SYSTEM FUNCTION
process = (_,_) : \(m1,m2).(m1 * GM1, m2 * GM2, m1 * GM3, m2 * GM4) :
 ( signalflow1a : signalflow1b : signalflow2a : signalflow2b : signalflow3) ~ si.bus(2) :
 (  ( par(i, 2, hgroup("GrainOut", inspect(i,-1,1))) : si.block(2) ),
        par(i, 6, hgroup("Signal Flow 3", inspect(i,-1,1))),
    ( par(i, 4, hgroup("Mics", inspect(i,-1,1))) : si.block(4) ),
        par(i, 8, hgroup("Signal Flow 1a", inspect(i,-1,1))),
        par(i, 8, hgroup("Signal Flow 1b", inspect(i,-1,1))),
        par(i, 8, hgroup("Signal Flow 2a", inspect(i,-1,1)))    );


// SYSTEM SIGNALS FLOW FUNCTIONS
signalflow1a( grainOut1, grainOut2, mic1, mic2, mic3, mic4 ) = 
    grainOut1, grainOut2, 
    mic1, mic2, mic3, mic4,
    diffHL, memWriteDel1, memWriteDel2, memWriteLev,
    cntrlLev1, cntrlLev2, cntrlFeed, cntrlMain

with{
    map6sumx6 = (mic3 : integrator(.01) : 
        ( \(fb,x).( (fb * .95 + x) @ba.sec2samp(.01) ) ~ _ ) ) +
        (mic4 : integrator(.01) : 
        ( \(fb,x).( (fb * .95 + x) @ba.sec2samp(.01) ) ~ _ ) ) : 
        \(x).(6 + x * 6);

    localMaxDiff = ((map6sumx6, mic3) : localmax) ,
        ((map6sumx6, mic4) : localmax) :
        \(x,y).(x-y);

    SenstoExt = (map6sumx6, localMaxDiff) : localmax <: _ , 
        @(ba.sec2samp(12)) : + : * (.5) : LPButterworthN(1, .5) ;

    diffHL = ((mic3 + mic4) : HPButterworthN(3, var2) : integrator(.05)) ,
        ((mic3 + mic4) : LPButterworthN(3, var2) : integrator(.10)) :
        \(x,y).(x-y) * (1 - SenstoExt) :
        ( \(fb,x).( (fb * .95 + x) @ba.sec2samp(.01) ) ~ _ ) : 
        LPButterworthN(5, 25.0) : 
        \(x).(.5 + x * .5) : 
        // LIMIT - max - min
        limit(20000, 0);

    memWriteLev = (mic3 + mic4) : integrator(.1) : 
        ( \(fb,x).( (fb * .90 + x) @ba.sec2samp(.01) ) ~ _ ) :
        LPButterworthN(5, 25) :
        \(x).(1 - (x * x)) : 
        // LIMIT - max - min
        limit(1, 0);

    memWriteDel1 = memWriteLev : @(ba.sec2samp(var1 / 2)) : 
        // LIMIT - max - min
        limit(1, 0);

    memWriteDel2 = memWriteLev : @(ba.sec2samp(var1 / 3)) : 
        // LIMIT - max - min
        limit(1, 0);

    cntrlMain = (mic3 + mic4) * SenstoExt : integrator(.01) :
        ( \(fb,x).( (fb * .995 + x) @ba.sec2samp(.01) ) ~ _ ) : 
        LPButterworthN(5, 25) : 
        // LIMIT - max - min
        limit(1, 0);

    cntrlLev1 = cntrlMain : @(ba.sec2samp(var1 / 3)) : 
        // LIMIT - max - min
        limit(1, 0);

    cntrlLev2 = cntrlMain : @(ba.sec2samp(var1 / 2)) : 
        // LIMIT - max - min
        limit(1, 0);

    cntrlFeed = cntrlMain : 
        \(x).(ba.if(x <= .5, 1.0, (1.0 - x) * 2.0)) : 
        // LIMIT - max - min
        limit(1, 0);
};

signalflow1b( grainOut1, grainOut2, mic1, mic2, mic3, mic4,
    diffHL, memWriteDel1, memWriteDel2, memWriteLev,
    cntrlLev1, cntrlLev2, cntrlFeed, cntrlMain ) =

    mic1, mic2, mic3, mic4,
    diffHL, memWriteDel1, memWriteDel2, memWriteLev,
    cntrlLev1, cntrlLev2, cntrlFeed, cntrlMain,
    cntrlMic1, cntrlMic2, directLevel, timeIndex1,
    timeIndex2, triangle1, triangle2, triangle3

with{
    cntrlMic(x) = x : HPButterworthN(1, 50) : LPButterworthN(1, 6000) : 
        integrator(.01) : 
        ( \(fb,x).( (fb * .995 + x) @ba.sec2samp(.01) ) ~ _ ) : 
        LPButterworthN(5, .5);

    cntrlMic1 = mic1 : cntrlMic : 
        // LIMIT - max - min
        limit(1, 0);

    cntrlMic2 = mic2 : cntrlMic : 
        // LIMIT - max - min
        limit(1, 0);

    directLevel =
        (grainOut1+grainOut2) : integrator(.01) : 
        ( \(fb,x).( (fb * .97 + x) @ba.sec2samp(.01) ) ~ _ ) : 
        LPButterworthN(5, .5)
        <: _,   (  _ : ( \(fb,x).( ( (fb * (1 - var3) * 0.5) + x) 
                    @ba.sec2samp(var1 * 2) ) ~ _ ) 
                ) : +
        : \(x).(1 - x * .5) : 
        // LIMIT - max - min
        limit(1, 0);

    timeIndex1 = triangleWave( 1 / (var1 * 2) ) : \(x).( (x - 2) * 0.5 ) : 
        // LIMIT - max - min
        limit(1, -1);

    timeIndex2 = triangleWave( 1 / (var1 * 2) ) : \(x).( (x + 1) * 0.5 ) : 
        // LIMIT - max - min
        limit(1, -1);

    triangle1 = triangleWave( 1 / (var1 * 6) ) * memWriteLev : 
        // LIMIT - max - min
        limit(1, 0);

    triangle2 = triangleWave( var1 * (1 - cntrlMain) ) : 
        // LIMIT - max - min
        limit(1, 0);

    triangle3 = triangleWave( 1 / var1 ) : 
        // LIMIT - max - min
        limit(1, 0);
};

signalflow2a( mic1, mic2, mic3, mic4,
    diffHL, memWriteDel1, memWriteDel2, memWriteLev,
    cntrlLev1, cntrlLev2, cntrlFeed, cntrlMain,
    cntrlMic1, cntrlMic2, directLevel, timeIndex1,
    timeIndex2, triangle1, triangle2, triangle3 ) =

    mic1, mic2, mic3, mic4,
    diffHL, memWriteDel1, memWriteDel2, memWriteLev,
    cntrlLev1, cntrlLev2, cntrlFeed, cntrlMain,
    cntrlMic1, cntrlMic2, directLevel, timeIndex1,
    timeIndex2, triangle1, triangle2, triangle3,
    sampWOut, sig1, sig2, sig3, sig4, sig5, sig6, sig7

with{
    micIN1 = mic1 : HPButterworthN(1, 50) : 
        LPButterworthN(1, 6000) * (1 - cntrlMic1);

    micIN2 = mic2 : HPButterworthN(1, 50) : 
        LPButterworthN(1, 6000) * (1 - cntrlMic2);

    SRSect1(x) = x : sampler( var1,
        (1 - memWriteDel2),
        (var2 + (diffHL * 1000))/261
        ) : HPButterworthN(4, 50) : 
        @(ba.sec2samp(var1/2));

    SRSect2(x) = x : sampler( var1,
        (memWriteLev + memWriteDel1)/2,
        ( 290 - (diffHL * 90))/261
        ) : HPButterworthN(4, 50) : 
        @(ba.sec2samp(var1));

    SRSect3(x) = x : sampler( var1, (1 - memWriteDel1),
        ((var2 * 2) - (diffHL * 1000))/261
        ) : HPButterworthN(4, 50);

    SRSectBP1(x) = x : SRSect3 : BPsvftpt( diffHL
        * 400 : limit(1,20000),
        (var2 / 2) * memWriteDel2
        : limit(1,20000) );

    SRSectBP2(x) = x : SRSect3 : BPsvftpt( (1 - diffHL)
        * 800 : limit(1,20000),
        var2 * (1 - memWriteDel1)
        : limit(1,20000) );

    SRSect4(x) = x : sampler(var1, 1, (250 + (diffHL * 20))/261);

    SRSect5(x) = x : sampler(var1, memWriteLev, .766283);

    fbG = 1; // normalization for SampleWriteLoop Feedback
    SampleWriteLoop = loop ~ _ * fbG
    with {
        loop(fb) =
            (
            ( SRSect1(fb),
            SRSect2(fb),
            SRSectBP1(fb),
            SRSectBP2(fb) :> + ) * (cntrlFeed * memWriteLev)
            ) <:
            ( _ + (micIN1+micIN2) : _ * triangle1 ),
            _,
            SRSect4(fb),
            SRSect5(fb),
            SRSect3(fb);
        };

    sig1 = micIN1 * directLevel : 
        // LIMIT - max - min
        limit(1, -1);

    sig2 = micIN2 * directLevel : 
        // LIMIT - max - min
        limit(1, -1);

    sampWOut = SampleWriteLoop : \(A,B,C,D,E).(A);

    sig3 = SampleWriteLoop : \(A,B,C,D,E).(B) :
        _ * memWriteLev : \(x).( x : de.sdelay( ba.sec2samp(.05), 1024, 
        ba.sec2samp( .05 * limit( 1, 0, cntrlMain ) ) ) )
        * triangle2 * directLevel : 
        // LIMIT - max - min
        limit(1, -1);

    sig4 = SampleWriteLoop : \(A,B,C,D,E).(B) :
        _ * memWriteLev
        * (1-triangle2) * directLevel : 
        // LIMIT - max - min
        limit(1, -1);

    sig5 = SampleWriteLoop : \(A,B,C,D,E).(C) :
        HPButterworthN(4, 50) :
        @(ba.sec2samp(var1 / 3)) : 
        // LIMIT - max - min
        limit(1, -1);

    sig6 = SampleWriteLoop : \(A,B,C,D,E).(D) :
        HPButterworthN(4, 50) :
        @(ba.sec2samp(var1 / 2.5)) : 
        // LIMIT - max - min
        limit(1, -1);

    sig7 = SampleWriteLoop : \(A,B,C,D,E).(E) :
        @(ba.sec2samp(var1 / 1.5))
        * directLevel : 
        // LIMIT - max - min
        limit(1, -1);
};

signalflow2b( mic1, mic2, mic3, mic4,
    diffHL, memWriteDel1, memWriteDel2, memWriteLev,
    cntrlLev1, cntrlLev2, cntrlFeed, cntrlMain,
    cntrlMic1, cntrlMic2, directLevel, timeIndex1,
    timeIndex2, triangle1, triangle2, triangle3,
    sampWOut, sig1, sig2, sig3, sig4, sig5, sig6, sig7 ) =

    mic1, mic2, mic3, mic4,
    diffHL, memWriteDel1, memWriteDel2, memWriteLev,
    cntrlLev1, cntrlLev2, cntrlFeed, cntrlMain,
    cntrlMic1, cntrlMic2, directLevel, timeIndex1,
    timeIndex2, triangle1, triangle2, triangle3,
    sampWOut, sig1, sig2, sig3, sig4, sig5, sig6, sig7,
    grainOut1, grainOut2, out1, out2

with{
    grainOut1 = granular_sampling(var1, timeIndex1, memWriteDel1, cntrlLev1, 21, sampWOut);

    grainOut2 = granular_sampling(var1, timeIndex2, memWriteDel2, cntrlLev2, 20, sampWOut);

    out1 =  ( 
        ( sig5 : @(ba.sec2samp(.04)) * (1 - triangle3) ),
        ( sig5 * triangle3 ),
        ( sig6 : @(ba.sec2samp(.036)) * (1 - triangle3) ),
        ( sig6 : @(ba.sec2samp(.036)) * triangle3 ),
        sig1,
        0,
        sig4,
        grainOut1 * (1 - memWriteLev) + grainOut2 * memWriteLev ) :> + : 
        // LIMIT - max - min
        limit(1, -1);

    out2 =  ( 
        ( sig5 * (1 - triangle3) ),
        ( sig5 : @(ba.sec2samp(.040)) * triangle3 ),
        ( sig6 * (1 - triangle3) ),
        ( sig6 * triangle3 ),
        sig2,
        sig3,
        sig7,
        grainOut1 * memWriteLev + grainOut2 * (1 - memWriteLev) ) :> + : 
    // LIMIT - max - min
    limit(1, -1);
};

signalflow3( mic1, mic2, mic3, mic4,
    diffHL, memWriteDel1, memWriteDel2, memWriteLev,
    cntrlLev1, cntrlLev2, cntrlFeed, cntrlMain,
    cntrlMic1, cntrlMic2, directLevel, timeIndex1,
    timeIndex2, triangle1, triangle2, triangle3,
    sampWOut, sig1, sig2, sig3, sig4, sig5, sig6, sig7,
    grainOut1, grainOut2, out1, out2 ) =

    grainOut1, grainOut2,
    out1, out2, 
    out2@(ba.sec2samp((var4 / 2 / 344))), 
    out1@(ba.sec2samp((var4 / 2 / 344))), 
    out1@(ba.sec2samp((var4 / 344))), 
    out2@(ba.sec2samp((var4 / 344))), 
    mic1, mic2, mic3, mic4,
    diffHL, memWriteDel1, memWriteDel2, memWriteLev, 
    cntrlLev1, cntrlLev2, cntrlFeed, cntrlMain,
    cntrlMic1, cntrlMic2, directLevel, timeIndex1, 
    timeIndex2, triangle1, triangle2, triangle3,
    sampWOut, sig1, sig2, sig3, sig4, sig5, sig6, sig7;


//------- ------------- ----- -----------
//-- LIBRARY -------------------------------------------------------------------
//------- --------

//----------------------------------------------------------------- UTILITIES --
// limit function for library and system
limit(maxl,minl,x) = x : max(minl, min(maxl));
// see signal values 
inspect(i, lower, upper) = _ * 1000 <: _ , 
    vbargraph("sig_%2i [style:numerical]", lower * 1000, upper * 1000) : attach;
    //process = (os.osc(.01) : inspect(1, .1, -1, 1));
diffDebug(x) = an.abs_envelope_tau(1, (x-x')) * (SampleRate/2);

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
