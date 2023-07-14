

---@class XUiBtnDownload 分包下载通用按钮
---@field GameObject UnityEngine.GameObject
---@field Transform UnityEngine.Transform
---@field BtnClick XUiComponent.XUiButton
---@field AnimLoop UnityEngine.Transform
---@field EntryType number
---@field EntryParam number 可以为0
---@field ProgressCb function
---@field DoneCb function
---@field TimelineComponent XUiPlayTimelineAnimation
---@field IsPlaying boolean
local XUiBtnDownload = XClass(nil, "XUiBtnDownload")

function XUiBtnDownload:Ctor(btnDownload, beforeCb)
    XTool.InitUiObjectByUi(self, btnDownload)
    self.BtnClick = self.Transform:GetComponent("XUiButton")
    self.AnimLoop = self.Transform:Find("Animation/DownloadLoop")
    self.BtnClick.CallBack = function() self:OnBtnClick() end
    self.DownloadBeforeCheckCb = beforeCb
    self.IsPlaying = false
end

function XUiBtnDownload:Init(entryType, entryParam, progressCb, doneCb)
    self.EntryType = entryType
    self.EntryParam = entryParam
    self.ProgressCb = progressCb
    self.DoneCb = doneCb
end

function XUiBtnDownload:RefreshView(refreshCb)
    if not XDataCenter.DlcManager.CheckIsOpen() then
        if not XTool.UObjIsNil(self.GameObject) then
            self.GameObject:SetActiveEx(false)
        end
        if refreshCb then refreshCb(false) end
        return
    end
    local needDownload = self:CheckNeedDownload()
    if self:Exist() then
        self.GameObject:SetActiveEx(needDownload)
        self:RefreshAnimation()
    end
    if refreshCb then refreshCb(needDownload) end
end

function XUiBtnDownload:RefreshAnimation()
    if not XDataCenter.DlcManager.CheckIsOpen() then
        if not XTool.UObjIsNil(self.GameObject) then
            self.GameObject:SetActiveEx(false)
        end
        return
    end
    local dlcListId = XDlcConfig.GetDlcListIdByEntry(self.EntryType, self.EntryParam)
    if not XTool.IsNumberValid(dlcListId) then
        return
    end
    self:StopTimeLineAnimation()
    XScheduleManager.ScheduleOnce(function()
        local itemData = XDataCenter.DlcManager.GetItemData(dlcListId)
        if not self:Exist() or not self.GameObject.activeInHierarchy or not itemData then
            return
        end
        if not (itemData and itemData:IsDownloading()) then
            self:StopTimeLineAnimation()
        else
            self:PlayTimeLineAnimation()
        end
    end, 100)
end

function XUiBtnDownload:CheckNeedDownload()
    if not XDataCenter.DlcManager.CheckIsOpen() then
        self.GameObject:SetActiveEx(false)
        return false
    end
    if not self.EntryParam and XTool.IsNumberValid(self.EntryType) then
        if self:Exist() then
            self.GameObject:SetActiveEx(false)
        end
        return false
    end
    return XDataCenter.DlcManager.CheckNeedDownload(self.EntryType, self.EntryParam)
end

function XUiBtnDownload:PlayTimeLineAnimation()
    if not self:Exist() or XTool.UObjIsNil(self.AnimLoop) 
            or not self.GameObject.activeInHierarchy or self.IsPlaying then
        return
    end
    self.IsPlaying = true
    self.AnimLoop:PlayTimelineAnimation(nil, nil, CS.UnityEngine.Playables.DirectorWrapMode.Loop)
    if XTool.UObjIsNil(self.TimelineComponent) then
        self.TimelineComponent = self.AnimLoop.gameObject:GetComponent("XUiPlayTimelineAnimation")
    end
end

function XUiBtnDownload:StopTimeLineAnimation()    
    self.IsPlaying = false
    if XTool.UObjIsNil(self.TimelineComponent) then
        return
    end
    self.TimelineComponent:Stop(true)
end

function XUiBtnDownload:OnBtnClick()
    local needDownload = self:CheckNeedDownload()
    if not needDownload then
        return
    end
    local itemData = XDataCenter.DlcManager.GetItemData(XDlcConfig.GetDlcListIdByEntry(self.EntryType, self.EntryParam))
    if itemData and itemData:IsComplete() then
        self.GameObject:SetActiveEx(false)
        return
    end
    if self.DownloadBeforeCheckCb and not self.DownloadBeforeCheckCb() then
        return
    end
    XDataCenter.DlcManager.TryDownloadByEntryTypeAndParam(self.EntryType, self.EntryParam,
            function(progress) self:OnProgress(progress) end,
            function() self:OnComplete(itemData) end, 
            function() self:PlayTimeLineAnimation() end)
end

function XUiBtnDownload:OnProgress(progress)
    if self.ProgressCb then
        self.ProgressCb(progress)
    end
end

function XUiBtnDownload:OnComplete(itemData)
    if self.DoneCb then
        self.DoneCb()
    end
    self:RefreshView()
    if itemData and itemData:IsComplete() then
        XUiManager.PopupLeftTip(XUiHelper.GetText("DlcDownloadCompleteTitle"), itemData:GetTitle())
    end
end

function XUiBtnDownload:Exist()
    return not XTool.UObjIsNil(self.GameObject)
end

function XUiBtnDownload:IsTimeLinePlaying()
    if not self:Exist() or XTool.UObjIsNil(self.AnimLoop)
            or not self.GameObject.activeInHierarchy then
        return false
    end
    return self.IsPlaying
end

return XUiBtnDownload