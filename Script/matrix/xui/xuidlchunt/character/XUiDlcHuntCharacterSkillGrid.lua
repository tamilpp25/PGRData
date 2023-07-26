---@class XUiDlcHuntCharacterSkillGrid
local XUiDlcHuntCharacterSkillGrid = XClass(nil, "XUiDlcHuntCharacterSkillGrid")

function XUiDlcHuntCharacterSkillGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiDlcHuntCharacterSkillGrid:Update(data)
    self.RImgIcon:SetRawImage(data.Icon)
end

return XUiDlcHuntCharacterSkillGrid