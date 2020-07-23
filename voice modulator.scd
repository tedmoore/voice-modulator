(  // <-- put cursor to the left of double slashes, hold COMMAND, push RETURN
s.options.device_("Lexicon Alpha In/Out");
s.waitForBoot({
	Task({
		~bus = Bus.audio(s,2);

		SynthDef(\Auto_Tune,{
			arg autoTuneFreq = 200, outBus, mix = 0, vol = 0;
			var in, freq, hasFreq, a, b, chain1, chain2, out;
			in = In.ar(outBus,2);
			//in = DelayC.ar(in,1,1);

			# freq, hasFreq = Pitch.kr(Mix(in),261);
			SendReply.kr(Impulse.kr(40),"/ea_freq",freq.lag(0.03));
			//freq.poll(label:"in freq");
			//autoTuneFreq.poll(label:"AT freq");
			a = LocalBuf.new(2048);
			b = LocalBuf.new(2048);
			chain1 = FFT(a, Blip.ar(autoTuneFreq));
			//chain1 = FFT(a,Saw.ar(autoTuneFreq.lag(0.03)));
			chain2 = FFT(b, Mix(in));
			//chain2 = PV_PartialSynthF(chain2);
			chain1 = PV_SpectralMap(chain1, chain2, 0.0, 0, 2, 1);
			out = IFFT(chain1);
			out = Compander.ar(out,in,-50.dbamp,1000,1);
			out = out * 36.dbamp;
			//out = Limiter.ar(out,-10.dbamp);

			out = out * vol.dbamp;
			out = SelectX.ar(mix.lag(0.03),[in,out.dup]);
			ReplaceOut.ar(outBus,out);
		}).add;

		~possibleFreqs = Array.fill(5,{
			arg i;
			[0,2,4,7,9] + (i * 12) + 24;
		}).flatten.midicps;

		OSCdef(\ea_freq,{
			arg msg;
			var atf;
			atf = ~possibleFreqs[~possibleFreqs.absdif(msg[3]).minIndex];
			//atf.postln;
			~synths.at(\Auto_Tune).set(\autoTuneFreq,atf);
		},"/ea_freq");

		SynthDef(\Laurie_Anderson,{
			arg outBus, mix = 0, vol = 0;
			var in, sig;
			in = In.ar(outBus,2);

			sig = PitchShift.ar(in,pitchRatio:0.5, mul: 10.dbamp);

			sig = sig * vol.dbamp;
			sig = SelectX.ar(mix.lag(0.03),[in,sig]);
			ReplaceOut.ar(outBus,sig);
		}).add;

		SynthDef(\Feminine,{
			arg outBus,mix,vol;
			var in, sig;
			in = In.ar(outBus,2);

			sig = PitchShift.ar(in,pitchRatio:5.midiratio,timeDispersion:0.05);
			sig = Mix(MidEQ.ar(sig,[8000,11000,17000],0.5,13));
			sig = Mix(MidEQ.ar(sig,[500,1500,2500,3500],0.7,-8));
			sig = sig * -12.dbamp;

			sig = sig * vol.dbamp;
			sig = SelectX.ar(mix.lag(0.03),[in,sig]);
			ReplaceOut.ar(outBus,sig);
		}).add;

		SynthDef(\Death_Aging,{
			arg outBus,mix,vol;
			var in, sig, delay, dry;
			in = In.ar(outBus,2);

			dry = Decimator.ar(in,7000);
			sig = dry + LocalIn.ar(1);
			delay = DelayL.ar(sig,1,LFDNoise0.ar(4.reciprocal.dup(4)).range(0.1,1));
			//delay = PitchShift.ar(delay,pitchRatio:-0.5.midiratio);
			delay = Decimator.ar(delay,LFDNoise0.ar(4.reciprocal.dup(4)).range(3500,7000));
			delay = LPF.ar(delay,5000);
			delay = Mix(delay)/4;
			LocalOut.ar(delay * -1.dbamp);
			sig = delay + dry;

			sig = sig * vol.dbamp;
			sig = SelectX.ar(mix.lag(4),[in,sig]);
			ReplaceOut.ar(outBus,sig);
		}).add;

		SynthDef(\Disaster,{
			arg outBus,mix,vol,inAmp,sigAmp,gbs,lowRumble,reverb,delay,dry;
			var in, sig;
			in = In.ar(outBus,2);
			sig = Mix(in)/2;
			// *********************************
			sig = DelayN.ar(sig,0.08,0.08);
			inAmp = Amplitude.kr(sig);
			sig = DelayC.ar(sig,0.1,LFDNoise3.kr(0.2).range(0.05,0.1));
			sig = CrossoverDistortion.ar(sig,0.4,0.7,inAmp * 38.dbamp);
			sig = sig * -14.dbamp;
			sigAmp = Amplitude.kr(sig);
			gbs = Mix(GbmanL.ar(LFDNoise0.kr(Rand(0.5.dup(7),3)).range(10000,20000))) * sigAmp;
			lowRumble = MoogFF.ar(BrownNoise.ar,LFNoise0.kr(0.5).range(50,200).lag(1),2,0,10.dbamp);

			reverb = LPF.ar(Mix(GVerb.ar(in,250,2.2,drylevel:0,mul:-2.dbamp)),2500);
			sig = sig + gbs;
			delay = Mix(HPF.ar(CombC.ar(sig,0.5,LFDNoise0.kr(Rand(0.5,1.dup(3))).range(0.1,0.5),3),Rand(2000,4000.dup(3))))/3;
			sig = sig + reverb + delay + lowRumble;
			sig = sig.dup * -28.dbamp;
			dry = BPF.ar(in,1500,0.1,29.dbamp);
			sig = Mix([sig,dry.dup])/2;
			sig = sig * 4.dbamp;
			// ******************************
			sig = sig * vol.dbamp;
			sig = SelectX.ar(mix.lag(4),[in,sig]);
			ReplaceOut.ar(outBus,sig);
		}).add;

		SynthDef(\MASTER,{
			arg outBus,mix,vol;
			var in;
			in = In.ar(outBus,2);
			in = in * vol.dbamp * mix.lag(0.03);
			Out.ar(0,in);
		}).add;

		s.sync;

		~winWidth = 800;
		~winHeight = 400;
		~win = Window("The Life and Times of Eric F. Avery",Rect(
			(Window.screenBounds.width-~winWidth)/2,
			(Window.screenBounds.height-~winHeight) * 0.75,
			~winWidth,
			~winHeight
		));
		~win.view.decorator_(FlowLayout(~win.bounds));
		~names = [
			\Laurie_Anderson,
			\Feminine,
			\Auto_Tune,
			\Death_Aging,
			\Disaster,
			\MASTER
		];
		~toggles = [];
		~vols = [];
		~synths = Dictionary.new;

		~names.do({
			arg name, i;
			var cv, sl;
			cv = CompositeView(~win,Rect(0,0,(~win.bounds.width/6)-5,~win.bounds.height));
			cv.decorator_(FlowLayout(cv.bounds,0@0,0@0));
			StaticText(cv,Rect(0,0,cv.bounds.width,20)).string_(name.asString+"("++(i+1).asString++")").align_(\center);
			~toggles = ~toggles.add(
				Button(cv,Rect(0,0,cv.bounds.width,40))
				.states_([["OFF",Color.black,Color.red],["ON",Color.black,Color.green]])
				.action_({
					arg b;
					~synths.at(name).set(\mix,b.value);
				});
			);

			~vols = ~vols.add(
				sl = EZSlider(cv,Rect(0,0,cv.bounds.width,cv.bounds.height-68),"Vol",\db.asSpec,{
					arg sl;
					~synths.at(name).set(\vol,sl.value);
				},0,layout:'vert')
			);

			sl.labelView.align_(\center);
			if(i == 5,{sl.sliderView.background_(Color.yellow)},{sl.sliderView.background_(Color.cyan)});

			~synths.put(name,
				if(i > 0,{
					Synth(name,[\vol,0,\outBus,~bus,\mix,0],~synths.at(~names[i-1]),\addAfter);
					},{
						Synth(name,[\vol,0,\outBus,~bus,\mix,0]);
				});
			);
		});

		SynthDef(\ea_in,{
			arg outBus;
			var in;
			in = SoundIn.ar(1);
			Out.ar(outBus,in.dup);
		}).play(~synths.at(~names[0]),[\outBus,~bus],\addBefore);

		s.sync;

		~win.view.keyDownAction_({
			arg view, char, modifiers, unicode, keycode, key;
			var toggleNumbers, volNumbers;
			toggleNumbers = (49..54);
			volNumbers = [
				113,
				97,
				119,
				115,
				101,
				100,
				114,
				102,
				116,
				103,
				121,
				104
			];
			//unicode.postln;
			if(toggleNumbers.includes(unicode),{
				var i = toggleNumbers.indexOf(unicode);
				~toggles[i].valueAction_(~toggles[i].value.neg+1);
			});
			if(volNumbers.includes(unicode),{
				var i, sl, dir;
				i = volNumbers.indexOf(unicode);
				sl = (i/2).floor;
				dir = i % 2;
				/*"index".post; i.postln;
				"which slider".post; sl.postln;
				"direction".post; dir.postln;
				"".postln;*/
				if(dir == 0,{
					~vols[sl].valueAction_(~vols[sl].value+1);
					},{
						~vols[sl].valueAction_(~vols[sl].value-1);
				});
			});
		});

		~win.onClose_({
			OSCdef(\ea_freq).free;
			s.quit;
		});
		s.meter;
		~win.front;
	}).play(AppClock);
});
)