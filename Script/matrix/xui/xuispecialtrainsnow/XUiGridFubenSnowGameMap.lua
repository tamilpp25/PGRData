local XUiGridFubenSnowGameMap = XClass(nil, "XUiGridFubenSnowGameMap")

function XUiGridFubenSnowGameMap:Ctor(stageId, ui, clickEvent)
    self.StageId = stageId
    self.GameObject = ui
    self.Transform = ui.transform
    self.ClickEvent = clickEvent
    XTool.InitUiObject(self)
    self.BtnNormal.CallBack = function()
        self:OnClickBtnSelect()
    end
    self:RefreshStage()
end

function XUiGridFubenSnowGameMap:OnClickBtnSelect()
    if self.ClickEvent then
        self.ClickEvent(self.StageId)
    end
end

function XUiGridFubenSnowGameMap:RefreshStage()
    local config = XDataCenter.FubenManager.GetStageCfg(self.StageId)
    if config then
        self.RImgTitle:SetRawImage(config.StoryIcon)
        self.TxtMusicName.text = config.Name
    end
end

function XUiGridFubenSnowGameMap:SetSelect(isSelect)
    self.PanelSelect.gameObject:SetActiveEx(isSelect)
    self.PanelNormal.gameObject:SetActiveEx(not isSelect)
end

return XUiGridFubenSnowGameMap