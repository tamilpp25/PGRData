local XUiGridStudent = XClass(nil, "XUiGridStudent")
local DefaultIndex = 1

function XUiGridStudent:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:SetButtonCallBack()
end

function XUiGridStudent:SetButtonCallBack()
    self.PanelPlayer:GetObject("BtnInfo").CallBack = function()
        self:OnBtnInfoClick()
    end
    
    self.PanelPlayer:GetObject("BtnRecording").CallBack = function()
        self:OnBtnRecordingClick()
    end
    
    self.BtnStudentRecruit.CallBack = function()
        self:OnBtnRecruitClick()
    end
end

function XUiGridStudent:OnBtnInfoClick()
    XDataCenter.PersonalInfoManager.ReqShowInfoPanel(self.Data.PlayerId)
end

function XUiGridStudent:OnBtnRecordingClick()
    XLuaUiManager.Open("UiMentorRecording", self.Data, false)
end

function XUiGridStudent:OnBtnRecruitClick()
    XDataCenter.MentorSystemManager.GetMentorRecommendPlayerListRequest(function ()
            XLuaUiManager.Open("UiMentorRecommendation")
        end)
end

function XUiGridStudent:UpdateGrid(data)
    self.Data = data
    if data then
        self:SetStudentInfo(data)
        self:ShowStudent(true)
    else
        self:ShowStudent(false)
    end
    self:ShowMySelfTag(data)
end

function XUiGridStudent:ShowMySelfTag(data)
    self.PanelMy.gameObject:SetActiveEx(data and data.PlayerId == XPlayer.Id or false)
end

function XUiGridStudent:ShowStudent(IsShow, IsTeacher)
    local mentorData = XDataCenter.MentorSystemManager.GetMentorData()
    self.PanelPlayer.gameObject:SetActiveEx(IsShow)
    self.PanelNone.gameObject:SetActiveEx(not IsShow)
    self.PanelNone:GetObject("TextStudent").gameObject:SetActiveEx(not IsShow and not mentorData:IsTeacher())
    self.PanelNone:GetObject("BtnStudentRecruit").gameObject:SetActiveEx(not IsShow and mentorData:IsTeacher())
    self.PanelPlayer:GetObject("BtnRecording").gameObject:SetActiveEx(mentorData:IsTeacher())
end

function XUiGridStudent:SetStudentInfo(data)
    local tmpData = data
    if data.PlayerId == XPlayer.Id then
        tmpData.HeadPortraitId = XPlayer.CurrHeadPortraitId
        tmpData.HeadFrameId = XPlayer.CurrHeadFrameId
        tmpData.Level = XPlayer.Level
        tmpData.PlayerName = XPlayer.Name
    end
    
    local headObj = {}
    if tmpData.IsOnline then
        headObj = self.PanelPlayer:GetObject("HeadOnLine")
    else
        headObj = self.PanelPlayer:GetObject("HeadOffLine")
    end
    
    XUiPLayerHead.InitPortrait(tmpData.HeadPortraitId, tmpData.HeadFrameId, headObj)
    self.PanelPlayer:GetObject("HeadOnLine").gameObject:SetActiveEx(tmpData.IsOnline)
    self.PanelPlayer:GetObject("HeadOffLine").gameObject:SetActiveEx(not tmpData.IsOnline)
    
    XUiPlayerLevel.UpdateLevel(tmpData.Level, self.PanelPlayer:GetObject("TxtLevel"))
    self.PanelPlayer:GetObject("TxtName").text = tmpData.PlayerName
end

function XUiGridStudent:ShowReddot(IsShow)
    self.PanelNone:GetObject("BtnStudentRecruit"):ShowReddot(IsShow)
end

return XUiGridStudent