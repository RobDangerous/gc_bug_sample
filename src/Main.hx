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

		for(i in 0...10) {
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
	public var duration: Float;
	public var next: Float;
	
	public var id: Int;
	public var groupId: Int;
	public var active: Bool;
	public var paused: Bool;
	
	public function new() {
		
	}
}

class Scheduler {
	private static var timeTasks: Array<TimeTask>;
	private static var pausedTimeTasks: Array<TimeTask>;

	private static var current: Float;
	private static var lastTime: Float;
	
	private static var frame_tasks_sorted: Bool;
	private static var stopped: Bool;

	private static var onedifhz: Float;

	private static var currentFrameTaskId: Int;
	private static var currentTimeTaskId: Int;
	private static var currentGroupId: Int;

	private static var DIF_COUNT = 3;
	private static var maxframetime = 0.5;
	
	private static var deltas: Array<Float>;
	
	private static var startTime: Float = 0;
	
	private static var activeTimeTask: TimeTask = null;
	
	public static function init(): Void {
		deltas = new Array<Float>();
		for (i in 0...DIF_COUNT) deltas[i] = 0;
		
		stopped = true;
		frame_tasks_sorted = true;
		current = lastTime = realTime();

		currentFrameTaskId = 0;
		currentTimeTaskId  = 0;
		currentGroupId     = 0;
		
		timeTasks = [];
		pausedTimeTasks = [];
	}
	
	public static function start(restartTimers : Bool = false): Void {
		var hz = 60;
		onedifhz = 1.0 / hz;

		stopped = false;
		resetTime();
		lastTime = realTime() - startTime;
		for (i in 0...DIF_COUNT) deltas[i] = 0;
		
		if (restartTimers) {
			for (timeTask in timeTasks) {
				timeTask.paused = false;
			}
		}
	}
	
	public static function stop(): Void {
		stopped = true;
	}
	
	public static function isStopped(): Bool {
		return stopped;
	}

	public static function executeFrame(): Void {
		var now: Float = realTime() - startTime;
		var delta = now - lastTime;
		
		var frameEnd: Float = current;
		
		if (delta >= 0) {
			//tdif = 1.0 / 60.0; //force fixed frame rate
			
			if (delta > maxframetime) {
				startTime += delta - maxframetime;
				delta = maxframetime;
				frameEnd += delta;
			}
			else {
				var realdif = onedifhz;
				while (realdif < delta - onedifhz) {
					realdif += onedifhz;
				}
				
				delta = realdif;
				for (i in 0...DIF_COUNT - 2) {
					delta += deltas[i];
					deltas[i] = deltas[i + 1];
				}
				delta += deltas[DIF_COUNT - 2];
				delta /= DIF_COUNT;
				deltas[DIF_COUNT - 2] = realdif;
				
				frameEnd += delta;
			}

			lastTime = frameEnd;
			if (!stopped) { // Stop simulation time
				current = frameEnd;
			}
			
			// Extend endpoint by paused time (individually paused tasks)
			for (pausedTask in pausedTimeTasks) {
				pausedTask.next += delta;
			}

			if (stopped) {
				// Extend endpoint by paused time (running tasks)
				for (timeTask in timeTasks) {
					timeTask.next += delta;
				}
			}

			executeTimeTasks(frameEnd);
		}
	}

	private static function executeTimeTasks(until: Float) {
		while (timeTasks.length > 0) {
			activeTimeTask = timeTasks[0];
			
			if (activeTimeTask.next <= until) {
				activeTimeTask.next += activeTimeTask.period;
				timeTasks.remove(activeTimeTask);
				
				if (activeTimeTask.active && activeTimeTask.task()) {
					if (activeTimeTask.period > 0 && (activeTimeTask.duration == 0 || activeTimeTask.duration >= activeTimeTask.start + activeTimeTask.next)) {
						insertSorted(timeTasks, activeTimeTask);
					}
				}
			}
			else {
				break;
			}
		}
		activeTimeTask = null;
	}

	public static function time(): Float {
		return current;
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
		for (i in 0...DIF_COUNT) deltas[i] = 0;
		current = 0;
		lastTime = 0;
	}
	
	public static function generateGroupId(): Int {
		return ++currentGroupId;
	}
	
	public static function addBreakableTimeTaskToGroup(groupId: Int, task: Void -> Bool, start: Float, period: Float = 0, duration: Float = 0): Int {
		var t = new TimeTask();
		t.active = true;
		t.task = task;
		t.id = ++currentTimeTaskId;
		t.groupId = groupId;

		t.start = current + start;
		t.period = 0;
		if (period != 0) t.period = period;
		t.duration = 0; //infinite
		if (duration != 0) t.duration = t.start + duration;

		t.next = t.start;
		insertSorted(timeTasks, t);
		return t.id;
	}
	
	public static function addTimeTaskToGroup(groupId: Int, task: Void -> Void, start: Float, period: Float = 0, duration: Float = 0): Int {
		return addBreakableTimeTaskToGroup(groupId, function () {
			task();
			return true;
		}, start, period, duration);
	}
	
	public static function addBreakableTimeTask(task: Void -> Bool, start: Float, period: Float = 0, duration: Float = 0): Int {
		return addBreakableTimeTaskToGroup(0, task, start, period, duration);
	}
	
	public static function addTimeTask(task: Void -> Void, start: Float, period: Float = 0, duration: Float = 0): Int {
		return addTimeTaskToGroup(0, task, start, period, duration);
	}

	private static function getTimeTask(id: Int): TimeTask {
		if (activeTimeTask != null && activeTimeTask.id == id) return activeTimeTask;
		for (timeTask in timeTasks) {
			if (timeTask.id == id) {
				return timeTask;
			}
		}
		for (timeTask in pausedTimeTasks) {
			if (timeTask.id == id) {
				return timeTask;
			}
		}
		return null;
	}

	public static function pauseTimeTask(id: Int, paused: Bool): Void {
		var timeTask = getTimeTask(id);
		if (timeTask != null) {
			pauseRunningTimeTask(timeTask, paused);
		}
		if (activeTimeTask != null && activeTimeTask.id == id) {
			activeTimeTask.paused = paused;
		}
	}

	private static function pauseRunningTimeTask(timeTask: TimeTask, paused: Bool): Void {
		timeTask.paused = paused;
		if (paused) {
			timeTasks.remove(timeTask);
			pausedTimeTasks.push(timeTask);
		}
		else {
			insertSorted(timeTasks, timeTask);
			pausedTimeTasks.remove(timeTask);
		}
	}
	
	public static function pauseTimeTasks(groupId: Int, paused: Bool): Void {
		for (timeTask in timeTasks) {
			if (timeTask.groupId == groupId) {
				pauseRunningTimeTask(timeTask, paused);
			}
		}
		if (activeTimeTask != null && activeTimeTask.groupId == groupId) {
			activeTimeTask.paused = paused;
		}
	}

	private static function insertSorted(list: Array<TimeTask>, task: TimeTask) {
		for (i in 0...list.length) {
			if (list[i].next > task.next) {
				list.insert(i, task);
				return;
			}
		}
		list.push(task);
	}
}

class Main {
	public static function main() {
		init();
	}
	
	static function init() {
		Scheduler.init();
		Scheduler.start();
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
	static var sound_counter: Int = 5;

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
