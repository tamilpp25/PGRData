local XUiGridSpSkillLine = XClass(nil, "XUiGridSpSkillLine")

---@param transform UnityEngine.RectTransform
function XUiGridSpSkillLine:Ctor(transform)
    self.Transform = transform
    XTool.InitUiObject(self)
end

function XUiGridSpSkillLine:SetIsActivation(isActivation)
    self.Activation.gameObject:SetActiveEx(isActivation)
    self.Disable.gameObject:SetActiveEx(not isActivation)
end

return XUiGridSpSkillLine