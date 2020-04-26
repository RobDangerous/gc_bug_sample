package;

import kha.System;

import kha.Assets;
import kha.Framebuffer;
import kha.Scheduler;
import t.TestT;
import t.Base;


class Main {
	public static function main() {
		System.start({title: "hxcpp please", width: 1280,height: 800, window: {	windowFeatures: FeatureMinimizable,	mode: kha.WindowMode.Windowed}}, 
			function (a: kha.Window) {
				init();
			}	
		);
	}
	
	static function init() {
		Assets.loadEverything(() -> {

			//will take something around 2gb in ram 
			take_ram(20);

			Scheduler.addTimeTask(() -> {
				update();
			}, 0, 1/60);

			//init a lot of data
			tests = [];
			for(i in 0...1400) {
				var a = new TestT();
				a.init();
				tests.push(a);
			}

			System.notifyOnFrames((frames) -> {
				render(frames);
			});
		});
	}

	//just to take some space in ram
	static var images: Array<kha.Image>;
	static function take_ram(size: Int): Void {
		images = [];
		for(i in 0...size) {
			images.push(kha.Image.createRenderTarget(4096, 4096));
		}
	}

	static var array: Array<Float> = [];
	static var sound_counter: Int = 5;
	static var last_sound: kha.audio1.AudioChannel;

	static function update(): Void {
		//just some random calculations and allocations to take some time
		array = [];
		for(i in 0...500) {
			array.push(Std.random(1280));
			array.push(Std.random(800));
		}

		allocate_bunch();
	}

	//simple array of poly object
	//I use something like that in my game so here it is
	static var tests: Array<Base>;
	static function allocate_bunch() {
		//bunch of allocations that we are not using
		for(i in 0...250) {
			var a = new TestT();
			a.init();
		}
		
		//a lot of remove and push
		// crashes on push() -> EnsureSize or something like that
		for(i in 0...1000) {
			tests.remove(tests[Std.random(tests.length)]);
			tests.remove(tests[Std.random(tests.length)]);

			var n = new TestT();
			n.init();
			tests.push(n);

			var n2 = new TestT();
			n2.init();
			tests.push(n2);
		}
	}

	static function render(frames: Array<Framebuffer>): Void {
		//simple rendering
		//I have my own g2 implementation, but I found out that it will crash with g2 too

		var g = frames[0].g2;
		g.begin(true, 0xbbbbbb);

		g.end();
	}
}
