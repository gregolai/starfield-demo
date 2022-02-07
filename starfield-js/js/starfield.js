var StarField = (function(){

	// Date.now() polyfill
	// 
	Date.now = Date.now || function() { return +new Date; };

	// performance.now() polyfill
	// 
	window.performance = window.performance || (function(){
		var _init = Date.now();
		return {
			now: function(){ return Date.now() - _init; }
		};
	})();

	// VERY lean 2D Vector class
	// 
	function Vec2(x, y){
		this.set(x || 0, y || 0);
	}
	Vec2.prototype = {
		set: function(x, y){
			this.x = x;
			this.y = y;
			return this;
		},
		setVec: function(vec){
			return this.set(vec.x, vec.y);
		},
		add: function(x, y){
			return this.set(this.x + x, this.y + y);
		},
		addVec: function(vec){
			return this.set(this.x + vec.x, this.y + vec.y);
		},
		mul: function(x, y){
			return this.set(this.x * x, this.y * (y !== undefined ? y : x)); // can be scalar
		},
		mulVec: function(vec){
			return this.set(this.x * vec.x, this.y * vec.y);
		},
	};

	// Star class
	// 
	var Star = (function(Vec2){

		// Color trails
		var COLORS = [
			'#82FF1A', // 80's green
			'#05AFEC', // 80's blue
			'#FE0293', // 80's pink
		];

		// Init velocity multiplier when star is reset
		var VEL_INIT_MULTIPLIER = 0.01;

		function Star(spawnRadius){
			this.normal = new Vec2();
			this.pos = new Vec2();
			this.vel = new Vec2();

			this._prevPos = new Vec2();

			this.reset(spawnRadius);
		}
		Star.prototype = {

			update: function(acceleration, proximity){

				// Save previous position
				this._prevPos.setVec( this.pos );

				// Update vel and pos
				this.vel.add( this.normal.x * acceleration, this.normal.y * acceleration );

				this.pos.addVec( this.vel );

				// It's coming right for us! Making 2D look 3D.
				//this.size *= proximity;
				this.size *= proximity + (Math.sqrt(this.vel.x * this.vel.x + this.vel.y * this.vel.y) * 0.001);
			},

			draw: function(ctx, colorful){

				var size = this.size;

				if(colorful){
					ctx.fillStyle = this.color;
					ctx.fillRect(this._prevPos.x - size * 0.5, this._prevPos.y - size * 0.5, size, size);
				}

				ctx.fillStyle = '#ffffff';
				ctx.fillRect(this.pos.x - size * 0.5, this.pos.y - size * 0.5, size, size);
			},

			reset: function(spawnRadius){

				// Spawn star in a random circle within camera bounds
				var angle = Math.random() * (2 * Math.PI);
				var length = Math.random() * spawnRadius;

				this.normal.set(Math.cos(angle), Math.sin(angle));
				
				this.pos.set(this.normal.x * length, this.normal.y * length);

				this.vel.set(this.pos.x * VEL_INIT_MULTIPLIER, this.pos.y * VEL_INIT_MULTIPLIER);

				this.color = COLORS[ Math.floor(Math.random() * COLORS.length) ];

				this.size = 1;
			},
		};

		return Star;
	})(Vec2);

	// Timer object used in the main loop
	// 
	var TimerLoop = (function(){

		// Weight ratio determines how fast we should adjust our previous framerate
		// to smoothe out the framerate changes
		var WEIGHT_RATIO = 0.01;

		// Initial fps
		var INIT_FPS = 30;

		// Delta time weighted across many frames
		var _weightedDeltaTime = 1000.0 / INIT_FPS;

		// Previous frame timestamp
		var _prevTime;

		// Frame function to call on each timer frame
		var _frameFn;

		function start(frameFn){
			_frameFn = frameFn;
			_prevTime = performance.now();

			// We use setTimeout instead of requestAnimationFrame because we
			// want to measure and adjust the framerate. Unfortunately, an async loop
			// is limited in performance depending on the browser's timer queue, versus a
			// "while(true)" synchronous loop with no limits.
			setTimeout(onFrame);
		}

		function onFrame(){

			// Infinite async loop
			setTimeout(onFrame);

			var currentTime = performance.now();
			
			var deltaTime = currentTime - _prevTime;
			
			_weightedDeltaTime = _weightedDeltaTime * (1 - WEIGHT_RATIO) + deltaTime * WEIGHT_RATIO;

			// Calculate FPS
			var fps = Math.floor(1000.0 / _weightedDeltaTime);

			// Call frame function
			_frameFn(deltaTime, fps);

			_prevTime = currentTime;
		}

		return {
			start: start,
			onFrame: onFrame,
		};
	})();

	return (function(Vec2, Star){

		// Constants
		var ACCELERATION_MULTIPLIER = 0.0001;
		var PROXIMITY_MULTIPLIER = 0.00002;

		// Camera bounds
		var _camera = {
			v0: new Vec2(), // top left
			v1: new Vec2(), // bottom right
			rotation: 0,
			containsVec: function(vec){
				var v0 = this.v0;
				var v1 = this.v1;
				return vec.x >= v0.x && vec.x <= v1.x && vec.y >= v0.y && vec.y <= v1.y;
			},
		};
		var _stars 			= [];
		var _starDrawCount 	= 0;
		var _spawnRadius 	= 1;

		// Stats meant to be shown to the user
		var stats = new ko.observable({
			drawnStars: 0,
			bufferedStars: 0,
			actualFPS: 0,
		});

		// Settings meant to be changed by the user
		var settings = {
			colorful: new ko.observable(true),
			
			goalFPS: {
				val: new ko.observable(60),
				min: 2,
				max: 200,
				step: 2,
			},

			acceleration: {
				val: new ko.observable(10),
				min: 0,
				max: 100,
				step: 2,
			},
			
			proximity: {
				val: new ko.observable(50),
				min: 0,
				max: 100,
				step: 2,
			}
		};

		function onResize(rootDom, canvas){

			// Get dom's width and height
			var width = rootDom.clientWidth;
			var height = rootDom.clientHeight;

			// Resize canvas
			canvas.width = width;
			canvas.height = height;

			// Set camera bounds
			var w2 = Math.floor(width * 0.5);
			var h2 = Math.floor(height * 0.5);
			_camera.v0.set(0 - w2, 0 - h2);
			_camera.v1.set(width - w2, height - h2);

			_spawnRadius = Math.min(_camera.v1.x, _camera.v1.y);
		}

		function updateStarCount(fps){

			// Target FPS based on settings. This will determine if we can draw more stars
			var goalFPS = settings.goalFPS.val();

			if(fps > goalFPS){
				_starDrawCount += (fps - goalFPS);
			}
			else if(fps < goalFPS){
				_starDrawCount -= (goalFPS - fps);
				_starDrawCount = Math.max(1, _starDrawCount);
			}

			// Buffer extra stars
			for(var i = _stars.length; i < _starDrawCount; ++i){
				_stars.push(new Star(_spawnRadius));
			}
		}

		function onFrame(ctx, deltaTime, fps){

			// Get specified settings
			var colorful = settings.colorful();

			// 0 - 100 values
			var rawAcceleration = settings.acceleration.val();
			var rawProximity = settings.proximity.val();

			var acceleration = rawAcceleration * ACCELERATION_MULTIPLIER * deltaTime;

			var proxAccelModifier = rawProximity / settings.proximity.max * rawAcceleration / settings.acceleration.max;

			var proximity = 1 + rawProximity * proxAccelModifier * PROXIMITY_MULTIPLIER * deltaTime;

			updateStarCount(fps);

			ctx.save();

			// Draw black space
			ctx.fillStyle = '#000000';
			ctx.fillRect(0, 0, ctx.canvas.width, ctx.canvas.height);

			// Translate camera to center of screen
			ctx.translate(-_camera.v0.x, -_camera.v0.y);

			for(var i =0; i < _starDrawCount; ++i){

				var star = _stars[i];

				if( !_camera.containsVec( star.pos ) ){

					star.reset(_spawnRadius);
				}

				star.update(acceleration, proximity);

				star.draw(ctx, colorful);
			}

			ctx.restore();

			// Update stats
			stats({
				drawnStars: _starDrawCount,
				bufferedStars: _stars.length,
				actualFPS: fps,
			});
		}

		return {
			stats: stats,
			settings: settings,
			start: function(){

				var dom = document.getElementById('sf-root');
				var cvs = document.getElementById('sf-star-canvas')
				var ctx = cvs.getContext('2d');

				// Bind resize listener and trigger initial resize
				window.addEventListener('resize', function(){
					onResize(dom, cvs);
				});
				onResize(dom, cvs);

				// Two-way data binding for knockout js
				ko.applyBindings(this, dom);

				TimerLoop.start(function(deltaTime, fps){

					onFrame(ctx, deltaTime, fps);
				})
			},
		};

	})(Vec2, Star);

})();