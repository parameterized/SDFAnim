require 'camera'

ssx = love.graphics.getWidth()
ssy = love.graphics.getHeight()

love.filesystem.setIdentity(love.window.getTitle())
math.randomseed(love.timer.getTime())

love.mouse.setRelativeMode(true)

shaders = {}

moveSpd = 2

function love.load()
	sdfText = love.filesystem.read('shaders/sdf.h')
	sdfRenderText = love.filesystem.read('shaders/sdfRender.h')
	reload()
end

function reload()
	time = 0
	camPos = {x=0, y=1, z=-2}
	camRot = {x=0, y=0, z=0}
	camTarget = {x=0, y=0, z=0}
	objects = {}
	sphereObj = addObject({dynamic=true, y=0.25}, true)
	boxObj = addObject({type='box', y=3, x='sin(time*2)', m=-1}, true)
	reloadSDFShader()
end

function isInt(x)
	return x == math.floor(x)
end

function glslVal(x)
	return (type(x) == 'number' and (x .. (isInt(x) and '.0' or '')) or x)
end

function vec3Str(x, y, z)
	return 'vec3(' .. glslVal(x)
	 	.. ', ' .. glslVal(y)
		.. ', ' .. glslVal(z) .. ')'
end

function addObject(t, preventReload)
	t = t or {}
	obj = {const={}}
	local defaults = {
		const = {type='sphere', dynamic=false, m=1},
		var = {x=0, y=0, z=0}
	}
	for k, v in pairs(defaults.const) do
		obj.const[k] = t[k] or v
	end
	for k, v in pairs(defaults.var) do
		obj[k] = t[k] or v
	end
	obj.id = #objects + 1
	objects[obj.id] = obj
	if not preventReload then reloadSDFShader() end
	return obj
end

function removeObject(t, preventReload)
	objects[t.id] = nil
	if not preventReload then reloadSDFShader() end
end

function reloadSDFShader()
	s = ''
	.. 'extern float time;\n'
	.. 'extern vec3 camPos;\n'
	.. 'extern vec3 camTarget;\n'
	for k, v in pairs(objects) do
		if v.const.dynamic then
			s = s .. 'extern vec3 v' .. k .. '_pos;\n'
		end
	end
	s = s .. sdfText
	.. 'vec2 map(vec3 pos) {\n'
	.. '	vec2 res = vec2(100000.0, -1.0);\n'
	for k, v in pairs(objects) do
		if v.const.dynamic then
			if v.const.type == 'sphere' then
				s = s
					.. '	res = opU(res, vec2(sdSphere(pos - v'
					.. k .. '_pos, 0.25), '
					.. glslVal(v.const.m) .. '), 0.0);\n'
			elseif v.const.type == 'box' then
				s = s
					.. '	res = opU(res, vec2(sdBox(pos - v'
					.. k .. '_pos, vec3(0.25)), '
					.. glslVal(v.const.m) .. '), 0.0);\n'
			end
		else
			if v.const.type == 'sphere' then
				s = s
					.. '	res = opU(res, vec2(sdSphere(pos - '
					.. vec3Str(v.x, v.y, v.z) .. ', 0.25), '
					.. glslVal(v.const.m) .. '), 0.0);\n'
			elseif v.const.type == 'box' then
				s = s
					.. '	res = opU(res, vec2(sdBox(pos - '
					.. vec3Str(v.x, v.y, v.z) .. ', vec3(0.25)), '
					.. glslVal(v.const.m) .. '), 0.0);\n'
			end
		end
	end
	--[
	s = s
	.. '	res = opU(res, vec2(sdPlane(pos), 1.0), 0.4);\n'
	.. '	res = opU(res, vec2(sdBox(pos - vec3(-0.75, 0.25, 0.0), vec3(0.25)), 1.0), 0.0);\n'
	.. '	res = opU(res, vec2(udRoundBox(pos - vec3(0.75, 0.25+(sin(time*2.0)+1.0)*0.2, 0.0), vec3(0.15), 0.1), 1.0), 0.4);\n'
	--]]
	s = s
	.. '	return res;\n'
	.. '}\n'
	s = s .. sdfRenderText
	.. 'vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {\n'
	.. '	vec2 p = (-love_ScreenSize.xy + 2.0*screen_coords)/love_ScreenSize.y;\n'
	.. '	p.y = -p.y;\n'
	.. '	vec3 ro = vec3(camPos);\n'
	.. '	vec3 ta = vec3(camTarget);\n'
	.. '	mat3 ca = setCamera(ro, ta, 0.0);\n'
	.. '	vec3 rd = ca * normalize(vec3(p.xy, 2.0));\n'
	.. '	vec3 col = render(ro, rd);\n'
	.. '	col += mod(time, 0.00001);\n'
	.. '	return vec4(col, 1.0);\n'
	.. '}\n'
	love.system.setClipboardText(s)
	shaders.sdf = love.graphics.newShader(s)
	for k, v in pairs(objects) do
		if v.const.dynamic then
			shaders.sdf:send('v' .. k .. '_pos', {v.x, v.y, v.z})
		end
	end
end

function love.update(dt)
	time = time + dt

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
	x, y, z = xp, yp, zp
	xp, yp, zp = z*math.sin(camRot.y) + x*math.cos(camRot.y), y, z*math.cos(camRot.y) - x*math.sin(camRot.y)
	x, y, z = xp, yp, zp

	if love.keyboard.isDown("d") then
		camPos.x = camPos.x + x*spd*dt
		camPos.y = camPos.y + y*spd*dt
		camPos.z = camPos.z + z*spd*dt
	elseif love.keyboard.isDown("a") then
		camPos.x = camPos.x - x*spd*dt
		camPos.y = camPos.y - y*spd*dt
		camPos.z = camPos.z - z*spd*dt
	end

	if love.keyboard.isDown('right') then
		sphereObj.x = sphereObj.x + x*spd*dt
		sphereObj.z = sphereObj.z + z*spd*dt
	elseif love.keyboard.isDown('left') then
		sphereObj.x = sphereObj.x - x*spd*dt
		sphereObj.z = sphereObj.z - z*spd*dt
	end

	x, y, z = 0, 0, 1
	xp, yp, zp = x, y*math.cos(camRot.x) - z*math.sin(camRot.x), y*math.sin(camRot.x) + z*math.cos(camRot.x)
	x, y, z = xp, yp, zp
	xp, yp, zp = z*math.sin(camRot.y) + x*math.cos(camRot.y), y, z*math.cos(camRot.y) - x*math.sin(camRot.y)
	x, y, z = xp, yp, zp

	if love.keyboard.isDown("w") then
		camPos.x = camPos.x + x*spd*dt
		camPos.y = camPos.y + y*spd*dt
		camPos.z = camPos.z + z*spd*dt
	elseif love.keyboard.isDown("s") then
		camPos.x = camPos.x - x*spd*dt
		camPos.y = camPos.y - y*spd*dt
		camPos.z = camPos.z - z*spd*dt
	end

	if love.keyboard.isDown('up') then
		sphereObj.x = sphereObj.x + x*spd*dt
		sphereObj.z = sphereObj.z + z*spd*dt
	elseif love.keyboard.isDown('down') then
		sphereObj.x = sphereObj.x - x*spd*dt
		sphereObj.z = sphereObj.z - z*spd*dt
	end

	camTarget = {x=camPos.x+x, y=camPos.y+y, z=camPos.z+z}

	shaders.sdf:send('time', time)
	shaders.sdf:send('camPos', {camPos.x, camPos.y, camPos.z})
	shaders.sdf:send('camTarget', {camTarget.x, camTarget.y, camTarget.z})
	for k, v in pairs(objects) do
		if v.const.dynamic then
			shaders.sdf:send('v' .. k .. '_pos', {v.x, v.y, v.z})
		end
	end

	love.window.setTitle('SDFAnim (' .. love.timer.getFPS() .. ' FPS)')
end

function love.mousepressed(x, y, btn, isTouch)
	if not love.mouse.getRelativeMode() then
		love.mouse.setRelativeMode(true)
	end
end

function love.mousemoved(x, y, dx, dy)
	if love.mouse.getRelativeMode() then
		camRot.y = camRot.y + -dx/200
		camRot.x = math.min(math.max(camRot.x + dy/200, -math.pi/2+0.001), math.pi/2-0.001)
	end
end

function love.keypressed(k, scancode, isrepeat)
	if k == 'escape' then
		if love.mouse.getRelativeMode() then
			love.mouse.setRelativeMode(false)
		else
			love.event.quit()
		end
	elseif k == 'r' then
		reload()
	end
end

function love.draw()
	love.graphics.setShader(shaders.sdf)
	love.graphics.rectangle('fill', 0, 0, ssx, ssy)
end
