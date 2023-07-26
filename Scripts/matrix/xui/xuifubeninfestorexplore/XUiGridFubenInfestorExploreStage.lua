local XUiGridFubenInfestorExploreStage = XClass(nil, "XUiGridFubenInfestorExploreStage")

function XUiGridFubenInfestorExploreStage:Ctor(rootUi, chapterId, nodeId, clickCb)
    self.RootUi = rootUi
    self.ChapterId = chapterId
    self.NodeId = nodeId
    self.ClickCb = clickCb
end

function XUiGridFubenInfestorExploreStage:Refresh(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    if self.BtnClick then
        CsXUiHelper.RegisterClickEvent(self.BtnClick, function() self:OnClickBtnClick() end)
    end

    self:SetSelect(false)

    local chapterId = self.ChapterId
    local nodeId = self.NodeId
    if self.ImgIcon then
        local icon = XDataCenter.FubenInfestorExploreManager.GetNodeTypeIcon(chapterId, nodeId)
        self.RootUi:SetUiSprite(self.ImgIcon, icon)
    end
end

function XUiGridFubenInfestorExploreStage:OnClickBtnClick()
    local chapterId = self.ChapterId
    local nodeId = self.NodeId

    if XDataCenter.FubenInfestorExploreManager.IsNodeCurrent(chapterId, nodeId)
    or XDataCenter.FubenInfestorExploreManager.IsNodeReach(chapterId, nodeId)
    or XDataCenter.FubenInfestorExploreManager.IsNodePassed(chapterId, nodeId)
    or XDataCenter.FubenInfestorExploreManager.IsNodeUnReach(chapterId, nodeId) then
        self.ClickCb(self, nodeId)
    elseif XDataCenter.FubenInfestorExploreManager.IsNodeFog(chapterId, nodeId) then
        XUiManager.TipText("InfestorExploreNodeFogTip")
    end
end

function XUiGridFubenInfestorExploreStage:SetSelect(value)
    if self.PanelSelect then
        self.PanelSelect.gameObject:SetActiveEx(value)
    end
end

return XUiGridFubenInfestorExploreStage