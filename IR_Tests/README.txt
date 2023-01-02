(su Kyma)
per tutti gli esempi: 44.1 kHz,16 bit, mono
(su Faust)
per tutti gli esempi: 44.1 kHz,24 bit, mono

segnale di test
pulse1.wav = 1 secondo di campioni = 0, poi 1 campione = 1, poi 1 secondo di campioni = 0

risposte
pulse hp1.wav = hipass ordine1, cf  50 hz
pulse lp1.wav = lopass ordine1, cf  6000 hz
pulse hp2.wav = hipass ordine2, cf 50 hz
pulse hp2-lp1-envF.wav = ...., envFoll 0.01
pulse hp2-lp1-envF-delFB.wav = ..., delFB time 0.01 fb 0.995
pulse lp4(0.5).wav = lopass ordine4, fc 0.5 hz (mezzo hz)
pulse lp4(0.04).wav = ..., lopass ordine 4, cf 0.04 hz (4 centesimi di hz)
pulse hp2-lp1-envF-delFB-lp4(0.5) = ..., lopass ordine 4, cf 0.5 (mezzo hz)
pulse hp2-lp1-envF-delFB-lp4(0.04).wav = ..., lopass ordine 4, cf 0.04 (4 centesimi di hz)
 
segnale di test
sine1000.wav = 1 secondo di sinusoide a 1 kHz, -34 dB

risposte
sine1000-CntrlMic1(partitura).wav = tutta la catena di cntrlMic come in partitura
sine1000-CntrlMic1(alternativa).wav = tutta la catena di cntrlMic con parametri alternativi
ovvero: hp ordine 2, delay feedback 0.995, lp ord 4 fc 0.04 hz, e con pow^2 alla fine
