
require 'utils'
require 'camera'
require 'sdf'

ssx = love.graphics.getWidth()
ssy = love.graphics.getHeight()

love.filesystem.setIdentity(love.window.getTitle())
math.randomseed(love.timer.getTime())

love.mouse.setRelativeMode(true)

canvases = {
	point = love.graphics.newCanvas(1, 1)
}

shaders = {}

moveSpd = 2

function love.load()
	sdfText = love.filesystem.read('shaders/sdf.h')
	sdfRenderText = love.filesystem.read('shaders/sdfRender.h')
	sdfRenderIdsText = love.filesystem.read('shaders/sdfRenderIds.h')
	reload()
end

function reload()
	time = 0
	camPos = {x=0, y=1, z=-2}
	camRot = {x=0, y=0, z=0}
	camTarget = {x=0, y=0, z=0}
	objects = {}
	-- can't use string values with dynamic objects or materials
	sphereObj = addObject({
		type='sphere', dynamic=true, pos={0, 0.25, 0}}, true)
	roundBoxObj1 = addObject({
		type='roundBox', pos={0.75, '0.25+(sin(time*2.0)+1.0)*0.2', 0}, smooth=0.4}, true)
	planeObj = addObject({
		type='plane', m=2, smooth=0.4}, true)
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

function love.update(dt)
	time = time + dt

	camera.update(dt)

	local spd = moveSpd
	if love.keyboard.isDown("lctrl") then
		spd = moveSpd/6
	elseif love.keyboard.isDown("lshift") then
		spd = moveSpd*6
	end

	local x, y, z = -1, 0, 0
	xp, yp, zp = x, y*math.cos(0) - z*math.sin(0), y*math.sin(0) + z*math.cos(0)
	x, y, z = zp*math.sin(camRot.y) + xp*math.cos(camRot.y), yp, zp*math.cos(camRot.y) - xp*math.sin(camRot.y)

	if love.keyboard.isDown('right') then
		sphereObj.pos[1] = sphereObj.pos[1] + x*spd*dt
		sphereObj.pos[3] = sphereObj.pos[3] + z*spd*dt
	elseif love.keyboard.isDown('left') then
		sphereObj.pos[1] = sphereObj.pos[1] - x*spd*dt
		sphereObj.pos[3] = sphereObj.pos[3] - z*spd*dt
	end

	x, y, z = 0, 0, 1
	xp, yp, zp = x, y*math.cos(0) - z*math.sin(0), y*math.sin(0) + z*math.cos(0)
	x, y, z = zp*math.sin(camRot.y) + xp*math.cos(camRot.y), yp, zp*math.cos(camRot.y) - xp*math.sin(camRot.y)

	if love.keyboard.isDown('up') then
		sphereObj.pos[1] = sphereObj.pos[1] + x*spd*dt
		sphereObj.pos[3] = sphereObj.pos[3] + z*spd*dt
	elseif love.keyboard.isDown('down') then
		sphereObj.pos[1] = sphereObj.pos[1] - x*spd*dt
		sphereObj.pos[3] = sphereObj.pos[3] - z*spd*dt
	end

	planeObj.m = math.sin(time)*0.5+1.5
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
	removeObject(selectedObj)
end

function love.mousemoved(x, y, dx, dy)
	if love.mouse.getRelativeMode() then
		camera.turn(dx, dy)
	end
end

function love.keypressed(k, scancode, isrepeat)
	if k == 'escape' then
		if love.mouse.getRelativeMode() then
			love.mouse.setRelativeMode(false)
			love.mouse.setPosition(ssx/2, ssy/2)
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
	love.graphics.setShader()
	love.graphics.setColor(200, 0, 0)
	love.graphics.circle('line', ssx/2, ssy/2, 2)
	love.graphics.setColor(0, 140, 0)
	love.graphics.print(selectedObj, 10, 10)
end
