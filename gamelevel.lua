local composer = require("composer")
local scene = composer.newScene()
local starFieldGenerator = require("starfieldgenerator")
local pulsatingText = require("pulsatingtext")
local physics = require("physics")
local gameData = require( "gamedata" )
local starGenerator -- an instance of the starFieldGenerator
local player
local playerHeight = 75
local playerWidth = 50
local invaderSize = 30 -- The width and height of the invader image
local leftBounds = 30 -- the left margin
local rightBounds = display.contentWidth - 30 -- the right margin
local invaderHalfWidth = 16
local invaders = {} -- Table that holds all the invaders
local invaderSpeed = 1
local playerBullets = {} -- Table that holds the players Bullets
local canFireBullet = true
local invadersWhoCanFire = {} -- Table that holds the invaders that are able to fire bullets
local invaderBullets = {}
local numberOfLives = 3
local playerIsInvincible = false
local rowOfInvadersWhoCanFire = 5
local invaderFireTimer -- timer used to fire invader bullets
local gameIsOver = false;
local drawDebugButtons = {}  --Temporary buttons to move player in simulator
local enableBulletFireTimer -- timer that enables player to fire
local invaderNum = 1
local rowsOfInvaders = 5
local maxLevels = 2

physics.start()

function movementButtons()
    local function movePlayer(event)
        if(event.target.name == "left") then
            player.x = player.x - 1
        elseif(event.target.name == "right") then
            player.x = player.x + 1
        end
    end
    local left = display.newRect(20,20,20,20)
    left.name = "left"
	left.x = display.contentCenterX-100
	left.y = display.contentHeight - 40
    scene.view:insert(left)
    local right = display.newRect(20,20,20,20)
    right.name = "right"
	right.x = display.contentCenterX + 100
	right.y = display.contentHeight - 40
    scene.view:insert(right)
    left:addEventListener("touch", movePlayer)
    right:addEventListener("touch", movePlayer)
end

function scene:create(event)
    local group = self.view
    starGenerator =  starFieldGenerator.new(100,group,3)
	setupPlayer()
	movementButtons()
	setupInvaders()
end

function scene:show(event)
    local phase = event.phase
    local previousScene = composer.getSceneName( "previous" )
    composer.removeScene(previousScene)
    local group = self.view
    if ( phase == "did" ) then
	   Runtime:addEventListener("enterFrame", gameLoop)
       Runtime:addEventListener("enterFrame", starGenerator)
	   Runtime:addEventListener("enterFrame", firePlayerBullet)
	   Runtime:addEventListener( "collision", onCollision )
	   invaderFireTimer =    timer.performWithDelay(1500, fireInvaderBullet,-1)
     end
end

function scene:hide(event)
    local phase = event.phase
    local group = self.view
    if ( phase == "will" ) then
		Runtime:removeEventListener("enterFrame", gameLoop)
        Runtime:removeEventListener("enterFrame", starGenerator)
		Runtime:removeEventListener("enterFrame", firePlayerBullet)
		Runtime:removeEventListener( "collision", onCollision )
		timer.cancel(invaderFireTimer)
    end
end

function setupPlayer()
    local sequenceData = {
     {  start=1, count=2, time=300,   loopCount=0 }
    }
    player = display.newImageRect("player.png", 40, 40)
    player.name = "player"
    player.x = display.contentCenterX- playerWidth /2 
    player.y = display.contentHeight - playerHeight - 10
    scene.view:insert(player)
	physics.addBody(player, "dynamic")
    player.gravityScale = 0
end

function firePlayerBullet()
    if(canFireBullet == true)then
        local tempBullet = display.newImageRect("banana.png", 15,15)
		tempBullet.x = player.x
		tempBullet.y = player.y
        tempBullet.name = "playerBullet"
        scene.view:insert(tempBullet)
        physics.addBody(tempBullet, "dynamic" )
        tempBullet.gravityScale = 0
        tempBullet.isBullet = true
        tempBullet.isSensor = true
        tempBullet:setLinearVelocity( 0,-400)
        table.insert(playerBullets,tempBullet)
        canFireBullet = false
 
    else
        return
    end
    local function enableBulletFire()
        canFireBullet = true
    end
    timer.performWithDelay(750,enableBulletFire,1)
end

function checkPlayerBulletsOutOfBounds()
    if(#playerBullets > 0)then
        for i=#playerBullets,1,-1 do
            if(playerBullets[i].y < 0) then
                playerBullets[i]:removeSelf()
                playerBullets[i] = nil
                table.remove(playerBullets,i)
            end
        end
    end
end

function setupInvaders()
    local xPositionStart = display.contentCenterX - invaderHalfWidth - (invaderNum *(invaderSize + 10))
    local numberOfInvaders = invaderNum *2+1 
    for i = 1, rowsOfInvaders do
        for j = 1, numberOfInvaders do
            local tempInvader = display.newImage("bread.png",xPositionStart + ((invaderSize+10)*(j-1)), i * 10 )			
            tempInvader.name = "invader"
			tempInvader.width = 40
			tempInvader.height = 40
            if(i== rowsOfInvaders)then
                table.insert(invadersWhoCanFire,tempInvader)
            end
            physics.addBody(tempInvader, "dynamic" )
            tempInvader.gravityScale = 0
            tempInvader.isSensor = true
            scene.view:insert(tempInvader)
            table.insert(invaders,tempInvader)
        end
    end
end

function moveInvaders()
    local changeDirection = false
    for i=1, #invaders do
          invaders[i].x = invaders[i].x + invaderSpeed
        if(invaders[i].x > rightBounds - invaderHalfWidth or invaders[i].x < leftBounds + invaderHalfWidth) then
            changeDirection = true;
        end
     end
    if(changeDirection == true)then
        invaderSpeed = invaderSpeed*-1
        for j = 1, #invaders do
            invaders[j].y = invaders[j].y+ 46
        end
        changeDirection = false;
    end 
end

function onCollision(event)
    local function removeInvaderAndPlayerBullet(event)
        local params = event.source.params
        local invaderIndex = table.indexOf(invaders,params.theInvader)
        local invadersPerRow = invaderNum *2+1
        if(invaderIndex > invadersPerRow) then
            table.insert(invadersWhoCanFire, invaders[invaderIndex - invadersPerRow])
       end
        params.theInvader.isVisible = false
        physics.removeBody(  params.theInvader )
        table.remove(invadersWhoCanFire,table.indexOf(invadersWhoCanFire,params.theInvader))
         
        if(table.indexOf(playerBullets,params.thePlayerBullet)~=nil)then
            physics.removeBody(params.thePlayerBullet)
            table.remove(playerBullets,table.indexOf(playerBullets,params.thePlayerBullet))
            display.remove(params.thePlayerBullet)
            params.thePlayerBullet = nil
        end
      end
       
      if ( event.phase == "began" ) then
        if(event.object1.name == "invader" and event.object2.name == "playerBullet")then
            local tm = timer.performWithDelay(10, removeInvaderAndPlayerBullet,1)
            tm.params = {theInvader = event.object1 , thePlayerBullet = event.object2}
        end
			
		if(event.object1.name == "playerBullet" and event.object2.name == "invader") then
            local tm = timer.performWithDelay(10, removeInvaderAndPlayerBullet,1)
            tm.params = {theInvader = event.object2 , thePlayerBullet = event.object1}
		end
		if(event.object1.name == "player" and event.object2.name == "invaderBullet") then
            table.remove(invaderBullets,table.indexOf(invaderBullets,event.object2))
            event.object2:removeSelf()
            event.object2 = nil
            if(playerIsInvincible == false) then
				killPlayer()
            end
            return
		end
		if(event.object1.name == "invaderBullet" and event.object2.name == "player") then
            table.remove(invaderBullets,table.indexOf(invaderBullets,event.object1))
            event.object1:removeSelf()
            event.object1 = nil
            if(playerIsInvincible == false) then
                killPlayer()
            end
            return
        end
		if(event.object1.name == "player" and event.object2.name == "invader") then
            numberOfLives = 0
            killPlayer()
        end
         
         if(event.object1.name == "invader" and event.object2.name == "player") then
            numberOfLives = 0
            killPlayer()
        end
    end
end 

function fireInvaderBullet()
    if(#invadersWhoCanFire >0) then
        local randomIndex = math.random(#invadersWhoCanFire)
        local randomInvader = invadersWhoCanFire[randomIndex]
        local tempInvaderBullet = display.newImage("banana.png", randomInvader.x , randomInvader.y + invaderSize/2)
		tempInvaderBullet.width = 15
		tempInvaderBullet.height = 15
        tempInvaderBullet.name = "invaderBullet"
        scene.view:insert(tempInvaderBullet)
        physics.addBody(tempInvaderBullet, "dynamic" )
        tempInvaderBullet.gravityScale = 0
        tempInvaderBullet.isBullet = true
        tempInvaderBullet.isSensor = true
        tempInvaderBullet:setLinearVelocity( 0,400)
        table.insert(invaderBullets, tempInvaderBullet)
    else
        levelComplete()
    end  
end

function checkInvaderBulletsOutOfBounds()
    if (#invaderBullets > 0) then
        for i=#invaderBullets,1,-1 do
            if(invaderBullets[i].y > display.contentHeight) then
                invaderBullets[i]:removeSelf()
                invaderBullets[i] = nil
                table.remove(invaderBullets,i)
            end
        end
    end
end

function killPlayer()
    numberOfLives = numberOfLives- 1;
      if(numberOfLives <= 0) then
        invaderNum  = 1
        composer.gotoScene("start")
    else
        playerIsInvincible = true
        spawnNewPlayer()
    end
end

function spawnNewPlayer()
    local numberOfTimesToFadePlayer = 5
    local numberOfTimesPlayerHasFaded = 0
     
    local  function fadePlayer()
        player.alpha = 0;
        transition.to( player, {time=400, alpha=1,  })
        numberOfTimesPlayerHasFaded = numberOfTimesPlayerHasFaded + 1
        if(numberOfTimesPlayerHasFaded == numberOfTimesToFadePlayer) then
            playerIsInvincible = false
        end
    end
     
  fadePlayer()
  timer.performWithDelay(400, fadePlayer,numberOfTimesToFadePlayer)
end

function levelComplete()
    invaderNum  = invaderNum  + 1
    if(invaderNum  <= maxLevels) then
         composer.gotoScene("gameover")
    else
        invaderNum  = 1
        composer.gotoScene("start")
     end
end

function gameLoop()
    checkPlayerBulletsOutOfBounds()
	checkInvaderBulletsOutOfBounds()
	--moveInvaders()
end

scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
return scene