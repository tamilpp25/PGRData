local XUiRogueLikeBoxEntrance = XClass(nil, "XUiRogueLikeBoxEntrance")

function XUiRogueLikeBoxEntrance:Ctor(ui, uiRoot)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot

    XTool.InitUiObject(self)
    self.BtnOpen.CallBack = function() self:OnBtnOpenClick() end
end

function XUiRogueLikeBoxEntrance:UpdateByNode(node, eventNode)
    self.Node = node
    self.EventNode = (eventNode == nil) and node or eventNode
    self.NodeTemplate = XFubenRogueLikeConfig.GetNodeTemplateById(self.EventNode.Id)
    self.NodeConfig = XFubenRogueLikeConfig.GetNodeConfigteById(self.EventNode.Id)

    self.TxtName.text = self.NodeConfig.Name
    self.RImgIcon:SetRawImage(self.NodeConfig.Icon)
    self.TxtRest.text = self.NodeConfig.Description

end

function XUiRogueLikeBoxEntrance:OnBtnOpenClick()
    XDataCenter.FubenRogueLikeManager.OpenBox(self.Node.Id, self.EventNode, function()
    -- 刷新操作
        self.UiRoot:Close()
    end)
end

return XUiRogueLikeBoxEntrance