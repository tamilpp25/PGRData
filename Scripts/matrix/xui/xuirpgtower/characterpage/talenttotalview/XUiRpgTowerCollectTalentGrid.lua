-- 兵法蓝图天赋总览技能列表项控件
local XUiRpgTowerCollectTalentGrid = XClass(nil, "XUiRpgTowerCollectTalentGrid")

function XUiRpgTowerCollectTalentGrid:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
end

function XUiRpgTowerCollectTalentGrid:Refresh(rTalent)
    self.RImgSkill:SetRawImage(rTalent:GetIconPath())
    self.TxtDescribe.text = rTalent:GetDescription()
end

return XUiRpgTowerCollectTalentGrid