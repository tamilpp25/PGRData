local XUiGridGroupName = XClass(nil, "XUiGridGroupName")

function XUiGridGroupName:Ctor(ui, exhibitionCfg)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:Refresh(exhibitionCfg)
end

function XUiGridGroupName:RefreshNameInfo()
    self.TxtName.text = self.GroupName
end

function XUiGridGroupName:Refresh(exhibitionCfg)
    self.GroupName = exhibitionCfg and exhibitionCfg.GroupName or CS.XTextManager.GetText("ExhibitionDefaultGroupName")
    self:RefreshNameInfo()
end

function XUiGridGroupName:ResetPosition(position)
    self.Transform.position = position
end

return XUiGridGroupName