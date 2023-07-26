local XUiGuidPracticeCharacterChapter = XClass(nil,"XUiGuidPracticeCharacterChapter")

function XUiGuidPracticeCharacterChapter:Ctor(rootUi, ui, parent)
    self.RootUi = rootUi
    self.Parent = parent
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
    self:AddBtnsListeners()
end

function XUiGuidPracticeCharacterChapter:AddBtnsListeners()
    XUiHelper.RegisterClickEvent(self, self.BtnStage, self.OnBtnStageClick)
end

function XUiGuidPracticeCharacterChapter:SetNormalStage(isLock, groupId)
    self.PanelStageNormal.gameObject:SetActive(not isLock)
    if not isLock then
        self.TxtFightNameNor.text = XPracticeConfigs.GetPracticeGroupName(groupId)
        self.RImgFightActiveNor:SetRawImage(XPracticeConfigs.GetPracticeGroupIcon(groupId))
    end
    if self.PanelActivityTag then
        local inActivity = XDataCenter.PracticeManager.CheckChapterInActivity(groupId)
        self.PanelActivityTag.gameObject:SetActiveEx(inActivity)
    end
end

function XUiGuidPracticeCharacterChapter:SetLockStage(isLock, groupId)
    self.PanelStageLock.gameObject:SetActive(isLock)
    if isLock then
        self.TxtFightNameLock.text = XPracticeConfigs.GetPracticeGroupName(groupId)
        self.RImgFightActiveLock:SetRawImage(XPracticeConfigs.GetPracticeGroupIcon(groupId))
    end
end

function XUiGuidPracticeCharacterChapter:SetPassStage(groupId)
    local isPass = XDataCenter.PracticeManager.CheckStageAllPass(groupId)
    self.PanelStagePass.gameObject:SetActive(isPass)
end

function XUiGuidPracticeCharacterChapter:UpdateNode(groupId)
    self.GroupId = groupId
    
    local isOpen = XDataCenter.PracticeManager.CheckPracticeChapterOpen(groupId)
    self.IsLock = not isOpen

    self:SetNormalStage(self.IsLock, groupId)
    self:SetLockStage(self.IsLock, groupId)
    self:SetPassStage(groupId)
end

function XUiGuidPracticeCharacterChapter:OnBtnStageClick()
    if not self.GroupId then return end
    if self.IsLock then
        local _, description = XDataCenter.PracticeManager.CheckPracticeChapterOpen(self.GroupId)
        XUiManager.TipMsg(description)
    else
        if self.Parent then
            self.Parent:PlayScrollViewMove(self.Transform.parent)
        end

        if self.RootUi.SetSelectStageId then
            self.RootUi:SetSelectStageId(self.GroupId)
        end

        self.RootUi:OpenStageDetail(self.GroupId)
    end
end

return XUiGuidPracticeCharacterChapter