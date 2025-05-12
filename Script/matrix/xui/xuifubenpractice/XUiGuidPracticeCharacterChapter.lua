local XUiGuidPracticeCharacterChapter = XClass(nil,"XUiGuidPracticeCharacterChapter")

function XUiGuidPracticeCharacterChapter:Ctor(rootUi, ui, parent)
    self.RootUi = rootUi
    self.Parent = parent
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
    self:AddBtnsListeners()

    local XUiTextScrolling = require("XUi/XUiTaikoMaster/XUiTaikoMasterFlowText")
    ---@type XUiTaikoMasterFlowText
    self.NameTextScrolling = XUiTextScrolling.New(self.TxtFightNameNor ,self.TxtNameMaskNor)
    self.NameTextScrolling:Stop()
    ---@type XUiTaikoMasterFlowText
    self.NameLockTextScrolling = XUiTextScrolling.New(self.TxtFightNameLock ,self.TxtNameMaskLock)
    self.NameLockTextScrolling:Stop()
end

function XUiGuidPracticeCharacterChapter:AddBtnsListeners()
    XUiHelper.RegisterClickEvent(self, self.BtnStage, self.OnBtnStageClick)
end

function XUiGuidPracticeCharacterChapter:UpdateNodeScroll()
    self.NameTextScrolling:Stop()
    self.NameLockTextScrolling:Stop()
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
    self.NameTextScrolling:Stop()
    self.NameTextScrolling:Play()
end

function XUiGuidPracticeCharacterChapter:SetLockStage(isLock, groupId)
    self.PanelStageLock.gameObject:SetActive(isLock)
    if isLock then
        self.TxtFightNameLock.text = XPracticeConfigs.GetPracticeGroupName(groupId)
        self.RImgFightActiveLock:SetRawImage(XPracticeConfigs.GetPracticeGroupIcon(groupId))
    end
    self.NameLockTextScrolling:Stop()
    self.NameLockTextScrolling:Play()
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
        
        local skipId = XPracticeConfigs.GetPracticeSkipIdByGroupId(self.GroupId)

        if XTool.IsNumberValid(skipId) then
            if XFunctionManager.IsCanSkip(skipId) then
                XFunctionManager.SkipInterface(skipId)
            else
                local skipCfg = XFunctionConfig.GetSkipFuncCfg(skipId)
                if skipCfg and XTool.IsNumberValid(skipCfg.FunctionalId) then
                    local desc = XFunctionManager.GetFunctionOpenCondition(skipCfg.FunctionalId)
                    XUiManager.TipMsg(desc)
                end
            end
        else
            self.RootUi:OpenStageDetail(self.GroupId)
        end

    end
end

return XUiGuidPracticeCharacterChapter