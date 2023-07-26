
local XUiSSBBalanceTipsGrid = XClass(nil, "XUiSSBBalanceTipsGrid")

function XUiSSBBalanceTipsGrid:Ctor(uiPrefab)
    self:Init(uiPrefab)
end

function XUiSSBBalanceTipsGrid:Init(uiPrefab)
    XTool.InitUiObjectByUi(self, uiPrefab)
end

function XUiSSBBalanceTipsGrid:Refresh(tipInfo)
    self.TxtTitle.text = tipInfo.Title
    self.TxtDescription.text = tipInfo.Description
    self.RImgIcon:SetRawImage(tipInfo.Icon)
end

return XUiSSBBalanceTipsGrid