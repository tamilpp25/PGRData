local XUiGridStageSpecialTrain = XClass(nil, "XUiGridStageSpecialTrain")

function XUiGridStageSpecialTrain:Ctor(ui, parent, rootUi)

    self.RootUi = rootUi
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.ParentUi = parent

    XTool.InitUiObject(self)
    CsXUiHelper.RegisterClickEvent(self.BtnStage, handler(self, self.OnBtnStageClick))
    self.Star = {}
    for i = 1, 3, 1 do
        self.Star[i] = self["ImgDone" .. i].gameObject
    end
end

function XUiGridStageSpecialTrain:Refresh(stageId, chapterData, index)
    self.StageId = stageId
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)

    self.StageCfg = stageCfg
    self.StageInfo = stageInfo

    self.TxtStage.text = stageCfg.Name
    self.RawImgBg:SetRawImage(stageCfg.Icon)
    self.TextOderNum.text = string.format("%s -%s", chapterData.PrefixName, index)
    if stageCfg.IsMultiplayer then
        self.PanelStar.gameObject:SetActiveEx(false)
    else
        self.PanelStar.gameObject:SetActiveEx(true)
        local starsMap = stageInfo.StarsMap
        for i, v in ipairs(self.Star) do
            self.Star[i]:SetActiveEx(starsMap[i] or false)
        end
    end

    self.PanelKillParent.gameObject:SetActiveEx(stageInfo.Passed)
end

function XUiGridStageSpecialTrain:OnBtnStageClick()
    if self.ClickCb then
        self.ClickCb(self)
    end

    self.ParentUi:ClickStageGrid(self)
end

return XUiGridStageSpecialTrain