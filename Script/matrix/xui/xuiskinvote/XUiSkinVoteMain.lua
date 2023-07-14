
---@class XUiSkinVoteMain 涂装投票主界面
local XUiSkinVoteMain = XLuaUiManager.Register(XLuaUi, "UiSkinVoteMain")

function XUiSkinVoteMain:OnAwake()
    ---@type XSkinVote
    self.ViewModel = XDataCenter.SkinVoteManager.GetViewModel()
    self:InitUi()
    self:InitCb()
end 

function XUiSkinVoteMain:OnStart()
    self:InitView()
end 

function XUiSkinVoteMain:OnEnable()
    self.Super.OnEnable(self)

    XDataCenter.SkinVoteManager.RequestSkinVoteData(function()
        self.PanelSkinVote:Show()
    end)
    
    if not self.Timer then
        self.Timer = XScheduleManager.ScheduleForever(function() 
            self:RefreshVote()
        end, XScheduleManager.SECOND)
    end
end 

function XUiSkinVoteMain:Close()
    self.ViewModel:ResetPreviewIndex()
    self.Super.Close(self)
end

function XUiSkinVoteMain:OnDisable()
    self.PanelSkinVote:Hide()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiSkinVoteMain:InitUi()
    local prefab = self.PanelContainer:LoadPrefab(self.ViewModel:GetPrefabPath())
    ---@type XUiPanelSkinVote
    self.PanelSkinVote = require("XUi/XUiSkinVote/XUiPanel/XUiPanelSkinVote").New(prefab, self)
    self.PanelDialog.gameObject:SetActiveEx(false)
    ---@type XUiPanelSkinVoteDialog
    self.PanelDialog = require("XUi/XUiSkinVote/XUiPanel/XUiPanelSkinVoteDialog").New(self.PanelDialog)
end 

function XUiSkinVoteMain:InitCb()
    self:BindExitBtns()
end 

function XUiSkinVoteMain:InitView()
    local endTime = self.ViewModel:GetActivityEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose or not XDataCenter.SkinVoteManager.IsOpen() then
            XDataCenter.SkinVoteManager.OnActivityEnd()
        end
    end)
    XDataCenter.SkinVoteManager.MarkViewPublicRedPoint()
end

function XUiSkinVoteMain:RefreshVote()
    if not self.PanelSkinVote then
        return
    end
    self.PanelSkinVote:RefreshTime()
end

function XUiSkinVoteMain:ShowDialog(title, content, cancelBtnName, cancelCb, confirmBtnName, confirmCb)
    if not self.PanelDialog then
        return
    end
    
    self.PanelDialog:Show(title, content, cancelBtnName, cancelCb, confirmBtnName, confirmCb)
end



