local XUiGridPlayer = XClass(nil, "XUiGridPlayer")
local CSTextManagerGetText = CS.XTextManager.GetText
function XUiGridPlayer:Ctor(ui,IsTeacher)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.IsTeacher = IsTeacher
    XTool.InitUiObject(self)
    self:SetButtonCallBack()
end

function XUiGridPlayer:SetButtonCallBack()
    self.BtnPlayerInfo.CallBack = function()
        self:OnBtnPlayerInfoClick()
    end
end

function XUiGridPlayer:OnBtnPlayerInfoClick()
    if self.Data and self.Data.PlayerId and self.Data.PlayerId > 0 then
        XDataCenter.PersonalInfoManager.ReqShowInfoPanel(self.Data.PlayerId) 
    end
end

function XUiGridPlayer:UpdateGrid(data)
    self.Data = data
    if data and data.PlayerId and data.PlayerId > 0 then
        self.TextName.text = data.PlayerName
        self.TeacherLabel.gameObject:SetActiveEx(false)
        self.TextState.text = self.IsTeacher and CSTextManagerGetText("MentorPlayerStateNoneText") or
        (data.IsGraduate and CSTextManagerGetText("MentorPlayerStateGraduateText") or CSTextManagerGetText("MentorPlayerStateStudyText"))
        XUiPLayerHead.InitPortrait(data.HeadPortraitId, data.HeadFrameId, self.Head)
    end
end

return XUiGridPlayer