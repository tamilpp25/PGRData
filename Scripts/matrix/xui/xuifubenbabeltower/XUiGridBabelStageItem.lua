local XUiGridBabelStageItem = XClass(nil, "XUiGridBabelStageItem")

function XUiGridBabelStageItem:Ctor(ui, uiRoot, stageId)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot
    self.StageId = stageId
    XTool.InitUiObject(self)
end

function XUiGridBabelStageItem:InitBanner()
    self.PanelLocking.gameObject:SetActiveEx(false)
    self.BtnReset.gameObject:SetActiveEx(false)
    self.BtnSkip.gameObject:SetActiveEx(false)
    self.BtnStageMask.CallBack = function() self:OnBtnStageMaskClick() end
end

function XUiGridBabelStageItem:UpdateStageInfo(stageId)
    self.StageId = stageId
    self.StageConfigs = XFubenBabelTowerConfigs.GetBabelStageConfigs(self.StageId)
    self.StageTemplate = XFubenBabelTowerConfigs.GetBabelTowerStageTemplate(self.StageId)

    if not self.GridStageChapter then
        self.GridStageChapter = self.Transform:LoadPrefab(self.StageConfigs.StagePrefab)
        local uiObj = self.GridStageChapter.transform:GetComponent("UiObject")

        for i = 0, uiObj.NameList.Count - 1 do
            self[uiObj.NameList[i]] = uiObj.ObjList[i]
        end

        self:InitBanner()
    end

    self:RefreshStageBanner()
end

function XUiGridBabelStageItem:RefreshStageBanner()
    local stageId = self.StageId

    self.FubenStageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
    self.BtnStageMask:SetNameByGroup(1, self.StageConfigs.Name)

    local curScore = XDataCenter.FubenBabelTowerManager.GetStageTotalScore(stageId)
    self.BtnStageMask:SetNameByGroup(0, curScore)

    self:RefreshStageInfo()
end

function XUiGridBabelStageItem:RefreshStageInfo()
    self.BtnStageMask:SetRawImage(self.FubenStageCfg.Icon)

    local isUnlock = XDataCenter.FubenBabelTowerManager.IsBabelStageUnlock(self.StageId)
    self.PanelStageOrder.gameObject:SetActiveEx(isUnlock)
    self.ImgStageNormal.gameObject:SetActiveEx(isUnlock)
    self.ImgStageLock.gameObject:SetActiveEx(not isUnlock)
    self.BtnStageMask:SetDisable(not isUnlock, isUnlock)

    local isPassed = XDataCenter.FubenBabelTowerManager.IsStagePassed(self.StageId)
    self.PanelNewChallenge.gameObject:SetActiveEx(isUnlock and (not isPassed))
    self.TabZx.gameObject:SetActiveEx(false)
end

function XUiGridBabelStageItem:OnBtnStageMaskClick()
    self.UiRoot:OnStageClick(self.StageId, self)
end

function XUiGridBabelStageItem:SetStageItemPress(isPress)
    self.PanelPress.gameObject:SetActiveEx(isPress)
end

return XUiGridBabelStageItem