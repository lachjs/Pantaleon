(

/*	Pantaleón
	by Juan S. Lach
	Computer 1 part		*/


// #1: prepare scales and chords

var natural, maj, min, fibo, rara, micro, mik, especial;
var byzantine, acordes, septimas, septAbiertas, secundales, aC;

var generador, genx, bajo1, bajo2, acomp, bajoIntro, bassy, groovbass;
var ampitas, introX, introY, introZ, acordex, acordex1, acordex2,acordex3;
var melody, accKey, root, oct, solobass, zPad;

var score, tap, tempo;


s = Server.internal;
Server.default = Server.internal;
o = Server.internal.options;

o.memSize = 65536;


MIDIIn.connect;


SynthDescLib.read;

maj =  [0, 12, 24, 30, 42, 54, 66]; // mayor
natural = [0, 12, 22, 30, 42, 54, 64];
min = [0, 12, 18, 30, 42, 48, 60]; // menor
fibo = [0, 5, 8, 13, 21, 34, 55]; // fibonacci

rara = [0];
[5, 6, 7, 11, 13, 19].scramble.do{|x| rara = rara.add(rara.last + x)};
micro  = Array.fill(6, {|i| rrand(5,15)});
if (micro.sum != 62) {micro[micro.size-1] = micro.last + (62 - micro.sum)};
mik = [0];
micro.do{|x| mik = mik.add(mik.last + x)};
especial = [0, 5, 12, 23, 36, 47, 60];

byzantine = [
			[0, 12, 23, 30, 42, 53, 60],	//diatonic
			[0, 7, 19, 30, 37, 49, 61],
			[0, 11, 18, 30, 42, 53, 60],
			[0, 7, 23, 30, 42, 49, 65], 	//soft chromatic
			[0, 12, 23, 30, 42, 49, 65],	// mixed
			[0, 5, 24, 30, 42, 49, 65]
		];
acordes = [
			[0, 2, 4], // tonic
			[1, 3, 5], // super tonic
			[2, 4, 6], // mediant
			[0, 3, 5], // sub dominant
			[1, 4, 6], // dominant
			[0, 2, 5], // sub mediant
			[1, 3, 6] // sensible
		];
septimas = [
			[0, 2, 4, 6],
			[1, 3, 5, 7],
			[2, 4, 6, 8],
			[-4, -2, 0, 2],
			[-3, -1, 1, 3],
			[-2, 0, 2, 4],
			[-1, 1, 3, 5]

		];
septAbiertas = septimas.collect({|n| n.collect({|i| i - (7*rrand(-2,2))})});
septAbiertas.postln;

aC = [];
10.do{aC = aC.add(Array.series(4,rrand(0,5),rrand(1,2)).scramble)};
~randChords = aC.collect({|n| n.collect({|i| i - (7*rrand(-2,2))})});

secundales = [
				[0,1,2,3],
				[1,2,3,4],
				[2,3,4,5],
				[4,5,6,7],
				[5,6,7,8],

			];
~secundas  = secundales.collect({|n| n.collect({|i| i - (7*rrand(-2,2))})});
~acc = septimas ++ acordes;
~sept = septimas ++ septAbiertas;
~septChrom = ~sept.collect({|n| var new;
			new = n.collect({|x|
				if ( (x%7 == 1) || (x%7 == 2) || (x%7 == 5))
					{x = x - 0.1}								{x}
			});
		});

~scala = byzantine ++ [maj, natural, min, fibo, rara, mik, especial ];

~duras = (0:	#[1,1],
		1: 	#[9,8],
		2: 	#[5,4],
		3:	#[4,3],
		4:	#[3,2],
		5:	#[5,3],
		6:	#[15,8]
	);

// #2 generate main patterns

~plaYer = {|run = false, amp = 1|
		if (run) {if (~buff.class == Buffer) {~buff.close};
		     ~buff = Buffer.cueSoundFile(s, "sounds/PantaScape", 0,2,65536);
			~soundskeip = Synth.new( \stereoplayer,
					[\out, 0, \buffer, ~buff.bufnum, \amp, amp],1,\addToTail);
		}{
			if (~soundskeip.class == Synth) {~soundskeip.free};
			~buff.close; ~buff.free}};

generador = Plazy({|event|
		var nota, anterior, ritmo;
		nota = ~duras[~duras.keys.asArray.sort.wchoose([14,2,4,5,6,3,1].normalizeSum)];
		n = nota;
		ritmo = Array.fill(nota[0], nota[1]/nota[0]);
		Pseq(ritmo,1);
});
genx = Pn(generador, inf);

bajo1 = Pbind(\instrument, \thump, \stepsPerOctave, 72, \scale, ~scala[3],
		\degree, Pwrand(#[0,1,2,3,4,-3,-2,-1,-5], #[7,2,4,5,6,6,3,2,4].normalizeSum, inf),
		\octave, Pwhite(3,5), \root, 6.0,
		\num, Pwhite(1,10),
		\type, Pwrand(#[\note, \rest], #[0.8, 0.2], inf),
		\dur, genx.next,
		\amp, 0.5);


// version con silencios
~anterior = genx.asStream.next;
bajo2 = Pbind(\instrument, \thump, \stepsPerOctave, 72, \scale, ~scala[3],
		\degree, Pwrand(#[0,1,2,3,4,5,6,-3,-2,-1,-5], #[7,2,4,5,6,3,2,6,3,2,4].normalizeSum, inf),
		\octave, Pwrand(#[3,4,5],[0.7, 0.2, 0.1], inf ),
		\num, Pwrand(#[2,0,1,3,4,5,6,7,8,9,10], [40, 2,3,4,5,6,7,8,9,10,11].normalizeSum, inf),
		\type, Pwrand(#[\note, \rest], #[0.65, 0.35], inf),
		\dur, Pfunc({|event| var dur;
				if (event.type == \rest) { dur = ~anterior } {dur = genx.asStream.next};
				~anterior = dur;
//				Post << "ant: "<< ~anterior<< "\n";
				dur}),
		\grnd, Prand(Array.series(10,0.2, 0.2), inf),
		\amp, Pwrand(#[0.65, 0.8], #[0.95, 0.05], inf));
//---------------------------------------

bajoIntro = Pbind(\instrument, \thump, \stepsPerOctave, 72, \scale, ~scala[3],
			\dur, PdurStutter(Pseq(#[8,1,1,2],inf), Pseq(#[4, 1.5, 0.5, 2 ],inf)),
			\degree, Pwrand(#[0,1,2,3,4,-4,-3,-2,-1,-5],
						#[12, 8, 10, 7, 6, 10, 6, 8, 6].normalizeSum, inf),
			\octave, 3,
			\root, 9.0,
			\num, Pwrand(#[2,0,1,3,4,5,6,7], [1,2,3,4,5,6,7,8].normalizeSum, inf),
			\grnd, Pwhite(0.2, 2),
			\amp, Pfunc({|e| var amp; if(e.dur > 0.5) {amp = 0.5} {amp = 0.35}; amp}));



// acompa

acomp = Pbind(\instrument, \zomp, \stepsPerOctave, 72, \scale, ~scala[3],
		\degree, Prand(~acc, inf),
		\type, Pseq(#[\rest, \note], inf),
		\dur, 1,
		\amp, 0.125, \pan, Pwrand(#[-0.4, -0.2, 0, 0.2, 0.4], [3,4,5,4,3].normalizeSum, inf),
		\legato, Pwhite(0.5, 1.5),
		\gtranspose, Pwrand(
					#[-7,-6,-5,-4,-3,-2,-1,0,1,2,3,4,5,6,7],
					[7,6,5,4,3,2,1,2,3,4,5,6,7].normalizeSum,inf),
		\octave, Pwhite(4,6),
		\w, Pwhite(1,8),
		\strum, Pfunc({|e| [e.legato/rrand(70,150), 0.0].wchoose([0.8,0.2])}));

~accomp2 = Pfin(56, Pbindf(acomp,
			\scale, ~scala[11],
			\degree, Prand(~septChrom, inf),
			\octave, Pwrand(#[5,6], #[0.75,0.25],inf),
//			\strum, Pfunc({|e| e.legato/rrand(70,100)}),
			\pan, Pbrown(-0.75,0.75, 0.25)
			)).asEventStreamPlayer;

~bajo = bajo1.asEventStreamPlayer;
~bajo2 = bajo2.asEventStreamPlayer;
~accomp = acomp.asEventStreamPlayer;

~intro = Pser([
			Ptpar([
					0,  Pfin(24, Pstretch(1.5,
						Pbindf(bajoIntro,
							\gtranspose, 5,
							 \amp, 0.4,
							 \octave, Prand(#[3,4,5],inf),
							 \num, Pwhite(0,20) ))),
					13, PfadeIn(Pfin(25, Pstretch(1.25,
						Pbindf(bajoIntro,
							\gtranspose, 4,
							\octave, Pwrand(#[3,4,5], #[0.2, 0.6, 0.2], inf),
							\amp, 0.4))), 4),
					28, PfadeIn(Pfin(46, bajoIntro), 3),
					40, Pfin(19, Pset(\amp, 0.1, acomp))
				], 1),
			Ppar([Pfin(50, bajo2), Pfin(40, Pbindf(acomp,
							\amp, 0.1,
							\scale, ~scala[3]))])
		], 2).asEventStreamPlayer;

// ================================== MELODY

melody = Pbind(\instrument, \melody, \stepsPerOctave, 72, \scale, ~scala[3],
		\degree, Pwrand(#[0,1b,2b,3,4,5b,6], #[6,3,4,3,5,3,3].normalizeSum, inf),
		\type, Pwrand(#[\rest, \note], #[0.3,0.7], inf),
		\dur, PdurStutter(Prand(#[1,2,3,4,5], inf), Pxrand(#[4,3,2,1,0.8,0.5,0.4],inf)),
		\amp, 0.15,
		\length, Pfunc({|e| e.dur * [1.5,2,1].choose}),
		\delay, Pwhite(0.01, 1.95),
		\decay, Pwhite(-10.0,10.0),
		\pan, Pwhite(-1,1),
		\legato, Pwhite(0.5, 1.5),
		\time, Pfunc({|e| e.dur * [1,0.5,1.5,2].choose}),
		\gtranspose, Pwrand(
					#[-7,-6,-5,-4,-3,-2,-1,0,1,2,3,4,5,6,7],
					[7,6,5,4,3,2,1,2,3,4,5,6,7].normalizeSum,inf),
		\octave, Pbrown(4,7,1),
		\y, Pwhite(1,8));
~melos = Pfin(250,melody).asEventStreamPlayer;


~melos2 = Pfindur(30, Pbindf(melody, \scale, ~scala[10],
				\degree, Prand([Pseq(#[0,1b,2b,3],1), Pseq(#[3,4,5b,6],1),
						Pseq(#[0,-1,-2b,-3],1), Pseq(#[5b,4,4b,3,3b],1),
						Prand(#[0,1,2,3,4,5,6],7)],inf),
				\dur, PdurStutter(
					Pseq(#[3,4,5,6], inf), Pxrand(#[3,2,1,0.8,0.5,0.4],inf)),
				\gtranspose, 0)).asEventStreamPlayer;
~melos3 = Pfin(370, Pbindf(melody, \scale, Prand(~scala.flatten, inf),
					\note, Prand(~scala.flatten, inf),
					\amp, Pseries(0.02, 0.2, 350),
					\dur, PdurStutter(
					Pxrand(#[4,5,6,7], inf), Pxrand(#[4,3,2,1,0.8,0.5,0.4],inf)),
					\octave, Pwrand(#[5,6,7,8],#[ 0.15, 0.15, 0.25, 0.45],inf),
					\type, Pseq([
							Pwrand(#[\rest, \note], #[0.8,0.2], 80),
							Pwrand(#[\rest, \note], #[0.6,0.4], 60),
							Pwrand(#[\rest, \note], #[0.2,0.8], 50),
							Pn(\note, inf)], inf))).asEventStreamPlayer;





// <------------------------------Intro pads

acordex = ~sept.degToFreq(9, 5, ~scala[3], 72);
ampitas = [];
20.do{ampitas = ampitas.add({rrand(0.025,0.125)}!4)};
introX = Pbind(\instrument, \klanF, \dur, Pwhite(1,3),
		\length, Prand(#[0.1,0.25,0.5,0.75,1,1.5,2,3],inf),
		\x, Pwhite(0.1,5),
		\i_freq, Prand(acordex[1],inf),
		\offset, Pxrand(acordex[0], inf),
		\freqs, Pxrand(acordex, inf),
		\amps, Pxrand(ampitas, inf),
		\phases, Prand(#[[0,0,0,0],[0.5pi,1pi,1.5pi,0],[0,1pi,0.5pi,1.5pi]],inf),
		\pan, Pwhite(-1,1));

acordex1 = ~secundas.degToFreq(9,4,~scala[3], 72);
introY = Pfin(31,PfadeIn(
			Pbindf(introX, \freqs, Pxrand(acordex1, inf),
				\type, Pwrand(#[\note, \rest], [0.9,0.1], inf),
				\x, Pwhite(1,10),
				\i_freq, Prand(acordex1.last, inf),	// aguas, es nueva
				\length, Prand(#[0.3, 0.5, 0.75, 1, 3], inf),
				\dur, Pwhite(0.5,4),
				\amp, 0.25), 20));
acordex2 = ~sept.degToFreq(9,5, ~scala[3], 72);
introZ = Pfin(55, Pbindf(introX,
				\freqs, Pxrand(acordex2, inf),
				\dur, Pwhite(0.5, 3),
				\amp, 0.07,
				\offset, Prand(acordex1[3], inf),
				\i_freq, Pxrand(#[1,2,3,4,pi,3pi,4pi],inf)));
~accrds = introY.asEventStreamPlayer;
~accrds2 = introZ.asEventStreamPlayer;

~accrdsFinal = Pfin(65, Pbindf(introZ,
					\freq, Pxrand(~acc.degToFreq(1,6,~scala.flatten,72), inf),
					\dur, PdurStutter(Prand(#[1,2,4],inf), Prand(#[3,4,5,6],inf)),
					\type, Pwrand(#[\rest, \note], #[0.7,0.3],inf),
					\amp, Pseries(0.002, 0.015,200),
					\x, Pwhite(0.01, 10),
					\pan, Pwhite(-1,1))).asEventStreamPlayer;

acordex3 = ~acc.degToFreq(9,6, ~scala[9], 72);
~pady = Pfin(72, Pbindf(introX,
				\freqs, Pxrand(acordex3, inf),
				\dur, Pwhite(0.5, 2),
				\i_freq, Prand(acordex3.choose, inf)
		)).asEventStreamPlayer;
~pady2 = Pfin(52, Pbindf(introX,
				\length, Pwhite(0.02,0.5),
				\freqs, Pxrand((acordex3 * 0.0125), inf),
				\dur, Pwhite(0.1,1.25),
				\i_freq, Prand(acordex3.choose*0.01, inf))).asEventStreamPlayer;

zPad = Pbind(\instrument, \padThai, \stepsPerOctave, 72,
		\scale, Pwrand([~scala[3],~scala[5], ~scala[0], ~scala[9]],
					#[10, 7, 4, 2].normalizeSum, inf),
		\degree, Prand(~acc, inf),
		\dur, PdurStutter(Prand(#[0,1,2,4],inf), Pseq(#[4,5,6],inf)),
		\amp, 0.1,
		\root, 2.0,
		\pan, Pwhite(-1,1),
//		\legato, Pwhite(0.5, 1.5),
		\length, Pfunc({|e| e.dur * 2}),
		\gtranspose, Pwrand(
					#[-7,-6,-5,-4,-3,-2,-1,0,1,2,3,4,5,6,7],
					[7,6,5,4,3,2,1,2,3,4,5,6,7].normalizeSum,inf),
		\octave, Pseq([Pn(4,5), Pn(5,7), Pwhite(5,7)], inf),
		\z, Pwhite(1,8));
~zPadd = Pfin(25, zPad).asEventStreamPlayer;

//<--------------------------------- Bassy

bassy = Pbind(\instrument, \thump, \stepsPerOctave, 72, \scale, ~scala[12],
			\dur, PdurStutter(Pseq(#[1,4,1,2,1],inf), Pseq(#[2,2,2,2,2],inf)),
			\degree, Pwrand(#[0,2,4],
						#[10, 2, 2].normalizeSum, inf),
			\octave, Pwrand(#[3,4], #[0.75, 0.25], inf),
			\root, 9.0,
			\n, Pwrand(#[0,1,3,4,5,6,7], [2,3,4,5,6,7,8].normalizeSum, inf),
 			\grnd, Pwhite(0.2, 2),
			\timeScale, Pfunc({|e| var tScale;
					if (e.dur < 1) {tScale = rrand(0.75,1.2)}{tScale = rrand(1.5,2.2)}; tScale}),
			\amp, Pfunc({|e| var amp; if(e.dur > 0.5) {amp = 0.5} {amp = 0.35}; amp}));

~bassy = Pfin(56, bassy).asEventStreamPlayer;
~bassy2 = Pfin(50, Pbindf(bassy, \root, 4, \dur,
				PdurStutter(Prand(#[1,4,2,3,0],inf), Pseq(#[2,2,2,1,1],inf))
						)).asEventStreamPlayer;

groovbass = Pbind(\instrument, \thump, \stepsPerOctave, 72, \scale, ~scala[4],
			\dur, PdurStutter(Prand(#[1,2,3,4], inf), Prand(#[2,3,4,2,1],inf)),
			\degree, Pwrand(#[0,1,2,3,4,5,6], #[7,6,5,4,3,2,1].normalizeSum, inf),
			\root, 9,
			\octave, Pwrand(#[3,4], #[0.75, 0.25], inf),
			\n, Pwrand(#[2,0,1,3,4,5,6,7], [1,2,3,4,5,6,7,8].normalizeSum, inf),
// 			\grnd, Pwhite(0.2, 2),
			\timeScale, Pfunc({|e| var tScale;
					if (e.dur < 1) {tScale = rrand(0.75,1.2)}{tScale = rrand(1.5,2.2)}; tScale}),
			\amp, Pfunc({|e| var amp; if(e.dur > 0.5) {amp = 0.5} {amp = 0.35}; amp}));

~grooveBass = Pfin(88, groovbass).asEventStreamPlayer;

~grBassFin = Ptpar([
				0, Pfin(44,
					Pbindf(groovbass, \dur, Pseq([0.5,0.5,1.5,0.5,0.5,0.5,2/3,2/3,2/3], inf),
						\degree, Pwrand(#[0,1,2b,3,4,5b,6b], #[7,2,5,4,6,3,1].normalizeSum,inf),
						\root, 4,
						\scale, ~scala[5],
						\amp, 0.3, \pan, Pwhite(-0.5,0.5),
						\timeScale, Pwhite(0.75,1.25),
						\octave, Pwrand(#[3,4], #[0.3,0.7], inf))),
				4.575, Pfin(28,
					Pbindf(melody, \dur, Pseq([0.5,0.5,1.5,0.5,0.5,0.5,2/3,2/3,2/3], inf),
						\degree, Pwrand(#[0,1,2b,3,4,5b,6b], #[7,2,5,4,6,3,1].normalizeSum,inf),
						\root, 4, \pan, Pwhite(-0.5,0.5),
						\scale, ~scala[3],
						\type, \note,
						\time, Pwhite(0.75, 1.5),
						\octave, Pwrand(#[6,7,8], #[0.2,0.5, 0.3], inf),
						\amp, 0.075,
						\gtranspose, 0))
				]).asEventStreamPlayer;

solobass = Pbind(\instrument, \thump, \stepsPerOctave, 72, \scale, ~scala[5],
			\dury, PdurStutter(
					Pwrand(#[1,2,2,4], #[0.3, 0.25, 0.15, 0.3], inf),
				 	Pwrand(#[2,4,4,2,1], #[0.3, 0.15, 0.3, 0.15, 0.1], inf)),
			\dur, Pfunc({|e| var dur, sig = false;
							if (sig) {dur = 0.5} {
								if ((i%4 == 0) || (i%4 == 2)) {
									dur = [0.5, 1].choose;
										if (dur == 0.5)												{sig = true}{sig = false}
								}{
									dur = e.dury}
							};
							i = i + 1;
//Post << "i: " << i << "  sig: " << sig << "\n";
							dur}),
			\degree, Pwrand(#[0,1,2,3,4,5,6],
							#[7,3,5,4,6,2,1].normalizeSum, inf),
			\root, 9,
			\gtranspose, Pwrand(#[0,1,2,3,4,5,6], #[7,2,5,4,6,3,1].normalizeSum, inf),
			\octave, Pwrand(#[3,4,5], #[0.65, 0.20, 0.15], inf),
			\n, Pwrand(#[2,0,1,3,4,5,6,7], [8,3,5,5,4,3,2,1].normalizeSum, inf),
 			\grnd, Pwhite(0.2, 2),
			\timeScale, Pfunc({|e| var tScale;
					if (e.dur < 1) {tScale = rrand(0.75,1.2)}{tScale = rrand(1.5,2.2)}; tScale}),
			\amp, Pfunc({|e| var amp; if(e.dur > 0.4) {amp = 0.5} {amp = 0.35}; amp}));

~soloBass = Pfin(88, solobass).asEventStreamPlayer;

~soloBass2 = Pfin(40, Pbindf(solobass,
					\dury, PdurStutter(
					Pwrand(#[3,5,2,4], #[0.3, 0.25, 0.15, 0.3], inf),
				 	Pwrand(#[2,4,6,3,1], #[0.3, 0.15, 0.3, 0.15, 0.1], inf)),
				 	\root, 2)).asEventStreamPlayer;



~acompleitor = Ppar([
				Pfin(24, Pbindf(solobass, \scale, ~scala[10], \root, 2,
					\octave, Pwrand(#[3,4], #[0.7, 0.3], inf),
					\gtranspose, 0,
					\dury, PdurStutter(


								Pseq(#[1,2,4],inf), Pseq(#[2,4,2,1], inf)))),
					 Pfin(20,Pbindf(zPad, \scale, ~scala[10],
				      		\gtranspose, 0,
					       	\octave, Pwrand(#[3,4,5,6,7], #[2,2,4,3,1].normalizeSum, inf)))
			       ]).asEventStreamPlayer;

~ultima = Ppar([
			bassy, Pbindf(zPad, \scale, ~scala[12],
					\root, 9, \amp, 0.035,
					\dur, Prand(#[0.75,1, 1.25], inf),
					\length, 1.5,
					\octave, Prand(#[4,5,6,7],inf))]).asEventStreamPlayer;

//========================
// SynthDefs...
//========================

// acompa
SynthDef(\zomp, {|out = 0, freq = 500, w = 5, amp = 1, pan= 0|
			var sig, sig2, env, panned, y;
			env = EnvGen.kr(Env.linen(0.01,0.05,w/20, amp,\sine), 1, doneAction: 2);
			sig = Impulse.ar(freq);
			sig2 = SinOsc.ar((freq + 2**w)/ w.sqrt,SinOsc.kr(freq/2,pi), 1);
			5.do{sig2 = AllpassN.ar(sig2, 0.02, rrand(0.0005,  0.001*w), -5)};
			sig2 = (sig difsqr: sig2);
			panned = Pan2.ar(Mix.ar([sig2,sig]), pan, env);
			Out.ar(out, panned )
}).store;

// da bass
// da bass nieuwe



SynthDef(\thump, {|out = 0, freq = 500, n = 5, amp = 1, grnd = 1, timeScale = 1, dur = 1|
			var sig, sig2, env, env2;
			env = EnvGen.ar(Env.perc(0.02,0.2,amp,'linear'), 1, timeScale: dur * 1.5, doneAction: 2);
			env2 =EnvGen.ar(Env.perc(0.02,0.5,amp, \lin), 1, timeScale: dur * 0.6);
			sig = SinOsc.ar(freq, 0, 1.5) * env2;
			sig = sig + Resonz.ar(sig, freq * 2.5, grnd, 3);
			sig2 = SinOsc.ar((freq + 2**n)/ n.sqrt,SinOsc.kr(freq/4,pi), 3);
			4.do{ sig2 = AllpassN.ar(sig2, 0.25, 0.25.rand, -0.75)};
			sig2 = (sig ring2: sig2) * env;
			Out.ar(out, (Mix.ar([ sig * 0.8, sig2 * 0.6 ]) * 0.6)!2);
}).store;



//// da bass
//SynthDef(\thump, {|out = 0, freq = 500, num = 5, amp = 1, grnd = 1, timeScale = 1|
//			var sig, sig2, env;
//			env = EnvGen.kr(Env.perc(0.02,0.2,amp,\lin), 1, timeScale: timeScale, doneAction: 2);
//			sig = SinOsc.ar(freq);
//			sig2 = SinOsc.ar((freq + 2**num)/ num.sqrt,SinOsc.kr(freq/2,pi), 3);
//			4.do{ sig2 = AllpassN.ar(sig2, 0.25, 0.25.rand, -0.75)};
//			sig = (sig * 0.7) + Resonz.ar(sig, freq * 3, grnd, 3);
//			sig2 = sig ring4: sig2;
//			Out.ar(out,Mix.ar([sig, sig2] * env)!2)
//}).store;

// harmony synth
SynthDef(\klanF, {|i_freq = 200, offset = 100, x = 2,
				amp = 0.7, out = 0, dur = 1, length = 1, pan = -1|
			var sig1, sig2, outsig1, outsig2, panO;
			var env, env2, form, freqs, amps, phases;
//			env2 = EnvGen.ar(Env.sine(dur * length * 0.5), doneAction: 2);
			env2 = EnvGen.ar(Env.new(
					[0, amp, 0], [(dur * length * 0.75), (dur * length * 0.75)], [-4, 4]),
				doneAction: 2);
			form = Formant.ar(i_freq,
					(i_freq * 2) + offset, (i_freq + offset)/x, 0.035).wrap2(0.8);
			freqs = Control.names([\freqs]).kr(
			[ 285.30470202372, 356.01745305132, 427.47405410764, 533.42346939755 ]);
			amps = Control.names([\amps]).kr(Array.fill(4,0.0));
			phases = Control.names([\phases]).kr([0,0,0,0]);
			env = EnvGen.ar(Env.perc(0.05, dur * length, amp, 5),1, doneAction: 2);
		 	sig1 = Klang.ar(`[freqs, amps, phases]) * env;
			sig2 = Klang.ar(`[freqs, amps, phases], i_freq ,offset);
			panO = SinOsc.kr(pan);
			outsig1 = Pan2.ar(sig1 ring1: sig2, panO);
			outsig2 = Pan2.ar(form ring2: sig2, panO.neg);
			Out.ar(out,Median.ar(6,Mix.ar([outsig1,outsig2 * env2])));
}).store;

// da melodie
SynthDef(\melody, {|out = 0, freq = 500, amp = 1, pan = 0, length = 1, delay = 1,
				y = 5, decay = 3, time = 1|
		var env, sig, dly, left, env2, dly2;
		env2 = EnvGen.kr(Env.perc(0.1, 0.5, 0.1), doneAction:2, timeScale: time);
		env = EnvGen.kr(
			Env.linen(0.1,1, 2, amp,\welch), 1, doneAction:2);
		sig = SinOsc.ar(freq*2, 0, 0.25) ring1: Impulse.ar(freq /2, mul: 0.25);
		sig = Ringz.ar(sig, freq/(2*y), length, 0.75);
		dly  = HPZ1.ar(CombC.ar(sig , 2, delay, decay, 0.01));
		dly = Pan2.ar(dly, pan.neg, env);
		left =  Pan2.ar(sig, pan, env2);
		Out.ar(out, Mix.ar([left, dly]));
}).store;

// da pad
SynthDef(\padThai, {| out = 0, freq = 500, amp = 1, pan = 0, length = 1, z = 3, q = 5, fact = 2 |
		var sig, sig2, osc, salida, env;
		env = EnvGen.kr(Env.sine( length, amp ), doneAction: 2);
		osc = VarSaw.ar(freq, Rand.new(freq/(50*z) , freq/(10*z)), Rand.new(0,1));
		sig  = Resonz.ar(osc, freq*fact, q);
		sig = AllpassC.ar(sig, 0.25, 0.25.rand, 10, 1);			Out.ar(out, Pan2.ar(sig,pan, env));
}).store;

// da soundfile player
SynthDef("stereoplayer",
		{ | out = 0, buffer = 1, amp = 1 | Out.ar(out, DiskIn.ar(2, buffer)*amp)}).store;

tap = {| before = 0| var now;
		if (before == 0) {
			now = Main.elapsedTime
		}{
			now = (Main.elapsedTime - before).reciprocal * 60;
			(now >= 122).if({now = 122});
		};
		now };

tempo = 120;
t = MetronomeGui.new.start(tempo);

score = [{nil},

/*01  */		{t.start(tempo,3); ~accrds.play(t.clock, true, 0);},
/*02  */		{t.start(tempo,1); ~accrds2.play(t.clock, true, 0 )},
/*03  */		{n = tap.(0)},
/*04  */		{t.start(tap.(n), 0); ~grooveBass.play(t.clock,  true, 0)},      //was #3
/*05  */		{t.start(tempo, 0); ~pady.play(t.clock,  true, 0)},              //was #4
/*06  */		{t.start(tempo,0); ~intro.play(t.clock,  true, 0)},              //was #5
/*07  */		{n = tap.(0)},
/*08  */		{t.start(tap.(n), 1);					                            //was #6
			~bassy.play(t.clock,  true, 0); ~melos.play(t.clock,  true, 0)},
/*09  */		{nil},
/*10  */		{/*t.start(tap.(n), 0);*/ ~accomp2.play(t.clock,  true, 0)},         //was #7
/*11  */		{n = tap.(0)},
/*12  */		{t.start(tap.(n), 1); i = 0; ~soloBass.play(t.clock,  true, 0)}, //was #8
/*13  */		{~soloBass.pause;~zPadd.play(t.clock,  true, 0)},                //was #9
/*14  */		{n = tap.(0)},
/*15  */		{t.start(tap.(n), 1); i = 0; ~soloBass2.play(t.clock,  true, 0)},//was #10
/*16  */		{t.start(tempo, 1); ~melos2.play(t.clock,  true, 0)},            //was #11
/*17  */		{n = tap.(0)},
/*18  */		{t.start(tap.(n),1); ~melos2.pause; 		                            //was #12


				i = 0; ~acompleitor.play(t.clock ,  true, 0)},


/*19  */		{~plaYer.(true, 0.8)},                                                //was #13
/*20  */		{~melos3.play(t.clock,  true, 0)},                               //was #14
/*21  */		{~accrdsFinal.play(t.clock,  true, 0)},                          //was #15
/*22  */		{t.start(tempo,1); ~bassy2.play(t.clock,  true, 0)},             //was #16
/*23  */		{~bassy2.pause; ~accrdsFinal.pause; ~melos3.pause;},
/*24  */		{n = tap.(0)},
///*25  */		{t.start(tap.(n), 3); ~grBassFin.play(t.clock,  true, 0)},       //was #17
/*25  */		{t.start(102, 3); ~grBassFin.play(t.clock,  true, 0)},       //was #17
///*26  */		{n = tap.(0)},
/*26  */		{nil},
/*27  */		{t.start(120, 1); ~ultima.play(t.clock,  true, 0) },          //was #18
/*28  */		{~ultima.stop; t.stop },


	{nil}];
PantaGUI.new;
Engine.new(score, "./sounds/*.*", 0.0, 0, 0);
)

/*
s.prepareForRecord;
s.record;
*/
