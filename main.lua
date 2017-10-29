require 'camera'

ssx = love.graphics.getWidth()
ssy = love.graphics.getHeight()

love.filesystem.setIdentity(love.window.getTitle())
math.randomseed(love.timer.getTime())

love.mouse.setRelativeMode(true)

canvases = {
	select = love.graphics.newCanvas(ssx, ssy),
	point = love.graphics.newCanvas(1, 1)
}

shaders = {}

moveSpd = 2

function love.load()
	sdfText = love.filesystem.read('shaders/sdf.h')
	sdfRenderText = love.filesystem.read('shaders/sdfRender.h')
	sdfRenderSelectText = love.filesystem.read('shaders/sdfRenderSelect.h')
	sdfRenderIdsText = love.filesystem.read('shaders/sdfRenderIds.h')
	reload()
end

function reload()
	time = 0
	camPos = {x=0, y=1, z=-2}
	camRot = {x=0, y=0, z=0}
	camTarget = {x=0, y=0, z=0}
	objects = {}
	-- can only use string values with static objects
	sphereObj = addObject({
		type='sphere', dynamic=true, pos={0, 0.25, 0}}, true)
	roundBoxObj1 = addObject({
		type='roundBox', pos={0.75, '0.25+(sin(time*2.0)+1.0)*0.2', 0}, smooth=0.4}, true)
	planeObj = addObject({
		type='plane', m='sin(time)*0.5+0.5', smooth=0.4}, true)
	roundBoxObj2 = addObject({
		type='roundBox', dynamic=true, pos={0, 0.25, 3}})
	ellipsoidObj = addObject({
		type='ellipsoid', pos={0, 0.25, 1.5}, size={0.5, 0.25, 0.25}})
	boxObj1 = addObject({
		type='box', pos={-0.75, 0.25, 0}, size='0.1+sin(time*3.0)*0.05'})
	boxObj2 = addObject({
		type='box', pos={'sin(time*2)', 3, 0}, m=-1}, true)
	selectedObj = 0
	reloadSDFShader()
end

function isInt(x)
	return x == math.floor(x)
end

function glslVal(x)
	return (type(x) == 'number' and (x .. (isInt(x) and '.0' or '')) or x)
end

function vec3Str(p)
	return 'vec3(' .. glslVal(p[1])
	 	.. ', ' .. glslVal(p[2])
		.. ', ' .. glslVal(p[3]) .. ')'
end

function addObject(t, preventReload)
	t = t or {}
	if t.size and not (type(t.size) == 'table') then
		t.size = {t.size, t.size, t.size}
	end
	obj = {const={}}
	local defaults = {
		const = {type='sphere', dynamic=false},
		var = {m=1, pos={0, 0, 0}, smooth=0}
	}
	local conditionalDefaults = {var={}}
	if t.type == 'sphere' then
		conditionalDefaults = {
			var = {r=0.25}
		}
	elseif t.type == 'box' then
		conditionalDefaults = {
			var = {size={0.25, 0.25, 0.25}}
		}
	elseif t.type == 'ellipsoid' then
		conditionalDefaults = {
			var = {size={0.25, 0.25, 0.25}}
		}
	elseif t.type == 'roundBox' then
		conditionalDefaults = {
			var = {round=0.1, size={0.15, 0.15, 0.15}}
		}
	end
	for k, v in pairs(defaults.const) do
		obj.const[k] = t[k] or v
	end
	for k, v in pairs(defaults.var) do
		obj[k] = t[k] or v
	end
	for k, v in pairs(conditionalDefaults.var) do
		obj[k] = t[k] or v
	end
	obj.const.id = #objects + 1
	objects[obj.const.id] = obj
	if not preventReload then reloadSDFShader() end
	return obj
end

function removeObject(t, preventReload)
	objects[t.const.id] = nil
	if not preventReload then reloadSDFShader() end
end

function reloadSDFShader()
	sdfShaderText = ''
	sdfSelectShaderText = ''
	for i=1, 3 do
		s = ''
		.. 'extern float time;\n'
		.. 'extern vec3 camPos;\n'
		.. 'extern vec3 camTarget;\n'
		for k, v in pairs(objects) do
			if v.const.dynamic then
				for k2, v2 in pairs(v) do
					if not (k2 == 'const') then
						if type(v2) == 'number' then
							s = s .. 'extern float v' .. k .. '_' .. k2 .. ';\n'
						elseif type(v2) == 'table' and #v2 == 3 then
							s = s .. 'extern vec3 v' .. k .. '_' .. k2 .. ';\n'
						end
					end
				end
			else
				s = s .. 'extern float v' .. k .. '_m;\n'
			end
		end
		s = s .. sdfText
		.. 'vec2 map(vec3 pos) {\n'
		.. '	vec2 res = vec2(100000.0, -1.0);\n'
		for k, v in pairs(objects) do
			if v.const.dynamic then
				if v.const.type == 'plane' then
					s = s
					.. '	res = opU(res, vec2(sdPlane(pos - '
					.. 'v' .. k .. '_pos), '
					.. 'v' .. k .. '_m), '
					.. 'v' .. k .. '_smooth);\n'
				elseif v.const.type == 'sphere' then
					s = s
					.. '	res = opU(res, vec2(sdSphere(pos - '
					.. 'v' .. k .. '_pos, '
					.. 'v' .. k .. '_r), '
					.. 'v' .. k .. '_m), '
					.. 'v' .. k .. '_smooth);\n'
				elseif v.const.type == 'box' then
					s = s
					.. '	res = opU(res, vec2(sdBox(pos - '
					.. 'v' .. k .. '_pos, '
					.. 'v' .. k .. '_size), '
					.. 'v' .. k .. '_m), '
					.. 'v' .. k .. '_smooth);\n'
				elseif v.const.type == 'ellipsoid' then
					s = s
					.. '	res = opU(res, vec2(sdEllipsoid(pos - '
					.. 'v' .. k .. '_pos, '
					.. 'v' .. k .. '_size), '
					.. 'v' .. k .. '_m), '
					.. 'v' .. k .. '_smooth);\n'
				elseif v.const.type == 'roundBox' then
					s = s
					.. '	res = opU(res, vec2(udRoundBox(pos - '
					.. 'v' .. k .. '_pos, '
					.. 'v' .. k .. '_size, '
					.. 'v' .. k .. '_round), '
					.. 'v' .. k .. '_m), '
					.. 'v' .. k .. '_smooth);\n'
				end
			else
				if v.const.type == 'plane' then
					s = s
					.. '	res = opU(res, vec2(sdPlane(pos - '
					.. vec3Str(v.pos) .. '), '
					.. (i == 1 and glslVal(v.m) or ('v' .. k .. '_m')) .. '), '
					.. glslVal(v.smooth) .. ');\n'
				elseif v.const.type == 'sphere' then
					s = s
					.. '	res = opU(res, vec2(sdSphere(pos - '
					.. vec3Str(v.pos) .. ', '
					.. glslVal(v.r) .. '), '
					.. (i == 1 and glslVal(v.m) or ('v' .. k .. '_m')) .. '), '
					.. glslVal(v.smooth) .. ');\n'
				elseif v.const.type == 'box' then
					s = s
					.. '	res = opU(res, vec2(sdBox(pos - '
					.. vec3Str(v.pos) .. ', '
					.. vec3Str(v.size) .. '), '
					.. (i == 1 and glslVal(v.m) or ('v' .. k .. '_m')) .. '), '
					.. glslVal(v.smooth) .. ');\n'
				elseif v.const.type == 'ellipsoid' then
					s = s
					.. '	res = opU(res, vec2(sdEllipsoid(pos - '
					.. vec3Str(v.pos) .. ', '
					.. vec3Str(v.size) .. '), '
					.. (i == 1 and glslVal(v.m) or ('v' .. k .. '_m')) .. '), '
					.. glslVal(v.smooth) .. ');\n'
				elseif v.const.type == 'roundBox' then
					s = s
					.. '	res = opU(res, vec2(udRoundBox(pos - '
					.. vec3Str(v.pos) .. ', '
					.. vec3Str(v.size) .. ', '
					.. glslVal(v.round) .. '), '
					.. (i == 1 and glslVal(v.m) or ('v' .. k .. '_m')) .. '), '
					.. glslVal(v.smooth) .. ');\n'
				end
			end
		end
		s = s
		.. '	return res;\n'
		.. '}\n'
		if i == 1 then
			s = s .. sdfRenderText
		elseif i == 2 then
			s = s .. sdfRenderSelectText
		elseif i == 3 then
			s = s .. sdfRenderIdsText
		end
		s = s .. '\n'
		.. 'vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {\n'
		.. '	vec2 p = (-love_ScreenSize.xy + 2.0*screen_coords)/love_ScreenSize.y;\n'
		.. '	p.y = -p.y;\n'
		.. '	vec3 ro = vec3(camPos);\n'
		.. '	vec3 ta = vec3(camTarget);\n'
		.. '	ta.x += mod(time, 0.000001);\n'
		.. '	mat3 ca = setCamera(ro, ta, 0.0);\n'
		.. '	vec3 rd = ca * normalize(vec3(p.xy, 2.0));\n'
		.. '	vec3 col = render(ro, rd);\n'
		.. '	return vec4(col, 1.0);\n'
		.. '}\n'
		if i == 1 then
			sdfShaderText = s
		elseif i == 2 then
			sdfSelectShaderText = s
		elseif i == 3 then
			sdfSelectIdShaderText = s
		end
	end
	if true then
		love.system.setClipboardText(sdfSelectIdShaderText)
	end
	shaders.sdf = love.graphics.newShader(sdfShaderText)
	shaders.sdfSelect = love.graphics.newShader(sdfSelectShaderText)
	shaders.sdfId = love.graphics.newShader(sdfSelectIdShaderText)
	updateShaderVars()
end

function updateShaderVars()
	shaders.sdf:send('time', time)
	shaders.sdfSelect:send('time', time)
	shaders.sdfId:send('time', time)
	shaders.sdf:send('camPos', {camPos.x, camPos.y, camPos.z})
	shaders.sdfSelect:send('camPos', {camPos.x, camPos.y, camPos.z})
	shaders.sdfId:send('camPos', {camPos.x, camPos.y, camPos.z})
	shaders.sdf:send('camTarget', {camTarget.x, camTarget.y, camTarget.z})
	shaders.sdfSelect:send('camTarget', {camTarget.x, camTarget.y, camTarget.z})
	shaders.sdfId:send('camTarget', {camTarget.x, camTarget.y, camTarget.z})
	for k, v in pairs(objects) do
		if v.const.dynamic then
			for k2, v2 in pairs(v) do
				if not (k2 == 'const') then
					shaders.sdf:send('v' .. k .. '_' .. k2, v2)
					if k2 == 'm' then
						shaders.sdfSelect:send('v' .. k .. '_' .. k2,
							(v.const.id == selectedObj and 1 or 0))
						shaders.sdfId:send('v' .. k .. '_' .. k2, v.const.id)
					else
						shaders.sdfSelect:send('v' .. k .. '_' .. k2, v2)
						shaders.sdfId:send('v' .. k .. '_' .. k2, v2)
					end
				end
			end
		else
			shaders.sdfSelect:send('v' .. k .. '_m', (v.const.id == selectedObj and 1 or 0))
			shaders.sdfId:send('v' .. k .. '_m', v.const.id)
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
		sphereObj.pos[1] = sphereObj.pos[1] + x*spd*dt
		sphereObj.pos[3] = sphereObj.pos[3] + z*spd*dt
	elseif love.keyboard.isDown('left') then
		sphereObj.pos[1] = sphereObj.pos[1] - x*spd*dt
		sphereObj.pos[3] = sphereObj.pos[3] - z*spd*dt
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
		sphereObj.pos[1] = sphereObj.pos[1] + x*spd*dt
		sphereObj.pos[3] = sphereObj.pos[3] + z*spd*dt
	elseif love.keyboard.isDown('down') then
		sphereObj.pos[1] = sphereObj.pos[1] - x*spd*dt
		sphereObj.pos[3] = sphereObj.pos[3] - z*spd*dt
	end

	camTarget = {x=camPos.x+x, y=camPos.y+y, z=camPos.z+z}

	roundBoxObj2.round = math.sin(time)*0.1+0.1

	updateShaderVars()

	love.graphics.setCanvas(canvases.point)
	love.graphics.setShader(shaders.sdfId)
	love.graphics.rectangle('fill', 0, 0, 1, 1)
	local r, g, b = canvases.point:newImageData():getPixel(0, 0)
	selectedObj = r
	if selectedObj == 3 then
		selectedObj = 0
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
	elseif k == 'c' and love.keyboard.isDown('lctrl') then
		love.system.setClipboardText(sdfShaderText)
	end
end

function love.draw()
	love.graphics.setCanvas()
	love.graphics.setShader()
	love.graphics.setColor(255, 255, 255)
	love.graphics.setShader(shaders.sdf)
	love.graphics.rectangle('fill', 0, 0, ssx, ssy)
	love.graphics.setCanvas(canvases.select)
	love.graphics.setShader(shaders.sdfSelect)
	love.graphics.rectangle('fill', 0, 0, ssx, ssy)
	love.graphics.setCanvas()
	love.graphics.setShader()
	love.graphics.setColor(255, 255, 255, 100)
	love.graphics.draw(canvases.select, 0, 0)
	love.graphics.setColor(200, 0, 0)
	love.graphics.circle('line', ssx/2, ssy/2, 2)
	love.graphics.setColor(0, 255, 0)
	love.graphics.print(selectedObj, 10, 10)
end
