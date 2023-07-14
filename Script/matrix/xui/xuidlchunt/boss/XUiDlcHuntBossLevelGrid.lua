local XUiDlcHuntUtil = require("XUi/XUiDlcHunt/XUiDlcHuntUtil")

---@class XUiDlcHuntBossLevelGrid
local XUiDlcHuntBossLevelGrid = XClass(nil, "XUiDlcHuntBossLevelGrid")

function XUiDlcHuntBossLevelGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiDlcHuntBossLevelGrid:GetButton()
    return self.Transform:GetComponent("XUiButton")
end

---@param world XDlcHuntWorld
function XUiDlcHuntBossLevelGrid:Update(world, index)
    local button = self:GetButton()
    button:SetNameByGroup(0, world:GetDifficultyName())
    button:SetNameByGroup(1, world:GetDifficultyNameEn())
    --button:SetNameByGroup(2, world:GetDifficultyLevel())
    local txtGroup = button.TxtGroupList[2]
    if txtGroup then
        for i, uiText in pairs(txtGroup.TxtList) do
            XUiDlcHuntUtil.SetTextIndex(uiText, index)
        end
    end
end

return XUiDlcHuntBossLevelGrid
