local XUiGridInfestorExploreOutPostStory = XClass(nil, "XUiGridInfestorExploreOutPostStory")

function XUiGridInfestorExploreOutPostStory:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiGridInfestorExploreOutPostStory:Refresh(des, timestamp)
    self.TxtTime.text = XTime.TimestampToGameDateTimeString(timestamp)
    self.TxtDescribe.text = des
end

return XUiGridInfestorExploreOutPostStory