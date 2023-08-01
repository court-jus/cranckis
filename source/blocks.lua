import "CoreLibs/graphics"
import "CoreLibs/object"

local gfx <const> = playdate.graphics

local blocks = {
    {{0, 0, 0, 0}, {0, 0, 0, 1}, {0, 0, 0, 2}, {0, 0, 1, 1}},
    {{0, 0, 0, 1}, {0, 0, 0, 1}, {0, 0, 0, 2}, {0, 0, 0, 1}},
    {{0, 0, 0, 0}, {0, 0, 1, 0}, {0, 0, 2, 0}, {0, 0, 1, 1}},
    {{0, 0, 0, 0}, {0, 0, 0, 0}, {0, 0, 1, 2}, {0, 0, 1, 1}},
    {{0, 0, 0, 0}, {0, 0, 1, 0}, {0, 0, 1, 2}, {0, 0, 0, 1}},
    {{0, 0, 0, 0}, {0, 0, 0, 1}, {0, 0, 2, 1}, {0, 0, 1, 0}},
    {{0, 0, 0, 0}, {0, 0, 0, 0}, {0, 0, 1, 0}, {0, 1, 2, 1}},
}

local blockImage = gfx.image.new("Images/block")
local centerImage = gfx.image.new("Images/blockcenter")

class("Block").extends(gfx.sprite)

function Block:init(isCenter)
    Block.super.init(self)
    self:setImage(isCenter and centerImage or blockImage)
    self:setOpaque(true)
    self.isCenter = isCenter
    self.destX = self.x
    self.destY = self.y
end

function Block:update()
    Block.super.update(self)
    self.destX = self.x
    self.destY = self.y
end

function Block:prepareMoveTo(x, y)
    self.destX, self.destY = x, y
end

function Block:prepareMoveBy(dx, dy)
    self.destX += dx
    self.destY += dy
end

function Block:commitMove()
    self:moveTo(self.destX, self.destY)
end

class("BlockList").extends()

function BlockList:init()
    self.blocks = {}
end

function BlockList:append(newBlock)
    self.blocks[#self.blocks+1] = newBlock
end

class("Piece").extends(BlockList)

function Piece:init()
    self.rotated = 0
    self.wannaMove = 0
    self.blocks = drawRandomBlock(0, 0)
end

function Piece:update(blockers)
    if self.wannaMove == 0 then return end
    local blocked = movePiece(self.blocks, blockers, 0, self.wannaMove)
    if not blocked then
        self.wannaMove = 0
    end
end

function Piece:rotate(blockers, direction)
    local center = { x = 200, y = 120 }
    for _,block in pairs(self.blocks) do
        if block.isCenter then
            center = screenPosToGridPos(block.x, block.y)
            break
        end
    end
    local forbidden = {}
    for _,blocker in pairs(blockers) do
        local gridPos = screenPosToGridPos(blocker.x, blocker.y)
        if forbidden[gridPos.x] == nil then
            forbidden[gridPos.x] = {}
        end
        forbidden[gridPos.x][gridPos.y] = true
    end
    -- prepare Move
    local globalDelta = 0
    local commit = true
    for _, block in pairs(self.blocks) do
        if not block.isCenter then
            local gridPos = screenPosToGridPos(block.x, block.y)
            local dx, dy = gridPos.x - center.x, gridPos.y - center.y
            local newX, newY = center.x + (dy * direction), center.y - (dx * direction)
            if forbidden[newX] ~= nil then
                if forbidden[newX][newY] then
                    commit = false
                end
            end
            local newScrPos = gridPosToScreenPos(newX, newY)
            if newScrPos.y >= 240 then
                commit = false
            end
            if newScrPos.y <= 0 then
                commit = false
            end
            block:prepareMoveTo(newScrPos.x, newScrPos.y)
        end
    end
    if commit then
        for _, block in pairs(self.blocks) do
            block:commitMove()
        end
        self.rotated = (self.rotated + direction) % ROTATIONS_TO_SHIFT
    elseif direction == 1 then
        self.rotated = 0
    elseif direction == -1 then
        self.rotated = 3
    end
    if (direction == 1 and self.rotated == 0) or (direction == -1 and self.rotated == 3) then
        -- move piece up/down
        self.wannaMove = direction
    end
return not commit
end

function screenPosToGridPos(sx, sy)
    return {
        x = sx / BLOCK_SIZE,
        y = (240 - sy) / BLOCK_SIZE
    }
end

function gridPosToScreenPos(gx, gy)
    return {
        x = gx * BLOCK_SIZE,
        y = 240 - gy * BLOCK_SIZE
    }
end

function drawBlock(blockIndex, x, y)
    local blockShape = blocks[blockIndex]
    local result = {}
    for i=1,4 do
        for j=1,4 do
            if blockShape[i][j] > 0 then
                local sprite = Block(blockShape[i][j] == 2)
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
        local newX = block.x + dx * BLOCK_SIZE
        local newY = block.y + dy * BLOCK_SIZE
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
        block:moveTo(block.x + dx * BLOCK_SIZE, block.y + dy * BLOCK_SIZE)
        maxX = math.max(maxX, block.x)
    end
    if maxX >= 400 - BLOCK_SIZE then
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

function clearFullLines(blockListIn)
    local linesRemoved = 0
    for row=12,0,-1 do
        local lineBlocks = getBlocksInX(blockListIn, row)
        if #lineBlocks == 7 then
            -- Remove the line
            blockListIn = clearBlocksLine(blockListIn, row)
            linesRemoved += 1
        else
            -- Move the line down by linesRemoved
            for _, lineBlock in pairs(lineBlocks) do
                lineBlock:moveBy(BLOCK_SIZE * linesRemoved, 0)
            end
        end
        
    end

    return linesRemoved, blockListIn
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