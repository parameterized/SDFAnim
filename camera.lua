
camera = {}

function camera.load()

end

function camera.update(dt)
	local spd = moveSpd
	if love.keyboard.isDown("lctrl") then
		spd = moveSpd/6
	elseif love.keyboard.isDown("lshift") then
		spd = moveSpd*6
	end

	if love.keyboard.isDown("space") then
		camPos.y = camPos.y + spd*dt
	end

	local x, y, z = -1, 0, 0
	local xp, yp, zp = x, y*math.cos(camRot.x) - z*math.sin(camRot.x), y*math.sin(camRot.x) + z*math.cos(camRot.x)
	x, y, z = zp*math.sin(camRot.y) + xp*math.cos(camRot.y), yp, zp*math.cos(camRot.y) - xp*math.sin(camRot.y)

	if love.keyboard.isDown("d") then
		camPos.x = camPos.x + x*spd*dt
		camPos.y = camPos.y + y*spd*dt
		camPos.z = camPos.z + z*spd*dt
	elseif love.keyboard.isDown("a") then
		camPos.x = camPos.x - x*spd*dt
		camPos.y = camPos.y - y*spd*dt
		camPos.z = camPos.z - z*spd*dt
	end

	x, y, z = 0, 0, 1
	xp, yp, zp = x, y*math.cos(camRot.x) - z*math.sin(camRot.x), y*math.sin(camRot.x) + z*math.cos(camRot.x)
	x, y, z = zp*math.sin(camRot.y) + xp*math.cos(camRot.y), yp, zp*math.cos(camRot.y) - xp*math.sin(camRot.y)

	if love.keyboard.isDown("w") then
		camPos.x = camPos.x + x*spd*dt
		camPos.y = camPos.y + y*spd*dt
		camPos.z = camPos.z + z*spd*dt
	elseif love.keyboard.isDown("s") then
		camPos.x = camPos.x - x*spd*dt
		camPos.y = camPos.y - y*spd*dt
		camPos.z = camPos.z - z*spd*dt
	end

	camTarget = {x=camPos.x+x, y=camPos.y+y, z=camPos.z+z}
end

function camera.turn(dx, dy)
	camRot.y = camRot.y + -dx/200
	camRot.x = math.min(math.max(camRot.x + dy/200, -math.pi/2+0.001), math.pi/2-0.001)
end
