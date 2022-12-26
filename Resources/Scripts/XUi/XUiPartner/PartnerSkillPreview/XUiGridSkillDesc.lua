local XUiGridSkillDesc = XClass(nil, "XUiGridSkillDesc")
local CSTextManagerGetText = CS.XTextManager.GetText
function XUiGridSkillDesc:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.IsLock = false
    XTool.InitUiObject(self)
end

function XUiGridSkillDesc:UpdateGrid(data,curLevel)
    self.Data = data
    if data then
        local panel
        local level = data:GetLevelStr()
        local sameLevel = curLevel == data:GetLevel()
        local IsShowUnLock = not data:GetIsLock() and sameLevel
        local IsLevelMax = data:GetLevel() >= data:GetLevelLimit()
        
         if IsShowUnLock then
            panel = self.PanelNormal
         else
            panel = self.PanelLock
         end 

        panel:GetObject("TxtLevel").text = level
        panel:GetObject("TxtContent").text = data:GetSkillDesc()
        panel:GetObject("CurText").gameObject:SetActiveEx(sameLevel)
        panel:GetObject("PanelLevelMax").gameObject:SetActiveEx(IsLevelMax)
        panel:GetObject("PanelLevel").gameObject:SetActiveEx(not IsLevelMax)
        
        self.PanelNormal.gameObject:SetActiveEx(IsShowUnLock)
        self.PanelLock.gameObject:SetActiveEx(not IsShowUnLock)
    end
end

return XUiGridSkillDesc