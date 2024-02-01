local XBlackRockChessGamer = require("XModule/XBlackRockChess/XGameObject/XBlackRockChessGamer")
local XBlackRockChessEnemy = require("XModule/XBlackRockChess/XGameObject/XBlackRockChessEnemy")
local XBlackRockChessReinforce = require("XModule/XBlackRockChess/XGameObject/XBlackRockChessReinforce")

---@class XBlackRockChessInfo : XControl 游戏对局信息
---@field _StageId number 关卡Id
---@field _Round number 回合数
---@field _EnemyInfo XBlackRockChessEnemy 棋子管理
---@field _GamerInfo XBlackRockChessGamer 玩家管理
---@field _ReinforceInfos table<number, XBlackRockChessReinforce> 玩家管理
---@field _MainControl XBlackRockChessControl 主控制器
---@field _Model XBlackRockChessModel 数据
local XBlackRockChessInfo = XClass(XControl, "XBlackRockChessInfo")

function XBlackRockChessInfo:OnInit()
    self._ReinforceInfos = {}
    self._ReinforcedDict = {} --已经增援的Id
    self._ConditionData = {
        Id = 0,
        Value = 0,
        Index = 1,
    }
    self._IsStageFinish = false
    self._Round = 0
    self._IncId = 0

    self._EnemyInfo = self._MainControl:AddSubControl(XBlackRockChessEnemy)
    self._GamerInfo = self._MainControl:AddSubControl(XBlackRockChessGamer)
end

function XBlackRockChessInfo:DoEnterFight()
    local instance = CS.XBlackRockChess.XBlackRockChessManager.Instance
    --设置玩家
    self:SetPlayerImp(instance.Player, instance.Enemy)
    --初始化棋子布局
    self._EnemyInfo:DoEnterFight()
    --初始化玩家布局
    self._GamerInfo:DoEnterFight()
    --初始化增援
    local reinforceIds = self._Model:GetStageReinforceIds(self._StageId)
    for _, reinforceId in ipairs(reinforceIds) do
        self:TryGetReinforce(reinforceId)
    end
end

function XBlackRockChessInfo:SetPlayerImp(gamerImp, enemyImp)
    self._GamerInfo:SetImp(gamerImp)
    self._EnemyInfo:SetImp(enemyImp)
end

function XBlackRockChessInfo:UpdateBaseInfo(chessInfo)
    self._StageId = chessInfo.StageId
    self._Round = chessInfo.CurRound
    self._IncId = chessInfo.IncId
    self:UpdateConditionData(chessInfo.ConditionData)
end

function XBlackRockChessInfo:UpdateData(chessInfo)
    if XTool.IsTableEmpty(chessInfo) then
        return
    end
    self:UpdateBaseInfo(chessInfo)
    --玩家数据
    self._GamerInfo:UpdateData(chessInfo.Energy, chessInfo.ReviveTimes, chessInfo.KillData)
    
    local formations = chessInfo.Formations or {}
    local exists = {}
    for _, formation in ipairs(formations) do
        local memberType = formation.Type
        if memberType == XEnumConst.BLACK_ROCK_CHESS.CHESS_MEMBER_TYPE.MASTER 
                or memberType == XEnumConst.BLACK_ROCK_CHESS.CHESS_MEMBER_TYPE.ASSISTANT then
            self._GamerInfo:UpdateRole(formation)
        else
            self._EnemyInfo:UpdateData(formation, exists)
        end
    end
    self._EnemyInfo:UpdateFormation(exists)
    --已经增援的Id
    self._ReinforcedDict = {}
    local trigger = chessInfo.TriggeredReinforces or {}
    for _, id in ipairs(trigger) do
        self._ReinforcedDict[id] = id
    end
    local reinforces = chessInfo.Reinforces or {}
    for _, reinforce in ipairs(reinforces) do
        local info = self:TryGetReinforce(reinforce.Id)
        if info then
            info:UpdateData(reinforce.PreviewCd, reinforce.TriggerCd)
        end
    end
    
    self._EnemyInfo:UpdateUpdateContainReinforce()
    XEventManager.DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_BATTLE_VIEW_REFRESH)
end

function XBlackRockChessInfo:Retract(chessInfo)
    if XTool.IsTableEmpty(chessInfo) then
        return
    end
    self:UpdateBaseInfo(chessInfo)
    --玩家数据
    self._GamerInfo:UpdateData(chessInfo.Energy, chessInfo.ReviveTimes, chessInfo.KillData)

    local formations = chessInfo.Formations or {}
    local disableDict, removeDict, allPieceDict = {}, {}, {}
    for _, formation in ipairs(formations) do
        local memberType = formation.Type
        if memberType == XEnumConst.BLACK_ROCK_CHESS.CHESS_MEMBER_TYPE.MASTER
                or memberType == XEnumConst.BLACK_ROCK_CHESS.CHESS_MEMBER_TYPE.ASSISTANT then
            self._GamerInfo:RetractRole(formation)
        else
            self._EnemyInfo:RetractData(formation, disableDict, removeDict, allPieceDict)
        end
    end

    local reinforces = chessInfo.Reinforces or {}
    for _, reinforce in ipairs(reinforces) do
        local info = self:TryGetReinforce(reinforce.Id)
        if info then
            info:UpdateData(reinforce.PreviewCd, reinforce.TriggerCd)
        end
    end
    
    self._EnemyInfo:Retract(disableDict, removeDict, allPieceDict)
    self._GamerInfo:OnRoundBegin()
    self._EnemyInfo:UpdateUpdateContainReinforce()
    
    XEventManager.DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_BATTLE_VIEW_REFRESH)
end

function XBlackRockChessInfo:UpdateCondition()
    for _, reinforce in pairs(self._ReinforceInfos) do
        reinforce:UpdateCondition()
    end
end

function XBlackRockChessInfo:UpdateConditionData(data)
    local id = data.Id
    local value = data.Value
    local index = 1
    local conditions = self._Model:GetStageTargetCondition(self:GetStageId())
    for i, conditionId in ipairs(conditions) do
        if id == conditionId then
            index = i
            break
        end
    end
    
    self._ConditionData.Id = id
    self._ConditionData.Value = value
    self._ConditionData.Index = index
end

--- 获取当前未完成的条件Id，全部完成则为最后一个
---@return number
--------------------------
function XBlackRockChessInfo:GetActiveConditionId()
    if not self._ConditionData then
        return 0
    end
    local index = self._ConditionData.Index
    local conditions = self._Model:GetStageTargetCondition(self:GetStageId())
    local id = conditions[index]
    
    local count = #conditions
    
    while true do
        local ret, _ = self._MainControl:CheckCondition(id)
        if not ret then
            break
        end
        index = index + 1
        if index > count then
            self._IsStageFinish = true
            break
        end
        id = conditions[index]
    end
    self._ConditionData.Index = math.min(count, index)
    return id
end

function XBlackRockChessInfo:IsFightingStageEnd()
    self:GetActiveConditionId()
    return self._IsStageFinish
end

function XBlackRockChessInfo:GetRetractCount()
    return self._Model:GetRetractCount()
end

function XBlackRockChessInfo:GetPieceDict()
    return self._EnemyInfo:GetPieceInfoDict()
end

---@return XBlackRockChessGamer
function XBlackRockChessInfo:GetGamerInfo()
    return self._GamerInfo
end

---@return XBlackRockChessEnemy
function XBlackRockChessInfo:GetEnemyInfo()
    return self._EnemyInfo
end

function XBlackRockChessInfo:GetPieceFormation(id)
    local info = self._EnemyInfo:GetPieceInfo(id)
    if not info then
        XLog.Error("获取棋子布局信息失败, 不存在Id = " .. id .. "的棋子")
        return
    end
    return info
end

function XBlackRockChessInfo:GetStageId()
    return self._StageId
end

function XBlackRockChessInfo:GetRound()
    return self._Round
end

function XBlackRockChessInfo:ChangeRound(count)
    self._Round = self._Round + count
end

---@return XBlackRockChessPiece[]
function XBlackRockChessInfo:GetCanMovePieceList()
    return self._EnemyInfo:GetCanMovePieceList()
end

function XBlackRockChessInfo:ExitFight()
    for _, info in pairs(self._ReinforceInfos or {}) do
        info:Release()
    end
    if self._MainControl then
        self._MainControl:RemoveSubControl(self._GamerInfo)
        self._MainControl:RemoveSubControl(self._EnemyInfo)
    end
    self._GamerInfo = nil
    self._EnemyInfo = nil
    self._ReinforceInfos = {}
    self._Round = 0
    self._IncId = 0
end

function XBlackRockChessInfo:UpdateReinforce()
    if XTool.IsTableEmpty(self._ReinforceInfos) then
        return
    end
    for _, info in pairs(self._ReinforceInfos) do
        info:UpdateAction()
    end
end

function XBlackRockChessInfo:GetReinforceActionList()
    if XTool.IsTableEmpty(self._ReinforceInfos) then
        return {}
    end
    local list = {}
    for _, info in pairs(self._ReinforceInfos) do
        list = XTool.MergeArray(list, info:GetActionList())
    end
    return list
end

function XBlackRockChessInfo:TryGetReinforce(reinforceId)
    local info = self._ReinforceInfos[reinforceId]
    if info then
        return info
    end
    
    --如果没有配置则不创建
    local template = self._Model:GetReinforceConfig(reinforceId)
    if not template then
        return
    end
    info = XBlackRockChessReinforce.New(reinforceId, self._MainControl)
    self._ReinforceInfos[reinforceId] = info
    return info
end

function XBlackRockChessInfo:CheckReinforceTrigger(reinforceId)
    return self._ReinforcedDict[reinforceId] ~= nil
end

function XBlackRockChessInfo:GetIncId()
    self._IncId = self._IncId + 1
    return self._IncId
end

function XBlackRockChessInfo:Sync()
    self._GamerInfo:Sync()
    self._EnemyInfo:Sync()

    if not XTool.IsTableEmpty(self._ReinforceInfos) then
        for _, info in pairs(self._ReinforceInfos) do
            info:Sync()
        end
    end
end

function XBlackRockChessInfo:Restore()
    self._GamerInfo:Restore()
    self._EnemyInfo:Restore()

    if not XTool.IsTableEmpty(self._ReinforceInfos) then
        for _, info in pairs(self._ReinforceInfos) do
            info:Restore()
        end
    end
end

function XBlackRockChessInfo:OnRelease()
    self:ExitFight()
    self._ReinforceInfos = nil
end

return XBlackRockChessInfo