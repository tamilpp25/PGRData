local XUiPanelArenaOnline = XClass(nil, "XUiPanelArenaOnline")

function XUiPanelArenaOnline:Ctor(uiRoot, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot

    XTool.InitUiObject(self)
    self:AutoAddListener()
    self:Hide()
    self.ToggleShow:SetButtonState(CS.UiButtonState.Normal)
end

function XUiPanelArenaOnline:AutoAddListener()
    self.BtnSure.CallBack = function() self:OnBtnSureClick() end
    self.BtnCancel.CallBack = function() self:OnBtnCancelClick() end
end

function XUiPanelArenaOnline:OnBtnCancelClick()
    self:StopTimer()
    self:Hide(true)
    self:CheckSetInviteTip()
end

function XUiPanelArenaOnline:OnBtnSureClick()
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.StageId)
    local fubenName = ""
    if stageInfo.Type == XDataCenter.FubenManager.StageType.BossOnline then
        fubenName = XFunctionManager.FunctionName.FubenActivity
    elseif stageInfo.Type == XDataCenter.FubenManager.StageType.Daily then
        local challengeCfg = XDataCenter.FubenDailyManager.GetDailyCfgBySectionId(stageInfo.DailySectionId)
        if challengeCfg and challengeCfg.Type == XDataCenter.FubenManager.ChapterType.EMEX then
            fubenName = XFunctionManager.FunctionName.FubenDailyEMEX
        end
    elseif stageInfo.Type == XDataCenter.FubenManager.StageType.ArenaOnline then
        fubenName = XFunctionManager.FunctionName.ArenaOnline
    end

    if not XFunctionManager.DetectionFunction(fubenName) then
        self:Hide(true)
        self:CheckSetInviteTip()
        return
    end

    if stageInfo.Type == XDataCenter.FubenManager.StageType.ArenaOnline then
        XDataCenter.RoomManager.ArenaOnlineEnterTargetRoom(self.RoomId, self.StageId, self.CreateTime)
    else
        XDataCenter.RoomManager.NormalEnterTargetRoom(self.RoomId, self.StageId, self.CreateTime)
    end

    self:Hide(true)
    self:CheckSetInviteTip()
end

function XUiPanelArenaOnline:CheckSetInviteTip()
    if not self.ToggleShow:GetToggleState() then
        return
    end

    XDataCenter.ArenaOnlineManager.SetInviteTip()
end

function XUiPanelArenaOnline:Show(chatData)
    if not XDataCenter.ArenaOnlineManager.CheckInviteTipShow() then
        return
    end

    if chatData.MsgType ~= ChatMsgType.RoomMsg then
        return
    end

    local contentData = XChatData.DecodeRoomMsg(chatData.Content)
    if not contentData then
        return
    end

    self.ToggleShow:SetButtonState(CS.UiButtonState.Normal)
    self.StageId = tonumber(contentData[3])
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.StageId)
    if not stageInfo or stageInfo.Type ~= XDataCenter.FubenManager.StageType.ArenaOnline then
        return
    end

    self:StopTimer()
    local senderId = chatData.SenderId
    local remark = XDataCenter.SocialManager.GetFriendRemark(senderId)
    if remark ~= "" then
        self.TxtName.text = remark
    else
        self.TxtName.text = chatData.NickName
    end
    self.RoomId = contentData[4]
    self.CreateTime = chatData.CreateTime


    local name = XArenaOnlineConfigs.GetFirstChapterName()
    self.TxtChpaterName.text = CS.XTextManager.GetText("ArenaOnlineInviteShow", name)

    self.LeftTime = XArenaOnlineConfigs.SHOW_TIME
    self.Timer = XScheduleManager.ScheduleForever(function()
        self.LeftTime = self.LeftTime - 1
        if self.LeftTime <= 0 then
            self:StopTimer()
            self:Hide(true)
            return
        end
    end, XScheduleManager.SECOND, 0)
    self.GameObject:SetActiveEx(true)
    self.UiRoot:PlayAnimation("AnimArenaOnlineEnable")
end

function XUiPanelArenaOnline:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiPanelArenaOnline:OnDestroy()
    self:StopTimer()
end

function XUiPanelArenaOnline:Hide(isAnima)
    if isAnima then
        self.UiRoot:PlayAnimation("AnimArenaOnlineDisable", function()
            self.GameObject:SetActiveEx(false)
        end)
    else
        self.GameObject:SetActiveEx(false)
    end
end

return XUiPanelArenaOnline