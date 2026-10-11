Engine { var <>score, sample, revLev;
	*new	{|score, sample, revLev=0.02, lop=0, drySet=1|
	^super.newCopyArgs(score).init(sample, revLev, lop, drySet)}
	init{|sample, revLev=0.02, lop=0, drySet=1|
var	w1, w2, w3, w4, w4X, w4Y, w5, w6, w7, w8, w9, w10,
	w11, w12, w13, w14, w15,
	w20, w21, w22, w23, timer, j,//23 is free
	w24, buff, w25, w26, w27,
	arr, pth, buffDraw,
	size, laScope, laPuta,
	scope, cnt=0, rev, s, bus, out, seq, tgr, butcnt,
	osCunt, atak;

Server.default = Server.internal;
s = Server.internal;

//-----------------------------------------------------------------------
//----------------------------------------------FUNC REVERB--------------
SynthDef(\reverbz, {|ins=4, inb=2, mod=0|
	var in, src, sig, rev;
	src = In.ar(ins, 2)*((mod*5));
	in  = In.ar(inb, 2)*(0.85);
	rev = In.kr(10, 1);
	sig = (1) * FreeVerb0.ar(in+src, 15);
	Out.ar(0, sig)
	}).load(s);
//-----------------------------------------------------------------------
//----------------------------------------------SOURCE LIVE and SAMPLE---
SynthDef(\sourceA, {|bus=16, gate=1, rev=0.02, amp=1, dry|
	var out;
	out = Mix.ar(AudioIn.ar([1, 2])) * amp;
	out = out * EnvGen.kr(Env.asr(0.1, 1, 0.1), gate, doneAction:2);
	Out.ar(bus, out);			// Out to internal synths
	Out.ar(4, {out * rev}.dup);	// Out to Reverb
	Out.ar(0, {out*K2A.ar(dry)}.dup);		// Dry Out
	}).send(s);
SynthDef(\sourceB, {|bus=16, gate=1, rev=0.02, amp=1, lopit=1, stp=0, dry|
	var out;
	out = PlayBuf.ar(1, 7, 1, loop:lopit, startPos:BufFrames.kr(7)*stp) * amp;
	out = out * EnvGen.kr(Env.asr(0.1, 1, 0.1), gate, doneAction:2);
	Out.ar(bus, out);			// Out to internal synths
	Out.ar(4, {out * rev}.dup);	// Out to Reverb
	Out.ar(0, {out*K2A.ar(dry)}.dup);		// Dry Out
	}).send(s);
//-----------------------------------------------------------------------
//----------------------------------------OSC Button/Amp/Score TriGGer---
SynthDef(\trigmehoney, {
	SendTrig.kr(
		EnvGen.kr(Env.triangle(0.1, 1))
		, 100, 0.9);
	}).send(s);

SynthDef(\amptrigger, {|gate=1, rel=1, thresh=0.1|
	var amp;
	amp = Amplitude.kr(In.ar(16, 1), 0.1, rel, add:thresh.neg);
	SendTrig.kr(
		EnvGen.kr(Env.triangle(0.1, 1), amp);
		, 100, 0.9)
		* EnvGen.kr(Env.asr(0.1, 1, 0.1), gate, doneAction:2);
	}).send(s);

SynthDef(\amptrigger2, {|gate=1, rel=1, thresh=0.1, del=1|
	var amp;
	amp = Amplitude.kr(In.ar(16, 1), 0.1, rel, add:thresh.neg);
	SendTrig.kr(
		EnvGen.kr(Env.triangle(0.1, 1), DelayN.kr(amp, del+1, del));
		, 100, 0.9)
		* EnvGen.kr(Env.asr(0.1, 1, 0.1), gate, doneAction:2);
	}).send(s);

//------------------------------------------La Trigger Happy-----------------------
//atak = {|sel=0, del=0.1, th=0.015, rel=1|
//	[{Routine({1.do({del.wait;
//		tgr = Synth(\amptrigger, [\thresh, th, \rel, rel]);("trigger set - "++del).postln;})}).play },
//	{tgr.set(\gate, 0); "trigger OFF".postln}].at(sel)};

//-----------------------------------------------------------------------
//--------------------------------------------------------------General--
bus  = Bus.audio(s, 2);
CmdPeriod.add({osCunt.remove; OSCresponder.removeAddr(s.addr); w1.close});

//-----------------------------------------------------------------------
//----------------------------------------------------BUILD ME A GIANT---
w1  = SCWindow("KILLA TRIGGA", Rect(1080, 0, 200, 600), border:true).front;
w1.view.background_(Color.yellow(0.2,alpha:0.4));
w2  = SCStaticText(w1, Rect(20, 140, 100, 100)).string_("Index Skip ->")
		.font_(Font("Arial", 10));
w3  = SCNumberBox(w1, Rect(140, 180, 40, 20), "Trigger", 0, 0, 1, 1.0, \linear);
w3.setProperty(\boxColor,Color(0.9, 0.6, 0.6));
w3.setProperty(\align,\center);
w4  = SC2DSlider(w1, Rect(20, 220, 160, 40)).x_(0.5).y_(revLev);
w10 = SCStaticText(w1, Rect(20, 230, 100, 100)).font_(Font("Arial", 16));
w10.string = "src : "++ControlSpec(0, 2, \lin).map(w4.x.value.round(0.01));
w11 = SCStaticText(w1, Rect(115, 230, 100, 100)).font_(Font("Arial", 16));
w11.string = "rev : "++w4.y.value;

//----------------------------------------------------SRC/REV Levels
w4.action_({|op| 	var cs; cs = ControlSpec(0, 2, \lin).map(op.x.value);
				w10.string = "src : "++cs.round(0.01);
				w11.string = "rev : "++op.y.value.round(0.01);
				w8.set(\amp, op.x.value);
				rev.set(\mod, op.y.value);
				});

//----------------------------------------------------SCOPE
scope = SCScope(w1, Rect(10, 300, 180, 100)).bufnum_(12)
	.background_(Color.black(0.2))
	.resize_(1)
	.waveColors_([Color.green(1), Color.green(1.5)]);
scope.xZoom_(45);
scope.yZoom_(1);
scope.style_(0);
/*12*/	s.sendMsg(\b_alloc, 12, 8000, 2);


//----------------------------------------------------SOURCE SELECT - THE PLAYAH
w5 = SCButton(w1, Rect(10, 410, 130, 20));
w5.states=([	["source: live",  Color.blue, Color.yellow(0.1,alpha:0.0)],
			["source: sample",  Color.blue, Color.yellow(0.1,alpha:0.0)]]);
w26 = SCButton(w1, Rect(145, 410, 45, 20));
w26.states=([	["bypass", Color.red(0.7), Color.yellow(0.1,alpha:0.0)],
			["thru", Color.green(0.3, 0.5, 0.1), Color.yellow(0.2,alpha:0.0)]]);
w26.value = drySet;
w26.action = {w8.set(\dry, w26.value;)};

w6 = SCButton(w1, Rect(20, 440, 100, 20)).states_(
	[["start sample", Color.white, Color(0.2, 0.55, 0.1)],
	["stop sample", Color.white, Color(0.55, 0.0, 0.3)]]).visible_(false);
w9 = SCButton(w1, Rect(130, 440, 50, 20)).states_(
	[["load", Color.white, Color(0.1, 0.0, 0.55)]]).visible_(false);
w25 = SCPopUpMenu(w1, Rect(20, 465, 160, 20)).visible_(false);

/*07*/	buff = Buffer.alloc(s, 44100, bufnum:7);
/*07*/	Buffer.read(s, sample, bufnum:7);

laPuta = {arg tell;
	laScope = SCScope(w1, Rect(10, 490, 180, 50)).bufnum_(7)
	.background_(Color.yellow(0.1,alpha:0.0))
	.xZoom_(tell)
	.resize_(1)
	.waveColors_([Color.black(10), Color.black(10.5)])
	};
laPuta.value(buff.numFrames).visible_(false).enabled_(false);
buff.updateInfo({|buf| {var size; size = buf.numFrames/180;
	laScope.xZoom = size; ScopeOut.kr(size, 7);}.defer;});
w27 = SCRangeSlider(w1, Rect(10, 490, 180, 50)).visible_(false);
w27.lo_(0);w27.hi_(1);
w27.action = {w27.hi_(1);w27.lo;};
//----------------------REDRAW THE SCOPE VIEW fn
buffDraw = {	var str;
			laScope.visible = false;w27.visible = false;
			str = SCStaticText(w1, Rect(70, 467, 100, 100)).font_(Font("Arial", 16)).string_("loading . . .");
			Routine({1.do({1.wait;
			buff.updateInfo({|buf| {var size; size = buf.numFrames/180;
						laScope.xZoom = size; ScopeOut.kr(size, 7);
						laScope.visible = true;w27.visible = true;
						str.visible_(false);}.defer;
			});
			})}).play;};

w5.action = {
	(w5.value == 1).if ({
	{//----------------IF SOURCE: SAMPLE
			w6.visible  = true;
			w9.visible  = true;
			w25.visible = true;
			w27.visible = true;
			laScope.visible = true;
			w9.action = {File.openDialog(" puta " , {arg path;
							Buffer.read(s, path, bufnum:7);
							buffDraw.value;
								})};
			w6.action = {(w6.value == 1).if (
					{w8=Synth.head(0, \sourceB, [\lopit, lop, \amp, w4.x.value,
										\stp, w27.lo.value, \dry, w26.value])},
					{w8.set(\gate, 0);})};
		}.defer;
			w8.set(\gate, 0);
			buffDraw.value;
			pth = ((sample.dirname)++"/*").pathMatch;pth;
			arr = Array.new(pth.size);
			do(pth.size, {|i|
				arr = arr.add(pth.at(i).basename)});
			w25.items = arr.value;
	},{//----------------IF SOURCE: LIVE
			(w8 == nil).if({"si esta nil".postln}, {w8.set(\gate, 0);});
			w8=Synth.head(0, \sourceA, [\amp, w4.x.value, \dry, w26.value]);
			w6.visible  = false;
			w9.visible  = false;
			w25.visible = false;
			w27.visible = false;
			laScope.visible = false;
	})
};

w25.action = {
			buff = Buffer.read(s, sample.dirname++"/"++arr.at(w25.value), bufnum:7);
			buffDraw.value;
			};

//----------------------------------------------------EGG TIMER
w20 = SCStaticText(w1, Rect(55, 6, 50, 20)).font_(Font("Arial", 20));
w21 = SCStaticText(w1, Rect(5, 6, 40, 20)).font_(Font("Arial", 20));
w22 = SCButton(w1, Rect(100, 8, 50, 15))
	.states_([["- - -",  Color.blue, Color.yellow(0.1,alpha:0.0)]]);
w20.string = ":00";w20.setProperty(\align,\left);
w21.string = "00";w21.setProperty(\align,\right);

timer = Routine({
			var min=0, sec=00, cnt;
			w22.action_({min=0; sec=0;});
			inf.do({
				(sec == 59).if({min = min+1; sec = 0;}, {sec = sec+1;});
				cnt = ": "++sec;
				{w21.string = min; w20.string = cnt;}.defer;
				1.wait;
			})}).play(SystemClock);

w3.value = 0;

//----------------------------------------------------AMP TRIGGER
w12 = SCButton(w1, Rect(20, 140, 160, 20))
	.states_([["AmpTrig   <dissabled>",  Color.blue, Color.yellow(0.1,alpha:0.0)],
			 ["AmpTrig   <enabled>", Color.white, Color.green(0.5,alpha:0.5)]])
	.action_({
			(w12.value == 0).if({tgr.set(\overide, 0.postln)}, {tgr.set(\overide, 1.postln)});
			});

//----------------------------------------------------DA BIG RED BUTTON
w24 = SCStaticText(w1, Rect(23, 30, 160, 100)).font_(Font("Arial", 40))
		.stringColor_(Color.white).string_("trigger").align_(\center);
w15 = SCButton(w1, Rect(20, 30, 160, 100))
	.states_([[" ", Color.white, Color(0.55, 0.0, 0.1)]])
	.action_({|btn|	// btn?
			Synth(\trigmehoney);
		});



//----------------------------------------------------RECEIVE an Amptrigger
osCunt = OSCresponderNode(s.addr, '/tr', {|time,resp,msg|
			(msg[2].asInteger == 100).if(
				{
				cnt = w3.value + 1;
				{	w3.value = cnt.value;
					w24.string = (cnt.value).asString;
					}.defer;
				out = (score.wrapAt(cnt.value.asInteger).value);
				});
			}).add;
//----------------------------------------------------INIT SRC/REV
Routine({1.wait;
	rev = Synth.head(1, \reverbz, [\inb, 2, \rev, 3]);
	w8  = Synth.head(0, \sourceA, [\dry, drySet]);
	{rev.set(\mod, w4.y.value);}.defer;
	}).play;


^out;
}
}




//--a.k.a. FreeVerb1

FreeVerb0 { *ar
{  arg  in, revTime = 3, hfDamping = 0.995,
   numTaps = 10, numCombs = 8, numAllpasses = 4,
   tapScale = 1, combScale = 1, allpassScale = 1;


 var buffer,  // a buffer for the delay line
  tapData,  // Early reflection tap data (times, levels)
  times, levels,
  tapsOut,   // output from the delay taps
  combData,   // Table of comb data (times, levels)
  allpassData,  // delayTimes for allpasses (times left, times right)
  usedAllpassData,

  combs,  // Array of comb objects
  combsOut,  // their sound output
  allPassIO,  // allPass chain in/out variable
  inMono;  // input signal is converted to mono if necessary.

 var timeOneSample;  // used for comb average-filtering;

 timeOneSample = 44100.reciprocal;

// Initialize the tap table for early reflections

tapData =
 // delay     amplitude Moorer/Loy numbers as quoted in Pope, SC Tutorial...
 [ [0.0046, 0.841],
  [0.0218, 0.504],
  [0.0268, 0.379],
  [0.0298, 0.346],
  [0.0485, 0.272],
  [0.0572, 0.192],
  [0.0595, 0.217],
  [0.0708, 0.181],
  [0.0741, 0.142],
  [0.0797, 0.134]];

// Initialize comb table for longer reverberations

combData =
 // delay amplitude
 [ [0.0253061, 0.46],  // orig was 0.050, 0.056, etc;
  [0.0269388, 0.48],  // last digit added by AdC to avoid a
  [0.0289569, 0.50],  // large common multiple, 0.001, which
  [0.0307483, 0.52],  // a slightly ringing tone in the reverb.
  [0.0322449, 0.53],
  [0.0338095, 0.55],
  [0.0353061, 0.56],
  [0.0366667, 0.57]
  ];

// Initialize allpass delay times:
        // primeNumber based delayTimes generated with:
         // [ 146, 174, 220, 244].collect({ arg each; each.nthPrime/32380 })
        // [ 160, 183, 208, 229]...
allpassData =
 [ 0.0126077,
   0.01,
   0.00773243,
   0.00510204 ];


// mix input down to mono if necessary:

// inMono = if(in.size > 0, { Mix.ar(in) }, { in });

// inMono = OnePole.ar(inMono, 0.6);  // round off reverb signal.

//// Create a multi-tap delay line:
// if (numTaps > 0,
//  {  #times, levels = tapData.copyRange(0, (numTaps - 1).min(tapData.size)).flop;
//   tapsOut = MultiTap.ar(`times, `levels, in);
//  },
//  {  tapsOut = 0 }
// );

// Create an array of 6 combs:
 combsOut = in;    // initialize combs output first,
 numCombs.min(combData.size).do({arg index;
  var time, level;
  #time, level = combData.at(index);
     // Get comb signal, scale by each comb's level and sum them up.
 combsOut = LeakDC.ar(CombL.ar(
   in,  // + tapsOut,
   0.1,
   (time * combScale).round(timeOneSample) + (hfDamping * timeOneSample/2),
   revTime,
   level,
   combsOut), 0.995)
 });

// Put the output through two parallel chains of allpass delays:


 allPassIO = combsOut;       // initialize daisy-chain variable

 if (numAllpasses > 0,
  {
   usedAllpassData = allpassData.copyRange(0, (numAllpasses - 1).min(allpassData.size));
    usedAllpassData.do({ arg each;
     allPassIO = AllpassN.ar(
	     allPassIO,   // use same variable name for in- and output,
	     each,         // maxDelayTime
	     each,         // one allpass comb per channel,
	    1)
    });         // 1 second decay time is fixed;
            // simply because it sounds better to me.
  });

 ^allPassIO
 }
}
