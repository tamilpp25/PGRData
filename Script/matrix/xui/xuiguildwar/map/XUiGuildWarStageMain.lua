---@class XUiGuildWarStageMain:XLuaUi
local XUiGuildWarStageMain = XLuaUiManager.Register(XLuaUi, "UiGuildWarStageMain")
local XUiPanelTop = require("XUi/XUiGuildWar/Map/XUiPanelTop")
local XUiPanelStage = require("XUi/XUiGuildWar/Map/XUiPanelStage")
local XUiPanelBottom = require("XUi/XUiGuildWar/Map/XUiPanelBottom")
local XUiPanelMap = require("XUi/XUiGuildWar/Map/XUiPanelMap")
local XUiPanelReview = require("XUi/XUiGuildWar/Map/XUiPanelReview")

local CSXTextManagerGetText = CS.XTextManager.GetText

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
end

function XUiGuildWarStageMain:OnDisable()
    XUiGuildWarStageMain.Super.OnDisable(self)
    self:RemoveEventListener()
    self.StagePanel:OnDisable()
    self:StopTimeRefresh()
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