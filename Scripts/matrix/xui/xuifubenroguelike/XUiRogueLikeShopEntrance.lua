local XUiRogueLikeShopEntrance = XClass(nil, "XUiRogueLikeShopEntrance")

function XUiRogueLikeShopEntrance:Ctor(ui, uiRoot)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot

    XTool.InitUiObject(self)
    self.BtnOpen.CallBack = function() self:OnBtnOpenClick() end
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
end


function XUiRogueLikeShopEntrance:UpdateByNode(node, eventNode)
    self.Node = node
    self.EventNode = (eventNode == nil) and node or eventNode
    self.NodeTemplate = XFubenRogueLikeConfig.GetNodeTemplateById(self.EventNode.Id)
    self.NodeConfig = XFubenRogueLikeConfig.GetNodeConfigteById(self.EventNode.Id)

    self.TxtName.text = self.NodeConfig.Name
    self.RImgIcon:SetRawImage(self.NodeConfig.Icon)
    self.TxtRest.text = self.NodeConfig.Description
end

function XUiRogueLikeShopEntrance:OnBtnOpenClick()
    if self.Node then
        XLuaUiManager.Open("UiRogueLikeShop", self.Node, self.EventNode)
    end
end

function XUiRogueLikeShopEntrance:OnBtnBackClick()
    if not self.Node then return end
    local title = CS.XTextManager.GetText("RogueLikeLeaveShopTitle")
    local content = CS.XTextManager.GetText("RogueLikeLeaveShopContent")

    XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, function()
    end, function()
        XDataCenter.FubenRogueLikeManager.FinishNode(self.Node.Id, function()
            self.UiRoot:Close()
        end)
    end)

end

return XUiRogueLikeShopEntrance