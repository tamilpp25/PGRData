local XUiGridFubenInfestorExploreChapter2Stage = XClass(nil, "XUiGridFubenInfestorExploreChapter2Stage")

function XUiGridFubenInfestorExploreChapter2Stage:Ctor(ui, clickCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.ClickCb = clickCb

    XTool.InitUiObject(self)
    self.BtnClick.CallBack = function() self:OnClickBtnClick() end

    self.Normal.gameObject:SetActiveEx(true)
    self.Disable.gameObject:SetActiveEx(false)
end

function XUiGridFubenInfestorExploreChapter2Stage:Refresh(stageId)
    self.StageId = stageId
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)

    local icon = stageCfg.Icon
    if not string.IsNilOrEmpty(icon) then
        self.RImgIcon:SetRawImage(icon)
    end

    self.TxtName.text = stageCfg.Name

    local score = XDataCenter.FubenInfestorExploreManager.GetChapter2StageScore(stageId)
    self.TxtScore.text = score
end

function XUiGridFubenInfestorExploreChapter2Stage:OnClickBtnClick()
    local stageId = self.StageId
    self.ClickCb(stageId)
end

return XUiGridFubenInfestorExploreChapter2Stage