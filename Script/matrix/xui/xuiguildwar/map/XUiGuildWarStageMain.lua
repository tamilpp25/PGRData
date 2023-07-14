local XUiGuildWarStageMain = XLuaUiManager.Register(XLuaUi, "UiGuildWarStageMain")
local XUiPanelTop = require("XUi/XUiGuildWar/Map/XUiPanelTop")
local XUiPanelStage = require("XUi/XUiGuildWar/Map/XUiPanelStage")
local XUiPanelBottom = require("XUi/XUiGuildWar/Map/XUiPanelBottom")
local XUiPanelMap = require("XUi/XUiGuildWar/Map/XUiPanelMap")
local XUiPanelReview = require("XUi/XUiGuildWar/Map/XUiPanelReview")

local CSXTextManagerGetText = CS.XTextManager.GetText

function XUiGuildWarStageMain:OnStart()
    self.BattleManager = XDataCenter.GuildWarManager.GetBattleManager()
    self:Init()
    self:SetButtonCallBack()
end

function XUiGuildWarStageMain:OnEnable()
    XUiGuildWarStageMain.Super.OnEnable(self)
    self:CheckNewRoundExit()
    self:AddEventListener()
    self:UpdatePanel()
    self:CheckShowAction()
    self:SetTimeRefresh()
    self:AddActionCheck()

end

function XUiGuildWarStageMain:OnDisable()
    XUiGuildWarStageMain.Super.OnDisable(self)
    self:RemoveEventListener()
    self:StopActionPlay()
    self:StopTimeRefresh()
    self:StopActionCheck()
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
    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool)
    XDataCenter.ItemManager.AddCountUpdateListener(itemIds, function()
            self.AssetActivityPanel:Refresh(itemIds, nil , { XDataCenter.GuildWarManager.GetMaxEnergy() })
        end, self.AssetActivityPanel)
    self.AssetActivityPanel:Refresh(itemIds, nil, { XDataCenter.GuildWarManager.GetMaxEnergy() })

    self.BattleManager:SetIsHistoryAction(true)
    XDataCenter.GuildWarManager.GetNewRoundFlag()--如果是新打开的界面则无视之前的新回合标记
end

function XUiGuildWarStageMain:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_PATHEDIT_OVER, self.PathEditOver, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILDWAR_NEW_ROUND, self.CheckNewRoundExit, self)
    self.TopPanel:AddEventListener()
    self.StagePanel:AddEventListener()
    self.BottomPanel:AddEventListener()
    self.MapPanel:AddEventListener()
    self.ReviewPanel:AddEventListener()

end

function XUiGuildWarStageMain:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_PATHEDIT_OVER, self.PathEditOver, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILDWAR_NEW_ROUND, self.CheckNewRoundExit, self)
    self.TopPanel:RemoveEventListener()
    self.StagePanel:RemoveEventListener()
    self.BottomPanel:RemoveEventListener()
    self.MapPanel:RemoveEventListener()
    self.ReviewPanel:RemoveEventListener()
end

function XUiGuildWarStageMain:StopActionPlay()
    self.StagePanel:StopActionPlay()
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

function XUiGuildWarStageMain:CheckShowAction()
    self.StagePanel:ShowAction(true)
end

function XUiGuildWarStageMain:PathEdit()
    self.MapPanel:ShowPanel()
    self.MapPanel:ShowButton(false)
    self.TopPanel:HidePanel()
    self.BottomPanel:HidePanel()
    self.StagePanel:PathEdit()
end

function XUiGuildWarStageMain:PathEditOver(IsSave)
    self.StagePanel:PathEditOver(IsSave, function ()
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
                XDataCenter.GuildWarManager.GetActivityData(function ()
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

function XUiGuildWarStageMain:AddActionCheck()
    self.ActionShowTimer = XScheduleManager.ScheduleForever(function()
            if XLuaUiManager.GetTopUiName() == "UiGuildWarStageMain" and not self.StagePanel:CheckIsPathEdit() then
                self.StagePanel:ShowAction(false)
            end
        end, XScheduleManager.SECOND , 0)
end

function XUiGuildWarStageMain:StopActionCheck()
    if self.ActionShowTimer then
        XScheduleManager.UnSchedule(self.ActionShowTimer)
        self.ActionShowTimer = nil
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
