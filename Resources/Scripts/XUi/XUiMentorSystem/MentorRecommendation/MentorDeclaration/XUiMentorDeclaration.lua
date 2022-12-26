local XUiMentorDeclaration = XLuaUiManager.Register(XLuaUi, "UiMentorDeclaration")
local CSTextManagerGetText = CS.XTextManager.GetText
local XUiGridMentorLabel = require("XUi/XUiMentorSystem/MentorRecommendation/MentorDeclaration/XUiGridMentorLabel")
function XUiMentorDeclaration:OnStart()
    local NormalLabelInfos = XMentorSystemConfigs.GetManifestoTags()
    local TimeLabelInfos = XMentorSystemConfigs.GetOnlineTags()
    local textMaxCount = XMentorSystemConfigs.GetMentorSystemData("AnnouncementMaxLength")
    
    self:SetButtonCallBack()
    self:InitLabelDic()
    self:InitLabel(NormalLabelInfos, self.PanelNormalLabel, self.BtnNormalLabel, self.NormalLabelBtnList, XMentorSystemConfigs.TagType.Normal)
    self:InitLabel(TimeLabelInfos, self.PanelTimeLabel, self.BtnTimeLabel, self.TimeLabelBtnList, XMentorSystemConfigs.TagType.Time)
    self:UpdateLabelCount()
    self.InputField.placeholder.text = CSTextManagerGetText("MentorManifestoMaxText",textMaxCount)
end

function XUiMentorDeclaration:OnDestroy()
   
end

function XUiMentorDeclaration:OnEnable()
    
end

function XUiMentorDeclaration:OnDisable()
    
end

function XUiMentorDeclaration:SetButtonCallBack()
    self.BtnClose.CallBack = function()
        self:OnBtnCloseClick()
    end
    
    self.BtnFinish.CallBack = function()
        self:OnBtnFinishClick()
    end
end

function XUiMentorDeclaration:InitLabel(labelInfos, parentObj, labelObj, btnList, type)
    labelObj.gameObject:SetActiveEx(false)
    for _,info in pairs(labelInfos or {}) do
        local btn = CS.UnityEngine.Object.Instantiate(labelObj, parentObj)
        btn.gameObject:SetActiveEx(true)
        btn = XUiGridMentorLabel.New(btn, self)
        btn:SetLabelInfo(info, type)
        table.insert(btnList,btn)
    end
end

function XUiMentorDeclaration:InitLabelDic()
    local mentorData = XDataCenter.MentorSystemManager.GetMentorData()
    
    self.NormalLabelIdDic = {}
    self.TimeLabelIdDic= {}
    self.OldNormalLabelIdDic = {}
    self.OldTimeLabelIdDic= {}
    for _,id in pairs(mentorData:GetTag() or {}) do
        self.NormalLabelIdDic[id] = id
        self.OldNormalLabelIdDic[id] = id
    end
    for _,id in pairs(mentorData:GetOnlineTag() or {}) do
        self.TimeLabelIdDic[id] = id
        self.OldTimeLabelIdDic[id] = id
    end
    
    self.InputField.text = mentorData:GetAnnouncement()
    self.OldAnnouncement = mentorData:GetAnnouncement()
    self.NormalLabelBtnList = {}
    self.TimeLabelBtnList = {}
end

function XUiMentorDeclaration:CheckDifferent()
    local IsDifferent = self.InputField.text ~= self.OldAnnouncement
    
    IsDifferent = IsDifferent or (#self.OldNormalLabelIdDic ~= #self.NormalLabelIdDic)
    IsDifferent = IsDifferent or (#self.OldNormalLabelIdDic ~= #self.NormalLabelIdDic)
    
    for key,lable in pairs(self.OldNormalLabelIdDic) do
        if lable ~= self.NormalLabelIdDic[key] then
            IsDifferent = true
            break
        end
    end
    
    for key,lable in pairs(self.OldTimeLabelIdDic) do
        if lable ~= self.TimeLabelIdDic[key] then
            IsDifferent = true
            break
        end
    end
    return IsDifferent
end

function XUiMentorDeclaration:CheckLabelIdInList(id, type)
    if type == XMentorSystemConfigs.TagType.Normal then
        return self.NormalLabelIdDic[id] and true or false
    elseif type == XMentorSystemConfigs.TagType.Time then
        return self.TimeLabelIdDic[id] and true or false
    end
    return false
end

function XUiMentorDeclaration:AddLabelId(id, type)
    if type == XMentorSystemConfigs.TagType.Normal then
        self.NormalLabelIdDic[id] = id
    elseif type == XMentorSystemConfigs.TagType.Time then
        self.TimeLabelIdDic[id] = id
    end
end

function XUiMentorDeclaration:RemoveLabelId(id, type)
    if type == XMentorSystemConfigs.TagType.Normal then
        self.NormalLabelIdDic[id] = self.NormalLabelIdDic[id] and nil
    elseif type == XMentorSystemConfigs.TagType.Time then
        self.TimeLabelIdDic[id] = self.TimeLabelIdDic[id] and nil
    end
end

function XUiMentorDeclaration:CheckLabelCount(type)
    if type == XMentorSystemConfigs.TagType.Normal then
        return self:GetLabelCount(self.NormalLabelIdDic) < XMentorSystemConfigs.GetMentorSystemData("NormalLabelMaxCount")
    elseif type == XMentorSystemConfigs.TagType.Time then
        return self:GetLabelCount(self.TimeLabelIdDic) < XMentorSystemConfigs.GetMentorSystemData("TimeLabelMaxCount")
    end
end

function XUiMentorDeclaration:UpdateLabelCount()
    self.NormalLabelText.text = string.format("%d/%d", self:GetLabelCount(self.NormalLabelIdDic), XMentorSystemConfigs.GetMentorSystemData("NormalLabelMaxCount"))
    self.TimeLabelText.text = string.format("%d/%d", self:GetLabelCount(self.TimeLabelIdDic), XMentorSystemConfigs.GetMentorSystemData("TimeLabelMaxCount"))
end

function XUiMentorDeclaration:GetLabelCount(idList)
    local count = 0
    for _,_ in pairs(idList or {}) do
        count = count + 1
    end
    return count
end

function XUiMentorDeclaration:GetLabelList(dic)
    local list = {}
    for _,id in pairs(dic or {}) do
        table.insert(list,id)
    end
    return list
end

function XUiMentorDeclaration:OnBtnCloseClick()
    if self:CheckDifferent() then
        self:TipDialog(nil,function ()
                self:Close()
            end,"MentorDoCancelDeclarationHint")
    else
        self:Close()
    end
end

function XUiMentorDeclaration:OnBtnFinishClick()
    local mentorData = XDataCenter.MentorSystemManager.GetMentorData()
    if not mentorData:IsCanDoApply(true) then
        return
    end
    local normalTag = self:GetLabelList(self.NormalLabelIdDic)
    local timeTag = self:GetLabelList(self.TimeLabelIdDic)
    local manifestoText = self.InputField.text
    if string.IsNilOrEmpty(manifestoText) then
        XUiManager.TipText("MentorEmptyManifestoHint")
        return
    end
    XDataCenter.MentorSystemManager.PublishAnnouncementRequest(normalTag, timeTag, manifestoText, function ()
            self:Close()
            XUiManager.TipText("MentorFinishManifestoText")
        end)
end

function XUiMentorDeclaration:TipDialog(cancelCb, confirmCb,TextKey)
    CsXUiManager.Instance:Open("UiDialog", CSTextManagerGetText("TipTitle"), CSTextManagerGetText(TextKey),
        XUiManager.DialogType.Normal, cancelCb, confirmCb)
end