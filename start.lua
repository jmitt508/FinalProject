--start screen
local composer = require("composer")
local scene = composer.newScene()
local startButton
local pulsatingText = require("pulsatingText")
local starFieldGenerator = require("starfieldgenerator")
local starGenerator

scene:addEventListener("create", scene)
scene:addEventListener("show",scene)
scene:addEventListener("hide", scene)

function scene:create(event)
	local group = self.view
	startButton = display.newImage("start.png", display.contentCenterX, display.contentCenterY+100)
	starGenerator =  starFieldGenerator.new(100,group,3)
	group:insert(startButton)
	local invadersText = pulsatingText.new("FOOD INVADERZ", display.contentCenterX, display.contentCenterY-200, "Conquest", 20, group)
	invadersText:setColor(1,1,1)
	invadersText:pulsate()
end

function scene:show(event)
	local phase = event.phase
	local previousScene = composer.getSceneName("previous")
	if(previousScene ~= nil) then
		composer.removeScene(previousScene)
	end
	if(phase == "did") then	
		startButton:addEventListener("tap", startGame)
		Runtime:addEventListener("enterFrame", starGenerator)
	end
end

function scene:hide(event)
	local phase = event.phase
	if(phase == "will") then
		startButton:removeEventListener("tap", startGame)
		Runtime:removeEventListener("enterFrame", starGenerator)
	end
end

function startGame()
	composer.gotoScene("gamelevel")
end


return scene
