function love.load()
    camera = require 'libraries/camera'
    NPC = require 'libraries/npc'
    anim8 = require 'libraries/anim8'
    sti = require 'libraries/sti'
    narrator = require 'libraries/narrator'

    cam = camera()

    love.graphics.setDefaultFilter("nearest", "nearest")

    gameMap = sti('maps/testMap.lua')
    gameMap:resize(love.graphics.getWidth()*2, love.graphics.getHeight())

    -- Player configuration 
    player = {}
    player.x = 400
    player.y = 200
    player.speed = 300
    player.spriteSheet = love.graphics.newImage('sprites/player-sheet.png')
    player.grid = anim8.newGrid( 12, 18, player.spriteSheet:getWidth(), player.spriteSheet:getHeight() )

    player.animations = {}
    player.animations.down = anim8.newAnimation( player.grid('1-4', 1), 0.2 )
    player.animations.left = anim8.newAnimation( player.grid('1-4', 2), 0.2 )
    player.animations.right = anim8.newAnimation( player.grid('1-4', 3), 0.2 )
    player.animations.up = anim8.newAnimation( player.grid('1-4', 4), 0.2 )

    player.anim = player.animations.left

    player.characterRoster = {"Kanin", "Kroko", "Leon"} 
    player.activeCharacterIndex = 1 
    player.inventory = {}
    
    -- character sheet, starting position, wander x, wander y
    krokoNPC = NPC.new('sprites/player-sheet.png', 1595, 1065, 80, 0)
    leonNPC = NPC.new('sprites/player-sheet.png', 1700, 230, 50, 50)

    -- Narrator: ink + talkies wrapper. See narrator.lua.
    narrator:init()

    characterKanin = narrator:newCharacter("Kanin", "sprites/kanin_avatar.png") 
    characterKroko = narrator:newCharacter("Kroko", "sprites/kroko_avatar.png")
    characterLeon = narrator:newCharacter("Leon", "sprites/leon_avatar.png")

    narrator:bindNPC(krokoNPC, characterKroko, "KrokoTalks")
    narrator:bindNPC(leonNPC, characterLeon, "LeonTalks") 

    -- Distance (in world pixels) at which the "E" prompt appears.
    interactRange = 80

    -- Set when the player is close enough to a bound NPC to interact.
    nearbyNPC = nil

    -- Font for the floating "E" key prompt.
    promptFont = love.graphics.newFont(14)
    
    -- Flashlight Setup
    local w, h = love.graphics.getDimensions()
    flashlightCanvas = love.graphics.newCanvas(w,h)
    flashlightRadius = 120 
end

-- Check if a world position collides with a tile on the Trees layer
function treeAt(x, y)
    local layer = gameMap.layers["Trees"]
    local tx = math.floor(x / gameMap.tilewidth) + 1
    local ty = math.floor(y / gameMap.tileheight) + 1
    return layer.data[ty] and layer.data[ty][tx] or nil
end

-- Renders darkness with a clear brightness circle around the player
function drawFlashlightDarkness()
    love.graphics.setCanvas(flashlightCanvas)
    love.graphics.clear(0, 0, 0, 1) -- black screen

    local screenX, screenY = cam:toScreenCoords(player.x, player.y) 

    -- Use subtractive blend to cut out a visibility circle 
    love.graphics.setBlendMode("subtract")
    love.graphics.setColor(1, 1, 1, 1) 
    love.graphics.circle("fill", screenX, screenY, flashlightRadius)

    -- Reset to default canvas and window blend settings
    love.graphics.setCanvas()
    love.graphics.setBlendMode("alpha")

    -- Draw darkness canvas
    love.graphics.setColor(1, 1, 1, 0.92) 
    love.graphics.draw(flashlightCanvas, 0, 0)
    love.graphics.setColor(1, 1, 1, 1)
end

-- Find the closest bound NPC within interactRange (or nil).
function findNearbyNPC()
    local closest, closestDist = nil, interactRange
    for _, npc in ipairs(narrator._boundNPCs) do
        local dx = npc.x - player.x
        local dy = npc.y - player.y
        local dist = math.sqrt(dx * dx + dy * dy)
        if dist <= closestDist then
            closest, closestDist = npc, dist
        end
    end
    return closest
end

function love.update(dt)
    local dialogueOpen = narrator:isOpen()

    -- Freeze the player while a dialog is on screen so the conversation feels
    -- grounded. NPCs are paused via narrator:bindNPC's update wrapper.
    if not dialogueOpen then
        local isMoving = false
        local oldX, oldY = player.x, player.y

        if love.keyboard.isDown("right") then
            player.x = player.x + (player.speed * dt)
            player.anim = player.animations.right
            isMoving = true
        end

        if love.keyboard.isDown("left") then
            player.x = player.x - (player.speed * dt)
            player.anim = player.animations.left
            isMoving = true
        end

        if love.keyboard.isDown("down") then
            player.y = player.y + (player.speed * dt)
            player.anim = player.animations.down
            isMoving = true
        end

        if love.keyboard.isDown("up") then
            player.y = player.y - (player.speed * dt) 
            player.anim = player.animations.up
            isMoving = true
        end

        -- Collision: check each axis separately so player slides along walls
        if treeAt(player.x, oldY) then player.x = oldX end
        if treeAt(player.x, player.y) then player.y = oldY end

        if isMoving == false then
            player.anim:gotoFrame(2)
        end
    else
        -- Hold the idle pose during conversation.
        player.anim:gotoFrame(2)
    end

    player.anim:update(dt)

    -- Update camera position
    cam:lookAt(player.x, player.y)

    -- This section prevents the camera from viewing outside the background
    -- First, get width/height of the game window
    local w, h = love.graphics.getDimensions()

    -- Get the size of the map in pixels
    local mapW = gameMap.width * gameMap.tilewidth
    local mapH = gameMap.height * gameMap.tileheight

    -- Keep the camera inside the map
    cam.x = math.max(w/2, math.min(cam.x, mapW - w/2))
    cam.y = math.max(h/2, math.min(cam.y, mapH - h/2))

    krokoNPC:update(dt)
    leonNPC:update(dt)

    -- Refresh proximity once per frame, only when no dialog is showing.
    if dialogueOpen then
        nearbyNPC = nil
    else
        nearbyNPC = findNearbyNPC()
    end

    narrator:update(dt)
end

-- Small "E" key hint floating above an NPC's head.
function drawInteractPrompt(npc)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Press E", npc.x - 25, npc.y - 60)
end

function love.draw()
    cam:attach()
        gameMap:drawLayer(gameMap.layers["Ground"])
        player.anim:draw(player.spriteSheet, player.x, player.y, nil, 6, nil, 6, 9)
        krokoNPC:draw()
        leonNPC:draw()
        gameMap:drawLayer(gameMap.layers["Trees"])

        if nearbyNPC then
            drawInteractPrompt(nearbyNPC)
        end
    cam:detach()

    drawFlashlightDarkness()

    love.graphics.print("x = " .. math.floor(player.x) .. " y = " .. math.floor(player.y), 10, 10)

    love.graphics.setColor(1, 1, 1)
    local currentHero = player.characterRoster[player.activeCharacterIndex] or "NONE" 
    love.graphics.print("Playing As " .. currentHero, 10, 30) 

    -- Dialogue UI is drawn last so it sits on top of everything.
    narrator:draw()
end

function killCharacter()
    local deadHero = player.characterRoster[player.activeCharacterIndex]
    print(deadHero .. "has died!")

    player.activeCharacterIndex = player.activeCharacterIndex + 1

    if player.activeCharacterIndex > #player.characterRoster then
        print("GAME IS OVER. YOU ARE DEAD.")
    end
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end

    if key == "k" then 
        killCharacter()
    end
    
    if narrator:isOpen() then
        -- Inside a dialog: advance / pick options.
        if key == "space" or key == "return" then
            narrator:onAction()
        elseif key == "up" then
            narrator:prevOption()
        elseif key == "down" then
            narrator:nextOption()
        end
    else
        -- Outside a dialog: E starts a conversation with the closest NPC.
        if key == "e" and nearbyNPC then
            narrator:startScript(nearbyNPC)
        end
    end
end
