
local XUiGridHud = require("XUi/XUiBlackRockChess/XUiGrid/XUiGridHud")

---@class XUiGridBuffHud : XUiGridHud
---@field _Control XBlackRockChessControl
local XUiGridBuffHud = XClass(XUiGridHud, "XUiGridBuffHud")

function XUiGridBuffHud:BindTarget(target, offset, skillId, count)
    XUiGridHud.BindTarget(self, target, offset)
    self.SkillId = skillId
    self.Count = count
end

function XUiGridBuffHud:RefreshView()
    self.RImgBuff:SetRawImage(self._Control:GetWeaponSkillIcon(self.SkillId))
    self.TxtBuffNum.text = "x" .. self.Count
end

return XUiGridBuffHud