--- 当前关的游戏数据
---@class XGame2048StageData
local XGame2048StageData = XClass(nil, 'XGame2048StageData')

function XGame2048StageData:SetContext(stageContext)
    if not XTool.IsTableEmpty(stageContext) then
        self.Score = stageContext.Score
        self.Grids = stageContext.Grids
        self.CurrentSteps = stageContext.CurrentSteps
        self.MaxSteps = stageContext.MaxSteps
        self._StageContext = stageContext
        self.BoardLv = stageContext.BoardLv
        self.FeverLeftRound = stageContext.FeverLeftRound
    else
        self.Score = 0
        self.CurrentSteps = 0
        self.MaxSteps = 0
    end
end


function XGame2048StageData:UpdateByResultData(resultData)
    if XTool.IsTableEmpty(resultData) then
        return
    end
    
    self:_UpdateCurrentSteps(resultData.CurrentSteps)
    self:UpdateScore(resultData.Score)
    if not XTool.IsTableEmpty(resultData.GeneratedResults) then
        self.GeneratedResults = resultData.GeneratedResults
        for i, v in pairs(resultData.GeneratedResults) do
            if not XTool.IsTableEmpty(v.TargetBlock) then
                self:UpdateNewGrids(v.TargetBlock)
            end
        end
    end
end

function XGame2048StageData:_UpdateCurrentSteps(curSteps)
    if XTool.IsNumberValid(curSteps) then
        self.CurrentSteps = curSteps
    end
end

---@param inturn @是否是回合内产生的
function XGame2048StageData:UpdateScore(score, inturn)
    if XTool.IsNumberValid(score) then
        if inturn then
            -- 记录增量
            if self.ChangeScore == nil then
                self.ChangeScore = 0
            end
            self.ChangeScore = self.ChangeScore + score - self.Score
        end
        
        self.Score = score
    end
end

---@param inturn @是否是回合内产生的
function XGame2048StageData:UpdateNewGrids(grid, inturn)
    if XTool.IsTableEmpty(grid) then
        return
    end
    
    if self.Grids == nil then
        self.Grids = {}
    end

    if inturn then
        if self._InTurnGrids == nil then
            self._InTurnGrids = {}
        end
        table.insert(self._InTurnGrids, grid)
    end

    table.insert(self.Grids, grid)
end

---@param inturn @是否是回合内消除的
function XGame2048StageData:RemoveGridData(data, inturn)
    if XTool.IsTableEmpty(data) then
        return
    end

    if not XTool.IsTableEmpty(self.Grids) then
        local isin, index = table.contains(self.Grids, data)
        if isin then

            if inturn then
                if self._RemoveInTurnGrids == nil then
                    self._RemoveInTurnGrids = {}
                end
                table.insert(self._RemoveInTurnGrids, self.Grids[index])
            end
            
            table.remove(self.Grids, index)
        end
    end
end

function XGame2048StageData:UpBoardLv()
    self.BoardLv = self.BoardLv + 1
end

function XGame2048StageData:GetCurBuffData()
    return self.GeneratedResults
end

function XGame2048StageData:GetLeftStepsCount()
    return self.MaxSteps - self.CurrentSteps
end

function XGame2048StageData:GetCurStepsCount()
    return self.CurrentSteps
end

function XGame2048StageData:GetMaxStepsCount()
    return self.MaxSteps
end

function XGame2048StageData:GetCurScore()
    return self.Score
end

function XGame2048StageData:GetBoardLv()
    return self.BoardLv
end

function XGame2048StageData:GetFeverLeftRound()
    return self.FeverLeftRound
end

function XGame2048StageData:AddFeverLeftRound(times)
    if not XTool.IsNumberValid(times) then
        return
    end
    
    if self.FeverLeftRound == nil then
        self.FeverLeftRound = times
    else
        self.FeverLeftRound = self.FeverLeftRound + times
    end
end

function XGame2048StageData:CountDownFeverLeftRound()
    if XTool.IsNumberValid(self.FeverLeftRound) then
        self.FeverLeftRound = self.FeverLeftRound - 1
    end
end

function XGame2048StageData:ClearLastInTurnData()
    self._InTurnGrids = nil
    self._RemoveInTurnGrids = nil
end

function XGame2048StageData:GetGridInfos()
    return self.Grids
end

function XGame2048StageData:GetStageContextFromClient()
    if self._StageContext == nil then
        self._StageContext = {}
    end
    
    -- 缓存前要把局内数据给清掉
    if not XTool.IsTableEmpty(self._InTurnGrids) then
        for i, v in pairs(self._InTurnGrids) do
            local isIn, index = table.contains(self.Grids, v)
            if isIn then
                table.remove(self.Grids, index)
            end
        end
        self:ClearLastInTurnData()
    end
    
    -- 局内消除的格子要还原回去
    if not XTool.IsTableEmpty(self._RemoveInTurnGrids) then
        for i, v in pairs(self._RemoveInTurnGrids) do
            table.insert(self.Grids, v)
        end
    end
    
    -- 局内分数变化要还原回去
    if XTool.IsNumberValid(self.ChangeScore) then
        self.Score = self.Score - self.ChangeScore
        self.ChangeScore = nil
    end

    -- 局内步数变化要还原回去
    if XTool.IsNumberValid(self.ChangeMaxSteps) then
        self.MaxSteps = self.MaxSteps - self.ChangeMaxSteps
        self.ChangeMaxSteps = nil
    end
    
    self._StageContext.GeneratedResults = self.GeneratedResults
    self._StageContext.Score = self.Score
    self._StageContext.Grids = self.Grids
    self._StageContext.CurrentSteps = self.CurrentSteps
    self._StageContext.MaxSteps = self.MaxSteps
    self._StageContext.BoardLv = self.BoardLv
    self._StageContext.FeverLeftRound = self.FeverLeftRound
    return self._StageContext
end

return XGame2048StageData