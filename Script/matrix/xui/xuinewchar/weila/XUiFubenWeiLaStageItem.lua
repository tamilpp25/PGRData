local XUiFubenWeiLaStageItem = XClass(nil, "XUiFubenWeiLaStageItem")
local XUiPanelStars = require("XUi/XUiFubenMainLineChapter/XUiPanelStars")

function XUiFubenWeiLaStageItem:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
end

function XUiFubenWeiLaStageItem:UpdateNode(id, stageId, stageIndex, panelType)
    self.Id = id
    self.StageId = stageId
    self.StageIndex = stageIndex
    self.Template = XFubenNewCharConfig.GetDataById(self.Id, self.StageIndex)

    if panelType == XFubenNewCharConfig.KoroPanelType.Teaching then
        self.StagePrefabName = self.Template.GridFubenPrefab
    end
    if panelType == XFubenNewCharConfig.KoroPanelType.Challenge then
        self.StagePrefabName = self.Template.GridFubenChallengePrefab
    end

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

    if panelType == XFubenNewCharConfig.KoroPanelType.Challenge then
        self.PanelStars = XUiPanelStars.New(self.PanelStar)
        local starsMap = XDataCenter.FubenNewCharActivityManager.GetStarMap(self.StageId)
        self.PanelStars:OnEnable(starsMap)
    end
end

function XUiFubenWeiLaStageItem:SetNormalStage()
    self.PanelStageNormal.gameObject:SetActiveEx(self.IsOpen)
    if self.IsOpen then
        self.StageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageId)
        self.RImgFightActiveNor:SetRawImage(self.StageCfg.Icon)
    end

    --self.TxtStageTitle.text = CS.XTextManager.GetText("TeachingActivityStageName", self.StagePrefix, self.StageName)
    self.TxtStageTitle.text = self.StageName
    --self.ImgStageOrder.gameObject:SetActiveEx(true)
    self.TxtStagePrefix.text = self.StagePrefix
    if self.PanelStageLock then
        self.PanelStageLock.gameObject:SetActiveEx(self.IsLock)
    end
end

function XUiFubenWeiLaStageItem:OnBtnStageClick()
    if self.StageId and self.Id then
        if self.IsOpen then
            self.RootUi:UpdateNodesSelect(self.StageId)
            self.RootUi:OpenStageDetails(self.StageId, self.Id)
            self.RootUi:PlayScrollViewMove(self.Transform)
        else
            XUiManager.TipMsg(self.Description)
        end
    end
end

--显示选中框
function XUiFubenWeiLaStageItem:SetNodeSelect(isSelect)
    if self.IsOpen then
        self.ImageSelected.gameObject:SetActiveEx(isSelect)
    end
end

return XUiFubenWeiLaStageItem