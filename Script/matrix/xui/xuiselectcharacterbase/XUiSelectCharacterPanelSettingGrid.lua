local XGridCharacterV2P6 = require("XUi/XUiCharacterV2P6/Grid/XGridCharacterV2P6")

---@class XUiSelectCharacterPanelSettingGrid:XGridCharacterV2P6
local XUiSelectCharacterPanelSettingGrid = XClass(XGridCharacterV2P6, "XUiSelectCharacterPanelSettingGrid")

function XUiSelectCharacterPanelSettingGrid:UpdateBaseCharacterInfo()
    self.Super.UpdateBaseCharacterInfo(self)

    -- 特攻角色
    local character = self.Character
    if character then
        local characterId = character:GetId()
        local isOnTeam = self.Parent.Parent:IsOnTeam(characterId)
        if isOnTeam then
            self.PanelSupportIn.gameObject:SetActiveEx(true)
            return
        end
    end
    self.PanelSupportIn.gameObject:SetActiveEx(false)
end

return XUiSelectCharacterPanelSettingGrid
