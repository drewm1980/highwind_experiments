
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

function get_rampGenerator_rampstatus()
	return rampGenerator:provides("info"):last()
end

function wait_till_ramp_is_done()
	str = get_rampGenerator_rampstatus()
	while true do
		sleep(0.1)
		str = get_rampGenerator_rampstatus()
		print( str )
		if  str == "Ramp goal achieved! Stoping rampGenerator..." then
			return
		end 
	end
	print( str )
	--rampGenerator:stop()
end

require "math"

softlimit = PI -- Rad/s


function ramp_with(targetSpeed,acceleration)
	set_property("rampGenerator","acceleration",acceleration)
	set_property("rampGenerator","targetSpeed",targetSpeed)
	rampGenerator:start()
	wait_till_ramp_is_done()
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
	phase = 3.1416 -- a bit more than PI to make sure we start at 0
	offset = get_carousel_setpoint()
	period = 2.0*lowtime
	frequency = 1.0/period

	set_functionGenerator_properties(functionType,whichDrive,amplitude,offset,frequency,phase)
	siemensActuators:start() -- make sure actuator are running
	functionGenerator:stop() -- make sure the sin will start at currentspeed to avoid jumps 
	print "Starting function generator"
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
	fast_ramp(offset) -- avoid jumps
	sin_around_current_setpoint(amplitude,frequency)
end

function step_around_offset(offset,stepheight,lowtime)
	fast_ramp(offset) -- avoid jumps
	step_around_current_setpoint(stepheight,lowtime)
end

function stop_FunctionGenerator_and_ramp_to_0()
	--safe stop of the functionGenerator
	functionGenerator:stop()
	fast_ramp(0)
	set_functionGenerator_properties(0,0,0,0,0,0)
end

function slow_ramp(targetSpeed)
	acceleration = 0.01
	ramp_with(targetSpeed,acceleration)
end

function fast_ramp(targetSpeed)
	acceleration = 0.1
	ramp_with(targetSpeed,acceleration)
end
----------------- THE EXPERIMENTS!!!!!!! -------------
function run()
	speedOffset = softlimit/2.0
	if (fast_ramp(speedOffset)) then
		fast_ramp(0.0)
		return 0
	end
	sleep(10)
	fast_ramp(0.0)
end

function run_step_experiment()
	print "Running experimint NAOOOO!"
	sleep(.5)
	start_stepping()
	sleep(21)
	stop_stepping()
end

function run_offset_sin_experiment()
	fast_ramp(normalFlyingSpeed) -- Just cause we don't want this included in the sleep time
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
	fast_ramp(normalFlyingSpeed) -- Just cause we don't want this included in the sleep time
	lowtime = 16
	step_around_offset(normalFlyingSpeed, -- offset
					.1, -- stepheight
					lowtime) -- lowtime
	periods = 4
	sleep(periods*lowtime*2)
	stop_FunctionGenerator_and_ramp_to_0()
end

function run_steady_state_experiment()
	fast_ramp(takeoffSpeed)
	sleep(.5)
	acceleration = .01 -- in rad/s^2
	ramp_with(	turbulentSpeed, -- targetSpeed
			acceleration) -- acceleration
	sleep(10)
	ramp_with(	takeoffSpeed, -- targetSpeed
			acceleration) -- acceleration
	fast_ramp(0)
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
	dspeed = 0.2
	fast_ramp(elevationJumpingSpeed + dspeed)
	slow_ramp(elevationJumpingSpeed - dspeed)
	slow_ramp(elevationJumpingSpeed + dspeed)
	slow_ramp(elevationJumpingSpeed - dspeed)
	slow_ramp(elevationJumpingSpeed + dspeed)
	fast_ramp(0)
end	
