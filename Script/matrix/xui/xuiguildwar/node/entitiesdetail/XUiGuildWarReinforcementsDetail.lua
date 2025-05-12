local XUiGuildWarEntityDetail = require('XUi/XUiGuildWar/Node/EntitiesDetail/XUiGuildWarEntityDetail')
local XUiPanelReinforcements = require('XUi/XUiGuildWar/Node/XUiPanelReinforcements')
local XUiPanelReinfoce = require('XUi/XUiGuildWar/Node/XUiPanelReinforce')
--######################## XUiGuildWarReinforcementsDetail ########################
--- 单独显示援军详情的界面
--- 剔除了对常规节点相关的处理
---@class XUiGuildWarReinforcementsDetail
---@field Entity XGWReinforcements
local XUiGuildWarReinforcementsDetail = XLuaUiManager.Register(XUiGuildWarEntityDetail, 'UiGuildWarReinforcementsDetail')

--region ------------------------------ 生命周期 ------------------------------->>>
function XUiGuildWarReinforcementsDetail:OnAwake()
    self.Super.OnAwake(self)
    
    -- 不需要显示区域安全性和说明入口
    self.TxtDanger.gameObject:SetActiveEx(false)
    self.BtnHelp.gameObject:SetActiveEx(false)
    self.BtnDefend.gameObject:SetActiveEx(true)
    self.BtnDefend.CallBack = handler(self, self.OnSupportBtnClick)
    
    self.GuildWarManager = XDataCenter.GuildWarManager
    self.BattleManager = self.GuildWarManager.GetBattleManager()
    self.UiPanelNodeDetail = XUiPanelReinforcements.New(self.PanelNodeDetail, self)
    self.UiPanelReinforce = XUiPanelReinfoce.New(self.PanelReinforce, self)
    self.TimeId = nil
    
    XUiHelper.NewPanelActivityAssetSafe({ XGuildWarConfig.ActivityPointItemId }
    , self.PanelSpecialTool, self, { self.GuildWarManager.GetMaxActionPoint() })
    
    -- 子面板信息配置
    self.ChildPanelInfoDic = {
        [XGuildWarConfig.NodeType.Buff] = {
            uiParent = self.PanelBuff,
            instanceGo = self.PanelBuff,
            proxy = require("XUi/XUiGuildWar/Node/XUiPanelBuff"),
            proxyArgs = { "Node" },
        },
    }
    
    self:RegisterUiEvents()
    -- 连接信号
    --self.UiPanelNodeDetail:ConnectSignal("ChangeTopDetailStatus", self, self.OnChangeTopDetailStatus)
end

-- node : XNormalGWNode
function XUiGuildWarReinforcementsDetail:OnStart(reinforcementsEntity)
    self._TimerIds = {}
    self:RefreshNode(reinforcementsEntity)
    self.UiPanelReinforce:SetData(reinforcementsEntity)
    self.UiPanelReinforce:Open()
end

function XUiGuildWarReinforcementsDetail:OnEnable()
    if not self.TimeId then
        self:RefreshTimeData()
        self.TimeId = XScheduleManager.ScheduleForever(function()
            self:RefreshTimeData()
        end, XScheduleManager.SECOND, 0)
    end

    local currentNode = self.Entity and self.BattleManager:GetNode(self.Entity:GetCurrentNodeId())
    if currentNode then
        XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_STAGEDETAIL_CHANGE, currentNode:GetStageIndexName(), nil, true)
    end
    
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_ACTIONLIST_CHANGE, self.CheckClose, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_TIME_REFRESH, self.RefreshNode, self)
end

function XUiGuildWarReinforcementsDetail:OnDisable()

    if self.TimeId then
        XScheduleManager.UnSchedule(self.TimeId)
        self.TimeId = nil
    end
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_ACTIONLIST_CHANGE, self.CheckClose, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_TIME_REFRESH, self.RefreshNode, self)
end

function XUiGuildWarReinforcementsDetail:OnDestroy()
    XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_STAGEDETAIL_CHANGE, nil, nil, nil)
    for i, v in pairs(self._TimerIds) do
        XScheduleManager.UnSchedule(v)
    end
    self._TimerIds = nil
end

--endregion <<<-----------------------------------------------------------------------

function XUiGuildWarReinforcementsDetail:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.Close)
    self.BtnPlayer.CallBack = handler(self, self.OnReinforceRankEnter)
end

function XUiGuildWarReinforcementsDetail:RefreshNode(entity)
    if entity == nil then
        entity = self.Entity
    end
    self.Entity = entity

    self.UiPanelNodeDetail:SetData(entity)
    -- 节点基本信息
    self.TxtName.text = entity:GetReinforcementName()

    self:RefreshTimeData()
    -- 刷新节点
    --self:RefreshNodeTypeDetail(node:GetNodeType())
    -- 刷新援助成员数
    self.BtnPlayer:SetNameByGroup(2, XGuildWarConfig.GetClientConfigValues('ReinforceSupportListEntranceTxt')[1])
    self.BtnPlayer:SetNameByGroup(1, self.Entity:GetSupportPlayerCount())
    -- 按钮状态
    self:RefreshButtonStatus()
end

function XUiGuildWarReinforcementsDetail:RefreshTimeData()
    -- 援军前进时间
end

function XUiGuildWarReinforcementsDetail:CheckClose(actionList)
    local IsClose = false
    for _, action in pairs(actionList or {}) do
        if action.NodeId and action.NodeId == self.Node:GetId() then
            IsClose = true
            break
        end
    end
    if IsClose then
        self:Close()
    end
end

function XUiGuildWarReinforcementsDetail:OnReinforceRankEnter()
    self.GuildWarManager.RequestRanking(XGuildWarConfig.RankingType.ReinforcementMembers, self.Entity.UID
    , function(rankList, myRankInfo)
                XLuaUiManager.Open("UiGuildWarReinforceRank", rankList, myRankInfo, XGuildWarConfig.RankingType.NodeStay, self.Entity:GetUID(), self.Entity)
            end)
end

function XUiGuildWarReinforcementsDetail:RefreshButtonStatus()
    -- 无法参与此轮
    if XDataCenter.GuildWarManager.CheckIsPlayerSkipRound() then
        self.BtnGo.gameObject:SetActiveEx(false)
        self.BtnAutoFight.gameObject:SetActiveEx(false)
        self.BtnFight.gameObject:SetActiveEx(false)
        self.TxtTipsCenter.gameObject:SetActiveEx(true)
        self.TxtTipsCenter.text = XUiHelper.ReplaceTextNewLine(XUiHelper.GetText("GuildWarNotQualify"))
        self.TxtTipsLeft.gameObject:SetActiveEx(false)
        self.TxtTipsCenter2.gameObject:SetActiveEx(false)
        self.BtnDefend.gameObject:SetActiveEx(false)
        return
    end

    self.BtnDefend.gameObject:SetActiveEx(true)
    
    if self.Entity and self.Entity:CheckPlayerIsSupported(XPlayer.Id) then
        self._PlayerIsSupported = true
        self.BtnDefend:SetNameByGroup(0, XGuildWarConfig.GetClientConfigValues('ReinforcementSupportTxt')[2])
        self.BtnDefend:SetButtonState(CS.UiButtonState.Disable)
    else
        self._PlayerIsSupported = false
        self.BtnDefend:SetNameByGroup(0, XGuildWarConfig.GetClientConfigValues('ReinforcementSupportTxt')[1])
        self.BtnDefend:SetButtonState(CS.UiButtonState.Normal)
    end
end

function XUiGuildWarReinforcementsDetail:OnSupportBtnClick()
    if not self._PlayerIsSupported then
        XDataCenter.GuildWarManager.RequestGuildWarSupportReinforcement(self.Entity.UID, function(reinforcementData)
            self:RefreshNode(reinforcementData)
            self.UiPanelReinforce:RefreshBuffShow()
            XUiManager.TipMsg(XGuildWarConfig.GetClientConfigValues('ReinforcementSupportResultTxt')[1])
        end)
    end
end

return XUiGuildWarReinforcementsDetail