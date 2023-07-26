local XUiMentorRecording = XLuaUiManager.Register(XLuaUi, "UiMentorRecording")

local CSXTextManagerGetText = CS.XTextManager.GetText

function XUiMentorRecording:OnStart(data, IsTeacher)
    self:SetButtonCallBack()
    self:ShowPanel(data, IsTeacher)
end

function XUiMentorRecording:SetButtonCallBack()
    self.BtnClose.CallBack = function()
        self:Close()
    end
end

function XUiMentorRecording:ShowPanel(data, IsTeacher)
    XUiPLayerHead.InitPortrait(data.HeadPortraitId, data.HeadFrameId, self.Head)
    XUiPlayerLevel.UpdateLevel(data.Level, self.TxtLevel)
    
    self.TxtName.text = data.PlayerName
    self.TxtLastLoginTime.text = CSXTextManagerGetText("LastLoginTimeText",self:CheckTime(data.LastLoginTime))
    
    self.PanelBuildTime:GetObject("TxtTime").text = self:CheckTime(data.JoinTime)
    self.PanelLevelTime:GetObject("TxtTime").text = self:CheckTime(data.ReachTime)
    
    self.PanelLevelTime.gameObject:SetActiveEx(not IsTeacher)
end

function XUiMentorRecording:CheckTime(time)
    if time == 0 then
        return "--"
    else
        return XTime.TimestampToGameDateTimeString(time, "yyyy-MM-dd")
    end
end