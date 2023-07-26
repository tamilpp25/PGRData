local XUiGridManifesto = XClass(nil, "XUiGridManifesto")
local CSTextManagerGetText = CS.XTextManager.GetText

function XUiGridManifesto:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    
    XTool.InitUiObject(self)

    self:SetButtonCallBack()

    self.TagObjs = {
        self.Label1,
        self.Label2,
    }
    self.TimeTagObjs = {
        self.Label3,
    }
end

function XUiGridManifesto:SetButtonCallBack()
    self.BtnRecycleConfirm.CallBack = function()
        self:OnBtnRecycleConfirmClick()
    end
    self.HearStudent:GetObject("BtnHead").CallBack = function()
        self:OnBtnHeadClick()
    end
    self.HearMentor:GetObject("BtnHead").CallBack = function()
        self:OnBtnHeadClick()
    end
end

function XUiGridManifesto:OnBtnRecycleConfirmClick()
    local mentorData = XDataCenter.MentorSystemManager.GetMentorData()
    if not mentorData:IsCanDoApply(true) then
        return
    end
    if self.IsApplyed then return end
    XDataCenter.MentorSystemManager.ApplyMentorRequest({self.Data.PlayerId}, function ()
            self.Base:UpdatePanel()--self:SetManifestoInfo(self.Data)
    end)
end

function XUiGridManifesto:OnBtnHeadClick()
    XDataCenter.PersonalInfoManager.ReqShowInfoPanel(self.Data.PlayerId)
end

function XUiGridManifesto:UpdateGrid(data, base)
    self.Data = data
    self.Base = base
    if data then
        self:InitTags(self.TagObjs)
        self:InitTags(self.TimeTagObjs)
        self:SetManifestoInfo(data)
    end
end

function XUiGridManifesto:SetManifestoInfo(data)
    local mentorData = XDataCenter.MentorSystemManager.GetMentorData()
    self.HearMentor.gameObject:SetActiveEx(mentorData:IsStudent())
    self.HearStudent.gameObject:SetActiveEx(mentorData:IsTeacher())

    if mentorData:IsTeacher() then
        XUiPLayerHead.InitPortrait(data.HeadPortraitId, data.HeadFrameId, self.HearStudent:GetObject("Head"))
    else
        local maxStudentCount = XMentorSystemConfigs.GetMentorSystemData("MaxStudentCount")
        XUiPLayerHead.InitPortrait(data.HeadPortraitId, data.HeadFrameId, self.HearMentor:GetObject("Head"))
        self.HearMentor:GetObject("TextMemberNum").text = string.format("%d/%d",data.StudentCount,maxStudentCount)
    end

    self.TextName.text = data.PlayerName
    self.ManifestoTxt.text = data.Announcement
    XUiPlayerLevel.UpdateLevel(data.Level, self.TxtLevel)
    
    self:SetTagList(self.TagObjs, data.Tag, XMentorSystemConfigs.TagType.Normal)
    self:SetTagList(self.TimeTagObjs, data.OnlineTag, XMentorSystemConfigs.TagType.Time)
    
    self.IsApplyed = XDataCenter.MentorSystemManager.IsApplyed(data.PlayerId)
    self.BtnRecycleConfirm:SetName(self.IsApplyed and CSTextManagerGetText("MentorShipApplyedText") or CSTextManagerGetText("MentorShipNotApplyedText"))
    self.BtnRecycleConfirm:SetDisable(self.IsApplyed)
end

function XUiGridManifesto:InitTags(objs)
    for _,obj in pairs(objs or {}) do
        obj.gameObject:SetActiveEx(false)
    end
end

function XUiGridManifesto:SetTagList(objs, tags, type)
    for index,tagId in pairs(tags or {}) do
        local tagCfg
        if type == XMentorSystemConfigs.TagType.Normal then
            tagCfg = XMentorSystemConfigs.GetManifestoTagById(tagId)
        elseif type == XMentorSystemConfigs.TagType.Time then
            tagCfg = XMentorSystemConfigs.GetOnlineTagById(tagId)
        end
        
        if objs[index] then
            objs[index].gameObject:SetActiveEx(true)
            objs[index]:GetObject("Bg"):SetSprite(tagCfg.Bg)
            objs[index]:GetObject("Text").text = tagCfg.Tab
        else
            XLog.Error("Tag's Count Is OverFlow")
        end
    end
end

return XUiGridManifesto