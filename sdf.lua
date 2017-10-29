
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

function removeObject(v, preventReload)
	if type(v) == 'table' then
		objects[v.const.id] = nil
	elseif type(v) == 'number' then
		objects[v] = nil
	end
	if not preventReload then reloadSDFShader() end
end

function reloadSDFShader()
	sdfShaderText = ''
	sdfIdShaderText = ''
	for i=1, 2 do
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
						elseif type(v2) == 'table' then
							if #v2 == 2 then
								s = s .. 'extern vec2 v' .. k .. '_' .. k2 .. ';\n'
							elseif #v2 == 3 then
								s = s .. 'extern vec3 v' .. k .. '_' .. k2 .. ';\n'
							elseif #v2 == 4 then
								s = s .. 'extern vec4 v' .. k .. '_' .. k2 .. ';\n'
							end
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
					.. vecStr(v.pos) .. '), '
					.. 'v' .. k .. '_m), '
					.. glslVal(v.smooth) .. ');\n'
				elseif v.const.type == 'sphere' then
					s = s
					.. '	res = opU(res, vec2(sdSphere(pos - '
					.. vecStr(v.pos) .. ', '
					.. glslVal(v.r) .. '), '
					.. 'v' .. k .. '_m), '
					.. glslVal(v.smooth) .. ');\n'
				elseif v.const.type == 'box' then
					s = s
					.. '	res = opU(res, vec2(sdBox(pos - '
					.. vecStr(v.pos) .. ', '
					.. vecStr(v.size) .. '), '
					.. 'v' .. k .. '_m), '
					.. glslVal(v.smooth) .. ');\n'
				elseif v.const.type == 'ellipsoid' then
					s = s
					.. '	res = opU(res, vec2(sdEllipsoid(pos - '
					.. vecStr(v.pos) .. ', '
					.. vecStr(v.size) .. '), '
					.. 'v' .. k .. '_m), '
					.. glslVal(v.smooth) .. ');\n'
				elseif v.const.type == 'roundBox' then
					s = s
					.. '	res = opU(res, vec2(udRoundBox(pos - '
					.. vecStr(v.pos) .. ', '
					.. vecStr(v.size) .. ', '
					.. glslVal(v.round) .. '), '
					.. 'v' .. k .. '_m), '
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
			sdfIdShaderText = s
		end
	end
	if false then
		love.system.setClipboardText(sdfShaderText)
	end
	shaders.sdf = love.graphics.newShader(sdfShaderText)
	shaders.sdfId = love.graphics.newShader(sdfIdShaderText)
	updateShaderVars()
end

function updateShaderVars()
	shaders.sdf:send('time', time)
	shaders.sdfId:send('time', time)
	shaders.sdf:send('camPos', {camPos.x, camPos.y, camPos.z})
	shaders.sdfId:send('camPos', {camPos.x, camPos.y, camPos.z})
	shaders.sdf:send('camTarget', {camTarget.x, camTarget.y, camTarget.z})
	shaders.sdfId:send('camTarget', {camTarget.x, camTarget.y, camTarget.z})
	for k, v in pairs(objects) do
		if v.const.dynamic then
			for k2, v2 in pairs(v) do
				if not (k2 == 'const') then
					if k2 == 'm' then
						shaders.sdf:send('v' .. k .. '_m', v.const.id == selectedObj and 0 or v.m)
						shaders.sdfId:send('v' .. k .. '_m', v.const.id)
					else
						shaders.sdf:send('v' .. k .. '_' .. k2, v2)
						shaders.sdfId:send('v' .. k .. '_' .. k2, v2)
					end
				end
			end
		else
			shaders.sdf:send('v' .. k .. '_m', v.const.id == selectedObj and 0 or v.m)
			shaders.sdfId:send('v' .. k .. '_m', v.const.id)
		end
	end
end
