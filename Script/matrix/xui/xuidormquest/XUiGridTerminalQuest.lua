---@class XUiGridTerminalQuest
local XUiGridTerminalQuest = XClass(nil, "XUiGridTerminalQuest")

function XUiGridTerminalQuest:Ctor(ui, rootUi, clickCb, isSpecialQuest)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.ClickCb = clickCb
    self.IsSpecialQuest = isSpecialQuest
    XTool.InitUiObject(self)
    XUiHelper.RegisterClickEvent(self, self.BtnStage, self.OnBtnStageClick)
end

---@param questData XDormQuestInfo
function XUiGridTerminalQuest:Refresh(questData, isUnlock)
    local isEmpty = XTool.IsTableEmpty(questData)
    self:SwitchQuestState(isEmpty, isUnlock)
    if isEmpty or not isUnlock then
        return
    end
    
    self.QuestId = questData:GetQuestId()
    self.Index = questData:GetIndex()
    self.IsAccept = XDataCenter.DormQuestManager.CheckQuestAccept(self.QuestId, self.Index, questData:GetResetCount())
    ---@type XDormQuest
    self.DormQuestViewModel = XDataCenter.DormQuestManager.GetDormQuestViewModel(self.QuestId)
    self:UpdateQuestCommonData()
    self:UpdateSpecialData()
end

function XUiGridTerminalQuest:SwitchQuestState(isEmpty, isUnlock)
    if self.IsSpecialQuest then
        self.TerminalSsUnopen.gameObject:SetActiveEx(not isUnlock)
        self.TerminalSsNotQuest.gameObject:SetActiveEx(isEmpty)
        self.TerminalSsFile.gameObject:SetActiveEx(false)
        self.TerminalSsAccepted.gameObject:SetActiveEx(false)
    else
        if isUnlock then
            self.RImgTerminalNotQuest.gameObject:SetActiveEx(isEmpty)
            self.RImgTerminalUpgrade.gameObject:SetActiveEx(false)
        else
            self.RImgTerminalNotQuest.gameObject:SetActiveEx(not isEmpty)
            self.RImgTerminalUpgrade.gameObject:SetActiveEx(isEmpty)
        end
        self.ImgTerminal.gameObject:SetActiveEx(false)
        self.RImgTerminalAccepted.gameObject:SetActiveEx(false)
    end
end

-- 设置公共信息
function XUiGridTerminalQuest:UpdateQuestCommonData()
    self.TxtName.text = self.DormQuestViewModel:GetQuestName()
    local typeIcon = XDormQuestConfigs.GetQuestTypeIconById(self.DormQuestViewModel:GetQuestType())
    self.RImgType:SetRawImage(typeIcon)
    local announcerIcon = XDormQuestConfigs.GetQuestAnnouncerIconById(self.DormQuestViewModel:GetQuestAnnouncer())
    self.RImgAnnouncer:SetRawImage(announcerIcon)
end

function XUiGridTerminalQuest:UpdateSpecialData()
    local qualityIcon = XDormQuestConfigs.GetQuestQualityIconById(self.DormQuestViewModel:GetQuestQuality())
    if self.IsSpecialQuest then
        self.TerminalSsFile.gameObject:SetActiveEx(not self.IsAccept)
        self.TerminalSsAccepted.gameObject:SetActiveEx(self.IsAccept)
        self.TxtRank.text = XDormQuestConfigs.GetQuestQualityNameById(self.DormQuestViewModel:GetQuestQuality())
    else
        self.ImgTerminal.gameObject:SetActiveEx(not self.IsAccept)
        self.RImgTerminalAccepted.gameObject:SetActiveEx(self.IsAccept)
        self.ImgTerminal:SetSprite(qualityIcon)
    end 
end

-- 选择
function XUiGridTerminalQuest:SetQuestSelect(isSelect)
    self.ImgSelect.gameObject:SetActiveEx(isSelect)
end

function XUiGridTerminalQuest:OnBtnStageClick()
    if not XTool.IsNumberValid(self.QuestId) then
        return
    end
    if self.IsAccept then
        return
    end
    if self.ClickCb then
        self.ClickCb(self)
    end
end

return XUiGridTerminalQuest