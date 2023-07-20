import "CoreLibs/graphics"

local gfx <const> = playdate.graphics

local blocks = {
    {{0, 0, 0, 0}, {0, 0, 0, 1}, {0, 0, 0, 1}, {0, 0, 1, 1}},
    {{0, 0, 0, 1}, {0, 0, 0, 1}, {0, 0, 0, 1}, {0, 0, 0, 1}},
}

local wallImage = gfx.image.new( "Images/wall" )

function screenPosToGridPos(sx, sy)
    return {
        x = sx / 32,
        y = sy / 32
    }
end

function gridPosToScreenPos(gx, gy)
    return {
        x = gx * 32,
        y = 240 - gy * 32
    }
end

function drawBlock(blockIndex, x, y)
    local blockShape = blocks[blockIndex]
    local result = {}
    for i=1,4 do
        for j=1,4 do
            if blockShape[i][j] == 1 then
                local sprite = gfx.sprite.new( wallImage )
                sprite:setOpaque(true)
                -- sprite:setCollideRect(0, 28, 32, 4)
                local screenPos = gridPosToScreenPos(x + i - 1, y + j - 1)
                sprite:moveTo( screenPos.x, screenPos.y)
                sprite:add()
                result[#result+1] = sprite
            end
        end
    end
    return result
end

function drawRandomBlock(x, y)
    return drawBlock(math.random(#blocks), x, y)
end

function movePiece(piece, blockers, dx, dy)
    local maxX = 0
    local forbidden = {}
    for i=1,#blockers do
        if forbidden[blockers[i].x] == nil then
            forbidden[blockers[i].x] = {}
        end
        forbidden[blockers[i].x][blockers[i].y] = true
    end
    for i=1,#piece do
        block = piece[i]
        local newX = block.x + dx * 32
        local newY = block.y + dy * 32
        if newY >= 240 or newY <= 0 then
            return true
        end
        if forbidden[newX] ~= nil then
            if forbidden[newX][newY] then
                return true
            end
        end
    end
    for i=1,#piece do
        block = piece[i]
        block:moveTo(block.x + dx * 32, block.y + dy * 32)
        maxX = math.max(maxX, block.x)
    end
    if maxX >= 400 - 32 then
        return true
    end
    return false
end

function transferBlocks(blockListIn, blockListOut)
    while #blockListIn > 0 do
        blockListOut[#blockListOut+1] = blockListIn[#blockListIn]
        blockListIn[#blockListIn] = nil
    end
end

function clearBlocks(blockListIn)
    while #blockListIn > 0 do
        blockListIn[#blockListIn]:remove()
        blockListIn[#blockListIn] = nil
    end
end

function clearBlocksLine(blockListIn, x)
    local blockListOut = {}
    for i=1,#blockListIn do
        local block = blockListIn[i]
        local gridPos = screenPosToGridPos(blockListIn[i].x, blockListIn[i].y)
        if gridPos.x == x then
            block:remove()
        else
            blockListOut[#blockListOut+1] = block
        end
    end
    return blockListOut
end

function getBlocksInX(blockListIn, x)
    local result = {}
    for i=1,#blockListIn do
        local gridPos = screenPosToGridPos(blockListIn[i].x, blockListIn[i].y)
        if gridPos.x == x then
            result[#result+1] = blockListIn[i]
        end
    end
    return result
end