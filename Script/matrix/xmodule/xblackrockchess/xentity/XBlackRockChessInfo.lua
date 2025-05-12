local XBlackRockChessGamer = require("XModule/XBlackRockChess/XGameObject/XBlackRockChessGamer")
local XBlackRockChessEnemy = require("XModule/XBlackRockChess/XGameObject/XBlackRockChessEnemy")
local XBlackRockChessReinforce = require("XModule/XBlackRockChess/XGameObject/XBlackRockChessReinforce")

---@class XBlackRockChessInfo : XControl 游戏对局信息
---@field _StageId number 关卡Id
---@field _Round number 回合数
---@field _EnemyInfo XBlackRockChessEnemy 棋子管理
---@field _PartnerInfo XBlackRockChessPartner 友方棋子
---@field _GamerInfo XBlackRockChessGamer 玩家管理
---@field _ShopInfo XBlackRockChessShop 局内商店信息
---@field _ReinforceInfos table<number, XBlackRockChessReinforce> 玩家管理
---@field _MainControl XBlackRockChessControl 主控制器
---@field _Model XBlackRockChessModel 数据
---@field _NodeGroupId number 节点组id
---@field _NodeIdx number 当前节点下标
local XBlackRockChessInfo = XClass(XControl, "XBlackRockChessInfo")

local MemberType = XEnumConst.BLACK_ROCK_CHESS.CHESS_MEMBER_TYPE

function XBlackRockChessInfo:OnInit()
    self._ReinforceInfos = {}
    self._ReinforcedDict = {} --已经增援的Id
    self._IsStageFinish = false
    self._Round = 0
    self._IncId = 0

    self._EnemyInfo = self._MainControl:AddSubControl(XBlackRockChessEnemy)
    self._PartnerInfo = self._MainControl:AddSubControl(require("XModule/XBlackRockChess/XGameObject/XBlackRockChessPartner"))
    self._GamerInfo = self._MainControl:AddSubControl(XBlackRockChessGamer)
    self._ShopInfo = self._MainControl:AddSubControl(require("XModule/XBlackRockChess/XEntity/XBlackRockChessShop"))
end

function XBlackRockChessInfo:DoEnterFight()
    local instance = CS.XBlackRockChess.XBlackRockChessManager.Instance
    --设置玩家
    self:SetPlayerImp(instance.Player, instance.Enemy, instance.Partner)
    --初始化棋子布局
    self._EnemyInfo:DoEnterFight()
    --初始化玩家布局
    self._GamerInfo:DoEnterFight()
    --初始化友军棋子布局
    self._PartnerInfo:DoEnterFight()
    --初始化增援
    local reinforceIds = self._MainControl:GetCurNodeCfg().ReinforceIds
    for _, reinforceId in ipairs(reinforceIds) do
        self:TryGetReinforce(reinforceId)
    end
end

function XBlackRockChessInfo:SetPlayerImp(gamerImp, enemyImp, partnerImp)
    self._GamerInfo:SetImp(gamerImp)
    self._EnemyInfo:SetImp(enemyImp)
    self._PartnerInfo:SetImp(partnerImp)
end

function XBlackRockChessInfo:UpdateBaseInfo(chessInfo)
    self._StageId = chessInfo.StageId
    self._Round = chessInfo.CurRound
    self._IncId = chessInfo.IncId
    self._NodeGroupId = chessInfo.NodeGroupId
    self._NodeIdx = chessInfo.NodeIdx + 1 -- 服务端索引从0开始
    self._BuffList = chessInfo.BuffList
end

-- 更新对局数据
function XBlackRockChessInfo:UpdateData(chessInfo)
    if XTool.IsTableEmpty(chessInfo) then
        return
    end
    self:UpdateBaseInfo(chessInfo)
    --玩家数据
    self._GamerInfo:UpdateData(chessInfo.Energy, chessInfo.ReviveTimes, chessInfo.StageStatData)
    --商店数据
    self._ShopInfo:UpdateBaseInfo(chessInfo)
    --检查临时友方棋子存活
    self._PartnerInfo:UpdateTransmigration()
    --友方棋子
    self._PartnerInfo:SetPrepareData(chessInfo.PartnerLayouts, chessInfo.PartnerPieces)
    
    -- 修改处理顺序
    local formations = chessInfo.Formations or {}
    table.sort(formations, function(a, b)
        return self:GetFormatDealOrder(a.Type) < self:GetFormatDealOrder(b.Type)
    end)
    
    local exists, partnerExists, bossExits = {}, {}, {}
    for _, formation in ipairs(formations) do
        local memberType = formation.Type
        if memberType == MemberType.MASTER or memberType == MemberType.ASSISTANT then
            self._GamerInfo:UpdateRole(formation)
        elseif memberType == MemberType.PARTNERPIECE or memberType == MemberType.PARTNERPIECE_PREVIEW then
            self._PartnerInfo:UpdatePieceData(formation, partnerExists)
        elseif memberType == XEnumConst.BLACK_ROCK_CHESS.CHESS_MEMBER_TYPE.BOSS then
            self._EnemyInfo:UpdateBossData(formation, bossExits)
        else
            self._EnemyInfo:UpdateData(formation, exists)
        end
    end
    self._EnemyInfo:UpdateFormation(exists)
    self._EnemyInfo:UpdateBossFormation(bossExits)
    self._PartnerInfo:UpdateFormation(partnerExists)
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
    self._MainControl:DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_BATTLE_VIEW_REFRESH)
end

-- 获取处理信息的顺序
function XBlackRockChessInfo:GetFormatDealOrder(memberType)
    if not self.FormatDealOrderDic then
        self.FormatDealOrderDic = {}
        local MEMBER_TYPE = XEnumConst.BLACK_ROCK_CHESS.CHESS_MEMBER_TYPE
        self.FormatDealOrderDic[MEMBER_TYPE.PIECE_PREVIEW] = 1
        self.FormatDealOrderDic[MEMBER_TYPE.REINFORCE_PREVIEW] = 2
        self.FormatDealOrderDic[MEMBER_TYPE.PIECE] = 3
        self.FormatDealOrderDic[MEMBER_TYPE.PARTNERPIECE_PREVIEW] = 4
        self.FormatDealOrderDic[MEMBER_TYPE.ASSISTANT] = 5
        self.FormatDealOrderDic[MEMBER_TYPE.PARTNERPIECE] = 6
        self.FormatDealOrderDic[MEMBER_TYPE.MASTER] = 7
        self.FormatDealOrderDic[MEMBER_TYPE.BOSS] = 8
    end
    return self.FormatDealOrderDic[memberType] or 0
end

---同步回合错误 根据服务端数据进行重置
function XBlackRockChessInfo:Retract(chessInfo)
    if XTool.IsTableEmpty(chessInfo) then
        return
    end
    self:UpdateBaseInfo(chessInfo)
    --玩家数据
    self._GamerInfo:UpdateData(chessInfo.Energy, chessInfo.ReviveTimes, chessInfo.StageStatData)
    --商店数据
    self._ShopInfo:UpdateBaseInfo(chessInfo)
    self._PartnerInfo:ClearRetractData()

    local formations = chessInfo.Formations or {}
    local disableDict, removeDict, allPieceDict = {}, {}, {}
    for _, formation in ipairs(formations) do
        local memberType = formation.Type
        if memberType == MemberType.MASTER or memberType == MemberType.ASSISTANT then
            self._GamerInfo:RetractRole(formation)
        elseif memberType == MemberType.BOSS then
            self._EnemyInfo:RetractBossData(formation)
        elseif memberType == MemberType.PARTNERPIECE or memberType == MemberType.PARTNERPIECE_PREVIEW then
            self._PartnerInfo:RetractData(formation)
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
    self._PartnerInfo:Retract()
    self._EnemyInfo:UpdateUpdateContainReinforce()
    
    self._MainControl:DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_BATTLE_VIEW_REFRESH)
end

function XBlackRockChessInfo:UpdateCondition()
    for _, reinforce in pairs(self._ReinforceInfos) do
        reinforce:UpdateCondition()
    end
end

--- 获取当前未完成的条件Id，全部完成则为最后一个
---@return number
--------------------------
function XBlackRockChessInfo:GetConditionId()
    local conditionId = self._Model:GetStageTargetCondition(self:GetStageId())
    if XTool.IsNumberValid(conditionId) and self._MainControl:CheckCondition(conditionId) then
        self._IsStageFinish = true
    end
    return conditionId
end

function XBlackRockChessInfo:IsFightingStageEnd()
    self:GetConditionId()
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

---@return XBlackRockChessPartner
function XBlackRockChessInfo:GetPartnerInfo()
    return self._PartnerInfo
end

---@return XBlackRockChessShop
function XBlackRockChessInfo:GetShopInfo()
    return self._ShopInfo
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

function XBlackRockChessInfo:GetNodeIdx()
    return self._NodeIdx
end

function XBlackRockChessInfo:GetBuffList()
    return self._BuffList
end

function XBlackRockChessInfo:GetNodeGroupId()
    return self._NodeGroupId
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
        self._MainControl:RemoveSubControl(self._PartnerInfo)
        self._MainControl:RemoveSubControl(self._ShopInfo)
    end
    self._GamerInfo = nil
    self._EnemyInfo = nil
    self._PartnerInfo = nil
    self._ShopInfo = nil
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

function XBlackRockChessInfo:GetReinforceCd(id)
    if self._ReinforceInfos[id] then
        return self._ReinforceInfos[id]:GetTriggerCd()
    end
    return 0
end

function XBlackRockChessInfo:Sync()
    self._GamerInfo:Sync()
    self._EnemyInfo:Sync()
    self._PartnerInfo:Sync()

    if not XTool.IsTableEmpty(self._ReinforceInfos) then
        for _, info in pairs(self._ReinforceInfos) do
            info:Sync()
        end
    end
end

function XBlackRockChessInfo:Restore()
    self._GamerInfo:Restore()
    self._EnemyInfo:Restore()
    self._PartnerInfo:Restore()

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