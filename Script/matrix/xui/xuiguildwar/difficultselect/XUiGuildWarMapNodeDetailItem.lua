---@class XUiGuildWarMapNodeDetailItem
local XUiGuildWarMapNodeDetailItem = XClass(nil, "XUiGuildWarMapNodeDetailItem")

function XUiGuildWarMapNodeDetailItem:Ctor(uiPrefab)
    XTool.InitUiObjectByUi(self, uiPrefab)
end

function XUiGuildWarMapNodeDetailItem:Refresh(data)
    self.ImgNodeIcon:SetSprite(data.Icon)
    self.TxtNodeName.text = data.Name
    self.TxtNodeNum.text = "x" .. data.Num
end

return XUiGuildWarMapNodeDetailItem