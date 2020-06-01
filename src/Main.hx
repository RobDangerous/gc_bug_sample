package;

class TestT {
	public var array: Array<Int>;
	public var _t: Int = 0;

	public function new() {
		var size: Int = 6 + Std.random(50);
		array = [for(i in 0...size) 256];
		_t = 0;
	}

	public function init() {
		for (i in 0...10) {
			array = [];
			array.push(Std.random(1280));
			array.push(Std.random(800));
		}
	}
}

class Main {
	static var timeTasks: Array<Void -> Void>;

	static function addTimeTask(task: Void -> Void): Void {
		timeTasks.push(task);
	}
	
	static function executeFrame(): Void {
		var activeTimeTask = timeTasks[0];
		timeTasks.remove(activeTimeTask);
		activeTimeTask();
		timeTasks.push(activeTimeTask);
	}

	public static function main() {
		timeTasks = [];
		addTimeTask(() -> {
			update();
		});

		//init a lot of data
		tests = [];
		for(i in 0...1400) {
			var a = new TestT();
			a.init();
			tests.push(a);
		}

		while (true) {
			executeFrame();
		}
	}

	static var array: Array<Float> = [];

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
	static var tests: Array<TestT>;

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
}
