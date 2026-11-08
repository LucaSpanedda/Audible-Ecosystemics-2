declare name "Agostino Di Scipio - AUDIBLE ECOSYSTEMICS n.2";
declare author "Luca Spanedda";
declare author "Dario Sanfilippo";
declare version "1.0";
declare description " 2025 version - Realised on composer's
instructions of the year 2017 edited in L’Aquila, Italy";
// import audible ecosystemics objects library
import("aelibrary.lib");


/*******************************************************************************
* SIGNAL FLOWS
*******************************************************************************/

// signal flow 1A
signalflow1a(grainOut1, grainOut2, mic1, mic2, mic3, mic4) =
grainOut1, grainOut2, mic1, mic2, mic3, mic4,
((diffHL, memWriteDel1, memWriteDel2, memWriteLev,
cntrlLev1, cntrlLev2, cntrlFeed, cntrlMain))
with {
    map6sumx6 = (mic3 : integrator(0.01) : delayfb(0.01, 0.95)) +
                (mic4 : integrator(0.01) : delayfb(0.01, 0.95)) :
                    \(x).(6 + x * 6);

    localMaxDiff =  ((map6sumx6, mic3) : localmax) ,
                    ((map6sumx6, mic4) : localmax) :
                        \(x, y).(x - y) : MaxDiffinspect(1);

    SenstoExt = (map6sumx6, localMaxDiff) :
        localmax <: _ , (_ : delayfb(12, 0)) : + : * (0.5) :
            LP1(0.5);

    diffHL =    ((mic3 + mic4) : HP3(var2) : integrator(0.05)) ,
                ((mic3 + mic4) : LP3(var2) : integrator(0.10)) :
                    \(x, y).((x - y)) *
                        (1 - SenstoExt) : delayfb(0.01, 0.995) :
                            LP5(25) : \(x).(0.5 + x * 0.5) :
                                // LIMIT - max - min
                                limit(1, 0) : DiffHLinspect(1);

    memWriteLev = (mic3 + mic4) : integrator(0.1) : delayfb(0.01, 0.9) :
        LP5(25) : \(x).(1 - (x * x)) :
            // LIMIT - max - min
            limit(1, 0) : MemWriteLevinspect(1);

    memWriteDel1 = memWriteLev : delayfb((var1 / 2), 0) :
        // LIMIT - max - min
        limit(1, 0) : MemWriteDelinspect(1);

    memWriteDel2 = memWriteLev : delayfb((var1 / 3), 0) :
        // LIMIT - max - min
        limit(1, 0) : MemWriteDelinspect(2);

    cntrlMain = (mic3 + mic4) * SenstoExt : integrator(0.01) :
        delayfb(0.01, 0.995) : LP5(25) :
            // LIMIT - max - min
            limit(1, 0) : CntrlMaininspect(1);

    cntrlLev1 = cntrlMain : delayfb((var1 / 3), 0) :
        // LIMIT - max - min
        limit(1, 0);

    cntrlLev2 = cntrlMain : delayfb((var1 / 2), 0) :
        // LIMIT - max - min
        limit(1, 0);

    cntrlFeed = cntrlMain : \(x).(ba.if(x <= 0.5, 1.0, (1.0 - x) * 2.0)) :
            // LIMIT - max - min
            limit(1, 0) : CntrlFeedinspect(1);
};

// signal flow 1B
signalflow1b(grainOut1, grainOut2, mic1, mic2, mic3, mic4, diffHL, memWriteDel1,
  memWriteDel2, memWriteLev, cntrlLev1, cntrlLev2, cntrlFeed, cntrlMain) =
  mic1, mic2, mic3, mic4,
  diffHL, memWriteDel1, memWriteDel2, memWriteLev, cntrlLev1, cntrlLev2,
  cntrlFeed, cntrlMain,
  ((cntrlMic1, cntrlMic2, directLevel, timeIndex1, timeIndex2, triangle1,
  triangle2, triangle3))
with {
    // cntrlMic - original version
    cntrlMic1 = (mic1 : Cntrlmicinspect(1) : HP1(50) : LP1(6000) :
        integrator(0.01) : delayfb(0.01, 0.995) : LP4(2.83) ^ 2) :
        // 2.83 = 25 Hz score (25 + Kyma smoother globalcontrol)
        limit(1, 0) : CntrlmicVinspect(1);

    cntrlMic2 = (mic2 : Cntrlmicinspect(2) : HP1(50) : LP1(6000) :
        integrator(0.01) : delayfb(0.01, 0.995) : LP4(2.83) ^ 2) :
        limit(1, 0) : CntrlmicVinspect(2);

    directLevel = (grainOut1 + grainOut2) : integrator(0.01) :
        delayfb(0.01, 0.97) : LP5(0.5) <:
        _, (_ : delayfb(var1 * 2, (1 - var3) * 0.5)) : + :
        \(x).(1 - x * 0.5) : limit(1, 0) : DirectLevelinspect(1);

    timeIndex1 = triangleWave(1 / (var1 * 2)) * - 1;
    timeIndex2 = triangleWave(1 / (var1 * 2));
    triangle1 = (triangleWave(1 / (var1 * 6)) * memWriteLev) <:
        _, hbargraph("v: Write + Read memory pointers /h: triangle/[1] tri1",
            -1, 1) : attach;
    triangle2 = (triangleWave(1 / (var1 * (1 - cntrlMain)))) ^ 2 <:
        _, hbargraph("v: Write + Read memory pointers /h: triangle/[2] tri2",
            -1, 1) : attach;
    triangle3 = (triangleWave(1 / var1)) <:
        _, hbargraph("v: Write + Read memory pointers /h: triangle/[3] tri3",
            -1, 1) : attach;
};

// signal flow 2A
signalflow2a(mic1, mic2, mic3, mic4, diffHL, memWriteDel1, memWriteDel2,
    memWriteLev, cntrlLev1, cntrlLev2, cntrlFeed, cntrlMain, cntrlMic1,
    cntrlMic2, directLevel, timeIndex1, timeIndex2, triangle1, triangle2,
    triangle3) =
    mic1, mic2, mic3, mic4,
    diffHL, memWriteDel1, memWriteDel2, memWriteLev, cntrlLev1, cntrlLev2,
    cntrlFeed, cntrlMain, cntrlMic1, cntrlMic2, directLevel, timeIndex1,
    timeIndex2, triangle1, triangle2, triangle3,
    ((sampWOut, sig1, sig2, sig3, sig4, sig5, sig6, sig7))
with {
    micIN1 = mic1 : Attentninspect(1) : HP1(50) : LP1(6000) * ((1 - cntrlMic1));
    micIN2 = mic2 : Attentninspect(2) : HP1(50) : LP1(6000) * ((1 - cntrlMic2));

    bufferWrite = ba.period(SampleRate * var1) <: _,
        (_ / (SampleRate * var1) : hbargraph(
            "v: Write + Read memory pointers /[0] timeRec", 0, 1)) :
        attach;
    SRSect1(x) = x : sampler(1, bufferWrite, var1, (1 - memWriteDel2),
        (var2 + (diffHL * 1000)) / 261) :
        SRinspect(1) : HP4(50) : delayfb(var1 / 2, 0);
    SRSect2(x) = x : sampler(2, bufferWrite, var1,
        (memWriteLev + memWriteDel1) / 2, (290 - (diffHL * 90)) / 261) :
        SRinspect(2) : HP4(50) : delayfb(var1, 0);
    SRSect3(x) = x : sampler(3, bufferWrite, var1, (1 - memWriteDel1),
        ((var2 * 2) - (diffHL * 1000)) / 261) :
        SRinspect(3) : HP4(50);
    SRSectBP1(x) = x : SRSect3 : BPsvftpt(diffHL * 400,
        (var2 / 2) * memWriteDel2);
    SRSectBP2(x) = x : SRSect3 : BPsvftpt((1 - diffHL) * 800, var2 *
        (1 - memWriteDel1));
    SRSect4(x) = x : sampler(4, bufferWrite, var1, 1,
        (250 + (diffHL * 20)) / 261) :
        SRinspect(4);
    SRSect5(x) = x : sampler(5, bufferWrite, var1, memWriteLev, 0.766283) :
        SRinspect(5);

    SampleWriteLoop = loop ~ _
    with {
        loop(fb) = (((fb : SRSect1), (fb : SRSect2), (fb : SRSectBP1),
            (fb : SRSectBP2)) :> + ) * (cntrlFeed * memWriteLev) <:
            (
                _ + (micIN1 + micIN2) : _ * triangle1 ),
                _ ,
                (fb : SRSect4) ,
                (fb : SRSect5) ,
                (fb : SRSect3) ;
    };

    sig1 = micIN1 * directLevel;
    sig2 = micIN2 * directLevel;
    sampWOut = SampleWriteLoop : \(A, B, C, D, E).(A);
    variabledelaysig3(x) = x : de.delay(max(0, ba.sec2samp(0.05)),
        max(0, int(ba.sec2samp(0.05 * cntrlMain))));
    sig3 = SampleWriteLoop : \(A, B, C, D, E).(B) : _ *
        memWriteLev : variabledelaysig3 * triangle2 * directLevel;
    sig4 = SampleWriteLoop : \(A, B, C, D, E).(B) : _ * memWriteLev *
        (1 - triangle2) * directLevel;
    sig5 = SampleWriteLoop : \(A, B, C, D, E).(C) : HP4(50) :
        delayfb(var1 / 3, 0);
    sig6 = SampleWriteLoop : \(A, B, C, D, E).(D) : HP4(50) :
        delayfb(var1 / 2.5, 0);
    sig7 = SampleWriteLoop : \(A, B, C, D, E).(E) :
        delayfb(var1 / 1.5, 0) * directLevel;
};

// signal flow 2B
signalflow2b(mic1, mic2, mic3, mic4, diffHL, memWriteDel1, memWriteDel2,
    memWriteLev, cntrlLev1, cntrlLev2, cntrlFeed, cntrlMain, cntrlMic1,
    cntrlMic2, directLevel, timeIndex1, timeIndex2, triangle1, triangle2,
    triangle3, sampWOut, sig1, sig2, sig3, sig4, sig5, sig6, sig7) =
      mic1, mic2, mic3, mic4,
        diffHL, memWriteDel1, memWriteDel2, memWriteLev, cntrlLev1, cntrlLev2,
        cntrlFeed, cntrlMain, cntrlMic1, cntrlMic2, directLevel, timeIndex1,
        timeIndex2, triangle1, triangle2, triangle3, sampWOut, sig1, sig2, sig3,
        sig4, sig5, sig6, sig7,
grainOut1, grainOut2,
out1, out2
with {
    grainOut1 = granular_sampling(var1,
        (timeIndex1 <: _,
            hbargraph("v: Write + Read memory pointers /h: mem/[1] time1",
                -1, 1) : attach),
        memWriteDel1, cntrlLev1, 21, sampWOut) : GSinspect(1);
    grainOut2 = granular_sampling(var1,
        (timeIndex2 <: _,
            hbargraph("v: Write + Read memory pointers /h: mem/[2] time2",
                -1, 1) : attach),
        memWriteDel2, cntrlLev2, 20, sampWOut) : GSinspect(2);

    out1 =
        (
            ((sig5 : delayfb(0.040, 0)) * (1 - triangle3)),
             (sig5 * triangle3),
            ((sig6 : delayfb(0.036, 0)) * (1 - triangle3)),
            ((sig6 : delayfb(0.036, 0)) * triangle3),
              sig1 * directOut,
              0,
              sig4,
              grainOut1 * (1 - memWriteLev) + grainOut2 * memWriteLev
        ) :> _;

    out2 =
        (
             (sig5 * (1 - triangle3)),
            ((sig5 : delayfb(0.040, 0)) * triangle3),
             (sig6 * (1 - triangle3)),
             (sig6 * triangle3),
              sig2 * directOut,
              sig3,
              sig7,
              grainOut1 * memWriteLev + grainOut2 * (1 - memWriteLev)
        ) :> _;
};

// signal flow 3
signalflow3(mic1, mic2, mic3, mic4, diffHL, memWriteDel1, memWriteDel2,
    memWriteLev, cntrlLev1, cntrlLev2, cntrlFeed, cntrlMain, cntrlMic1,
    cntrlMic2, directLevel, timeIndex1, timeIndex2, triangle1, triangle2,
    triangle3, sampWOut, sig1, sig2, sig3, sig4, sig5, sig6, sig7,
    grainOut1, grainOut2, out1, out2) =
      grainOut1, grainOut2,
          (
          (   out1,
              out2,
          (   out2 : delayfb((var4 / 2) / 344, 0)),
          (   out1 : delayfb((var4 / 2) / 344, 0)),
          (   out1 : delayfb(var4 / 344, 0)),
          (   out2 : delayfb(var4 / 344, 0)) )
          ),
    mic1, mic2, mic3, mic4,
    diffHL, memWriteDel1, memWriteDel2, memWriteLev, cntrlLev1, cntrlLev2,
    cntrlFeed, cntrlMain, cntrlMic1, cntrlMic2, directLevel, timeIndex1,
    timeIndex2, triangle1, triangle2, triangle3, sampWOut, sig1, sig2, sig3,
    sig4, sig5, sig6, sig7;


/*******************************************************************************
* NETWORK
*******************************************************************************/

process = si.bus(4) :
  (signalflow1a : signalflow1b : signalflow2a : signalflow2b : signalflow3) ~
      si.bus(2) : (si.block(2), par(i, 6, _ * globalGain), si.block(28));
