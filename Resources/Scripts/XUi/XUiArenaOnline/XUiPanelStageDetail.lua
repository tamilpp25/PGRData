local XUiPanelStageDetail = XClass(nil, "XUiPanelStageDetail")
local XUiPanelStagInfo = require("XUi/XUiArenaOnline/XUiPanelStagInfo")
local XUiPanelTargetInfo = require("XUi/XUiArenaOnline/XUiPanelTargetInfo")
local XUiPanelBuffDetail = require("XUi/XUiArenaOnline/XUiPanelBuffDetail")

local Select = CS.UiButtonState.Select
local Normal = CS.UiButtonState.Normal

function XUiPanelStageDetail:Ctor(uiRoot, ui, openCb, closeCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot
    self.OpenCb = openCb
    self.CloseCb = closeCb

    XTool.InitUiObject(self)
    self:AutoAddListener()
    self:Init()
    self.GameObject:SetActiveEx(false)
end

function XUiPanelStageDetail:Init()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint)
    self.StageInfoPanel = XUiPanelStagInfo.New(self.UiRoot, self.PanelStageInfo)
    self.TargetInfoPanel = XUiPanelTargetInfo.New(self.UiRoot, self, self.PanelTargetInfo)
    self.BuffDetailPanel = XUiPanelBuffDetail.New(self.PanelBuffDetail)
end

function XUiPanelStageDetail:Show(stageId)
    if self.StageId == stageId then
        self.GameObject:SetActiveEx(true)
        if self.OpenCb then self.OpenCb() end
        return
    end
    self.MultiplayerMode = true
    self.StageId = stageId
    self:Refresh()
end

function XUiPanelStageDetail:Refresh(checkActive)
    if not self.StageId then return end
    if checkActive and not self.GameObject.activeSelf then return end

    self.ArenaStageCfg = XArenaOnlineConfigs.GetStageById(self.StageId)
    local id = XDataCenter.ArenaOnlineManager.GetStageId(self.StageId)
    self.FubenStageCfg = XDataCenter.FubenManager.GetStageCfg(id)
    local leastPlayer = self.FubenStageCfg.OnlinePlayerLeast <= 0 and 1 or self.FubenStageCfg.OnlinePlayerLeast
    self.TxtTitle.text = self.ArenaStageCfg.Name
    self.TxtPeople.text = leastPlayer
    local stageInfo = XDataCenter.ArenaOnlineManager.GetStageInfo(self.StageId)
    local atNums = stageInfo.Passed and 0 or self.ArenaStageCfg.EnduranceCost
    self.TxtATNums.text = atNums
    self.PanelMatching.gameObject:SetActiveEx(false)
    self.BtnModeToggle.gameObject:SetActiveEx(self.ArenaStageCfg.SingleSwitch)
    self.BtnModeToggle:SetButtonState(not self.MultiplayerMode and Select or Normal)
    self.TxtConsumeHint.text = self.MultiplayerMode and CS.XTextManager.GetText("ArenaOnlineStageDetailHintOnline") or CS.XTextManager.GetText("ArenaOnlineStageDetailHintSingle")
    self.BtnCreateRoom:SetName(self.MultiplayerMode and CS.XTextManager.GetText("ArenaOnlineCreateRoomOnline") or CS.XTextManager.GetText("ArenaOnlineCreateRoomSingle"))
    local isNoStart = not self.FubenStageCfg.StarDesc or #self.FubenStageCfg.StarDesc <= 0
    if isNoStart then
        self.StageInfoPanel:Hide()
        self.TargetInfoPanel:Show(self.StageId, checkActive)
    else
        self.StageInfoPanel:Show(self.StageId, self.MultiplayerMode, checkActive)
        self.TargetInfoPanel:Hide()
    end

    self.BtnTarget.gameObject:SetActiveEx(not isNoStart)
    self.BtnStage.gameObject:SetActiveEx(isNoStart)

    local isMatching = XDataCenter.RoomManager.Matching
    self.BtnMatch.gameObject:SetActive(not isMatching and self.MultiplayerMode)
    self.PanelMatching.gameObject:SetActive(isMatching and self.MultiplayerMode)
    self.BtnCreateRoom.interactable = not isMatching

    self.GameObject:SetActiveEx(true)
    if self.OpenCb then self.OpenCb() end
end

function XUiPanelStageDetail:BuffDetailShow(stageId)
    self.BuffDetailPanel:Show(stageId)
    self.UiRoot:PlayAnimation("BuffDetailEnable")
end

function XUiPanelStageDetail:Hide()
    self.GameObject:SetActiveEx(false)
    if self.CloseCb then self.CloseCb() end
end

function XUiPanelStageDetail:AutoAddListener()
    self.BtnStage.CallBack = function() self:OnBtnStageClick() end
    self.BtnTarget.CallBack = function() self:OnBtnTargetClick() end
    self.BtnMatch.CallBack = function() self:OnBtnMatchClick() end
    self.BtnCreateRoom.CallBack = function() self:OnBtnCreateRoomClick() end
    self.BtnModeToggle.CallBack = function() self:OnBtnModeToggleClick() end
end

function XUiPanelStageDetail:OnBtnStageClick()
    self.StageInfoPanel:Show(self.StageId, self.MultiplayerMode)
    self.TargetInfoPanel:Hide()

    self.BtnTarget.gameObject:SetActiveEx(true)
    self.BtnStage.gameObject:SetActiveEx(false)
end

function XUiPanelStageDetail:OnBtnTargetClick()
    self.StageInfoPanel:Hide()
    self.TargetInfoPanel:Show(self.StageId)

    self.BtnTarget.gameObject:SetActiveEx(false)
    self.BtnStage.gameObject:SetActiveEx(true)
end

function XUiPanelStageDetail:OnBtnModeToggleClick()
    self.MultiplayerMode = not self.BtnModeToggle:GetToggleState()
    self:Refresh()
end

function XUiPanelStageDetail:OnBtnCreateRoomClick()
    if XDataCenter.RoomManager.Matching then
        XUiManager.TipMsg(CS.XTextManager.GetText("OnlineInstanceMatching"))
        return
    end

    if XDataCenter.ArenaOnlineManager.CheckTimeOut() then
        XUiManager.TipMsg(CS.XTextManager.GetText("ArenaOnlineTimeOut"))
        return
    end
        -- if XDataCenter.FubenManager.CheckPreFight(self.Stage) then
        --     self.Parent:CloseStageDetail()
        -- end
    if self.MultiplayerMode then
        XDataCenter.FubenManager.RequestArenaOnlineCreateRoom(self.FubenStageCfg, self.StageId)
    else
        -- local id = XDataCenter.ArenaOnlineManager.GetStageId(self.StageId)
        -- XLog.Warning(id, self.StageId)
            local data = {ChallengeId = self.StageId}
            local cfg = XDataCenter.ArenaOnlineManager.GetArenaOnlineStageCfgStageId(self.StageId)
            local levelControl = XFubenConfigs.GetStageMultiplayerLevelControlCfgById(cfg.SingleDiff[1])
            XLuaUiManager.Open("UiNewRoomSingle", levelControl.StageId, data)
    end
end

function XUiPanelStageDetail:OnBtnMatchClick()
    if XDataCenter.ArenaOnlineManager.CheckTimeOut() then
        XUiManager.TipMsg(CS.XTextManager.GetText("ArenaOnlineTimeOut"))
        return
    end

    if XDataCenter.RoomManager.Matching then
        return
    end

    XDataCenter.FubenManager.RequestAreanaOnlineMatchRoom(self.FubenStageCfg, self.StageId, function()
        if XDataCenter.RoomManager.Matching then
            XLuaUiManager.Open("UiOnLineMatching", self.FubenStageCfg)
        end
        self.BtnCreateRoom.interactable = false
        self.BtnMatch.gameObject:SetActiveEx(false)
        self.PanelMatching.gameObject:SetActiveEx(true)
    end)
end

function XUiPanelStageDetail:OnCancelMatch()
    self.BtnCreateRoom.interactable = true
    self.BtnMatch.gameObject:SetActiveEx(self.MultiplayerMode)
    self.PanelMatching.gameObject:SetActiveEx(false)
end

function XUiPanelStageDetail:ResetState()
    self.BtnMatch.gameObject:SetActive(self.MultiplayerMode)
    self.PanelMatching.gameObject:SetActive(false)
    self.BtnCreateRoom.interactable = true
end


return XUiPanelStageDetail