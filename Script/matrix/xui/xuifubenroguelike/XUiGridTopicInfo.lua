local XUiGridTopicInfo = XClass(nil, "XUiGridTopicInfo")

function XUiGridTopicInfo:Ctor(ui, uiRoot)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot

    XTool.InitUiObject(self)
end

function XUiGridTopicInfo:SetTopicInfo(topic)
    local buffTemplate = XFubenRogueLikeConfig.GetBuffConfigById(topic.BuffId)
    self.TxtUnActive.text = buffTemplate.Description
    self.TxtActive.text = buffTemplate.Description
    self.PanelActive.gameObject:SetActiveEx(topic.IsActive)
end

return XUiGridTopicInfo