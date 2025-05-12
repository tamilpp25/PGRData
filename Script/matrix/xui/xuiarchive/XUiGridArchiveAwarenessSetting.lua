local XUiGridArchive = require("XUi/XUiArchive/XUiGridArchive")
--
-- Author: wujie
-- Note: 图鉴意识详细设定格子信息

local XUiGridArchiveAwarenessSetting = XClass(XUiNode, "XUiGridArchiveAwarenessSetting")

function XUiGridArchiveAwarenessSetting:OnStart(rootUi, ui)

end

function XUiGridArchiveAwarenessSetting:Refresh(data)
    self.TxtTitle.text = data.Title
    self.TxtContent.text = data.IsOpen and data.ContentDesc or data.ConditionDesc
end

return XUiGridArchiveAwarenessSetting