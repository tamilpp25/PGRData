local XLineArithmeticEnum = require("XModule/XLineArithmetic/Game/XLineArithmeticEnum")

---@class XLineArithmeticEvent
local XLineArithmeticEvent = XClass(nil, "XLineArithmeticEvent")

function XLineArithmeticEvent:Ctor()
    self._EventType = 0
    self._Score = 0
    self._Uid = 0
    self._FromGrid = false
end

function XLineArithmeticEvent:SetUid(uid)
    self._Uid = uid
end

function XLineArithmeticEvent:GetUid()
    return self._Uid
end

function XLineArithmeticEvent:SetEventType(eventType)
    self._EventType = eventType
end

function XLineArithmeticEvent:SetFromGrid(grid)
    self._FromGrid = grid
end

function XLineArithmeticEvent:SetScore(score)
    self._Score = score
end

function XLineArithmeticEvent:GetEventType()
    return self._EventType
end

function XLineArithmeticEvent:GetScore()
    return self._Score
end

---@param game XLineArithmeticGame
function XLineArithmeticEvent:Do(game)
    local eventType = self:GetEventType()

    if eventType == XLineArithmeticEnum.EVENT.FINAL_HARD then
        -- 终点加
        local score = self:GetScore()
        local finalGrids = game:GetAllFinalGrids()
        for i = 1, #finalGrids do
            local finalGrid = finalGrids[i]
            if not finalGrid:IsFinish() then
                finalGrid:SetNumberPreview(self, score)
            end
        end

    elseif eventType == XLineArithmeticEnum.EVENT.FINAL_EASY then
        -- 未通关的终点格 - params[2]
        local score = self:GetScore()
        local finalGrids = game:GetAllFinalGrids()
        for i = 1, #finalGrids do
            local finalGrid = finalGrids[i]
            if not finalGrid:IsFinish() then
                finalGrid:SetNumberPreview(self, score)
            end
        end

    elseif eventType == XLineArithmeticEnum.EVENT.PASS_EASY then
        -- 数字格 + params[2]
        local score = self:GetScore()
        local line = game:GetLineCurrent()
        local isEffect = false
        for i = #line, 1, -1 do
            local grid = line[i]
            if isEffect then
                if grid:IsNumberGrid() then
                    grid:SetNumberPreview(self, score)
                end
            end
            if grid:Equals(self._FromGrid) then
                isEffect = true
            end
        end

    elseif eventType == XLineArithmeticEnum.EVENT.PASS_HARD then
        -- 数字格 - params[2]
        local score = self:GetScore()
        local line = game:GetLineCurrent()
        local isEffect = false
        for i = #line, 1, -1 do
            local grid = line[i]
            if isEffect then
                if grid:IsNumberGrid() then
                    grid:SetNumberPreview(self, score)
                end
            end
            if grid:Equals(self._FromGrid) then
                isEffect = true
            end
        end
    end
end

---@param game XLineArithmeticGame
function XLineArithmeticEvent:UndoOnEventRemove(game)
    local eventType = self:GetEventType()

    if eventType == XLineArithmeticEnum.EVENT.FINAL_HARD then
        -- 终点加
        local score = self:GetScore()
        local finalGrids = game:GetAllFinalGrids()
        for i = 1, #finalGrids do
            local finalGrid = finalGrids[i]
            if not finalGrid:IsFinish() then
                finalGrid:SetNumberPreview(self, 0)
            end
        end

    elseif eventType == XLineArithmeticEnum.EVENT.FINAL_EASY then
        -- 未通关的终点格 - params[2]
        local score = self:GetScore()
        local finalGrids = game:GetAllFinalGrids()
        for i = 1, #finalGrids do
            local finalGrid = finalGrids[i]
            if not finalGrid:IsFinish() then
                finalGrid:SetNumberPreview(self, 0)
            end
        end

    elseif eventType == XLineArithmeticEnum.EVENT.PASS_EASY then
        -- 数字格 + params[2]
        local score = self:GetScore()
        local line = game:GetLineCurrent()
        for i = 1, #line do
            local grid = line[i]
            if grid:IsNumberGrid() then
                grid:SetNumberPreview(self, 0)
            end
        end

    elseif eventType == XLineArithmeticEnum.EVENT.PASS_HARD then
        -- 数字格 - params[2]
        local score = self:GetScore()
        local line = game:GetLineCurrent()
        for i = 1, #line do
            local grid = line[i]
            if grid:IsNumberGrid() then
                grid:SetNumberPreview(self, 0)
            end
        end
    end
end

---@param grid XLineArithmeticGrid
function XLineArithmeticEvent:UndoOnGridRemoveFromLineCurrent(grid)
    local eventType = self:GetEventType()
    if eventType == XLineArithmeticEnum.EVENT.PASS_HARD then
        grid:SetNumberPreview(self, 0)
    elseif eventType == XLineArithmeticEnum.EVENT.PASS_EASY then
        grid:SetNumberPreview(self, 0)
    end
end

---@param game XLineArithmeticGame
function XLineArithmeticEvent:Confirm(game)
    local eventType = self:GetEventType()

    if eventType == XLineArithmeticEnum.EVENT.FINAL_HARD then
        -- 终点加
        local score = self:GetScore()
        local finalGrids = game:GetAllFinalGrids()
        for i = 1, #finalGrids do
            local finalGrid = finalGrids[i]
            if not finalGrid:IsFinish() then
                finalGrid:SetNumberPreview(self, 0)
                --finalGrid:SetNumberOnConfirm(self, score)
            end
        end
        -- 只有这次连接的终点, 会+3
        local tailGrid = game:GetTailGridOfLineCurrent()
        if tailGrid and tailGrid:IsFinalGrid() then
            tailGrid:SetNumberOnConfirm(self, score)
        end

    elseif eventType == XLineArithmeticEnum.EVENT.FINAL_EASY then
        -- 未通关的终点格 - params[2]
        local score = self:GetScore()
        local finalGrids = game:GetAllFinalGrids()
        for i = 1, #finalGrids do
            local finalGrid = finalGrids[i]
            if not finalGrid:IsFinish() then
                finalGrid:SetNumberPreview(self, 0)
                finalGrid:SetNumberOnConfirm(self, score)
            end
        end

    elseif eventType == XLineArithmeticEnum.EVENT.PASS_EASY then
        -- 数字格 + params[2]
        local score = self:GetScore()
        local line = game:GetLineCurrent()
        local isEffect = false
        for i = #line, 1, -1 do
            local grid = line[i]
            if grid:Equals(self._FromGrid) then
                isEffect = true
            end
            if isEffect then
                if grid:IsNumberGrid() then
                    grid:SetNumberPreview(self, 0)
                    grid:SetNumberOnConfirm(self, score)
                end
            end
        end

    elseif eventType == XLineArithmeticEnum.EVENT.PASS_HARD then
        -- 数字格 - params[2]
        local score = self:GetScore()
        local line = game:GetLineCurrent()
        local isEffect = false
        for i = #line, 1, -1 do
            local grid = line[i]
            if grid:Equals(self._FromGrid) then
                isEffect = true
            end
            if isEffect then
                if grid:IsNumberGrid() then
                    grid:SetNumberPreview(self, 0)
                    grid:SetNumberOnConfirm(self, score)
                end
            end
        end
    end
end

---@param event XLineArithmeticEvent
function XLineArithmeticEvent:Equals(event)
    return self:GetUid() == event:GetUid()
end

return XLineArithmeticEvent
