local XUiGridGotManifesto = XClass(nil, "XUiGridGotManifesto")
local CSTextManagerGetText = CS.XTextManager.GetText

function XUiGridGotManifesto:Ctor(ui)
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

function XUiGridGotManifesto:SetButtonCallBack()
    self.BtnTcanchaungEnter.CallBack = function()
        self:OnBtnTcanchaungEnterClick()
    end
    self.BtnTcanchaungCancel.CallBack = function()
        self:OnBtnTcanchaungCancelClick()
    end
    self.BtnHead.CallBack = function()
        self:OnBtnHeadClick()
    end
end

function XUiGridGotManifesto:OnBtnTcanchaungEnterClick()
    local mentorData = XDataCenter.MentorSystemManager.GetMentorData()
    if not mentorData:IsCanDoApply(true) then
        return
    end
    XDataCenter.MentorSystemManager.OperationApplyMentorRequest({self.Data.PlayerId}, true, false, function ()
            self.Base:UpdatePanel()
        end)
end

function XUiGridGotManifesto:OnBtnTcanchaungCancelClick()
    XDataCenter.MentorSystemManager.OperationApplyMentorRequest({self.Data.PlayerId}, false, false, function ()
            self.Base:UpdatePanel()
        end)
end

function XUiGridGotManifesto:OnBtnHeadClick()
    XDataCenter.PersonalInfoManager.ReqShowInfoPanel(self.Data.PlayerId)
end

function XUiGridGotManifesto:UpdateGrid(data, base)
    self.Data = data
    self.Base = base
    if data then
        self:InitTags(self.TagObjs)
        self:InitTags(self.TimeTagObjs)
        self:SetManifestoInfo(data)
    end
end

function XUiGridGotManifesto:SetManifestoInfo(data)
    local mentorData = XDataCenter.MentorSystemManager.GetMentorData()
    if mentorData:IsTeacher() then
        self.IconMember.gameObject:SetActiveEx(false)
    else
        local maxStudentCount = XMentorSystemConfigs.GetMentorSystemData("MaxStudentCount")
        self.TextMemberNum.text = string.format("%d/%d",data.StudentCount,maxStudentCount)
        self.IconMember.gameObject:SetActiveEx(true)
    end

    self.TxtName.text = data.PlayerName
    self.ManifestoTxt.text = data.Announcement
    XUiPlayerLevel.UpdateLevel(data.Level, self.TxtLevel)
    XUiPLayerHead.InitPortrait(data.HeadPortraitId, data.HeadFrameId, self.Head)
    self:SetTagList(self.TagObjs, data.Tag, XMentorSystemConfigs.TagType.Normal)
    self:SetTagList(self.TimeTagObjs, data.OnlineTag, XMentorSystemConfigs.TagType.Time)
end

function XUiGridGotManifesto:InitTags(objs)
    for _,obj in pairs(objs or {}) do
        obj.gameObject:SetActiveEx(false)
    end
end

function XUiGridGotManifesto:SetTagList(objs, tags, type)
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

return XUiGridGotManifesto