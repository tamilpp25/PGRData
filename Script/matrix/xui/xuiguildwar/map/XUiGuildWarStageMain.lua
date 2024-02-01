---@class XUiGuildWarStageMain:XLuaUi
local XUiGuildWarStageMain = XLuaUiManager.Register(XLuaUi, "UiGuildWarStageMain")
local XUiPanelTop = require("XUi/XUiGuildWar/Map/XUiPanelTop")
local XUiPanelStage = require("XUi/XUiGuildWar/Map/XUiPanelStage")
local XUiPanelBottom = require("XUi/XUiGuildWar/Map/XUiPanelBottom")
local XUiPanelMap = require("XUi/XUiGuildWar/Map/XUiPanelMap")
local XUiPanelReview = require("XUi/XUiGuildWar/Map/XUiPanelReview")

local CSXTextManagerGetText = CS.XTextManager.GetText

local ResultType = {
    Boss = 1,
    DefendFault = 2,
    DefendSuccess = 3,
}

function XUiGuildWarStageMain:OnStart()
    self:SetButtonCallBack()
    self.BattleManager = XDataCenter.GuildWarManager.GetBattleManager()
    self:Init()
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_NEW_ROUND, self.CheckNewRoundExit, self)
    self.StagePanel:OnStart()
end
function XUiGuildWarStageMain:Init()
    self.IsPathChange = false

    self.TopPanel = XUiPanelTop.New(self.PanelTop, self, self.BattleManager)
    self.StagePanel = XUiPanelStage.New(self.PanelStage, self, self.BattleManager)
    self.BottomPanel = XUiPanelBottom.New(self.PanelBottom, self, self.BattleManager)
    self.MapPanel = XUiPanelMap.New(self.PanelMap, self, self.BattleManager)
    self.ReviewPanel = XUiPanelReview.New(self.PanelReview, self)

    local endTime = XDataCenter.GuildWarManager.GetActivityEndTime()
    self:CheckTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            XDataCenter.GuildWarManager.OnActivityEndHandler()
        else
            self:CheckTime()
        end
    end)

    local itemIds = XGuildWarConfig.GetClientConfigValues("StageMainCostItems", "Int")
    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool, self)
    XDataCenter.ItemManager.AddCountUpdateListener(itemIds, function()
        self.AssetActivityPanel:Refresh(itemIds, nil, { XDataCenter.GuildWarManager.GetMaxActionPoint() })
    end, self.AssetActivityPanel)
    self.AssetActivityPanel:Refresh(itemIds, nil, { XDataCenter.GuildWarManager.GetMaxActionPoint() })

    self.BattleManager:SetIsHistoryAction(true)
    XDataCenter.GuildWarManager.GetNewRoundFlag()--如果是新打开的界面则无视之前的新回合标记
end
function XUiGuildWarStageMain:SetButtonCallBack()
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end
    self.BtnMainUi.CallBack = function()
        self:OnBtnMainUiClick()
    end
    self:BindHelpBtn(self.BtnHelp, "GuildWarHelp")
end

function XUiGuildWarStageMain:OnEnable()
    XUiGuildWarStageMain.Super.OnEnable(self)
    self:CheckNewRoundExit()
    self.StagePanel:OnEnable()
    self:AddEventListener()
    self:UpdatePanel()
    self:SetTimeRefresh()
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_ATTACKINFO_UPDATE,self.OnResourcesAttackInfoUpdateEvent,self)
    self._CheckDefendTimeId = XScheduleManager.ScheduleForever(function()
        if not XDataCenter.GuildWarManager.GetBattleManager():CheckActionPlaying() and not XDataCenter.GuideManager.CheckIsInGuide() then
            if XTool.IsNumberValid(self._CheckDefendTimeId) then
                XScheduleManager.UnSchedule(self._CheckDefendTimeId)
                self._CheckDefendTimeId = nil
            end
            self:OnResourcesAttackInfoUpdateEvent()
        end
    end,XScheduleManager.SECOND)
end

function XUiGuildWarStageMain:OnDisable()
    XUiGuildWarStageMain.Super.OnDisable(self)
    self:RemoveEventListener()
    self.StagePanel:OnDisable()
    self:StopTimeRefresh()
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_ATTACKINFO_UPDATE,self.OnResourcesAttackInfoUpdateEvent,self)
end

function XUiGuildWarStageMain:OnDestroy()
    XUiGuildWarStageMain.Super.OnDestroy(self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_NEW_ROUND, self.CheckNewRoundExit, self)
end

function XUiGuildWarStageMain:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_PATHEDIT_OVER, self.PathEditOver, self)
    --XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_ACTION_ROUND_START, self.ShowNodeExchange, self)
    --XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_EXCHANGE_NODE, self.ExchangeNode, self)
    self.TopPanel:AddEventListener()
    self.BottomPanel:AddEventListener()
    self.MapPanel:AddEventListener()
    self.ReviewPanel:AddEventListener()

end

function XUiGuildWarStageMain:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_PATHEDIT_OVER, self.PathEditOver, self)
    --XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_ACTION_ROUND_START, self.ShowNodeExchange, self)
    --XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_EXCHANGE_NODE, self.ExchangeNode, self)
    self.TopPanel:RemoveEventListener()
    self.BottomPanel:RemoveEventListener()
    self.MapPanel:RemoveEventListener()
    self.ReviewPanel:RemoveEventListener()
end

function XUiGuildWarStageMain:StopActionPlay()
    self.StagePanel:StopActionPlay()
end

function XUiGuildWarStageMain:OnBtnBackClick()
    if self.StagePanel:CheckIsPathEdit() then
        self:PathEditOver(false)
    else
        self:Close()
    end
end

function XUiGuildWarStageMain:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiGuildWarStageMain:UpdatePanel()
    self.TopPanel:UpdatePanel()
    self.BottomPanel:UpdatePanel()
end

function XUiGuildWarStageMain:PathEdit()
    self.MapPanel:ShowPanel()
    self.MapPanel:ShowButton(false)
    self.TopPanel:HidePanel()
    self.BottomPanel:HidePanel()
    self.StagePanel:PathEdit()
end

function XUiGuildWarStageMain:PathEditOver(IsSave)
    self.StagePanel:PathEditOver(IsSave, function()
        self.MapPanel:HidePanel()
        self.TopPanel:ShowPanel()
        self.BottomPanel:ShowPanel()
    end)
end

function XUiGuildWarStageMain:CheckTime()
    local timeLeft = XDataCenter.GuildWarManager.GetRoundEndTime() - XTime.GetServerNowTimestamp()
    self.TopPanel:UpdateTime(timeLeft)
end

function XUiGuildWarStageMain:SetTimeRefresh()
    if not self.TimeTimer then
        --首次进入刷新一次
        XDataCenter.GuildWarManager.GetActivityData(function()
            XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_TIME_REFRESH)
        end)
        
        local time = XDataCenter.GuildWarManager.GetHourRefreshTime()
        self.TimeTimer = XScheduleManager.ScheduleForever(function()
            XDataCenter.GuildWarManager.GetActivityData(function()
                XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_TIME_REFRESH)
            end)
        end, XScheduleManager.SECOND * time * 60, 0)
    end
end

function XUiGuildWarStageMain:StopTimeRefresh()
    if self.TimeTimer then
        XScheduleManager.UnSchedule(self.TimeTimer)
        self.TimeTimer = nil
    end
end

function XUiGuildWarStageMain:CheckNewRoundExit()
    local IsExit = XDataCenter.GuildWarManager.GetNewRoundFlag()
    if IsExit then
        XUiManager.TipText("GuildWarBattleStart")
        XScheduleManager.ScheduleOnce(function()
            XLuaUiManager.RunMain()
        end, 1)

    end
end

--region 2期轮次开启时播放的据点交换动画(已经弃用 莫名其妙的功能)
--播放交换动画
function XUiGuildWarStageMain:ShowNodeExchange(actionGroup, isJustOneFrame)
    local action
    for i = 1, #actionGroup do
        if actionGroup[i].ActionType == XGuildWarConfig.GWActionType.RoundStart then
            action = actionGroup[i]
        end
    end
    local callback = function()
        if not isJustOneFrame then
            self.BattleManager:DoActionFinish(XGuildWarConfig.GWActionType.RoundStart)
        end
    end
    if action.RoundId == XDataCenter.GuildWarManager.GetCurrentRoundId() then
        self:SetActiveObjExchangeNode(true)
        if action.DifficultyId == 1 then
            self:PlayAnimationWithMask("Line1QieHuan", callback)
        elseif action.DifficultyId == 2 then
            self:PlayAnimationWithMask("Line2QieHuan", callback)
        elseif action.DifficultyId == 3 then
            -- 3 = 1和2同时播放
            local count = 0
            self:PlayAnimationWithMask("Line1QieHuan", function()
                count = count + 1
                if count >= 2 then
                    callback()
                end
            end)
            self:PlayAnimationWithMask("Line2QieHuan", function()
                count = count + 1
                if count >= 2 then
                    callback()
                end
            end)
        end
    else
        XScheduleManager.ScheduleOnce(callback, 0)
    end
end
function XUiGuildWarStageMain:ExchangeNode(action)
    -- 动画第一帧是交换位置, 所以只Evaluate一帧, 然后立刻disable, 等待后续播放
    self:ShowNodeExchange({ action }, true)
    if action.DifficultyId == 1 then
        self.Transform:Find("Animation/PanelStageQieHuan/Line1QieHuan"):GetComponent("PlayableDirector"):Evaluate()
    elseif action.DifficultyId == 2 then
        self.Transform:Find("Animation/PanelStageQieHuan/Line2QieHuan"):GetComponent("PlayableDirector"):Evaluate()
    elseif action.DifficultyId == 3 then
        self.Transform:Find("Animation/PanelStageQieHuan/Line1QieHuan"):GetComponent("PlayableDirector"):Evaluate()
        self.Transform:Find("Animation/PanelStageQieHuan/Line2QieHuan"):GetComponent("PlayableDirector"):Evaluate()
    end
    self:SetActiveObjExchangeNode(false)
end
function XUiGuildWarStageMain:SetActiveObjExchangeNode(isActive)
    self.Transform:Find("Animation/PanelStageQieHuan/Line1QieHuan").gameObject:SetActiveEx(isActive)
    self.Transform:Find("Animation/PanelStageQieHuan/Line2QieHuan").gameObject:SetActiveEx(isActive)
end
--endregion

--region 5.0
function XUiGuildWarStageMain:OnResourcesAttackInfoUpdateEvent()
    --检测当次是否播放过动画
    if XLuaUiManager.IsUiShow('UiGuildWarStageMain') and not XDataCenter.GuildWarManager.CheckNearestAttackAnimIsPlayed() then
        self:PlayBossBombAnimation()
    end
end

function XUiGuildWarStageMain:PlayBossBombAnimation()
    local resultType = XDataCenter.GuildWarManager.CheckLastDefendSuccess() and ResultType.DefendSuccess or ResultType.DefendFault
    
    --获取被攻击的资源点Id及其索引（索引序号与动画后缀编号一致）
    local attackedResNodeId = XDataCenter.GuildWarManager.GetLastAttackedResourcesId()
    local rescourceIndex = XGuildWarConfig.GetNodeStageIndex(attackedResNodeId)
    local attackedResGrid = self.StagePanel.NodeId2GridStageDic[attackedResNodeId]
    --获取所有驻守人数最大（存在相同）的节点Id
    local resNodeIds = XDataCenter.GuildWarManager.GetMaxDefendResourceNodeIds()
    --通过节点Id获取这些节点的UI控制对象（需要通过这些对象来控制特效的显示）
    local resGrids = {}
    for index, nodeId in ipairs(resNodeIds) do
        resGrids[index] = self.StagePanel.NodeId2GridStageDic[nodeId]
    end
    
    local beforeBomb = function() 
        --在播放动画之前，展开护盾
        for i, grid in ipairs(resGrids) do
            grid:ShowEffectShield(true)
        end
    end
    local afterBomb = function() 
        --在播放完动画后关闭护盾
        for i, grid in ipairs(resGrids) do
            grid:ShowEffectShield(false)
        end
        attackedResGrid:ShowEffectExplode(false)
        
        --炮击动画播完再刷新节点数据
        self.StagePanel:RefreshResourcesNodeState()
    end
    
    --播放动画前要把Pop的界面给关了
    XLuaUiManager.Close('UiGuildWarStageDetail')
    
    self.ReviewPanel:ShowPanelWithoutAnimation()
    self:PlayAnimationWithMask('PanelReviewEnable',function()
        --隐藏节点状态信息
        self.StagePanel:SetResourcesDisplayWithAttackAnimation(true)
        XLuaUiManager.SetMask(true)
        --查看地图
        self.StagePanel:LookAllMap(true, function()
            self:PlayAnimationWithMask('BossbombEnable'..rescourceIndex,function()
                XDataCenter.GuildWarManager.MarkNearestAttackAnimIsPlayed()
                self.StagePanel:LookAllMap(false,function()
                    self:PlayAnimationWithMask("PanelReviewDisable", function ()
                        self.ReviewPanel:HidePanelWithoutAnimation()

                        if afterBomb then
                            afterBomb()
                        end
                        XLuaUiManager.SetMask(false)
                        if resultType == ResultType.DefendFault then
                            XLuaUiManager.Open('UiGuildWarBossReaultsFail',nil)
                        elseif resultType == ResultType.DefendSuccess then
                            XLuaUiManager.Open('UiGuildWarBossReaultsSuccess',nil)
                        elseif resultType == ResultType.Boss then
                            XLuaUiManager.Open('UiGuildWarBossReaults',nil)
                        end
                    end)
                end)
            end, beforeBomb, CS.UnityEngine.Playables.DirectorWrapMode.None)
        end)
    end)

end
--endregion