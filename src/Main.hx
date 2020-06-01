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

class TimeTask {
	public var task: Void -> Bool;
	
	public var start: Float;
	public var period: Float;
	public var next: Float;
	
	public function new() {
		
	}
}

class Scheduler {
	private static var timeTasks: Array<TimeTask>;
	private static var current: Float;
	private static var lastTime: Float;
	private static var startTime: Float = 0;

	public static function init(): Void {
		current = lastTime = realTime();
		timeTasks = [];
		resetTime();
		lastTime = realTime() - startTime;
	}
	
	public static function executeFrame(): Void {
		var now: Float = realTime() - startTime;
		var delta = 0.1;
		var frameEnd: Float = current;
		frameEnd += delta;
		lastTime = frameEnd;
		current = frameEnd;
		executeTimeTasks(frameEnd);
	}

	private static function executeTimeTasks(until: Float) {
		while (timeTasks.length > 0) {
			var activeTimeTask = timeTasks[0];
			if (activeTimeTask.next <= until) {
				activeTimeTask.next += activeTimeTask.period;
				timeTasks.remove(activeTimeTask);
				activeTimeTask.task();
				timeTasks.push(activeTimeTask);
			}
			else {
				break;
			}
		}
	}

	static var lastRealTime: Float = 0.0;

	public static function realTime(): Float {
		lastRealTime += 0.1;
		return lastRealTime;
	}
	
	public static function resetTime(): Void {
		var now = realTime();
		var dif = now - startTime;
		startTime = now;
		for (timeTask in timeTasks) {
			timeTask.start -= dif;
			timeTask.next -= dif;
		}
		current = 0;
		lastTime = 0;
	}
	
	public static function addBreakableTimeTaskToGroup(task: Void -> Bool, start: Float, period: Float): Int {
		var t = new TimeTask();
		t.task = task;
		t.start = current + start;
		t.period = period;
		t.next = t.start;
		timeTasks.push(t);
		return 0;
	}
	
	public static function addTimeTaskToGroup(task: Void -> Void, start: Float, period: Float): Int {
		return addBreakableTimeTaskToGroup(function () {
			task();
			return true;
		}, start, period);
	}
	
	public static function addBreakableTimeTask(task: Void -> Bool, start: Float, period: Float): Int {
		return addBreakableTimeTaskToGroup(task, start, period);
	}
	
	public static function addTimeTask(task: Void -> Void, start: Float, period: Float): Int {
		return addTimeTaskToGroup(task, start, period);
	}
}

class Main {
	public static function main() {
		Scheduler.init();
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

		while (true) {
			Scheduler.executeFrame();
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
