local XUiStageItem = XClass(nil, "XUiStageItem")

local XUiPanelStars = require("XUi/XUiFubenMainLineChapter/XUiPanelStars")

function XUiStageItem:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
end
 
function XUiStageItem:SetNormalStage(stageId, stagePrefix, stageName)
    self.PanelStageNormal.gameObject:SetActiveEx(not self.IsLock)

    self.TxtStageTitle.text = string.format("%02d", self.Index)
    -- SetLockStage
    self.PanelStageLock.gameObject:SetActiveEx(self.IsLock)
    self:SetPassStage()
    self:SetNodeSelect(false)
end

function XUiStageItem:SetPassStage()
    --XDataCenter.FubenManager.CheckStageIsPass(self.StageId)
    local useList = XDataCenter.FubenCoupleCombatManager.GetStageUsedRobot(self.StageId)
    if useList and next(useList) then
        self.PanelHead.gameObject:SetActiveEx(true)
        self.PanelStagePass.gameObject:SetActiveEx(true)
        for i, v in ipairs(useList) do
            self["RImgHead"..i]:SetRawImage(XDataCenter.CharacterManager.GetDefaultCharSmallHeadIcon(XRobotManager.GetCharacterId(v)))
        end
    else
        self.PanelHead.gameObject:SetActiveEx(false)
        self.PanelStagePass.gameObject:SetActiveEx(false)
    end
end

function XUiStageItem:UpdateNode(stageId, index, stageType)
    self.StageId = stageId
    self.Index = index
    --self.StageType = stageType
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.StageId)
    local actCfg = XDataCenter.FubenCoupleCombatManager.GetCurrentActTemplate()

    local isOpen = stageInfo.IsOpen
    self.GameObject:SetActiveEx(isOpen)
    local gridGo = self.Transform:LoadPrefab(actCfg.GridPrefab)
    local uiObj = gridGo.transform:GetComponent("UiObject")
    for i = 0, uiObj.NameList.Count - 1 do
        self[uiObj.NameList[i]] = uiObj.ObjList[i]
    end
    self.RImgNormalBg:SetRawImage(actCfg.StageGridBg[stageType])
    self.BtnStage.CallBack = function() self:OnBtnStageClick() end

    self.IsLock = not stageInfo.Unlock
    --local stagePrefix = XDataCenter.FubenManager.GetStageName(stageId)
    --local stageName = XDataCenter.FubenManager.GetStageDes(stageId)
    self:SetNormalStage(self.StageId)
    --self.IsPass = stageInfo.Passed
    --self.PanelStagePass.gameObject:SetActiveEx(self.IsPass)

    --self.PanelStarMap = self.PanelStarMap or XUiPanelStars.New(self.PanelStars)
    --self.PanelStars.gameObject:SetActiveEx(stageType == XFubenSimulatedCombatConfig.StageType.Hard)
    --local starsMap = XDataCenter.FubenSimulatedCombatManager.GetPlainStarMap(self.StageId)
    --self.PanelStarMap:OnEnable(starsMap)
end

function XUiStageItem:OnBtnStageClick()
    if not self.StageId then return end
    if not self.IsLock then
        self.RootUi:UpdateNodesSelect(self.StageId)
        -- 打开详细界面
        self.RootUi:OpenStageDetails(self.StageId)
        self.RootUi:PlayScrollViewMove(self.Transform)
    else
        -- 是否达到时间
        local isInOpenTime, desc = XDataCenter.FubenCoupleCombatManager.CheckStageOpen(self.StageId, true)
        if isInOpenTime then
            desc = CS.XTextManager.GetText("FubenPreStageNotPass")
        end
        XUiManager.TipMsg(desc)
    end
end

function XUiStageItem:SetNodeSelect(isSelect)
    if not self.IsLock then
        self.ImageSelected.gameObject:SetActiveEx(isSelect)
    end
end

function XUiStageItem:ResetItemPosition(pos)
    if self.ImgHideLine then
        local rect = self.ImgHideLine:GetComponent("RectTransform").rect
        self.Transform.localPosition = CS.UnityEngine.Vector3(pos.x, pos.y - rect.height, pos.z)
    end
end

return XUiStageItem