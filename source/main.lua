import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/crank"
import "CoreLibs/ui"

import "blocks"
import "globals"
import "sounds"

local pd <const> = playdate
local ui <const> = pd.ui
local gfx <const> = pd.graphics

local currentPiece
local dropping = false
local staticBlocks = {}
local nextMove = pd.getCurrentTimeMilliseconds() + PIECE_SPEED
local font = gfx.font.new("Fonts/Pedallica/font-pedallica-fun-16")
gfx.setFont(font)
local score = 0
local totalLinesRemoved = 0
local storedData = pd.datastore.read()
local highScore =  1
if storedData ~= nil then
    highScore = storedData.highScore
end
local currentState = "menu"
local prevState = "menu"
local backgroundImage = gfx.image.new("Images/background")

local function loadMain()
    assert( backgroundImage )
    gfx.sprite.setBackgroundDrawingCallback(
        function( x, y, width, height )
            backgroundImage:draw( 0, 0 )
        end
    )
    ui.crankIndicator:start()
    pd.getCrankTicks(100)
end

local function getLevel()
    return math.floor(totalLinesRemoved / 10) + 1
end

local function clearGame()
    if currentPiece ~= nil then
        clearBlocks(currentPiece.blocks)
    end
    clearBlocks(staticBlocks)
end

local function restartGame()
    clearGame()
    score = 0
    currentPiece = Piece()
end

local function checkStateChange()
    if currentState == prevState then
        return
    end
    if currentState == "game" then
        playHappySound()
        restartGame()
    elseif currentState == "menu" then
        clearGame()
    elseif currentState == "gameover" then
        clearGame()
    end
    prevState = currentState
end

local function updateGame()
    local stopped = false
    local now = pd.getCurrentTimeMilliseconds()
    local crankTicks = pd.getCrankTicks(8)
    if crankTicks ~= 0 then
        print(crankTicks)
    end
    if crankTicks > 0 then
        currentPiece:rotate(staticBlocks, 1)
    end
    if crankTicks < 0 then
        currentPiece:rotate(staticBlocks, -1)
    end
    if pd.buttonJustPressed(pd.kButtonA) or pd.buttonJustPressed(pd.kButtonB) then
        dropping = true
        nextMove = now
    end
    local level = getLevel()
    local timeStep = (PIECE_SPEED / (dropping and DROP_SPEED or 1))
    if now >= nextMove then
        stopped = movePiece(currentPiece.blocks, staticBlocks, 1, 0)
        if stopped then
            playSound()
            dropping = false
            transferBlocks(currentPiece.blocks, staticBlocks)
            print(#staticBlocks)
            local topBlocks = getBlocksInX(staticBlocks, 1)
            if #topBlocks > 0 then
                currentState = "gameover"
                return
            end
            currentPiece = Piece()
            nextMove = now - timeStep
        end
        nextMove = now + timeStep
    end
    local linesRemoved = 0
    linesRemoved, staticBlocks = clearFullLines(staticBlocks)
    if linesRemoved > 0 then
        playHappySound()
        score += math.floor(2^(linesRemoved)-1)
        totalLinesRemoved += linesRemoved
    end
end

local function drawGame()
    local level = getLevel()
    gfx.drawText("Score " .. score .. " - Level " .. level, 1, 32*7)
end

local function drawMenu()
    local titleBg = gfx.image.new("Images/titlebg")
    titleBg:draw(0, 0)
    local text = "Welcome to Crankis\na game by Court-Jus\nHigh score " .. highScore
    gfx.drawTextInRect(text, 20, 20, 380, 200,nil,nil, 2)
end

local function drawGameover()
    local titleBg = gfx.image.new("Images/titlebg")
    titleBg:draw(0, 0)
    local text = "GAME OVER\nscore " .. score
    if score > highScore then
        text = text .. "\nNew high score,\nCongratulations !"
        highScore = score
        pd.datastore.write({highScore=score})
    end
    gfx.drawTextInRect(text, 20, 20, 380, 200,nil,nil, 2)
end

local function drawMain()
    gfx.sprite.update()
    if pd.isCrankDocked() then
        ui.crankIndicator:update()
        currentState = "menu"
    end
    if currentState == "game" then
        drawGame()
    elseif currentState == "menu" then
        drawMenu()
    elseif currentState == "gameover" then
        drawGameover()
    end
    pd.timer.updateTimers()
end

local function updateMenu()
    if (pd.buttonJustPressed(pd.kButtonA) or pd.buttonJustPressed(pd.kButtonB)) and not pd.isCrankDocked() then
        currentState = "game"
    end
    if pd.isCrankDocked() then
        ui.crankIndicator:update()
    end
end

local function updateGameover()
    if pd.buttonJustPressed(pd.kButtonA) or pd.buttonJustPressed(pd.kButtonB) then
        currentState = "menu"
    end
end

local function updateMain()
    if currentState == "game" then
        updateGame()
    elseif currentState == "menu" then
        updateMenu()
    elseif currentState == "gameover" then
        updateGameover()
    end
    checkStateChange()
end

function pd.gameWillPause()
    local level = getLevel()
    local menuImage = gfx.image.new(400, 240, gfx.kColorWhite)
    gfx.pushContext(menuImage)
        gfx.drawRoundRect(2, 2, 196, 236, 5)
        local text = "Crankis\n\nScore "..score.."\n\nLevel "..level.."\nLines "..totalLinesRemoved.."\n\nHigh score "..highScore
        print(text)
        gfx.drawTextAligned(text, 100, 10, 2)
    gfx.popContext()
    pd.setMenuImage(menuImage)
end

loadMain()

function pd.update()
	updateMain()
	drawMain()
end