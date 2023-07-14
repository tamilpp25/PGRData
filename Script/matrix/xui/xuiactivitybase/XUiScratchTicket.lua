-- 刮刮乐界面控件
local XUiScratchTicket = XClass(nil, "XUiScratchTicket")

function XUiScratchTicket:Ctor(uiGameObject, rootUi)
    XTool.InitUiObjectByUi(self, uiGameObject)
    self.RootUi = rootUi
    self:RegisterEventListeners()
end

function XUiScratchTicket:Refresh(activityCfg)
    local activityId = activityCfg.Params[1]
    self.Controller = XDataCenter.ScratchTicketManager.GetActivityController(activityId)
    if not self.Controller then
        XLog.Error("没有找到刮刮乐控制器！ activityId:" .. activityId)
        return
    end
    self:InitPanels()
end

function XUiScratchTicket:InitPanels()
    self:InitTicketPanel()
    self:InitTopPanel()
    self:InitLeftPanel()
    self:InitPlayPanel()
    self:ShowPanels()
end

function XUiScratchTicket:InitTicketPanel()
    local isOrdinaryTicket = not self.Controller:GetIsCanReset()
    self.OrdinaryTicket.gameObject:SetActiveEx(isOrdinaryTicket)
    self.GoldenTicket.gameObject:SetActiveEx(not isOrdinaryTicket)
    self.TicketPanel = {}
    XTool.InitUiObjectByUi(self.TicketPanel, isOrdinaryTicket and self.OrdinaryTicket or self.GoldenTicket)
end

function XUiScratchTicket:InitTopPanel()
    local panelScript = require("XUi/XUiActivityBase/ScratchTicket/XUiScratchTicketPanelTop")
    self.TopPanel = panelScript.New(self.TicketPanel.PanelTop, self.Controller, self)
end

function XUiScratchTicket:InitLeftPanel()
    local panelScript = require("XUi/XUiActivityBase/ScratchTicket/XUiScratchTicketPanelLeft")
    self.LeftPanel = panelScript.New(self.TicketPanel.PanelLeft, self.Controller, self)
end

function XUiScratchTicket:InitPlayPanel()
    local panelScript = require("XUi/XUiActivityBase/ScratchTicket/XUiScratchTicketPanelPlay")
    self.PlayPanel = panelScript.New(self.TicketPanel.PanelPlay, self.Controller, self)
end

function XUiScratchTicket:ShowPanels()
    local ticket = self.Controller:GetTicket()
    local playStatus = ticket and ticket:GetPlayStatus() or XDataCenter.ScratchTicketManager.PlayStatus.NotStart
    if playStatus == XDataCenter.ScratchTicketManager.PlayStatus.NotStart then
        self:OnReady()
    elseif playStatus == XDataCenter.ScratchTicketManager.PlayStatus.Playing then
        if self.Controller:CheckPreviewFinish() then
            self.PlayPanel:ShowChooseChose()
        else
            self:OnGameStart()
        end
    end
end

function XUiScratchTicket:OnGameEnd()
    if not self:Exist() then return end
    XLuaUiManager.RunMain()
    XUiManager.TipMsg(CS.XTextManager.GetText("CommonActivityEnd"))
end

function XUiScratchTicket:OnOpenGrid(activityId)
    if not self:Exist() then return end
    if activityId and self.Controller:GetId() ~= activityId then return end
    self.PlayPanel:OnOpenGrid()
end

function XUiScratchTicket:OnShowResult(activityId, rewardList)
    if not self:Exist() then return end
    if activityId and self.Controller:GetId() ~= activityId then return end
    if rewardList and not self.Mask then
        self.Mask = true
        XLuaUiManager.SetMask(true)
    end
    self.LeftPanel:RefreshSelect()
    self.PlayPanel:ShowResult()
    self.ResultTimer = XScheduleManager.ScheduleOnce(function()
            if self.Mask then
                self.Mask = false
                XLuaUiManager.SetMask(false)
            end
            if rewardList then
                XUiManager.OpenUiObtain(rewardList, nil, function()
                        self.ResultTimer = nil
                    end)
            end
        end, 1000)
end

function XUiScratchTicket:Exist()
    if XTool.UObjIsNil(self.Transform) then
        self:OnDestroy()
        return false
    end
    return true
end

function XUiScratchTicket:OnGameStart(activityId)
    if not self:Exist() then return end
    if activityId and self.Controller:GetId() ~= activityId then return end
    self.LeftPanel:RefreshPanel()
    self.PlayPanel:ShowGaming()
end

function XUiScratchTicket:OnReady(activityId)
    if not self:Exist() then return end
    if activityId and self.Controller:GetId() ~= activityId then return end
    self.LeftPanel:OnReset()
    self.PlayPanel:ShowReady()
end

function XUiScratchTicket:PlayAnimation(animName)
    if self.TicketPanel[animName] then
        self.TicketPanel[animName]:Stop()
        self.TicketPanel[animName]:Play()
    end
end

function XUiScratchTicket:RegisterEventListeners()
    if self.ListenersAdded then return end
    self.ListenersAdded = true
    XEventManager.AddEventListener(XEventId.EVENT_SCRATCH_TICKET_ACTIVITY_START, self.OnGameStart, self)
    XEventManager.AddEventListener(XEventId.EVENT_SCRATCH_TICKET_OPEN_GRID, self.OnOpenGrid, self)
    XEventManager.AddEventListener(XEventId.EVENT_SCRATCH_TICKET_SHOW_RESULT, self.OnShowResult, self)
    XEventManager.AddEventListener(XEventId.EVENT_SCRATCH_TICKET_RESET, self.OnGameStart, self)
end

function XUiScratchTicket:RemoveEventListeners()
    if not self.ListenersAdded then return end
    XEventManager.RemoveEventListener(XEventId.EVENT_SCRATCH_TICKET_ACTIVITY_START, self.OnGameStart, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SCRATCH_TICKET_OPEN_GRID, self.OnOpenGrid, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SCRATCH_TICKET_SHOW_RESULT, self.OnShowResult, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SCRATCH_TICKET_RESET, self.OnReset, self)
    self.ListenersAdded = false
end

function XUiScratchTicket:OnDisable()
    self.PlayPanel:OnDisable()
end

function XUiScratchTicket:OnDestroy()
    self.TopPanel:OnDestroy()
    self.LeftPanel:OnDestroy()
    self.PlayPanel:OnDestroy()
    if self.Mask then
        XLuaUiManager.SetMask(false)
    end
    if self.ResultTimer then
        XScheduleManager.UnSchedule(self.ResultTimer)
        self.ResultTimer = nil
    end
    self:RemoveEventListeners()
end

return XUiScratchTicket