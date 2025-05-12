local XUiNewCharStageItem = XClass(nil, "XUiNewCharStageItem")

local XUiPanelStars = require("XUi/XUiFubenMainLineChapter/XUiPanelStars")

function XUiNewCharStageItem:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
end

function XUiNewCharStageItem:SetNormalStage(stageId, stagePrefix, stageName)
    self.PanelStageNormal.gameObject:SetActiveEx(not self.IsLock)
    if not self.IsLock then
        local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
        self.RImgFightActiveNor:SetRawImage(stageCfg.Icon)
    end
    
    self.TxtStageTitle.text = stageName
    self.TxtStagePrefix.text = stagePrefix
    -- SetLockStage
    self.PanelStageLock.gameObject:SetActiveEx(self.IsLock)
end

function XUiNewCharStageItem:UpdateNode(actId, stageId, stageIndex)
    local chapterTemplate = XFubenNewCharConfig.GetDataById(actId, stageIndex)
    self.ActId = actId
    self.StageId = stageId
    self.StageIndex = stageIndex
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.StageId)
    local stagePrefabName = chapterTemplate.GridFubenPrefab

    local isOpen, description = XDataCenter.FubenNewCharActivityManager.CheckStageOpen(stageId), CS.XTextManager.GetText("FubenPreStageNotPass")
    -- self.GameObject:SetActiveEx(isOpen)
    local gridGo = self.Transform:LoadPrefab(stagePrefabName)
    local uiObj = gridGo.transform:GetComponent("UiObject")
    for i = 0, uiObj.NameList.Count - 1 do
        self[uiObj.NameList[i]] = uiObj.ObjList[i]
    end
    self.BtnStage.CallBack = function() self:OnBtnStageClick() end

    self.IsLock = not isOpen
    self.Description = description
    local stagePrefix = XDataCenter.FubenManager.GetStageName(chapterTemplate.StageId[self.StageIndex])
    local stageName = XDataCenter.FubenManager.GetStageDes(chapterTemplate.StageId[self.StageIndex])
    self:SetNormalStage(self.StageId, stagePrefix, stageName)
    self.PanelStagePass.gameObject:SetActiveEx(XDataCenter.FubenNewCharActivityManager.CheckStagePass(stageId))

    self.PanelStars = XUiPanelStars.New(self.PanelStar)
    local starsMap = XDataCenter.FubenNewCharActivityManager.GetStarMap(self.StageId)
    self.PanelStars:OnEnable(starsMap)
end

function XUiNewCharStageItem:OnBtnStageClick()
    if self.StageId and self.ActId then
        if not self.IsLock then
            self.RootUi:UpdateNodesSelect(self.StageId)
            -- 打开详细界面
            self.RootUi:OpenStageDetails(self.StageId, self.ActId)
            self.RootUi:PlayScrollViewMove(self.Transform)
        else
            XUiManager.TipMsg(self.Description)
        end

    end
end

function XUiNewCharStageItem:SetNodeSelect(isSelect)
    if not self.IsLock then
        self.ImageSelected.gameObject:SetActiveEx(isSelect)
    end
end

function XUiNewCharStageItem:ResetItemPosition(pos)
    if self.ImgHideLine then
        local rect = self.ImgHideLine:GetComponent("RectTransform").rect
        self.Transform.localPosition = CS.UnityEngine.Vector3(pos.x, pos.y - rect.height, pos.z)
    end
end

return XUiNewCharStageItem