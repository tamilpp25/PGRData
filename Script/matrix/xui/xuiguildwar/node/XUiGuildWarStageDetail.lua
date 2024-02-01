local XUiPanelEliteMonster = require("XUi/XUiGuildWar/Node/XUiPanelEliteMonster")
local XUiPanelNodeDetail = require("XUi/XUiGuildWar/Node/XUiPanelNodeDetail")
--######################## XUiGuildWarStageDetail ########################
local XUiGuildWarStageDetail = XLuaUiManager.Register(XLuaUi, "UiGuildWarStageDetail")

function XUiGuildWarStageDetail:OnAwake()
    self.GuildWarManager = XDataCenter.GuildWarManager
    self.BattleManager = self.GuildWarManager.GetBattleManager()
    self.UiPanelNodeDetail = XUiPanelNodeDetail.New(self.PanelNodeDetail, self)
    self.UiPanelEliteMonster = XUiPanelEliteMonster.New(self.PanelEliteMonster)
    ---@type XGWNode
    self.Node = nil
    self.IsMonsterStatus = false
    self.TimeId = nil
    self.CurrentChildPanel = nil
    self:RegisterUiEvents()
    XUiHelper.NewPanelActivityAssetSafe({ XGuildWarConfig.ActivityPointItemId }
    , self.PanelSpecialTool, self, { self.GuildWarManager.GetMaxActionPoint() })
    -- 子面板信息配置
    self.ChildPanelInfoDic = {
        [XGuildWarConfig.NodeType.Sentinel] = {
            uiParent = self.PanelSentinel,
            instanceGo = self.PanelSentinel,
            proxy = require("XUi/XUiGuildWar/Node/XUiPanelSentinel"),
            proxyArgs = { "Node" },
        },
        [XGuildWarConfig.NodeType.SecondarySentinel] = {
            uiParent = self.PanelLittleSentinel,
            instanceGo = self.PanelLittleSentinel,
            proxy = require("XUi/XUiGuildWar/Node/XUiPanelSecondarySentinel"),
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
        [XGuildWarConfig.NodeType.PandaRoot] = {
            uiParent = self.PanelBoss,
            instanceGo = self.PanelBoss,
            proxy = require("XUi/XUiGuildWar/Node/XUiPanelPanda"),
            proxyArgs = { "Node" },
        },
        [XGuildWarConfig.NodeType.TwinsRoot] = {
            uiParent = self.PanelBoss,
            instanceGo = self.PanelBoss,
            proxy = require("XUi/XUiGuildWar/Node/XUiPanelTwins"),
            proxyArgs = { "Node" },
        },
        [XGuildWarConfig.NodeType.Blockade] = {
            uiParent = self.PanelBlock,
            instanceGo = self.PanelBlock,
            proxy = require("XUi/XUiGuildWar/Node/XUiPanelBlockade"),
            proxyArgs = { "Node" },
        },
        [XGuildWarConfig.NodeType.Term4BossRoot] = {
            uiParent = self.PanelBossTerm4,
            instanceGo = self.PanelBossTerm4,
            proxy = require("XUi/XUiGuildWar/Node/XUiPanelBossTerm4"),
            proxyArgs = { "Node" },
        },
        [XGuildWarConfig.NodeType.Resource] = {
            uiParent = self.PanelResource,
            instanceGo = self.PanelResource,
            proxy = require("XUi/XUiGuildWar/Node/XUiPanelResource"),
            proxyArgs = { "Node" },
        }
    }
    -- 连接信号
    self.UiPanelNodeDetail:ConnectSignal("ChangeTopDetailStatus", self, self.OnChangeTopDetailStatus)
    self.UiPanelEliteMonster:ConnectSignal("ChangeTopDetailStatus", self, self.OnChangeTopDetailStatus)
end

-- node : XNormalGWNode
function XUiGuildWarStageDetail:OnStart(node, isMonsterStatus)
    self._TimerIds = {}
    if isMonsterStatus == nil then
        isMonsterStatus = false
    end
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
            return
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
    for i, v in pairs(self._TimerIds) do
        XScheduleManager.UnSchedule(v)
    end
    self._TimerIds = nil
end

function XUiGuildWarStageDetail:RefreshNode(node)
    if node == nil then
        node = self.Node
    end
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
    self.UiPanelEliteMonster.GameObject:SetActiveEx(self.IsMonsterStatus)
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
        self.CurrentChildPanel:RefreshTimeData(self.Node)
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
    self.BtnDefend.CallBack = handler(self,self.OnBtnDefendClick)
end

function XUiGuildWarStageDetail:OnBtnFightClicked()
    local node = self.Node
    if node:GetIsTerm4Boss() then
        self:OpenTerm4Ui(node)
        return
    end

    -- 检查体力是否充足
    if self.IsMonsterStatus then
        local monster = self:GetNodeMonster()
        if monster == nil then
            --当玩家扫荡击杀怪物后 Action的Notify可能回比MonsterUpdate晚 会导致这里为空
            return
        end
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
        if self.Node:GetIsInfectNode() or self.Node:GetIsRuinsStatus() then
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
        if monster == nil then
            --当玩家扫荡击杀怪物后 Action的Notify可能回比MonsterUpdate晚 会导致这里为空
            return
        end
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
        if self.Node:OnDetailGoCallback() then
            return
        end
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
    if isMonster then
        self.PanelNormal.gameObject:SetActiveEx(false)
    else
        self:RefreshNodeTypeDetail(self.Node:GetNodeType())
    end
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
        if data.uiParent then
            data.uiParent.gameObject:SetActiveEx(key == nodeType)
        end
    end
    self.PanelTitle.gameObject:SetActiveEx(nodeType ~= XGuildWarConfig.NodeType.Home and nodeType ~= XGuildWarConfig.NodeType.Resource)

    -- 普通节点补充“作战说明”栏目,读取node.Desc
    if nodeType == XGuildWarConfig.NodeType.Normal and not self.IsMonsterStatus then
        local desc = self.Node:GetDesc()
        self.PanelNormal.gameObject:SetActiveEx(true)
        self.TxtAreaDetails.text = desc
    end

    local childPanelData = self.ChildPanelInfoDic[nodeType]
    if childPanelData == nil then
        return
    end
    -- 加载子面板实体
    local instanceGo = childPanelData.instanceGo
    if instanceGo == nil then
        instanceGo = childPanelData.uiParent:LoadPrefab(childPanelData.assetPath)
        childPanelData.instanceGo = instanceGo
    end
    -- 加载子面板代理
    local instanceProxy = childPanelData.instanceProxy
    if instanceProxy == nil then
        instanceProxy = childPanelData.proxy.New(instanceGo,self)
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

    -- 基地隐藏普通血条
    if nodeType == XGuildWarConfig.NodeType.Home or nodeType == XGuildWarConfig.NodeType.Resource then
        self.UiPanelNodeDetail.GameObject:SetActiveEx(false)
    end
end

function XUiGuildWarStageDetail:RefreshButtonStatus()
    -- 无法参与此轮
    if XDataCenter.GuildWarManager.CheckIsPlayerSkipRound() then
        self.BtnGo.gameObject:SetActiveEx(false)
        self.BtnAutoFight.gameObject:SetActiveEx(false)
        self.BtnFight.gameObject:SetActiveEx(false)
        self.TxtTipsCenter.gameObject:SetActiveEx(true)
        self.TxtTipsCenter.text = XUiHelper.ReplaceTextNewLine(XUiHelper.GetText("GuildWarNotQualify"))
        self.TxtTipsLeft.gameObject:SetActiveEx(false)
        self.TxtTipsCenter2.gameObject:SetActiveEx(false)
        return
    end
    -- 默认值 begin
    if self.Node:GetNodeType() ~= XGuildWarConfig.NodeType.Resource then
        self.BtnGo:SetNameByGroup(1
        , XDataCenter.GuildWarManager.GetMoveCost(self.Node:GetId()))
    end
    local isShowBtnGo = self.Node:CheckIsCanGo()
    self.BtnGo.gameObject:SetActiveEx(isShowBtnGo)
    self.BtnGo:SetRawImage(XEntityHelper.GetItemIcon(XGuildWarConfig.ActivityPointItemId))
    self.TxtTipsCenter.gameObject:SetActiveEx(false)
    self.TxtTipsLeft.gameObject:SetActiveEx(false)
    self.BtnFight:SetRawImage(XEntityHelper.GetItemIcon(XGuildWarConfig.ActivityPointItemId))
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
    elseif node:GetNodeType() == XGuildWarConfig.NodeType.Resource then
        self.BtnAutoFight.gameObject:SetActiveEx(false)
        self.BtnFight.gameObject:SetActiveEx(false)
        self.BtnGo.gameObject:SetActiveEx(false)
        self.BtnDefend.gameObject:SetActiveEx(true)
        self:RefreshDefendBtnDisplay(XDataCenter.GuildWarManager.CheckDefensePointIsPlayerInById(self.Node._Id))
        return
    end
    --显示扫荡和战斗所需能量
    local sweepCost = node:GetSweepCostEnergy()
    local fightCost = node:GetFightCostEnergy()
    local monster = self:GetNodeMonster()
    if monster == nil then
        self.IsMonsterStatus = false
    end
    if self.IsMonsterStatus then
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
    if node:GetIsLastNode()
            and not node:GetAllGuardIsDead() then
        self.BtnAutoFight.gameObject:SetActiveEx(false)
        self.BtnFight.gameObject:SetActiveEx(false)
        self.BtnGo.gameObject:SetActiveEx(false)
        self.TxtTipsCenter.gameObject:SetActiveEx(true)
        self.TxtTipsCenter2.gameObject:SetActiveEx(false)
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
    -- 黑白鲨
    if node:GetIsRuinsStatus() and node:GetIsPlayerNode() then
        self.BtnAutoFight.gameObject:SetActiveEx(node:GetMaxDamage() > 0)
        self.BtnFight.gameObject:SetActiveEx(true)
        return
    end
    -- 第四期
    --if node:GetIsTerm4Boss() then
    --    self:UpdateTerm4Boss(node)
    --end

    local isShowAutoFight = node:CheckCanSweep() and node:GetIsPlayerNode()
    local isShowFight = self.Node:GetIsPlayerNode() and (self.Node:GetHP() > 0 or self.Node:GetIsInfectNode())

    -- 封锁点
    ---@type XGWNode[]
    local frontNodes = node:GetFrontNodes()
    for i = 1, #frontNodes do
        local frontNode = frontNodes[i]
        if frontNode:GetIsBlockadeNode() then
            -- 封锁点的后序节点
            if node:IsLink2TheEndUnpassBlockade() then
                self.TxtTipsCenter2.gameObject:SetActiveEx(not isShowFight and not isShowAutoFight and not isShowBtnGo)
            end
            break
        end
    end

    self.BtnAutoFight.gameObject:SetActiveEx(isShowAutoFight)
    self.BtnFight.gameObject:SetActiveEx(isShowFight)
end

function XUiGuildWarStageDetail:CheckClose(actionList)
    local IsClose = false
    local monster = self:GetNodeMonster()
    for _, action in pairs(actionList or {}) do
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
    --if self.IsMonsterStatus then
    --    local monster = self.Node:GetCurrentEliteMonster(false)
    --    return monster
    --end
    local monster = self.Node:GetCurrentEliteMonster()
    return monster
end

function XUiGuildWarStageDetail:RefreshRewardList()
    if self.Node:GetIsTerm4Boss() then
        self.PanelReward.gameObject:SetActiveEx(false)
        return
    end
    self.PanelReward.gameObject:SetActiveEx(not self.IsMonsterStatus)
    if self.IsMonsterStatus then
        return
    end
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

---@param node XTerm4BossGWNode
function XUiGuildWarStageDetail:UpdateTerm4Boss(node)
end

---@param node XTerm4BossGWNode
function XUiGuildWarStageDetail:OpenTerm4Ui(node)
    XLuaUiManager.Open("UiGuildWarTerm4Panel", node)
end

function XUiGuildWarStageDetail:OnBtnDefendClick()
    if XDataCenter.GuildWarManager.CheckDefensePointIsPlayerInById(self.Node._Id) then
        --弹窗提示是否要取消驻守
        XUiManager.DialogTip('',table.concat(XGuildWarConfig.GetClientConfigValues('CancelDefend')),nil,nil,function()
            self:SelectDefend(true)
        end)
    elseif XDataCenter.GuildWarManager.IsPlayerDefend() then
        --弹窗提示是否要更换驻守
        XUiManager.DialogTip('',table.concat(XGuildWarConfig.GetClientConfigValues('ChangeDefend')),nil,nil,function()
            self:SelectDefend()
        end)
    else
        --直接驻守
        self:SelectDefend()
    end
end

function XUiGuildWarStageDetail:SelectDefend(isCancel)
    if isCancel then
        XDataCenter.GuildWarManager.SelectDefenseNodeRequest(0,function(success)
            if success then
                self:RefreshDefendBtnDisplay(false)
                XDataCenter.GuildWarManager.RefreshDefendDictData(0)
            end
        end)
    else
        XDataCenter.GuildWarManager.SelectDefenseNodeRequest(self.Node._Id,function(success)
            if success then
                XUiManager.TipMsg(table.concat(XGuildWarConfig.GetClientConfigValues('DefendSuccess')))
                self:RefreshDefendBtnDisplay(true)
                XDataCenter.GuildWarManager.RefreshDefendDictData(self.Node._Id)
            end
        end)
    end
end

function XUiGuildWarStageDetail:RefreshDefendBtnDisplay(isDefend)
    local data = XGuildWarConfig.GetClientConfigValues('DefendBtnDisplay')
    if isDefend then
        self.BtnDefend:SetNameByGroup(0,data[2])
    else
        self.BtnDefend:SetNameByGroup(0,data[1])
    end
end

return XUiGuildWarStageDetail