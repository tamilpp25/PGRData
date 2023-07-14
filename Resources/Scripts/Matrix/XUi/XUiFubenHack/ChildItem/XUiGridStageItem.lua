local XUiGridStageItem = XClass(nil, "XUiGridStageItem")
local Type = {
    Locked = 1,
    First = 2,
    NotFirst = 3, -- 人物专属词缀
}

local XUiPanelStars = require("XUi/XUiFubenMainLineChapter/XUiPanelStars")

function XUiGridStageItem:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
end

function XUiGridStageItem:SetNormalStage(stageId, stageName)
    local stageInterInfo = XFubenHackConfig.GetStageInfo(stageId)
    self.PanelStageNormal.gameObject:SetActiveEx(not self.IsLock)
    if not self.IsLock then
        local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
        self.RImgNor:SetRawImage(stageCfg.Icon)
    end
    
    self.TxtStageName.text = stageInterInfo.GridName
    self.PanelStageLock.gameObject:SetActiveEx(self.IsLock)
    self.GridSecond.gameObject:SetActiveEx(false)
    self.GridFirst.gameObject:SetActiveEx(self.State == Type.First)
    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.GridFirst)

    self.GridLock.gameObject:SetActiveEx(self.State == Type.Locked)
    self.TxtNumber.text = string.format("x%d", stageInterInfo.ConsumeTicket)
    --self.TxtFirstResume.text = CS.XTextManager.GetText("FubenHackFirstResume")
    self.TxtUnlockTip.text = CS.XTextManager.GetText("FubenHackUnlockTip")
    self.RImgIcon:SetRawImage(XDataCenter.ItemManager.GetItemIcon(self.ActTemplate.ExpId))
end

function XUiGridStageItem:UpdateNode(actId, stageId, stageIndex)
    self.ActId = actId
    self.StageId = stageId
    self.StageIndex = stageIndex
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
    local actTemplate = XDataCenter.FubenHackManager.GetCurrentActTemplate()
    self.ActTemplate = actTemplate
    local isOpen, description = XDataCenter.FubenManager.CheckStageOpen(stageId), CS.XTextManager.GetText("FubenHackUnlockTip")
    self.GameObject:SetActiveEx(isOpen)
    local prefabPath
    if stageCfg.StageGridStyle == "Normal" then
        prefabPath = actTemplate.GridPrefab[1]
    elseif stageCfg.StageGridStyle == "Hard" then
        prefabPath = actTemplate.GridPrefab[2]
    end
    local gridGo = self.Transform:LoadPrefab(prefabPath)
    local uiObj = gridGo.transform:GetComponent("UiObject")
    for i = 0, uiObj.NameList.Count - 1 do
        self[uiObj.NameList[i]] = uiObj.ObjList[i]
    end
    self.BtnStage.CallBack = function() self:OnBtnStageClick() end

    self.IsLock = not XDataCenter.FubenManager.CheckStageIsUnlock(stageId)
    self.IsPass = XDataCenter.FubenManager.CheckStageIsPass(stageId)
    if self.IsLock then
        self.State = Type.Locked
    elseif self.IsPass then
        self.State = Type.NotFirst
    else
        self.State = Type.First
    end
    self.Description = description
    local stageName = XDataCenter.FubenManager.GetStageName(stageId)
    self:SetNormalStage(self.StageId, stageName)
    self.PanelStagePass.gameObject:SetActiveEx(self.IsPass)

    self.PanelStars = XUiPanelStars.New(self.PanelStar)
    local starsMap = XDataCenter.FubenHackManager.GetStarMap(self.StageId)
    self.PanelStars:OnEnable(starsMap)
end

function XUiGridStageItem:OnBtnStageClick()
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

function XUiGridStageItem:SetNodeSelect(isSelect)
    if not self.IsLock then
        self.ImageSelected.gameObject:SetActiveEx(isSelect)
    end
end

function XUiGridStageItem:ResetItemPosition(pos)
    if self.ImgHideLine then
        local rect = self.ImgHideLine:GetComponent("RectTransform").rect
        self.Transform.localPosition = CS.UnityEngine.Vector3(pos.x, pos.y - rect.height, pos.z)
    end
end

return XUiGridStageItem