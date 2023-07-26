local XUiRogueLikeClearanceScoreItem = XClass(nil, "XUiRogueLikeClearanceScoreItem")

function XUiRogueLikeClearanceScoreItem:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiRogueLikeClearanceScoreItem:Init()
    self.GameObject:SetActiveEx(true)
end

function XUiRogueLikeClearanceScoreItem:UpdateViewByData(data)
    self.TextValue.text = data.Point
    self.TextTitle.text = XFubenRogueLikeConfig.GetRogueLikePurgatoryScoreTitleByType(data.PointType)
    self.TextDesc.text = XFubenRogueLikeConfig.GetRogueLikePurgatoryScoreDescriptionByType(data.PointType)
end

return XUiRogueLikeClearanceScoreItem