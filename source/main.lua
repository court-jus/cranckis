import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

import "blocks"

local pd <const> = playdate
local gfx <const> = pd.graphics

local currentPiece
local staticBlocks = {}
local pieceSpeed = 300 -- milliseconds per piece movement
local nextMove = pd.getCurrentTimeMilliseconds() + pieceSpeed


local function loadGame()
    local backgroundImage = gfx.image.new( "Images/background" )
    assert( backgroundImage )
    gfx.sprite.setBackgroundDrawingCallback(
        function( x, y, width, height )
            -- x,y,width,height is the updated area in sprite-local coordinates
            -- The clip rect is already set to this area, so we don't need to set it ourselves
            backgroundImage:draw( 0, 0 )
        end
    )
    currentPiece = drawRandomBlock(0, 0)
end

local function updateGame()
    local now = pd.getCurrentTimeMilliseconds()
    if pd.buttonJustPressed( pd.kButtonUp ) then
        movePiece(currentPiece, staticBlocks, 0, -1)
    end
    if pd.buttonJustPressed( pd.kButtonDown ) then
        movePiece(currentPiece, staticBlocks, 0, 1)
    end
    if now > nextMove then
        local stopped = movePiece(currentPiece, staticBlocks, 1, 0)
        if stopped then
            transferBlocks(currentPiece, staticBlocks)
            print(#staticBlocks)
            local topBlocks = getBlocksInX(staticBlocks, 1)
            if #topBlocks > 0 then
                print("gamove")
                clearBlocks(staticBlocks)
            end
            currentPiece = drawRandomBlock(0, 0)
            nextMove = now + pieceSpeed
        end
        nextMove = now + pieceSpeed
    end
    local bottomBlocks = getBlocksInX(staticBlocks, 12)
    while #bottomBlocks >= 7 do
        staticBlocks = clearBlocksLine(staticBlocks, 12)
        movePiece(staticBlocks, {}, 1, 0)
        print("line !")
        bottomBlocks = getBlocksInX(staticBlocks, 12)
    end
end

local function drawGame()
	-- gfx.clear() -- Clears the screen
    gfx.sprite.update()
    pd.timer.updateTimers()
end

loadGame()

function pd.update()
	updateGame()
	drawGame()
	pd.drawFPS(0,0) -- FPS widget
end