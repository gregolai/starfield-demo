package
{
	import flash.utils.getTimer;

	public class PerformanceTimer
	{
		// Weight ratio determines how fast we should adjust our previous framerate
		// to current delta times. ie: It smoothes the framerate changes.
		private static const WEIGHT_RATIO:Number = 0.1;
		
		// Gets the elapsed seconds since the timer was started
		public function get elapsedSeconds():Number { return _elapsedTime / 1000.0; }
		
		// Gets the delta seconds
		public function get deltaSeconds():Number { return _deltaTime / 1000.0; }
		
		// Calculates the frames-per-second based on the milliseconds-per-frame
		public function get framesPerSecond():int { return _msPerFrame > 0 ? 1000.0 / _msPerFrame : 60; }

		// Elapsed time, in milliseconds
		private var _elapsedTime:int;
		
		// Previous time, in milliseconds
		private var _prevTime:int;
		
		// Delta time per frame, in milliseconds
		private var _deltaTime:int;
		
		// Milliseconds per frame
		private var _msPerFrame:Number;
		
		public function PerformanceTimer()
		{
			_elapsedTime = 0;
			_prevTime = 0;
			_deltaTime = 0;
			_msPerFrame = 0;
		}
		
		// Starts the timer with an initial FPS
		public function start(initialFPS:int):void
		{
			_elapsedTime = 0;
			_prevTime = getTimer();
			_deltaTime = 0;	
			_msPerFrame = 1000.0 / initialFPS;
		}
		
		// Queries the current time to compare with the previous time,
		// computes the delta time and calculates the framerate
		public function tick():void
		{
			var curTime:int = getTimer();
			_deltaTime = curTime - _prevTime;
			_elapsedTime += _deltaTime;
			_prevTime = curTime;
			
			// Adjusts the time-per-second smoothely by using weights to multiply with the previous
			// time-per-frame and the current frame time
			_msPerFrame = _msPerFrame * (1 - WEIGHT_RATIO) + _deltaTime * WEIGHT_RATIO;
		}
		
	}
}