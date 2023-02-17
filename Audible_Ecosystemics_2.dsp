declare name "Agostino Di Scipio - AUDIBLE ECOSYSTEMICS n.2";
declare author "Luca Spanedda";
declare author "Dario Sanfilippo";
declare version "alpha";
declare description " 2022 version - Realised on composer's instructions
    of the year 2017 edited in L’Aquila, Italy";

// import faust standard library
import("stdfaust.lib");
// import audible ecosystemics objects library
import("aelibrary.lib");


//------- ------------- ----- -----------
//-- AE2 -----------------------------------------------------------------------
//------- --------


// MAIN SYSTEM FUNCTION
outputrouting(grainOut1, grainOut2, out1, out2, out3, out4, out5, out6, mic1, mic2, mic3, mic4, diffHL, memWriteDel1, memWriteDel2, memWriteLev, cntrlLev1, cntrlLev2, cntrlFeed, cntrlMain, cntrlMic1, cntrlMic2, directLevel, timeIndex1, timeIndex2, triangle1, triangle2, triangle3, sampWOut, sig1, sig2, sig3, sig4, sig5, sig6, sig7) =
out1, out2, out3, out4, out5, out6; // choose here the signals in output

process =
    si.bus(8) :> si.bus(4) : 
    (signalflow1a : signalflow1b : signalflow2a : signalflow2b : signalflow3) ~ si.bus(2) : 
        outputrouting;

signalflow1a( grainOut1, grainOut2, mic1, mic2, mic3, mic4 ) = 
grainOut1, grainOut2, 
mic1, mic2, mic3, mic4, 
((diffHL, memWriteDel1, memWriteDel2, memWriteLev, cntrlLev1, cntrlLev2, cntrlFeed, cntrlMain) : SF1Ainspect)
with {
    Mic_1A_1 = mic3 : gainMic_1A1;
    Mic_1A_2 = mic4 : gainMic_1A2;
    map6sumx6 = (Mic_1A_1 : integrator(.01) : delayfb(.01, .95)) +
                (Mic_1A_2 : integrator(.01) : delayfb(.01, .95)) : 
                    \(x).(6 + x * 6);

    localMaxDiff =  ((map6sumx6, Mic_1A_1) : localmax) ,
                    ((map6sumx6, Mic_1A_2) : localmax) :
                        \(x, y).(x - y);

    SenstoExt = (map6sumx6, localMaxDiff) : 
        localmax <: _ , (_ : delayfb(12, 0)) : + : * (.5) : 
            LP1(.5) :   tgroup("Control", vgroup("System Inspectors",
                        hgroup("Signal Flow 1a [1]",
                        hgroup("Sens. to Ext. Cond.", 
                        inspect(101, -1, 1)))));

    diffHL =    ((Mic_1A_1 + Mic_1A_2) : HP3(var2) : integrator(.05)) ,
                ((Mic_1A_1 + Mic_1A_2) : LP3(var2) : integrator(.10)) :
                    \(x, y).((x - y) :  tgroup("Control", vgroup("System Inspectors",
                                        hgroup("Signal Flow 1a [1]",
                                        hgroup("diffHL Centroid", 
                                        inspect(100, -1, 1)))))) * 
                        (1 - SenstoExt) : delayfb(.01, .995) : 
                            LP5(25) : \(x).(.5 + x * .5) : 
                                // LIMIT - max - min
                                limit(1, 0);

    memWriteLev = (Mic_1A_1 + Mic_1A_2) : integrator(.1) : delayfb(.01, .9) :
        LP5(25) : \(x).(1 - (x * x)) : 
            // LIMIT - max - min
            limit(1, 0);

    memWriteDel1 = memWriteLev : delayfb((var1 / 2), 0) : 
        // LIMIT - max - min
        limit(1, 0);

    memWriteDel2 = memWriteLev : delayfb((var1 / 3), 0) : 
        // LIMIT - max - min
        limit(1, 0);

    cntrlMain = (Mic_1A_1 + Mic_1A_2) * SenstoExt : integrator(.01) : 
        delayfb(.01, .995) : LP5(25) : 
            // LIMIT - max - min
            limit(1, 0);

    cntrlLev1 = cntrlMain : delayfb((var1 / 3), 0) : 
        // LIMIT - max - min
        limit(1, 0);

    cntrlLev2 = cntrlMain : delayfb((var1 / 2), 0) : 
        // LIMIT - max - min
        limit(1, 0);

    cntrlFeed = cntrlMain : \(x).(ba.if(x <= .5, 1.0, (1.0 - x) * 2.0)) : 
            // LIMIT - max - min
            limit(1, 0);
};

signalflow1b( grainOut1, grainOut2, mic1, mic2, mic3, mic4, diffHL, memWriteDel1, memWriteDel2, memWriteLev, cntrlLev1, cntrlLev2, cntrlFeed, cntrlMain ) = 
mic1, mic2, mic3, mic4, 
diffHL, memWriteDel1, memWriteDel2, memWriteLev, cntrlLev1, cntrlLev2, cntrlFeed, cntrlMain, 
((cntrlMic1, cntrlMic2, directLevel, timeIndex1, timeIndex2, triangle1, triangle2, triangle3) : SF1Binspect)
with {
    Mic_1B_1 = mic1 : gainMic_1B1;
    Mic_1B_2 = mic2 : gainMic_1B2;
    // cntrlMic - original version
    cntrlMic(x) = x : HP1(50) : LP1(6000) : 
        integrator(.01) : delayfb(.01, .995) : LP5(.5);

    // cntrlMic - alternative version
    // cntrlMic(x) = x : HP2(50) : LP1(6000) :
    //     integrator(.01) : delayfb(.01, .995) : LP5(.04);
    cntrlMic1 = Mic_1B_1 : cntrlMic : 
        // LIMIT - max - min
        limit(1, 0);

    cntrlMic2 = Mic_1B_2 : cntrlMic : 
        // LIMIT - max - min
        limit(1, 0);

    directLevel =
        (grainOut1 + grainOut2) : integrator(.01) : delayfb(.01, .97) : 
            LP5(.5) <: 
                 _ , 
                (_ : delayfb(var1 * 2, (1 - var3) * 0.5)) : + : 
                    \(x).(1 - x * .5) : 
                        // LIMIT - max - min
                        limit(1, 0);

    timeIndex1 = triangleWave(1 / (var1 * 2)) : \(x).((x - 2) * 0.5);

    timeIndex2 = triangleWave(1 / (var1 * 2)) : \(x).((x + 1) * 0.5);

    triangle1 = triangleWave(1 / (var1 * 6)) * memWriteLev;

    triangle2 = triangleWave(var1 * (1 - cntrlMain));

    triangle3 = triangleWave(1 / var1);
};

signalflow2a( mic1, mic2, mic3, mic4, diffHL, memWriteDel1, memWriteDel2, memWriteLev, cntrlLev1, cntrlLev2, cntrlFeed, cntrlMain, cntrlMic1, cntrlMic2, directLevel, timeIndex1, timeIndex2, triangle1, triangle2, triangle3 ) = 
mic1, mic2, mic3, mic4, 
diffHL, memWriteDel1, memWriteDel2, memWriteLev, cntrlLev1, cntrlLev2, cntrlFeed, cntrlMain, 
cntrlMic1, cntrlMic2, directLevel, timeIndex1, timeIndex2, triangle1, triangle2, triangle3, 
((sampWOut, sig1, sig2, sig3, sig4, sig5, sig6, sig7) : SF2Ainspect)
with {
    Mic_2A_1 = mic1 : gainMic_2A1;
    Mic_2A_2 = mic2 : gainMic_2A2;
    micIN1 = Mic_2A_1 : HP1(50) : LP1(6000) * 
        (1 - cntrlMic1);

    micIN2 = Mic_2A_2 : HP1(50) : LP1(6000) * 
        (1 - cntrlMic2);

    SRSect1(x) = x : sampler(var1, (1 - memWriteDel2), (var2 + (diffHL * 1000)) / 261) : 
        SRinspect(1) : HP4(50) : delayfb(var1 / 2, 0);

    SRSect2(x) = x : sampler(var1, (memWriteLev + memWriteDel1) / 2, (290 - (diffHL * 90)) / 261) : 
        SRinspect(2) : HP4(50) : delayfb(var1, 0);

    SRSect3(x) = x : sampler(var1, (1 - memWriteDel1), ((var2 * 2) - (diffHL * 1000)) / 261) : 
        SRinspect(3) : HP4(50);

    SRSectBP1(x) = x : SRSect3 : BPsvftpt(diffHL * 400, (var2 / 2) * memWriteDel2);

    SRSectBP2(x) = x : SRSect3 : BPsvftpt((1 - diffHL) * 800, var2 * (1 - memWriteDel1));

    SRSect4(x) = x : sampler(var1, 1, (250 + (diffHL * 20)) / 261) : SRinspect(4);

    SRSect5(x) = x : sampler(var1, memWriteLev, .766283) : SRinspect(5);

    SampleWriteLoop = loop ~ _
    with {
        loop(fb) =
            (
                (   SRSect1(fb) ,
                    SRSect2(fb) ,
                    SRSectBP1(fb) ,
                    SRSectBP2(fb) :> + 
                ) * (cntrlFeed * memWriteLev)
            ) <:
            (   
                _ + (micIN1 + micIN2) : _ * triangle1 ),
                _ ,
                SRSect4(fb) ,
                SRSect5(fb) ,
                SRSect3(fb) ;
    };

    sig1 = micIN1 * directLevel;

    sig2 = micIN2 * directLevel;

    sampWOut = SampleWriteLoop : \(A,B,C,D,E).( A );

    variabledelaysig3(x) = x : de.delay(max(0, ba.sec2samp(.05)), max(0, int(ba.sec2samp(.05 * cntrlMain))) );
    sig3 = SampleWriteLoop : \(A,B,C,D,E).( B ) : _ * 
        memWriteLev : variabledelaysig3 * triangle2 * directLevel;

    sig4 = SampleWriteLoop : \(A,B,C,D,E).( B ) : _ * 
        memWriteLev * (1-triangle2) * directLevel;

    sig5 = SampleWriteLoop : \(A,B,C,D,E).( C ) :
        HP4(50) : delayfb(var1 / 3, 0);

    sig6 = SampleWriteLoop : \(A,B,C,D,E).( D ) :
        HP4(50) : delayfb(var1 / 2.5, 0);

    sig7 = SampleWriteLoop : \(A,B,C,D,E).( E ) : delayfb(var1 / 1.5, 0) * 
        directLevel;
};

signalflow2b( mic1, mic2, mic3, mic4, diffHL, memWriteDel1, memWriteDel2, memWriteLev, cntrlLev1, cntrlLev2, cntrlFeed, cntrlMain, cntrlMic1, cntrlMic2, directLevel, timeIndex1, timeIndex2, triangle1, triangle2, triangle3, sampWOut, sig1, sig2, sig3, sig4, sig5, sig6, sig7 ) = 
mic1, mic2, mic3, mic4, 
diffHL, memWriteDel1, memWriteDel2, memWriteLev, cntrlLev1, cntrlLev2, cntrlFeed, cntrlMain, 
cntrlMic1, cntrlMic2, directLevel, timeIndex1, timeIndex2, triangle1, triangle2, triangle3, 
sampWOut, sig1, sig2, sig3, sig4, sig5, sig6, sig7, 
grainOut1, grainOut2, 
out1, out2
with {
    grainOut1 = 
        granular_sampling(var1, timeIndex1, memWriteDel1, cntrlLev1, 21, sampWOut) : 
            GSinspect(1);

    grainOut2 = 
        granular_sampling(var1, timeIndex2, memWriteDel2, cntrlLev2, 20, sampWOut) : 
            GSinspect(2);

    out1 =  
        ( 
            ((sig5 : delayfb(.040, 0)) * (1 - triangle3)),
             (sig5 * triangle3),
            ((sig6 : delayfb(.036, 0)) * (1 - triangle3)),
            ((sig6 : delayfb(.036, 0)) * triangle3 ),
              sig1,
              0,
              sig4,
              grainOut1 * (1 - memWriteLev) + grainOut2 * memWriteLev 
        ) :> _ : gainMic_3O1;

    out2 =  
        ( 
             (sig5 * (1 - triangle3)),
            ((sig5 : delayfb(.040, 0)) * triangle3),
             (sig6 * (1 - triangle3)),
             (sig6 * triangle3),
              sig2,
              sig3,
              sig7,
              grainOut1 * memWriteLev + grainOut2 * (1 - memWriteLev) 
        ) :> _ : gainMic_3O2;
};

signalflow3( mic1, mic2, mic3, mic4, diffHL, memWriteDel1, memWriteDel2, memWriteLev, cntrlLev1, cntrlLev2, cntrlFeed, cntrlMain, cntrlMic1, cntrlMic2, directLevel, timeIndex1, timeIndex2, triangle1, triangle2, triangle3, sampWOut, sig1, sig2, sig3, sig4, sig5, sig6, sig7, grainOut1, grainOut2, out1, out2 ) = 
grainOut1, grainOut2,
( 
(   out1, out2, 
(   out2 : delayfb((var4 / 2) / 344, 0)), 
(   out1 : delayfb((var4 / 2) / 344, 0)), 
(   out1 : delayfb(var4 / 344, 0)), 
(   out2 : delayfb(var4 / 344, 0)) ) 
: SF3Oinspect
), 
mic1, mic2, mic3, mic4,
diffHL, memWriteDel1, memWriteDel2, memWriteLev, cntrlLev1, cntrlLev2, cntrlFeed, cntrlMain, 
cntrlMic1, cntrlMic2, directLevel, timeIndex1, timeIndex2, triangle1, triangle2, triangle3, 
sampWOut, sig1, sig2, sig3, sig4, sig5, sig6, sig7;