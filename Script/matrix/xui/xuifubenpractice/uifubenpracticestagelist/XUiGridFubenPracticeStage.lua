local XUiGridFubenPracticeStage = XClass(XUiNode, "XUiGridFubenPracticeStage")

function XUiGridFubenPracticeStage:UpdateNode(id, stageId, stageIndex)
    self.Id = id
    self.StageId = stageId
    self.StageIndex = stageIndex
    self.Template = XFubenNewCharConfig.GetDataById(self.Id, self.StageIndex)

    self.StagePrefabName = self.Template.GridFubenPrefab

    self.IsOpen, self.Des = true, CS.XTextManager.GetText("FubenPreStageNotPass")
    local gridGo = self.Transform:LoadPrefab(self.StagePrefabName)
    local uiObject = gridGo.transform:GetComponent("UiObject")
    for i = 0, uiObject.NameList.Count - 1 do
        self[uiObject.NameList[i]] = uiObject.ObjList[i]
    end
    self.BtnStage.CallBack = function()
        self:OnBtnStageClick()
    end

    self.IsLock = not self.IsOpen
    self.StagePrefix = XDataCenter.FubenManager.GetStageName(self.StageId)
    self.StageName = XDataCenter.FubenManager.GetStageDes(self.StageId)
    self:SetNormalStage()
    if not self.PanelStagePass then
        self.PanelStagePass = gridGo.transform:Find("ChristmasStageParent/PanelStagePass")
    end

    if self.PanelStagePass then
        self.PanelStagePass.gameObject:SetActiveEx(XDataCenter.FubenNewCharActivityManager.CheckStagePass(stageId))
    end
end

function XUiGridFubenPracticeStage:SetNormalStage()
    self.PanelStageNormal.gameObject:SetActiveEx(self.IsOpen)
    if self.IsOpen then
        self.StageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageId)
        self.RImgFightActiveNor:SetRawImage(self.StageCfg.Icon)
    end

    if self.TxtStageTitle then
        self.TxtStageTitle.text = self.StageName
    end

    if self.TxtStagePrefix then 
        self.TxtStagePrefix.text = self.StagePrefix
    end
    if self.PanelStageLock then
        self.PanelStageLock.gameObject:SetActiveEx(self.IsLock)
    end
end

function XUiGridFubenPracticeStage:OnBtnStageClick()
    if self.StageId and self.Id then
        if self.IsOpen then
            self.Parent:UpdateNodesSelect(self.StageId)
            self.Parent:OpenStageDetails(self.StageId, self.Id)
            self.Parent:PlayScrollViewMove(self.Transform)
        else
            XUiManager.TipMsg(self.Description)
        end
    end
end

--显示选中框
function XUiGridFubenPracticeStage:SetNodeSelect(isSelect)
    if self.IsOpen then
        self.ImageSelected.gameObject:SetActiveEx(isSelect)
    end
end

return XUiGridFubenPracticeStage