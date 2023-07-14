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
    if self.Data.IconPath then
        --local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageId)
        self.RImgFightActiveNor:SetRawImage(self.Data.IconPath)
        self.RImgFightActiveLock:SetRawImage(self.Data.IconPath)
    end

    --self.TxtStageTitle.text = stageName
    --self.TxtStagePrefix.text = stagePrefix
    self.TxtStageOrder.text = stagePrefix..stageName
    -- SetLockStage
    self.PanelStageLock.gameObject:SetActiveEx(self.IsLock)
    --self.PanelChallenging.gameObject:SetActiveEx(false)
end

function XUiStageItem:SetChallengingStage(value)
    local isChallenging = value and not self.IsPass
    self.PanelChallenging.gameObject:SetActiveEx(isChallenging)
end

function XUiStageItem:SetPassStage()
    self.PanelStagePass.gameObject:SetActiveEx(XDataCenter.FubenManager.CheckStageIsPass(stageId))
end

function XUiStageItem:UpdateNode(data)
    self.StageId = data.StageId
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.StageId)
    self.Data = data
    local stagePrefabName = data.PrefabPath

    local isOpen, description = stageInfo.IsOpen, CS.XTextManager.GetText("FubenPreStageNotPass")
    self.GameObject:SetActiveEx(isOpen)
    local gridGo = self.Transform:LoadPrefab(stagePrefabName)
    local uiObj = gridGo.transform:GetComponent("UiObject")
    for i = 0, uiObj.NameList.Count - 1 do
        self[uiObj.NameList[i]] = uiObj.ObjList[i]
    end
    self.BtnStage.CallBack = function() self:OnBtnStageClick() end

    self.IsLock = not stageInfo.Unlock
    self.Description = description
    local stagePrefix = XDataCenter.FubenManager.GetStageName(data.StageId)
    local stageName = XDataCenter.FubenManager.GetStageDes(data.StageId)
    self:SetNormalStage(self.StageId, stagePrefix or "", stageName or "")
    self.IsPass = stageInfo.Passed
    self.PanelStagePass.gameObject:SetActiveEx(self.IsPass)

    self.PanelStarMap = self.PanelStarMap or XUiPanelStars.New(self.PanelStars)
    self.PanelStars.gameObject:SetActiveEx(data.Type == XFubenSimulatedCombatConfig.StageType.Challenge)
    local starsMap = XDataCenter.FubenSimulatedCombatManager.GetPlainStarMap(self.StageId)
    self.PanelStarMap:OnEnable(starsMap)
end

function XUiStageItem:OnBtnStageClick()
    if self.StageId then
        if not self.IsLock then
            self.RootUi:UpdateNodesSelect(self.StageId)
            -- 打开详细界面
            self.RootUi:OpenStageDetails(self.Data.Id)
            self.RootUi:PlayScrollViewMove(self.Transform)
        else
            XUiManager.TipMsg(self.Description)
        end

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