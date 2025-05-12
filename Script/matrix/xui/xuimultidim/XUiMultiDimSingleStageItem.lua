local XUiMultiDimSingleStageItem = XClass(nil, "XUiMultiDimSingleStageItem")

function XUiMultiDimSingleStageItem:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
end

function XUiMultiDimSingleStageItem:SetNormalStage()
    self.PanelStageNormal.gameObject:SetActiveEx(not self.IsLock)
    if not self.IsLock then
        self.RImgFightActiveNor:SetRawImage(self.StageCfg.Icon)
    end
    self.TxtStageOrder.text = self.ThemeDataCfg.StagePrefix..self.OrderIndex
    -- SetLockStage
    self.PanelStageLock.gameObject:SetActiveEx(self.IsLock)
end

function XUiMultiDimSingleStageItem:SetStars()
    local stars = self.StageInfo.Stars
    for i = 1, 3 do
        local isShow = i <= stars
        local img = self["Star"..i]:Find("Img" .. i)
        local imgDis = self["Star"..i]:Find("ImgDis" .. i)
        img.gameObject:SetActive(isShow)
        imgDis.gameObject:SetActive(not isShow)
    end
end

function XUiMultiDimSingleStageItem:SetPassStage()
    self.PanelStagePass.gameObject:SetActiveEx(self.StageInfo.Passed)
end

function XUiMultiDimSingleStageItem:UpdateNode(themeId, stageId, orderIndex)
    local mStage = XMultiDimConfig.GetMultiSingleStageDataById(stageId)
    if not mStage then return end
    self.ThemeId = themeId
    self.StageId = stageId
    self.MStage = mStage
    self.StageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
    self.StageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
    self.ThemeDataCfg = XDataCenter.MultiDimManager.GetMultiDimThemeData(themeId)
    self.OrderIndex = orderIndex
    -- self.FChapter = mStage:GetChapter()
    -- self.StageIndex = mStage:GetOrderIndex()
    local stagePrefabName = self.ThemeDataCfg.GridFubenSinglePrefab
    -- local isOpen, description = self.MStage:GetCanOpen()
    local isOpen = self.StageInfo.IsOpen 
    self.GameObject:SetActiveEx(isOpen)
    local gridGameObject = self.Transform:LoadPrefab(stagePrefabName)
    local uiObj = gridGameObject.transform:GetComponent("UiObject")
    for i = 0, uiObj.NameList.Count - 1 do
        self[uiObj.NameList[i]] = uiObj.ObjList[i]
    end
    self.BtnStage.CallBack = function() self:OnBtnStageClick() end
    self.IsLock = not isOpen or not XFunctionManager.CheckInTimeByTimeId(self.MStage.OpenTimeId)
    -- self.Description = description
    self:SetNormalStage()
    self:SetPassStage()
    self:SetStars()
    -- local isEgg = self.StageCfg.StageType and ((self.StageCfg.StageType == XFubenConfigs.STAGETYPE_STORYEGG) or (self.StageCfg.StageType == XFubenConfigs.STAGETYPE_FIGHTEGG))
    -- self.ImgStageOrder.gameObject:SetActiveEx(not isEgg)
    -- self.ImgStageHide.gameObject:SetActiveEx(isEgg)
    -- if self.ImgHideLine then
    --     self.ImgHideLine.gameObject:SetActiveEx(isEgg)
    -- end
end

function XUiMultiDimSingleStageItem:OnBtnStageClick()
    if self.MStage then
        self.RootUi:UpdateNodesSelect(self.StageId)
        -- 打开详细界面
        self.RootUi:OpenStageDetails(self.StageId, self.ThemeId)
        self.RootUi:PlayScrollViewMove(self.Transform)
    end
end

function XUiMultiDimSingleStageItem:SetNodeSelect(isSelect)
    if not self.IsLock then
        self.ImageSelected.gameObject:SetActiveEx(isSelect)
    end
end

function XUiMultiDimSingleStageItem:ResetItemPosition(pos)
    if self.ImgHideLine then
        local rect = self.ImgHideLine:GetComponent("RectTransform").rect
        self.Transform.localPosition = CS.UnityEngine.Vector3(pos.x, pos.y - rect.height, pos.z)
    end
end

return XUiMultiDimSingleStageItem