local XGridCharacterV2P6 = require("XUi/XUiCharacterV2P6/Grid/XGridCharacterV2P6")

---@class XUiSelectCharacterPlayerSupportGrid:XGridCharacterV2P6
local XUiSelectCharacterPlayerSupportGrid = XClass(XGridCharacterV2P6, "XUiSelectCharacterPlayerSupportGrid")

function XUiSelectCharacterPlayerSupportGrid:UpdateBaseCharacterInfo()
    self.Super.UpdateBaseCharacterInfo(self)

    -- 特攻角色
    local character = self.Character
    if character then
        local characterId = character:GetId()
        local id = XDataCenter.AssistManager.GetAssistCharacterId()
        if id == characterId then
            self.PanelSupportIn.gameObject:SetActiveEx(true)
            return
        end
    end
    self.PanelSupportIn.gameObject:SetActiveEx(false)
end

return XUiSelectCharacterPlayerSupportGrid
