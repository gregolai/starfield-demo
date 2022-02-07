package
{
	import flash.display.BitmapData;

	public class Star
	{
		// A reference to the main canvas
		private var _canvas:BitmapData;
		
		// 2D positions and velocities
		public var positionX:Number;
		public var positionY:Number;
		public var velocityX:Number;
		public var velocityY:Number;

		// The stars in the Windows 3.1 starfield screensaver start out small and gain a
		// pixel of growth over time. This flag is set initially and is unset when enough
		// time has accumulated, in which case it will be shown as a 2x2 pixel.
		public var isSmall:Boolean;
		public var sizeAccum:Number;

		public function Star(canvas:BitmapData)
		{
			_canvas = canvas;
			
			reset();
		}

		public function reset():void
		{
			var canvasWidth:int = _canvas.width;
			var canvasHeight:int = _canvas.height;
			
			// Set star position to a random coordinate on the canvas
			positionX = Math.random() * canvasWidth;
			positionY = Math.random() * canvasHeight;
			
			// Stars further from the center should naturally have higher velocities. Acceleration
			// will have more of an impact than initial velocity, otherwise stars that spawn near
			// the center will move too slow and become 2x2 pixels too quickly, thus ruining the 3D illusion.
			velocityX = (positionX - (canvasWidth >> 1)) * 0.25;
			velocityY = (positionY - (canvasHeight >> 1)) * 0.25;
			
			// Velocities are modified by multiplication instead of addition, so if both x & y speeds
			// are zero, the star will be stuck at the center. This checks and prevents that.
			if(velocityX == 0 && velocityY == 0)
				velocityX = 1;
			
			isSmall = true;
			sizeAccum = 0;			
		}
	}
}