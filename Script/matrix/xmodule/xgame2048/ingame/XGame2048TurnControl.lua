--- 2048 玩法中分管回合信息的子控制器，包括棋盘状态等数据的管理
---@class XGame2048TurnControl: XControl
---@field private _MainControl XGame2048ActionsControl
---@field private _Model XGame2048Model
local XGame2048TurnControl = XClass(XControl, 'XGame2048TurnControl')
local XGame2048StageData = require('XModule/XGame2048/InGame/Entity/XGame2048StageData')
local XGame2048Transform = require('XModule/XGame2048/InGame/Entity/XGame2048Transform')

local GameScoreMaxLimit = 0

function XGame2048TurnControl:OnInit()
    ---@type XGame2048StageData
    self._StageDataFromServer = XGame2048StageData.New()
    ---@type XGame2048Transform
    self._TransformData = XGame2048Transform.New()

    GameScoreMaxLimit = self._MainControl._MainControl:GetClientConfigNum('GameScoreMaxLimit')

end

function XGame2048TurnControl:OnRelease()

end

function XGame2048TurnControl:InitOnNewGame(stageContext)
    self._StageDataFromServer:SetContext(stageContext)
    self._TransformData:Reset()
end

--region ---------- 回合信息显示 ---------->

function XGame2048TurnControl:GetLeftStepsCount()
    return self._StageDataFromServer:GetLeftStepsCount()
end

function XGame2048TurnControl:GetCurStepsCount()
    return self._StageDataFromServer:GetCurStepsCount()
end

function XGame2048TurnControl:GetCurScore()
    return self._StageDataFromServer:GetCurScore()
end

function XGame2048TurnControl:GetBoardLv()
    return self._StageDataFromServer:GetBoardLv()
end

function XGame2048TurnControl:GetFeverLeftRound()
    return self._StageDataFromServer:GetFeverLeftRound()
end

function XGame2048TurnControl:GetCurTargetMergeValue()
    local blockId = self:GetCurTargetBlockId()

    if XTool.IsNumberValid(blockId) then
        ---@type XTableGame2048Block
        local blockCfg = self._Model:GetGame2048BlockCfgById(blockId)

        if blockCfg then
            return blockCfg.Level
        end
    end
    
    return 0
end

function XGame2048TurnControl:GetCurTargetBlockCfg()
    local blockId = self:GetCurTargetBlockId()

    if XTool.IsNumberValid(blockId) then
        ---@type XTableGame2048Block
        local blockCfg = self._Model:GetGame2048BlockCfgById(blockId)

        return blockCfg
    end
end

--endregion <----------------------------

--region ---------- Getter ---------->

--- 获取当前回合方块信息源数据
function XGame2048TurnControl:GetGridInfos()
    return self._StageDataFromServer:GetGridInfos()
end

--- 获取经过客户端变换后的当前回合状态源数据的缓存
function XGame2048TurnControl:GetStageContextFromClient()
    return self._StageDataFromServer:GetStageContextFromClient()
end

function XGame2048TurnControl:GetCurBoardCfgId()
    local boardId = self._MainControl:GetCurBoardId()

    local ferverState = XTool.IsNumberValid(self:GetFeverLeftRound()) and 1 or 0

    local id = ferverState + self:GetBoardLv() * 10 + boardId * 10000
    
    return id
end

--- 当前目标方块的Id
function XGame2048TurnControl:GetCurTargetBlockId()
    local id = self:GetCurBoardCfgId()
    
    ---@type XTableGame2048Board
    local boardCfg = self._Model:GetGame2048BoardCfgById(id)

    if boardCfg then
        return boardCfg.TargetBlockId
    end
end

--- 获取当前盘面等级升级时的fever回合数增量
function XGame2048TurnControl:GetCurBoardFeverTimePlus()
    local id = self:GetCurBoardCfgId()

    ---@type XTableGame2048Board
    local boardCfg = self._Model:GetGame2048BoardCfgById(id)

    if boardCfg then
        return boardCfg.FeverTimePlus
    end
end

--- 获取当前盘面等级升级时的加分
function XGame2048TurnControl:GetCurBoardScoreAdd()
    local id = self:GetCurBoardCfgId()

    ---@type XTableGame2048Board
    local boardCfg = self._Model:GetGame2048BoardCfgById(id)

    if boardCfg then
        return boardCfg.BoardScore or 0
    end
end

--- 检查是否还有下一级目标
function XGame2048TurnControl:CheckHasNextTarget()
    local boardId = self._MainControl:GetCurBoardId()
    
    local id = (self:GetBoardLv() + 1) * 10 + boardId * 10000

    ---@type XTableGame2048Board
    local boardCfg = self._Model:GetGame2048BoardCfgById(id, true)

    return boardCfg and true or false
end

--endregion <-------------------------

--region ---------- Setter ---------->

function XGame2048TurnControl:UpdateNewTurnStageData(data)
    self._StageDataFromServer:UpdateByResultData(data)
end

--- 移除服务端数据中的方块源数据
function XGame2048TurnControl:RemoveGridDataInServerData(grid, isTurnBegin)
    self._StageDataFromServer:RemoveGridData(grid:GetServerData(), isTurnBegin)
end

--- 增加分数, 用于响应客户端变换的结果
function XGame2048TurnControl:AddScore(scoreAdds, isTurnBegin)
    local curScore = self:GetCurScore()
    local finalScore = curScore + scoreAdds

    if finalScore > GameScoreMaxLimit then
        finalScore = GameScoreMaxLimit
    end
    
    self._StageDataFromServer:UpdateScore(finalScore, isTurnBegin)
end

function XGame2048TurnControl:AddFeverLeftRound(feverTimePlus)
    self._StageDataFromServer:AddFeverLeftRound(feverTimePlus)
end

--- 盘面等级提升
function XGame2048TurnControl:BoardLevelUp()
    local feverTimePlus = self:GetCurBoardFeverTimePlus()

    -- 盘面升级加分
    self:AddScore(self:GetCurBoardScoreAdd())
    
    self._StageDataFromServer:UpBoardLv()
    
    -- 升级后进入充能状态
    self._StageDataFromServer:AddFeverLeftRound(feverTimePlus)
end

function XGame2048TurnControl:CountDownFeverLeftRound()
    self._StageDataFromServer:CountDownFeverLeftRound()
end

-- 按照当前盘面等级增加充能回合数
function XGame2048TurnControl:AddCurFeverLeftRound()
    local feverTimePlus = self:GetCurBoardFeverTimePlus()
    self._StageDataFromServer:AddFeverLeftRound(feverTimePlus)
end

--endregion <-------------------------

--region ---------- 棋盘状态变换记录 ---------->

--- 记录当前客户端棋盘上存在的方块及它们的坐标、类型信息
--- 转换成服务端能够识别的结构
---@param gridEntities table<XGame2048Grid>
function XGame2048TurnControl:SyncCurGridsToTransformData(gridEntities)
    self._TransformData:SetAfterBlocks(gridEntities)
end

--- 获取变换数据用于请求传参
function XGame2048TurnControl:GetTransformDataForServer()
    return self._TransformData:GetDataForServer()
end

--- 清空回合内操作产生的变换缓存
function XGame2048TurnControl:ClearLastTurnData()
    self._TransformData:Reset()
    self._StageDataFromServer:ClearLastInTurnData()
end

--endregion <----------------------------

return XGame2048TurnControl