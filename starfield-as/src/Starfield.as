package
{

	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.ui.Keyboard;
	
	[SWF(width="640", height="480", frameRate="120")]
	public class Starfield extends Sprite
	{
		private const MINIMUM_STAR_COUNT:int = 50;

		// Number of stars to draw that will change over time, depending on the frame rate.
		private var drawStarCount:int;
		
		// Goal frames-per-second. Starfield will try to create/draw an appropriate number of
		// stars to meet this framerate. Framerate will decrease as more stars are drawn.
		private var goalFPS:int;
		
		// Star's acceleration, for creating the illusion of the stars rushing by
		private var starAcceleration:Number;
		
		// This is how long it takes, in seconds, for the star to grow into a 2x2 pixel,
		// similar to the Windows 3.1 starfield screensaver
		private var starGrowthTime:Number;
		
		// Main canvas for blitting to
		private var canvas:BitmapData;

		// The expandable buffer for placing the stars
		private var starArray:Vector.<Star>;
		
		// Text fields for showing instructions and debug information
		private var debugField:TextField;
		private var instructionField:TextField;
		
		// The timer used for calculating framerate and delta time
		private var timer:PerformanceTimer;
		
		public function Starfield()
		{
			// Set initial values
			drawStarCount = MINIMUM_STAR_COUNT;	
			goalFPS = 45;
			starAcceleration = 1;
			starGrowthTime = 1.5;
			
			// Set the canvas to be the same size as the stage
			canvas = new BitmapData(stage.stageWidth, stage.stageHeight, false, 0x000000);	
			addChild(new Bitmap(canvas));

			// Create an empty vector
			starArray = new Vector.<Star>();

			// Create the debug info textbox to display stats and performance
			var format:TextFormat = new TextFormat("Arial", 12, 0xffff00);
			debugField = new TextField();
			debugField.x = 0;
			debugField.y = 0;
			debugField.autoSize = TextFieldAutoSize.LEFT;
			debugField.defaultTextFormat = format;				
			debugField.background = true;
			debugField.backgroundColor = 0x404080;
			debugField.selectable = true;
			addChild(debugField);
			
			// Create instruction textbox to display keyboard controls
			instructionField = new TextField();
			instructionField.x = canvas.width - 180;
			instructionField.y = 0;
			instructionField.width = 180;
			instructionField.autoSize =  TextFieldAutoSize.LEFT;
			instructionField.defaultTextFormat = format;
			instructionField.background = true;
			instructionField.backgroundColor = 0x404080;
			instructionField.selectable = false;
			instructionField.wordWrap = true;
			instructionField.text =
				"The star-field will draw as many stars to meet the goal framerate. " +
				"The real framerate decreases as more stars are drawn.\n" +
				"-----------------\n" +
				"Controls:\n" +
				"Goal FPS: E / R\n" +
				"Star Acceleration: D / F\n" +
				"Star Growth: C / V\n" +
				"GUI toggle: X";
			addChild(instructionField);

			// Create and initialize the timer with the initial goal framerate
			timer = new PerformanceTimer();
			timer.start(goalFPS);
			
			// Add event listeners for keydown input and frame updating
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
		}

		private function onKeyDown(event:KeyboardEvent):void
		{
			switch(event.keyCode)
			{
				case Keyboard.E:
					// Decrease the goal framerate
					--goalFPS;
					if(goalFPS < 10)
						goalFPS = 10;
					break;
				case Keyboard.R:
					// Increase the goal framerate
					++goalFPS;
					if(goalFPS > 110)
						goalFPS = 110;					
					break;
				case Keyboard.D:
					// Decrease star acceleration
					starAcceleration -= 0.1;
					if(starAcceleration < 0)
						starAcceleration = 0;
					break;
				case Keyboard.F:
					// Increase star acceleration
					starAcceleration += 0.1;
					if(starAcceleration > 10)
						starAcceleration = 10;
					break;
				case Keyboard.C:
					// Decrease star growth time
					starGrowthTime -= 0.1;
					if(starGrowthTime < 0)
						starGrowthTime = 0;
					break;
				case Keyboard.V:
					// Increase star growth time
					starGrowthTime += 0.1;
					if(starGrowthTime > 10.0)
						starGrowthTime = 10.0;
					break;				
				case Keyboard.X:
					// 3-state GUI toggle system
					// 1) Text and backgrounds
					// 2) Text, no background
					// 3) No text, no background
					if(debugField.visible)
					{
						if(debugField.background)
							debugField.background = instructionField.background = false;
						else
							debugField.visible = instructionField.visible = false;
					}
					else
					{
						debugField.visible = instructionField.visible = true;
						debugField.background = instructionField.background = true;
					}
					break;				
			}
		}

		private function onEnterFrame(event:Event):void
		{
			// Tick the timer to signal a frame increase
			timer.tick();
			
			// Get the smoothed fps from the previous tick
			var fps:int = timer.framesPerSecond;
			
			// If our real fps is greater than the goal fps, we can draw more stars in our
			// star field, so increase the number of stars to be drawn
			if(fps > goalFPS)
				drawStarCount += (fps-goalFPS);
			else if(fps < goalFPS)
			{
				// Our fps is suffering, so we must decrease the number of stars drawn
				drawStarCount -= (goalFPS-fps);
				if(drawStarCount < MINIMUM_STAR_COUNT)
					drawStarCount = MINIMUM_STAR_COUNT;
			}
			
			var numStars:int = starArray.length as int;

			// Create as many stars needed to be drawn, if any
			for(var s:int=numStars; s<drawStarCount; ++s)			
				starArray.push(new Star(canvas));
				
			updateAndDrawStars();
			
			debugField.text =
				"Elapsed Seconds: " + timer.elapsedSeconds.toFixed(1).toString() + "\n" +
				"Real FPS: " + fps.toString() + "\n" +
				"Goal FPS: " + goalFPS.toString() + "\n" +
				"Star Acceleration: " + starAcceleration.toFixed(1).toString() + "\n" +
				"Star Growth Time: " + starGrowthTime.toFixed(1).toString() + "\n" +					
				"Stars Drawn: " + drawStarCount.toString() + "\n" +				
				"Stars Buffered: " + starArray.length.toString();
		}
		
		private function updateAndDrawStars():void
		{
			var deltaSeconds:Number = timer.deltaSeconds;
			
			// Create a vector to fill the canvas. All element values are zero (black).
			// NOTE: We give each dimension an extra pixel of padding on the right and bottom because
			// it's faster than checking if 2x2 stars will overflow the edges of the buffer.
			var pixels:Vector.<uint> = new Vector.<uint>( (canvas.width+1) * (canvas.height+1));

			// Go through all stars that will be drawn, updating and drawing them.
			// NOTE: Thousands of stars can be set to be drawn and update/draw functions within it have been
			// expanded for a significant performance boost, resulting in more stars for the same framerate			
			for(var i:int=0; i<drawStarCount; ++i)
			{
				var star:Star = starArray[i];

				// Acceleration creates the illusion of stars getting closer by increasing their
				// velocities as they move away from the center of the stage
				var deltaAcc:Number = 1 + deltaSeconds * starAcceleration;
				star.velocityX *= deltaAcc;
				star.velocityY *= deltaAcc;
				
				// Modify star's position by a velocity step
				star.positionX += star.velocityX * deltaSeconds;
				star.positionY += star.velocityY * deltaSeconds;
				
				// Convert star's position to x & y coordinates
				var pixelX:int = Math.floor(star.positionX);
				var pixelY:int = Math.floor(star.positionY);
				
				// Check if the star is out-of-bounds. If it is, recycle it.
				if(pixelX < 0 || pixelX >= canvas.width || pixelY < 0 || pixelY >= canvas.height)
				{
					star.reset();
					
					// Star has a new position, and therefore a new x & y coordinate
					pixelX = Math.floor(star.positionX);
					pixelY = Math.floor(star.positionY);
				}

				// DRAW STAR
				// Set the pixel at the star's x & y position to white
				var pixelPos:int = pixelX + pixelY * canvas.width;
				pixels[pixelPos] = 0xffffffff;
				if(star.isSmall)
				{
					// If the star is small, increment the size accumulator by delta time
					star.sizeAccum += deltaSeconds;
					
					// If star's size accumulator is large enough, it becomes a 2x2 pixel star
					// on the next loop
					if(star.sizeAccum >= starGrowthTime)
						star.isSmall = false;
				}
				else
				{
					// The star is 2x2 pixels, so set those pixels to the bottom and right as well.
					// NOTE: As stated above, the pixels array has an extra pixel of padding on the
					// bottom and right sides, which helps performance because we don't have to perform
					// buffer overflow checks for 2x2 stars. We know it will fit.
					var nextYPos:int = pixelPos+canvas.width;
					pixels[pixelPos+1] = pixels[nextYPos] = pixels[nextYPos+1] = 0xffffffff;
				}

			}
			
			// Lock canvas, set pixels, unlock canvas - nice and quick
			canvas.lock();
			canvas.setVector(canvas.rect, pixels);			
			canvas.unlock();
		}
	}
}