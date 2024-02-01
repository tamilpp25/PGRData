local XUiBtnKeyItem = require("XUi/XUiSet/ChildItem/XUiBtnKeyItem")
local XUiNotCustomKeyItemHandle = XClass(XUiBtnKeyItem, "XUiNotCustomKeyItemHandle")

function XUiNotCustomKeyItemHandle:OnStart()
    self.Super.OnStart(self)
    self.BtnClear.gameObject:SetActiveEx(false)
end

function XUiNotCustomKeyItemHandle:Refresh(data, cb, resetTextOnly, curOperationType)
    self.Super.Refresh(self, data, cb, resetTextOnly, curOperationType)
    self.GroupRecommend.gameObject:SetActiveEx(false)
end

function XUiNotCustomKeyItemHandle:SetRecommendText(operationKey)
    self.Super.SetRecommendText(self, operationKey)
    self.GroupRecommend.gameObject:SetActiveEx(false)
end

return XUiNotCustomKeyItemHandle