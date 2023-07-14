local XUiPanelEliteMonster = require("XUi/XUiGuildWar/Node/XUiPanelEliteMonster")
local XUiPanelNodeDetail = require("XUi/XUiGuildWar/Node/XUiPanelNodeDetail")
--######################## XUiGuildWarStageDetail ########################
local XUiGuildWarStageDetail = XLuaUiManager.Register(XLuaUi, "UiGuildWarStageDetail")

function XUiGuildWarStageDetail:OnAwake()
    self.GuildWarManager = XDataCenter.GuildWarManager
    self.BattleManager = self.GuildWarManager.GetBattleManager()
    self.UiPanelNodeDetail = XUiPanelNodeDetail.New(self.PanelNodeDetail, self)
    self.UiPanelEliteMonster = XUiPanelEliteMonster.New(self.PanelEliteMonster)
    self.Node = nil
    self.IsMonsterStatus = false
    self.TimeId = nil
    self.CurrentChildPanel = nil
    self:RegisterUiEvents()
    XUiHelper.NewPanelActivityAsset({ XGuildWarConfig.ActivityPointItemId }
        , self.PanelSpecialTool, { self.GuildWarManager.GetMaxEnergy() })
    -- 子面板信息配置
    self.ChildPanelInfoDic = {
        [XGuildWarConfig.NodeType.Sentinel] = {
            uiParent = self.PanelSentinel,
            instanceGo = self.PanelSentinel,
            proxy = require("XUi/XUiGuildWar/Node/XUiPanelSentinel"),
            proxyArgs = { "Node" },
        },
        [XGuildWarConfig.NodeType.Guard] = {
            uiParent = self.PanelGuard,
            instanceGo = self.PanelGuard,
            proxy = require("XUi/XUiGuildWar/Node/XUiPanelGuard"),
            proxyArgs = { "Node" },
        },
        [XGuildWarConfig.NodeType.Infect] = {
            uiParent = self.PanelInfect,
            instanceGo = self.PanelInfect,
            proxy = require("XUi/XUiGuildWar/Node/XUiPanelInfect"),
            proxyArgs = { "Node" },
        },
        [XGuildWarConfig.NodeType.Buff] = {
            uiParent = self.PanelBuff,
            instanceGo = self.PanelBuff,
            proxy = require("XUi/XUiGuildWar/Node/XUiPanelBuff"),
            proxyArgs = { "Node" },
        },
        [XGuildWarConfig.NodeType.Home] = {
            uiParent = self.PanelHome,
            instanceGo = self.PanelHome,
            proxy = require("XUi/XUiGuildWar/Node/XUiPanelHome"),
            proxyArgs = { "Node" },
        },
    }
    -- 连接信号
    self.UiPanelNodeDetail:ConnectSignal("ChangeTopDetailStatus", self, self.OnChangeTopDetailStatus)
    self.UiPanelEliteMonster:ConnectSignal("ChangeTopDetailStatus", self, self.OnChangeTopDetailStatus)
end

-- node : XNormalGWNode
function XUiGuildWarStageDetail:OnStart(node, isMonsterStatus)
    if isMonsterStatus == nil then isMonsterStatus = false end
    self.IsMonsterStatus = isMonsterStatus
    self:RefreshNode(node)
    if isMonsterStatus then
        self:OnChangeTopDetailStatus(true)
    end
end

function XUiGuildWarStageDetail:OnEnable()
    XUiGuildWarStageDetail.Super.OnEnable(self)
    if not self.TimeId then
        self.TimeId = XScheduleManager.ScheduleForever(function()
                self:RefreshTimeData()
            end, XScheduleManager.SECOND, 0)
    end
    
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_ACTIONLIST_CHANGE, self.CheckClose, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_TIME_REFRESH, self.RefreshNode, self)
    XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_STAGEDETAIL_CHANGE, self.Node:GetStageIndexName(), self.IsMonsterStatus)
end

function XUiGuildWarStageDetail:OnDisable()
    XUiGuildWarStageDetail.Super.OnDisable(self)
    
    if self.TimeId then
        XScheduleManager.UnSchedule(self.TimeId)
        self.TimeId = nil
    end 
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_ACTIONLIST_CHANGE, self.CheckClose, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_TIME_REFRESH, self.RefreshNode, self)
end

function XUiGuildWarStageDetail:OnDestroy()
    XUiGuildWarStageDetail.Super.OnDestroy(self)
    XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_STAGEDETAIL_CHANGE, nil, nil)
end

function XUiGuildWarStageDetail:RefreshNode(node)
    if node == nil then node = self.Node end
    self.Node = node
    
    local monster = self:GetNodeMonster()
    if self.IsMonsterStatus and not monster then
        return
    end
        
    self.BattleManager:UpdateCurrentClientBattleInfo(node:GetUID(), node:GetStutesType())
    self.UiPanelNodeDetail:SetData(node)
    self.UiPanelEliteMonster:SetData(monster)
    -- 节点基本信息
    self.TxtName.text = node:GetName()
    -- 感染区攻破后名字特殊处理
    if node:GetNodeType() == XGuildWarConfig.NodeType.Infect and node:GetIsDead() then
        self.TxtName.text = XUiHelper.GetText("GuildWarResidueName")
    end
    -- 安全区域or危险区域提示
    local statusType = node:GetStutesType()
    self.TxtDanger.gameObject:SetActiveEx(statusType == XGuildWarConfig.NodeStatusType.Alive
        or statusType == XGuildWarConfig.NodeStatusType.Revive)
    self.TxtSave.gameObject:SetActiveEx(statusType == XGuildWarConfig.NodeStatusType.Die)
    -- 节点奖励
    self:RefreshRewardList()
    -- 精英怪信息
    self.PanelEliteMonsterDetail.gameObject:SetActiveEx(self.IsMonsterStatus)
    self:RefreshTimeData()
    -- 刷新节点
    self:RefreshNodeTypeDetail(node:GetNodeType())
    -- 刷新在线成员
    self.BtnPlayer:SetNameByGroup(1, node:GetMemberCount())
    -- 按钮状态
    self:RefreshButtonStatus()
end

function XUiGuildWarStageDetail:RefreshTimeData()
    -- 怪物前进时间
    local monster = self:GetNodeMonster()
    if monster then
        self.TxtMonsterForwardTime.text = XUiHelper.GetText("GuildWarForwardTimeTip", monster:GetForwardTimeStr())
        self.TxtMonsterDetails.text = XUiHelper.GetText("GuildWarMonsterDetails", monster:GetDamagePercent())
    end
    -- 更新子界面刷新时间
    if self.CurrentChildPanel and self.CurrentChildPanel.RefreshTimeData then
        self.CurrentChildPanel:RefreshTimeData()
    end
    -- 节点详情重建时间
    self.UiPanelNodeDetail:RefreshTimeData()
    if self.Node:GetNodeType() == XGuildWarConfig.NodeType.Sentinel and self.Node:GetIsOverMaxRebuildTime() then
        -- 因为上面RefreshTimeData有可能会关掉页面，会继续导致进来资源已经被销毁，判个空
        if XTool.UObjIsNil(self.GameObject) then
            return
        end
        self.BtnAutoFight.gameObject:SetActiveEx(false)
        self.BtnFight.gameObject:SetActiveEx(false)
        self.TxtTipsLeft.gameObject:SetActiveEx(not self.BattleManager:CheckAllInfectIsDead())
        self.TxtTipsLeft.text = XUiHelper.ConvertLineBreakSymbol(XUiHelper.GetText("GuildWarRebuildMaxTimeTip", self.Node:GetRebuildTimeStr()))
        return
    end
end

--######################## 私有方法 ########################

function XUiGuildWarStageDetail:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnFight, self.OnBtnFightClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnAutoFight, self.OnBtnAutoFightClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnGo, self.OnBtnGoClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnHelp, self.OnBtnHelpClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnPlayer, self.OnBtnPlayerClicked)
end

function XUiGuildWarStageDetail:OnBtnFightClicked()
    -- 检查体力是否充足
    if self.IsMonsterStatus then
        local monster = self:GetNodeMonster()
        if not XEntityHelper.CheckItemCountIsEnough(XGuildWarConfig.ActivityPointItemId, 
            monster:GetFightCostEnergy()) then
            return
        end
    else
        if not XEntityHelper.CheckItemCountIsEnough(XGuildWarConfig.ActivityPointItemId, 
            self.Node:GetFightCostEnergy()) then
            return
        end
    end    
    if self.IsMonsterStatus then
        self.BattleManager:UpdateCurrentClientBattleInfo(
            self:GetNodeMonster():GetUID(), self.Node:GetStutesType())
    else
        self.BattleManager:UpdateCurrentClientBattleInfo(self.Node:GetUID(), self.Node:GetStutesType())
    end
    if self.IsMonsterStatus then
        self:OpenBattleRoomUi(self:GetNodeMonster():GetStageId())
    else
        -- 前哨节点特殊处理
        if self.Node:GetNodeType() == XGuildWarConfig.NodeType.Sentinel and
           self.Node:GetStutesType() == XGuildWarConfig.NodeStatusType.Revive then
            self:OpenBattleRoomUi(self.Node:GetStageId())    
            return
        end
        -- boss节点特殊处理
        if self.Node:GetIsInfectNode() then
            self:OpenBattleRoomUi(self.Node:GetStageId())
            return
        end
        if self.Node:GetHP() <= 0 then
            XUiManager.TipErrorWithKey("GuildWarNodeIsDead")
            return
        end
        self:OpenBattleRoomUi(self.Node:GetStageId())
    end
end

function XUiGuildWarStageDetail:OpenBattleRoomUi(stageId)
    self:Close()
    self.BattleManager:OpenBattleRoomUi(stageId)
end

function XUiGuildWarStageDetail:OnBtnAutoFightClicked()
    local cost = self.Node:GetSweepCostEnergy()
    local damage = getRoundingValue((self.Node:GetMaxDamage() / self.Node:GetMaxHP()) * 100, 2) 
    local power = self.BattleManager:GetSweepHpFactor() * 100
    if self.IsMonsterStatus then
        local monster = self:GetNodeMonster()
        cost = monster:GetSweepCostEnergy()
        damage = getRoundingValue((monster:GetMaxDamage() / monster:GetMaxHP()) * 100, 2) 
    end
    if not XEntityHelper.CheckItemCountIsEnough(XGuildWarConfig.ActivityPointItemId, cost) then
        return
    end
    XLuaUiManager.Open("UiDialog", nil
        , XUiHelper.GetText("GuildWarSweepTip", cost, damage, power)
        , XUiManager.DialogType.Normal, nil
        , function()
            local uid = self.Node:GetUID()
            local sweepType = XGuildWarConfig.NodeFightType.FightNode
            local stageId = self.Node:GetStageId()
            if self.IsMonsterStatus then
                local monster = self:GetNodeMonster()
                uid = monster:GetUID()
                sweepType = XGuildWarConfig.NodeFightType.FightMonster
                stageId = monster:GetStageId()
            end
            self.GuildWarManager.StageSweep(uid, sweepType, stageId, function()
                XUiManager.TipMsg(XUiHelper.GetText("GuildWarSweepFinished"))
                self:RefreshNode(self.Node)
            end)
        end)
end

function XUiGuildWarStageDetail:OnBtnGoClicked()
    self.GuildWarManager.RequestPlayerMove(self.Node:GetId(), function()
        self:RefreshNode(self.Node)
    end)
end

function XUiGuildWarStageDetail:OnBtnHelpClicked()
    XLuaUiManager.Open("UiGuildWarStageTips", self.Node)
end

function XUiGuildWarStageDetail:OnBtnPlayerClicked()
    local rankType = XGuildWarConfig.RankingType.Node
    local uid = self.Node:GetUID()
    if self.IsMonsterStatus then
        rankType = XGuildWarConfig.RankingType.Elite
        uid = self:GetNodeMonster():GetUID()
    end
    self.GuildWarManager.RequestRanking(rankType, uid, function(rankList, myRankInfo)
        XLuaUiManager.Open("UiGuildWarStageRank", rankList, myRankInfo, rankType, uid, self.Node)
    end)
end

function XUiGuildWarStageDetail:OnChangeTopDetailStatus(isMonster)
    self.IsMonsterStatus = isMonster
    self.UiPanelNodeDetail.GameObject:SetActiveEx(not isMonster)
    self.UiPanelEliteMonster.GameObject:SetActiveEx(isMonster)
    self.PanelEliteMonsterDetail.gameObject:SetActiveEx(isMonster)
    self:RefreshButtonStatus()
    XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_STAGEDETAIL_CHANGE, self.Node:GetStageIndexName(), self.IsMonsterStatus)
    if self.AnimSwitch then
        self.AnimSwitch:Play()
    end
    self:RefreshRewardList()
end

function XUiGuildWarStageDetail:RefreshNodeTypeDetail(nodeType)
    -- 隐藏其他的子面板
    for key, data in pairs(self.ChildPanelInfoDic) do
        data.uiParent.gameObject:SetActiveEx(key == nodeType)
    end
    self.PanelTitle.gameObject:SetActiveEx(nodeType ~= XGuildWarConfig.NodeType.Home)
    local childPanelData = self.ChildPanelInfoDic[nodeType]
    if childPanelData == nil then return end
    -- 加载子面板实体
    local instanceGo = childPanelData.instanceGo
    if instanceGo == nil then
        instanceGo = childPanelData.uiParent:LoadPrefab(childPanelData.assetPath)
        childPanelData.instanceGo = instanceGo
    end
    -- 加载子面板代理
    local instanceProxy = childPanelData.instanceProxy
    if instanceProxy == nil then
        instanceProxy = childPanelData.proxy.New(instanceGo)
        childPanelData.instanceProxy = instanceProxy
    end
    -- 设置子面板代理参数
    local proxyArgs = {}
    if childPanelData.proxyArgs then
        for _, argName in ipairs(childPanelData.proxyArgs) do
            if type(argName) == "string" then
                proxyArgs[#proxyArgs + 1] = self[argName]
            else
                proxyArgs[#proxyArgs + 1] = argName
            end
        end
    end
    instanceProxy:SetData(table.unpack(proxyArgs))
    self.CurrentChildPanel = instanceProxy
end

function XUiGuildWarStageDetail:RefreshButtonStatus()
    -- 默认值 begin
    self.TxtTipsCenter.gameObject:SetActiveEx(false)
    self.TxtTipsLeft.gameObject:SetActiveEx(false)
    self.BtnGo:SetNameByGroup(1
        , XGuildWarConfig.GetServerConfigValue("MoveCostEnergy"))
    self.BtnGo.gameObject:SetActiveEx(self.Node:CheckIsCanGo())
    self.BtnFight:SetRawImage(XEntityHelper.GetItemIcon(XGuildWarConfig.ActivityPointItemId))
    self.BtnGo:SetRawImage(XEntityHelper.GetItemIcon(XGuildWarConfig.ActivityPointItemId))
    self.BtnAutoFight:SetRawImage(XEntityHelper.GetItemIcon(XGuildWarConfig.ActivityPointItemId))
    -- 默认值 end
    if not self.GuildWarManager.CheckRoundIsInTime() then
        self.BtnGo.gameObject:SetActiveEx(false)
        self.BtnAutoFight.gameObject:SetActiveEx(false)
        self.BtnFight.gameObject:SetActiveEx(false)
        return
    end
    local node = self.Node
    if node:GetNodeType() == XGuildWarConfig.NodeType.Home then
        self.BtnAutoFight.gameObject:SetActiveEx(false)
        self.BtnFight.gameObject:SetActiveEx(false)
        return
    end
    local monster = self:GetNodeMonster()
    local sweepCost = node:GetSweepCostEnergy()
    local fightCost = node:GetFightCostEnergy()
    if self.IsMonsterStatus  then
        sweepCost = monster:GetSweepCostEnergy()
        fightCost = monster:GetFightCostEnergy()
    end
    -- 体力
    self.BtnAutoFight:SetNameByGroup(1, sweepCost)
    self.BtnFight:SetNameByGroup(1, fightCost)
    -- 显隐
    if self.IsMonsterStatus then
        self.BtnAutoFight.gameObject:SetActiveEx(monster:CheckCanSweep()
            and node:GetIsPlayerNode())
        self.BtnFight.gameObject:SetActiveEx(self.Node:GetIsPlayerNode() 
            and not monster:GetIsDead())
        return
    end
    if node:GetNodeType() == XGuildWarConfig.NodeType.Infect 
        and not node:GetAllGuardIsDead() then
        self.BtnAutoFight.gameObject:SetActiveEx(false)
        self.BtnFight.gameObject:SetActiveEx(false)
        self.BtnGo.gameObject:SetActiveEx(false)
        self.TxtTipsCenter.gameObject:SetActiveEx(true)
        return
    end
    -- 前哨 + 超出
    if node:GetNodeType() == XGuildWarConfig.NodeType.Sentinel 
       and node:GetIsOverMaxRebuildTime() then
        self.BtnAutoFight.gameObject:SetActiveEx(false)
        self.BtnFight.gameObject:SetActiveEx(false)
        self.TxtTipsLeft.gameObject:SetActiveEx(not self.BattleManager:CheckAllInfectIsDead())
        self.TxtTipsLeft.text = XUiHelper.ConvertLineBreakSymbol(XUiHelper.GetText("GuildWarRebuildMaxTimeTip"
        , node:GetRebuildTimeStr())) 
        return
    end
    -- 前哨
    if node:GetNodeType() == XGuildWarConfig.NodeType.Sentinel then
        self.BtnAutoFight.gameObject:SetActiveEx(node:CheckCanSweep() 
            and node:GetIsPlayerNode())    
        self.BtnFight.gameObject:SetActiveEx(self.Node:GetIsPlayerNode() 
            and not self.BattleManager:CheckAllInfectIsDead())
        return
    end
    self.BtnAutoFight.gameObject:SetActiveEx(node:CheckCanSweep() 
        and node:GetIsPlayerNode())
    self.BtnFight.gameObject:SetActiveEx(self.Node:GetIsPlayerNode() and (self.Node:GetHP() > 0 or self.Node:GetIsInfectNode()))
end

function XUiGuildWarStageDetail:CheckClose(actionList)
    local IsClose = false
    local monster = self:GetNodeMonster()
    for _,action in pairs(actionList or {}) do
        if action.NodeId and action.NodeId == self.Node:GetId() then
            IsClose = true
            break
        end
        
        if monster and action.MonsterUid and action.MonsterUid == monster:GetUID() then
            IsClose = true
            break
        end
    end
    if IsClose then
        self:Close()
    end
end

function XUiGuildWarStageDetail:GetNodeMonster()
    if self.IsMonsterStatus then
        return self.Node:GetCurrentEliteMonster(false)
    end
    return self.Node:GetCurrentEliteMonster()
end

function XUiGuildWarStageDetail:RefreshRewardList()
    self.PanelReward.gameObject:SetActiveEx(not self.IsMonsterStatus)
    if self.IsMonsterStatus then return end
    local rewardId = self.Node:GetRewardId()
    self.PanelReward.gameObject:SetActiveEx(rewardId > 0)
    if rewardId > 0 then
        local rewardDatas = XRewardManager.GetRewardList(rewardId) or {}
        self.PanelReward.gameObject:SetActiveEx(#rewardDatas > 0)
        XUiHelper.RefreshCustomizedList(self.RewardParent, self.GridCommon, #rewardDatas, function(index, child)
            local grid = XUiGridCommon.New(self, child)
            grid:Refresh(rewardDatas[index])
        end)
    end
end

return XUiGuildWarStageDetail