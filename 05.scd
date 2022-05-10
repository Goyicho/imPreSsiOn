NetAddr.langPort;
s.options.memSize = 1024*1024;


//synthdefs
SynthDef(\sin, {|out = 0, amp = 0.5, freq = 440, release = 5, reverb_mix = 0.9|
	var env = Env.asr(1,1,release).kr(2, Trig1.kr(1,1,0.5));
	var snd  = SinOsc.ar(freq+[0,1], mul: env) ** 2;

	Out.ar(0, Pan2.ar(FreeVerb.ar(snd * amp, reverb_mix, 0.8, 0.2), LFNoise1.kr(10)));
}).add;

// if freq_1 and freq_2 are close, the sound is constant
SynthDef(\jump, {|out=0, amp=1,freq=440, freq_1=1, freq_2=4, env_2 = 0.01, dust_kr = 500, tri = 0.5|
	var trig, sig;
	freq = SinOsc.kr(1).exprange(freq * freq_1,freq * freq_2).round(freq);
	sig = SinOsc.ar(freq) * 0.2;
	trig = Dust.kr(dust_kr);
	sig = sig * EnvGen.kr(Env.perc(0.1, env_2), trig);
	sig = Pan2.ar(sig, LFNoise1.kr(10));
	sig = sig * Env.triangle(tri,tri).kr(2);
	Out.ar(out, sig * amp);
}).add;


SynthDef(\amb, { |freq = 440, amp = 0.5, dur = 200, del=200|
	var src, loc, rt;
	var env = EnvGen.kr(Env.sine(dur, 0.2), doneAction: 2);

	rt = 0.25;
	src = SinOsc.ar(freq, mul: env * 0.2) + SinOsc.ar(freq * 2, mul: env * 0.2)
+ SinOsc.ar(freq * del.linlin(0,255,0,10), mul: env * 0.4);
	src = src * Decay.ar(src, 1/rt, del.linlin(0,255,1,0.01));

	loc = src + DelayC.ar(src, 0.2, freq.reciprocal);
	loc = loc + AllpassC.ar(loc, 1, LFNoise0.ar(rt!2).range(0.1, del.linlin(0,255,0.1,0.5)),4);

	Out.ar(0,Limiter.ar(loc)*0.5);
}).add;

// some presets for \perc
~p = [[0.4,0.4,6,6,1,1],
	[0.2,0.2,2,2,1,1],
	[0.3,0.6,2,2,10,1],
	[0.9,0.1,20,2,1,10],
	[3,1,5,2,1,1],
	[2,30,1,1,1,1],
	[2,3,10,1,1,10],
	[8,6,1,5,1,6],
	[10,1,1,1,1,10],
	[20,20,1,10,1,10]
];
SynthDef(\perc, {|freq = 200, amp=1, rel = 2, pan_op = 0, c1 = 1, c2 = 1, m1 = 1, m1i = 1, m2 = 1, m2i = 1|
	var mod1env = Env.perc(releaseTime: rel).kr();
	var mod2env = Env.perc(releaseTime: rel/5).kr();

	var carenv = Env.perc(releaseTime: rel * Rand.new(0.5,1)).kr(2);

	var mod1 = SinOsc.ar(freq * m1, mul: m1i * mod1env);
	var mod2 = SinOsc.ar(freq * m2, mul: m2i * mod2env);

	var car1 = SinOsc.ar(freq * c1 + mod1, mul: amp * carenv);
	var car2 = SinOsc.ar(freq * c2 + mod2, mul: amp * carenv);

	var pan = Pan2.ar(car1 + car2, pos:pan_op);
	pan = FreeVerb.ar(pan, mix:Rand.new(0,1), room:Rand.new(0,1), damp:0);
	Out.ar(0, pan * amp);

}).add;


SynthDef(\randFm , { arg freq=440, amp=0.8, gate=1, pan=0, ratio=1;
	var env, mod, car, snd1, fft, magfreeze, snd2, snd;
	env = Env.perc( ratio.linlin(1,10,0.3,0) , ratio.linlin(1,10,0.3,0.9));
	env = EnvGen.kr(env, gate,  Rand(1.0,2.5) );
	mod = SinOsc.ar(freq +  Rand(0, ratio/5)  *  Rand(0,ratio), env);
	env = Env.perc( Rand(0,ratio/50) ,  1);
	env = EnvGen.kr(env, gate, 0.3 );
	car = SinOsc.ar(freq + Rand(0, ratio/5)  *  ratio , mod, env);

	snd1 = FreeVerb.ar(car, 0.5, 0.8, 0.2);

	car = car + AllpassC.ar(car, 0.1, LFNoise0.ar(0.25!2).range(0.05,0.1),4);

	snd = SelectX.ar(Rand(1.5).round(1),[snd1,car]);

	DetectSilence.ar(snd, doneAction: 2);

	//Out.ar(0, Pan2.ar(car, pan, amp));
	Out.ar(0, Pan2.ar(snd, pan, amp));

}).add;


SynthDef(\freezeFm , { arg freq=440, amp=1, gate=1, pan=0, ratio=4, fft_ratio = 0.75;
	var env, mod, car, snd1, ifft, sig, fft, magfreeze, snd2, snd;
	var in, chain;

	env = Env.perc( 1, 0.3 );
	env = EnvGen.kr(env, gate,  1 );
	mod = SinOsc.ar(freq * ratio +  1.5  *  1.1, 1.2, env);
	env = Env.perc( 0.07 ,  1);
	env = EnvGen.kr(env, gate, 0.7 );
	car = SinOsc.ar(freq * ratio + 1.5  *  1.1 , mod, env);

	snd1 = FreeVerb.ar(car, 0.5, 0.8, 0.2);

	sig = snd1;
	fft = FFT(LocalBuf(2048, 2), sig, fft_ratio);
	magfreeze = PV_MagFreeze(fft, LFNoise0.kr(1, 200, 0.1));
	ifft = Mix(IFFT(magfreeze) * 0.5);

	DetectSilence.ar(ifft, doneAction: 2);
    Out.ar(0, Pan2.ar(ifft, LFNoise1.kr(10)););

}).add;


// OSCdefs
~build_notes = OSCdef(\notes, {|msg| msg.postln;
	~notes =  Array.fill(10, { |i|   msg[i+1].linlin(0,255,1,127).round(1).asInteger().nearestInScale([0,2,4,5,7,9,11])});
	~notes.postln;
}, '/notes');

OSCdef(\perc_index, {|msg| msg.postln;
	~index = msg[1];

}, '/perc_index');

OSCdef(\perc_index2, {|msg| msg.postln;
	~index2 = msg[1];

}, '/perc_index2');

OSCdef(\level, {|msg| msg.postln;
	~level = msg[1];
	if (~level == 1){~instrument = \sin}{};
	if (~level == 2){~instrument = \freezeFm}{};
	if (~level == 3){~instrument = \randFm}{};

}, '/level');

OSCdef(\ratio, {|msg| msg.postln;
	msg[0].postln;
	msg[1].postln;
	~ratio = msg[1];
	~fms = [];
	~durs =  Array.fill(msg[2].asInt, { |i| msg[i+4]});
	~durs.postln;
	~durs.size.do({|i|
		~fms = ~fms.add(~durs[i]);
		~fms = ~fms.add(Pbind(\instrument, ~instrument, \ratio, ~ratio, \midinote, ~notes[i%10],  \dur, Pseq([1], 1) ));

});

}, '/ratio');

~compose = OSCdef( \compose, {|msg| msg.postln;

	~in = [msg[1]];
	~in_dur = ~in.linlin(0,255,10,1);

	x = Ptpar(~fms);
	a = Pbind(\instrument, \perc, \amp, 0.5, \midinote, Pseq(~notes,1), \c1, ~p[~index][0], \c2, ~p[~index][1], \m1, ~p[~index][2], \m1i, ~p[~index][3], \m2,~p[~index][4], \m2i,~p[~index][5]);
	b = Pbind(\instrument, \perc, \amp, 0.3, \midinote, Pseq(~notes,1), \c1, ~p[~index2][0], \c2, ~p[~index2][1], \m1, ~p[~index2][2], \m1i, ~p[~index2][3], \m2,~p[~index2][4], \m2i,~p[~index2][5]);
	y = Ptpar([0,a,~ratio.linlin(1,10,1.1,0,3),b]);

	z = [Pbind(\instrument, \amb,  \del, Pseq(~in), \dur, Pseq(~in_dur, 1)),
		Pbind(\instrument, \jump,   \freq_2, ~ratio, \dust_kr, ~ratio*100, \tri, ~ratio/10,  \midinote, Pseq(~notes,1))
	].at(2.rand);
	Ppar([x,y,z]).play


}, '/compose');
