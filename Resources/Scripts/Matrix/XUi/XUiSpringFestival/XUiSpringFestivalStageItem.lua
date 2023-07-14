local XUiSpringFestivalStageItem = XClass(nil, "XUiSpringFestivalStageItem")

function XUiSpringFestivalStageItem:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
end

function XUiSpringFestivalStageItem:SetNormalStage()

    if self.IsLock then
        self.BtnStage:SetButtonState(CS.UiButtonState.Disable)
    else
        self.BtnStage:SetButtonState(CS.UiButtonState.Normal)
        self.BtnStage:SetRawImage(self.FStage:GetIcon())
    end
    self.BtnStage:SetName(self.FStage:GetOrderName())
end


function XUiSpringFestivalStageItem:SetPassStage()
    self.ImgFubenEnd.gameObject:SetActiveEx(self.FStage:GetIsPass())
end

function XUiSpringFestivalStageItem:UpdateNode(festivalId, stageId)
    local fStage = XDataCenter.FubenFestivalActivityManager.GetFestivalStageByFestivalIdAndStageId(festivalId, stageId)
    if not fStage then return end
    self.FestivalId = festivalId
    self.StageId = stageId
    self.FStage = fStage
    self.FChapter = fStage:GetChapter()
    self.StageIndex = fStage:GetOrderIndex()
    local stagePrefabName = fStage:GetStagePrefab()
    local isOpen, description = self.FStage:GetCanOpen()
    self.GameObject:SetActiveEx(isOpen)
    local gridGameObject = self.Transform:LoadPrefab(stagePrefabName)
    local uiObj = gridGameObject.transform:GetComponent("UiObject")
    for i = 0, uiObj.NameList.Count - 1 do
        self[uiObj.NameList[i]] = uiObj.ObjList[i]
    end
    self.BtnStage.CallBack = function() self:OnBtnStageClick() end
    self.IsLock = not isOpen
    self.Description = description
    self:SetNormalStage()
    self:SetPassStage()
end

function XUiSpringFestivalStageItem:OnBtnStageClick()
    if self.FStage then
        if not self.IsLock then
            self.RootUi:UpdateNodesSelect(self.StageId)
            -- 打开详细界面
            self.RootUi:OpenStageDetails(self.StageId, self.FestivalId)
            self.RootUi:PlayScrollViewMove(self.Transform)
        else
            XUiManager.TipMsg(self.Description)
        end

    end
end

function XUiSpringFestivalStageItem:SetNodeSelect(isSelect)
    if not self.IsLock then
        self.BtnStage:SetButtonState(isSelect and CS.UiButtonState.Select or CS.UiButtonState.Normal)
    end
end

return XUiSpringFestivalStageItem