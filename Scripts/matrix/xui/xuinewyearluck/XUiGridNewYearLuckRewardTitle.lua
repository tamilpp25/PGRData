local XUiGridNewYearLuckRewardTitle = XClass(nil, "XUiGridNewYearLuckRewardTitle")

---@param transform UnityEngine.RectTransform
function XUiGridNewYearLuckRewardTitle:Ctor(transform,type)
    self.Transform = transform
    self.GameObject = transform.gameObject
    XTool.InitUiObject(self)
    self.Type = type
    self:Refresh()
end

function XUiGridNewYearLuckRewardTitle:Refresh()
    self.TxtTitle.text = CS.XTextManager.GetText("NewYearLuckTipTitle" .. self.Type)
end


return XUiGridNewYearLuckRewardTitle