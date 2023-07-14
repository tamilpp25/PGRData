local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiGridMissionCommon = XClass(XUiGridCommon, "XUiGridMissionCommon")

function XUiGridMissionCommon:Ctor(rootUi, ui)
    self.ImgBig = XUiHelper.TryGetComponent(self.Transform, "ImgBig", "Image")
    self.ImgAdditional = XUiHelper.TryGetComponent(self.Transform, "ImgAdditional", "Image")
end

return XUiGridMissionCommon
