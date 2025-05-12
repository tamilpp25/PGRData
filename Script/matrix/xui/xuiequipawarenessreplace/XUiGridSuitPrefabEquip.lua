local XUiGridEquip = require("XUi/XUiEquip/XUiGridEquip")

local XUiGridSuitPrefabEquip = XClass(XUiNode, "XUiGridSuitPrefabEquip")

function XUiGridSuitPrefabEquip:Refresh(conflictInfo)
    self.RImgHead:SetRawImage(XMVCA.XCharacter:GetCharRoundnessHeadIcon(conflictInfo.CharacterId))
    local grid = XUiGridEquip.New(self.GridEquip, self.Parent)
    grid:Open()
    grid:Refresh(conflictInfo.EquipId)
end

return XUiGridSuitPrefabEquip