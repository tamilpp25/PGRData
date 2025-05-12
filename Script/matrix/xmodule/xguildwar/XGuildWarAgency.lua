--- 公会战
---@class XGuildWarAgency : XAgency
---@field private _Model XGuildWarModel
---@field GarrisonCom XGarrisonAgencyCom @驻守玩法代理组件
---@field DragonRageCom XDragonRageAgencyCom @龙怒玩法代理组件
local XGuildWarAgency = XClass(XAgency, "XGuildWarAgency")
function XGuildWarAgency:OnInit()
    self.GarrisonCom = require("XModule/XGuildWar/SubModule/Garrison/XGarrisonAgencyCom").New()
    self.DragonRageCom = require('XModule/XGuildWar/SubModule/DragonRage/XDragonRageAgencyCom').New()
    
    self.GarrisonCom:Init(self, self._Model)
    self.DragonRageCom:Init(self, self._Model)
end

function XGuildWarAgency:InitRpc()
    XRpc.NotifyGuildWarActivityData = handler(self, self.OnNotifyGuildWarActivityData)
    XRpc.NotifyGuildWarRoundSettle = handler(self, self.OnNotifyGuildWarRoundSettle)
    XRpc.NotifyGuildWarFightRecordChange = handler(self, self.OnNotifyGuildWarFightRecordChange)
    XRpc.NotifyGuildWarActivityDataChange = handler(self, self.OnNotifyGuildWarActivityDataChange)
    XRpc.NotifyGuildWarAction = handler(self, self.OnNotifyGuildWarAction)
    XRpc.NotifyGuildWarNodeUpdate = handler(self, self.OnNotifyGuildWarNodeUpdate)
    XRpc.NotifyGuildWarMonsterUpdate = handler(self, self.OnNotifyGuildWarMonsterUpdate)
    XRpc.NotifyGuildWarBossLevelUp = handler(self, self.OnNotifyGuildWarBossLevelUp)
    XRpc.NotifyResourceNodeAttackedInfo = handler(self, self.OnNotifyResourceNodeAttackedInfo)
    XRpc.NotifyAddExtraActionPoint = handler(self, self.OnNotifyAddExtraActionPoint)
    XRpc.NotifyGuildWarDragonRageChange = handler(self, self.OnNotifyGuildWarDragonRageChange)
    XRpc.NotifyGuildWarNewGameThrough = handler(self, self.OnNotifyGuildWarNewGameThrough)
    XRpc.NotifyGuildWarDragonRageOpen = handler(self, self.OnNotifyGuildWarDragonRageOpen)
end

function XGuildWarAgency:InitEvent()

end

function XGuildWarAgency:OnRelease()
    self.GarrisonCom:Release()
    self.DragonRageCom:Release()

    self.GarrisonCom = nil
    self.DragonRageCom = nil
end

--region ---------- 玩法数据管理对象 ---------->>>

function XGuildWarAgency:GetGarrisonData()
    return self._Model:GetGarrisonData()
end

--endregion <<<--------------------------------

--region ---------- Network ---------->>>

--endregion <<<-------------------------

--region ---------- RPC ---------->>>

--- 登陆数据通知
function XGuildWarAgency:OnNotifyGuildWarActivityData(data)
    if XGuildWarConfig.CLOSE_DEBUG then
        return
    end
    self:GetGarrisonData():ClearDefensePlayerPercentCache()
    XDataCenter.GuildWarManager.OnNotifyActivityData(data)
    self.DragonRageCom:UpdateDataFromLoginNotify(data)
end

--- 轮次结算通知
function XGuildWarAgency:OnNotifyGuildWarRoundSettle(data)
    if XGuildWarConfig.CLOSE_DEBUG then
        return
    end
    XDataCenter.GuildWarManager.OnNotifyGuildWarRoundSettle(data)
end

--- 通知客户端，战斗记录有刷新
function XGuildWarAgency:OnNotifyGuildWarFightRecordChange(data)
    if XGuildWarConfig.CLOSE_DEBUG then
        return
    end
    XDataCenter.GuildWarManager.GetBattleManager():UpdateFightRecords(data.FightRecords)
end

--- 通知客户端，活动数据有刷新(8点)
function XGuildWarAgency:OnNotifyGuildWarActivityDataChange(data)
    if XGuildWarConfig.CLOSE_DEBUG then
        return
    end
    self:GetGarrisonData():ClearDefensePlayerPercentCache()
    XDataCenter.GuildWarManager.RefreshActivityData(data.ActivityData)
end

--- 通知客户端，新事件发生
function XGuildWarAgency:OnNotifyGuildWarAction(data)
    if XGuildWarConfig.CLOSE_DEBUG then
        return
    end
    local battleManager = XDataCenter.GuildWarManager.GetBattleManager()
    battleManager:AddActionList(data.ActionList)
    XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_ACTIONLIST_CHANGE, data.ActionList)
end

--- 通知客户端，节点数据更新
function XGuildWarAgency:OnNotifyGuildWarNodeUpdate(data)
    if XGuildWarConfig.CLOSE_DEBUG then
        return
    end

    if not XTool.IsTableEmpty(data.NodeDataList) then
        for i, nodeData in pairs(data.NodeDataList) do
            XDataCenter.GuildWarManager.GetBattleManager():UpdateNodeData(nodeData)
        end
    end
    XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_NODEDATA_CHANGE)
end

--- 通知客户端，怪物数据更新
function XGuildWarAgency:OnNotifyGuildWarMonsterUpdate(data)
    if XGuildWarConfig.CLOSE_DEBUG then
        return
    end
    XDataCenter.GuildWarManager.GetBattleManager():UpdateMonsterData(data.MonsterData)
    XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_MONSTER_CHANGE)
end

--- 通知客户端，Boss等级提升
function XGuildWarAgency:OnNotifyGuildWarBossLevelUp(data)
    if XGuildWarConfig.CLOSE_DEBUG then
        return
    end
    XDataCenter.GuildWarManager.GetBattleManager():UpdateNodeData(data.NodeData)
    XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_NODEDATA_CHANGE)
end

--- 通知客户端，资源点被炮击的信息
function XGuildWarAgency:OnNotifyResourceNodeAttackedInfo(data)
    if XGuildWarConfig.CLOSE_DEBUG then
        return
    end

    ---@type XGuildWarGarrisonData
    local garrisonData = self:GetGarrisonData()
    garrisonData:RefreshResourceNodeAttackedInfo(data)
end

--- 通知客户端，奖励额外行动点数
function XGuildWarAgency:OnNotifyAddExtraActionPoint(data)
    if XGuildWarConfig.CLOSE_DEBUG then
        return
    end
    -- 本地构造
    local rewardGoodsList = {{TemplateId = data.ItemId , RewardType = XRewardManager.XRewardType.Item, Count = data.Count}}
    XDataCenter.GuildWarManager.UpdateExtraActionPointData(rewardGoodsList)
end

function XGuildWarAgency:OnNotifyGuildWarDragonRageChange(data)
    ---@type XGuildWarDragonRageData
    local dragonRageData = self._Model:GetDragonRageData()
    
    dragonRageData:UpdateDragonRageValue(data)
end

function XGuildWarAgency:OnNotifyGuildWarNewGameThrough(data)
    ---@type XGuildWarDragonRageData
    local dragonRageData = self._Model:GetDragonRageData()

    dragonRageData:UpdateDragonRageData(data.RoundData)
    
    -- 更新轮次数据
    ---@type XGuildWarRound
    local roundData = XDataCenter.GuildWarManager.GetRoundByRoundId(data.RoundData.RoundId)

    if roundData then
        roundData:RefreshRoundData(data.RoundData)
    end
    
    XDataCenter.GuildWarManager.RefreshFightRecords({})
    
    -- 更新玩家自己的点位
    if XTool.IsNumberValid(data.CurNodeId) then
        local battleManager = XDataCenter.GuildWarManager.GetBattleManager()

        if battleManager then
            battleManager:UpdateCurrentNodeId(data.CurNodeId)
        end
    end

    -- 同步行为动画
    if not XTool.IsTableEmpty(data.ActionList) then
        local battleManager = XDataCenter.GuildWarManager.GetBattleManager()
        battleManager:AddActionList(data.ActionList)
        XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_ACTIONLIST_CHANGE, data.ActionList)
    end
end

--- 开启龙怒实时下推
function XGuildWarAgency:OnNotifyGuildWarDragonRageOpen(data)
    ---@type XGuildWarDragonRageData
    local dragonRageData = self._Model:GetDragonRageData()

    dragonRageData:UpdateDragonRageData(data.RoundData)

    -- 更新轮次数据
    ---@type XGuildWarRound
    local roundData = XDataCenter.GuildWarManager.GetRoundByRoundId(data.RoundData.RoundId)

    if roundData then
        roundData:RefreshRoundData(data.RoundData)
    end

    -- 同步行为动画
    if not XTool.IsTableEmpty(data.ActionList) then
        local battleManager = XDataCenter.GuildWarManager.GetBattleManager()
        battleManager:AddActionList(data.ActionList)
        XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_ACTIONLIST_CHANGE, data.ActionList)
    end
end
--endregion <<<----------------------

--region ---------- 界面临时数据 ---------->>>

--- set/get 当前关卡详情页查看的节点数据

function XGuildWarAgency:SetNodeInDetailShow(node)
    self._NodeInDetailShow = node
end

function XGuildWarAgency:GetNodeInDetailShow()
    return self._NodeInDetailShow
end
--endregion <<<----------------------------

return XGuildWarAgency