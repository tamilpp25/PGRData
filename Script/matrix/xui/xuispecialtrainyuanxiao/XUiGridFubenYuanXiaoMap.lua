local XUiGridFubenYuanXiaoMap = XClass(nil,"XUiGridFubenYuanXiaoMap")

function XUiGridFubenYuanXiaoMap:Ctor(stageId, ui, clickEvent)
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

function XUiGridFubenYuanXiaoMap:OnClickBtnSelect()
    if self.ClickEvent then
        self.ClickEvent(self.StageId)
    end
end

function XUiGridFubenYuanXiaoMap:RefreshStage()
    local isRandomStage = XDataCenter.FubenSpecialTrainManager.CheckHasRandomStage(self.StageId)
    if not isRandomStage then
        local config = XDataCenter.FubenManager.GetStageCfg(self.StageId)
        if config then
            self.RImgTitle:SetRawImage(config.StoryIcon)
            self.TxtMusicName.text = config.Name
        end
    else
        local storyIcon = XFubenSpecialTrainConfig.GetRandomStageStoryIconById(self.StageId)
        self.RImgTitle:SetRawImage(storyIcon)
        self.TxtMusicName.text = XFubenSpecialTrainConfig.GetRandomStageNameById(self.StageId)
    end
end

function XUiGridFubenYuanXiaoMap:SetSelect(isSelect)
    self.PanelSelect.gameObject:SetActiveEx(isSelect)
    self.PanelNormal.gameObject:SetActiveEx(not isSelect)
end

return XUiGridFubenYuanXiaoMap