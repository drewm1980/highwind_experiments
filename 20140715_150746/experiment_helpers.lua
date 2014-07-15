
takeoffSpeed = 1.0 -- Rad/s, a bit before takeoff.
turbulentSpeed = 2.4 -- Rad/s . speed above which the ball starts moving eratically
normalFlyingSpeed = 2.0

elevationJumpingSpeed = 1.84 -- Rad/s, speed at which (+-0.1) the elevation angle jumps ca 4 deg

function set_carousel_speed(speed)
	if speed==nil then
		print "Speed cannot be nil!!!"
		return
	end
	siemensActuators:stop()
	siemensActuators:getOperation('setCarouselSpeed')(speed)
end

function get_carousel_speed()
	return siemensSensors:provides("data"):last()['carouselSpeedSmoothed']
end

function get_carousel_setpoint()
	return siemensSensors:provides("data"):last()['carouselSpeedSetpoint']
end

require "math"

softlimit = PI -- Rad/s

-- ALWAYS check the return value of this!
function ramp_with(targetSpeed,acceleration)
	dt = .5 -- s
	threshold = acceleration -- Rad/s
	retrys = 10
	if (math.abs(targetSpeed) > softlimit) then
		print "Requested speed is outside the soft limit!"
		return 0
	end
	while true do
		currentSetpoint = get_carousel_setpoint()
		currentSpeed = get_carousel_speed()
		-- check if targetspeed is reached
		if math.abs(currentSetpoint - targetSpeed) < threshold then
			set_carousel_speed(targetSpeed)
			print "Ramp goal achieved!"
			return 1
		end
		-- check if setpoint is reached
		if math.abs(currentSetpoint - currentSpeed) < threshold then
			if currentSetpoint > targetSpeed then
				print "Ramping down..."
				nextspeed = math.max(targetSpeed, currentSetpoint - dt*acceleration)
			else
				print "Ramping up..."
				nextspeed = math.min(targetSpeed, currentSetpoint + dt*acceleration)
			end
			retrys = 10
		else 
			print ("currentSetpoint not reached! Retrying("..tostring(retrys)..")")
			retrys = retrys - 1
		end
		-- check if ramp got stuck
		if retrys <= 0 then
			print ("Aborting ramp! Current Setpoint = "..tostring(currentSetpoint))
			return 0 
		else 
			print ("Target Speed: "..tostring(targetSpeed).." Current Speed: "..tostring(currentSetpoint).." Next Speed: "..tostring(nextspeed))
			set_carousel_speed(nextspeed)
			sleep(dt)
		end	
	end
end

function ramp_to(targetSpeed)
	acceleration = .1
	ramp_with(targetSpeed,acceleration)
end

-- functionGenerator related functions

function set_functionGenerator_properties(functionType,whichDrive,amplitude,offset,frequency,phase)
	
	set_property("functionGenerator","type",functionType)
	set_property("functionGenerator","amplitude",amplitude)
	set_property("functionGenerator","phase",phase)
	set_property("functionGenerator","offset",offset)
	set_property("functionGenerator","frequency",frequency)
	set_property("functionGenerator","whichDrive",whichDrive)
end

-- Stepping from zero to some value
function start_stepping()
	--Set the parameterf of our function generator for a step response
	--stepheight = 3.141/2000 -- Rad/s
	stepheight = PI/10 -- Rad/s
	lowtime = 1 -- seconds.  This is also the hightime.  Make longer than your settling time.
	functionType = 1 -- for square wave
	whichDrive = 1 -- for carousel
	amplitude = stepheight/2.0
	phase =3.2 -- a bit more than PI to make sure we start at 0
	offset = amplitude
	period = 2.0*lowtime
	frequency = 1.0/period

	set_functionGenerator_properties(functionType,whichDrive,amplitude,offset,frequency,phase)
	siemensActuators:start()
	functionGenerator:start()
end

function stop_stepping()
	functionGenerator:stop()
end

function step_around_current_setpoint(stepheight,lowtime)
	--Set the parameterf of our function generator for a step response
	--stepheight = 3.141/20 -- Rad/s
	--lowtime = 4.0 -- seconds.  This is also the hightime.  Make longer than your settling time.

	functionType = 1 -- for square wave
	whichDrive = 1 -- for carousel
	amplitude = stepheight/2.0
	phase =3.1416 -- a bit more than PI to make sure we start at 0
	offset = get_carousel_setpoint()
	period = 2.0*lowtime
	frequency = 1.0/period

	set_functionGenerator_properties(functionType,whichDrive,amplitude,offset,frequency,phase)
	siemensActuators:start() -- make sure actuator are running
	functionGenerator:start() -- start!!
end

function sin_around_current_setpoint(amplitude,frequency)
	--Set the parameterf of our function generator for a step response
	functionType = 0 -- for sin wave
	whichDrive = 1 -- for carousel
	phase = 0 
	offset = get_carousel_setpoint()

	set_functionGenerator_properties(functionType,whichDrive,amplitude,offset,frequency,phase)
	siemensActuators:start()
	functionGenerator:stop() -- make sure the sin will start at currentspeed to avoid jumps 
	print "Starting function generator"
	functionGenerator:start()
end

function sin_around_offset(offset,amplitude,frequency)
	ramp_to(offset) -- avoid jumps
	sin_around_current_setpoint(amplitude,frequency)
end

function step_around_offset(offset,stepheight,lowtime)
	ramp_to(offset) -- avoid jumps
	step_around_current_setpoint(stepheight,lowtime)
end

function stop_FunctionGenerator_and_ramp_to_0()
	--safe stop of the functionGenerator
	functionGenerator:stop()
	ramp_to(0)
	set_functionGenerator_properties(0,0,0,0,0,0)
end

function ramp_to_with_rampGenerator(targetSpeed,acceleration)
	set_property("rampGenerator","acceleration",acceleration)
	set_property("rampGenerator","targetSpeed",targetSpeed)
	rampGenerator:start()
	t = 1.1 * (targetSpeed / acceleration);
	sleep(t)
end
----------------- THE EXPERIMENTS!!!!!!! -------------
function run()
	speedOffset = softlimit/2.0
	if (ramp_to(speedOffset)) then
		ramp_to(0.0)
		return 0
	end
	sleep(10)
	ramp_to(0.0)
end

function run_step_experiment()
	print "Running experimint NAOOOO!"
	sleep(.5)
	start_stepping()
	sleep(21)
	stop_stepping()
end

function run_offset_sin_experiment()
	ramp_to(normalFlyingSpeed) -- Just cause we don't want this included in the sleep time
	frequency = 0.3 -- Hz
	sin_around_offset(normalFlyingSpeed, -- offset
					.07, -- amplitude
					frequency) -- frequency
	periods = 8
	sleeptime = 8.0*1.0/frequency
	print ("Going to sleep for "..tostring(sleeptime).." seconds while function generator runs...")
	sleep(sleeptime)
	stop_FunctionGenerator_and_ramp_to_0()
end

function run_offset_step_experiment()
	step_around_offset(normalFlyingSpeed, -- offset
					.14, -- stepheight
					12) -- lowtime
	sleep(49)
	stop_FunctionGenerator_and_ramp_to_0()
end

function run_steady_state_experiment()
	ramp_to(takeoffSpeed)
	sleep(.5)
	acceleration = .01 -- in rad/s^2
	ramp_with(	turbulentSpeed, -- targetSpeed
			acceleration) -- acceleration
	sleep(10)
	ramp_with(	takeoffSpeed, -- targetSpeed
			acceleration) -- acceleration
	ramp_to(0)
	--stop_FunctionGenerator_and_ramp_to_0()
end

function run_rampGenerator_test()
	
	print "Running experimint NAOOOO!"
	sleep(.5)
	set_property("rampGenerator","acceleration",0.1)
	set_property("rampGenerator","targetSpeed",0.5)
	rampGenerator:start()
	for i=1,100 do
		rampGenerator:stat()
		sleep(.5)
	end
	set_property("rampGenerator","targetSpeed",0.0)
	for i=1,100 do
		rampGenerator:stat()
		sleep(.5)
	end
end

function run_ramp_around_jump_experiment()
	print "Running experimint NAOOOO!"
	sleep(.5)
	dspeed = 0.2
	acceleration = 0.1
	targetSpeed = elevationJumpingSpeed + dspeed
	ramp_to_with_rampGenerator(targetSpeed,acceleration)
	targetSpeed = elevationJumpingSpeed - dspeed
	ramp_to_with_rampGenerator(targetSpeed,acceleration)
	targetSpeed = elevationJumpingSpeed + dspeed
	ramp_to_with_rampGenerator(targetSpeed,acceleration)
	targetSpeed = elevationJumpingSpeed - dspeed
	ramp_to_with_rampGenerator(targetSpeed,acceleration)
	targetSpeed = elevationJumpingSpeed + dspeed
	ramp_to_with_rampGenerator(targetSpeed,acceleration)
	targetSpeed = 0
	ramp_to_with_rampGenerator(targetSpeed,acceleration)
end	
