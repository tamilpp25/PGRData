--增益详情的布局
local XUiPanelDetailNature = XClass(nil, "XUiPanelDetailNature")

function XUiPanelDetailNature:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self.TheatreManager = XDataCenter.TheatreManager
    self.AdventureManager = self.TheatreManager.GetCurrentAdventureManager()
end

--skill：XAdventureSkill
function XUiPanelDetailNature:Show(skill)
    self.TxtAttrInfo.text = XUiHelper.ConvertLineBreakSymbol(skill:GetLevelDesc())
    self.TxtEffectInfo.text = XUiHelper.ConvertLineBreakSymbol(skill:GetDesc())
    self.GameObject:SetActiveEx(true)
end

return XUiPanelDetailNature