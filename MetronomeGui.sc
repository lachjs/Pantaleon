MetronomeGui {

	var window, text, <>clock, metro;

	*new {|aClock|
		^super.new.init(aClock);
	}

	init {|aClock|
		clock = aClock ? TempoClock.new;
		window = SCWindow.new("Metronome", Rect(890, 0, 190, 200));
		CmdPeriod.add({window.close});
		window.onClose = {metro.stop};
		window.view.decorator = FlowLayout(window.view.bounds);
		text = SCStaticText(window, window.bounds).font_(Font("Lucida Grande",190));
	}

	start { |bpm = 60, silent = true|
		var i, type;
		if (silent) {type = \rest} {type = \note};
		clock.tempo = bpm/60;
		text.string_("");
		window.front;
		i = 0;
		metro = Pbind(\instrument, \default,
				\dur, 1, \degree, 16,
				\legato, 0.01,
				\type, type,
				\amp, Pseq(#[0.125, 0.05, 0.05, 0.05], inf),
				\print, Pfunc({ {text.string_(" " ++ (i%4+1).asString);i = i + 1}.defer(0.1)})
		).asEventStreamPlayer;
		metro.play(clock, quant:1);
	}

	stop {
		Routine {
			metro.stop;
			clock.beatDur.wait;
			window.close;
			clock.clear;
		}.play;
	}

	bpm {|tempo| clock.tempo = tempo/60}
}