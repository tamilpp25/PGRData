local XUiPlayerLevel = require("XUi/XUiCommon/XUiPlayerLevel")
local XUiGridTeacher = XClass(nil, "XUiGridTeacher")
local DefaultIndex = 1

function XUiGridTeacher:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    
    self:SetButtonCallBack()
end

function XUiGridTeacher:SetButtonCallBack()
    self.PanelPlayer:GetObject("BtnInfo").CallBack = function()
        self:OnBtnInfoClick()
    end
    
    self.PanelPlayer:GetObject("BtnRecording").CallBack = function()
        self:OnBtnRecordingClick()
    end
    
    self.PanelRobot:GetObject("BtnTecherRecruit").CallBack = function()
        self:OnBtnRecruitClick()
    end
    
end

function XUiGridTeacher:OnBtnInfoClick()
    XDataCenter.PersonalInfoManager.ReqShowInfoPanel(self.Data.PlayerId)
end

function XUiGridTeacher:OnBtnRecordingClick()
    XLuaUiManager.Open("UiMentorRecording", self.Data, true)
end

function XUiGridTeacher:OnBtnRecruitClick()
    XDataCenter.MentorSystemManager.GetMentorRecommendPlayerListRequest(function ()
            XLuaUiManager.Open("UiMentorRecommendation")
        end)
end

function XUiGridTeacher:UpdateGrid(data)
    self.Data = data
    if data and data.PlayerId and data.PlayerId > 0 then
        self:ShowMentorTag(true)
        self:SetMentorInfo(data)
    else
        self:ShowMentorTag(false)
    end
    self.TutorLabel.gameObject:SetActiveEx(true)
end

function XUiGridTeacher:ShowMentorTag(IsShow)
    self.PanelPlayer.gameObject:SetActiveEx(IsShow)
    self.PanelRobot.gameObject:SetActiveEx(not IsShow)
end

function XUiGridTeacher:SetMentorInfo(data)
    local mentorData = XDataCenter.MentorSystemManager.GetMentorData()
    self.PanelMy.gameObject:SetActiveEx(mentorData:IsTeacher())
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

    XUiPlayerHead.InitPortrait(tmpData.HeadPortraitId, tmpData.HeadFrameId, headObj)
    self.PanelPlayer:GetObject("HeadOnLine").gameObject:SetActiveEx(tmpData.IsOnline)
    self.PanelPlayer:GetObject("HeadOffLine").gameObject:SetActiveEx(not tmpData.IsOnline)
    
    XUiPlayerLevel.UpdateLevel(tmpData.Level, self.PanelPlayer:GetObject("TxtLevel"))
    self.PanelPlayer:GetObject("TxtName").text = tmpData.PlayerName
    
    self.PanelPlayer:GetObject("BtnRecording").gameObject:SetActiveEx(mentorData:IsStudent())
end

function XUiGridTeacher:ShowReddot(IsShow)
    self.PanelRobot:GetObject("BtnTecherRecruit"):ShowReddot(IsShow)
end

return XUiGridTeacher