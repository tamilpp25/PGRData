--
-- Author: wujie
-- Note: 图鉴意识详细设定格子信息

local XUiGridArchiveAwarenessSetting = XClass(nil, "XUiGridArchiveAwarenessSetting")

function XUiGridArchiveAwarenessSetting:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi

    XTool.InitUiObject(self)
end

function XUiGridArchiveAwarenessSetting:Refresh(data)
    self.TxtTitle.text = data.Title
    self.TxtContent.text = data.IsOpen and data.ContentDesc or data.ConditionDesc
end

return XUiGridArchiveAwarenessSetting