local XUiGridMemorySave = XClass(nil, "XUiGridMemorySave")

function XUiGridMemorySave:Ctor(ui, stageId, chapterId)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.StageId = stageId
    self.ChapterId = chapterId
    self.Stage = XDataCenter.FubenManager.GetStageCfg(self.StageId)
    XTool.InitUiObject(self)
end

function XUiGridMemorySave:Refresh(data)
    self.StageConfig = self.StageConfig or XDataCenter.MemorySaveManager.GetChapterStageConfig(self.ChapterId)
    local gridGameObject = self.Transform:LoadPrefab(XDataCenter.MemorySaveManager.GetStagePrefabPath())
    -- 不用XTool.InitUiObjectByUi是为了直接使用self
    local uiObject = gridGameObject.transform:GetComponent("UiObject")
    for i = 0, uiObject.NameList.Count - 1 do
        self[uiObject.NameList[i]] = uiObject.ObjList[i]
    end
    local isOpen = XDataCenter.MemorySaveManager.GetStageIsOpen(self.StageId)
    self.TxtStageOrder.text = XMemorySaveConfig.GetStageShortName(self.ChapterId).."-"..data.stageIndex
    self.Passed = XDataCenter.MemorySaveManager.GetPassStageById(self.StageId)
    self.PanelStagePass.gameObject:SetActiveEx(self.Passed)
    self.PanelStageLock.gameObject:SetActiveEx(false)
    self.ImageSelected.gameObject:SetActiveEx(false)
    self.RImgBoss:SetRawImage(self.Stage.Icon)
    self.RImgFightActiveNor:SetRawImage(self.StageConfig.StageBg)
    self.ShowDetailCb = data.ShowDetailCb
    self.HideDetailCb = data.HideDetailCb
    self.UpDateSelectStageCb = data.UpDateSelectStageCb
    self.ScrollViewMoveCb = data.ScrollViewMoveCb
    self:AddListener()
    self.GameObject:SetActiveEx(isOpen)
end

function XUiGridMemorySave:AddListener()
    self.BtnStage.CallBack = function ()
        self:OnClickBtnStage()
    end
end

function XUiGridMemorySave:HideGameObject()
    self.GameObject:SetActiveEx(false)
end

function XUiGridMemorySave:SetSelected(bSelect)
    self.ImageSelected.gameObject:SetActiveEx(bSelect)
end

function XUiGridMemorySave:OnClickBtnStage()
    if self.UpDateSelectStageCb then self.UpDateSelectStageCb(self.StageId) end
    if self.ScrollViewMoveCb then self.ScrollViewMoveCb(self.Transform) end
    self:SetSelected(true)
    if self.ShowDetailCb then self.ShowDetailCb(self.Stage) end
end

return XUiGridMemorySave