local XGridCharacterV2P6 = require("XUi/XUiCharacterV2P6/Grid/XGridCharacterV2P6")

---@class XGridCharacterGuildWarAssistantV2P6:XGridCharacterV2P6
local XGridCharacterGuildWarAssistantV2P6 = XClass(XGridCharacterV2P6, "XGridCharacterGuildWarAssistantV2P6")

function XGridCharacterGuildWarAssistantV2P6:UpdateBaseCharacterInfo()
    self.Super.UpdateBaseCharacterInfo(self)

    -- 特攻角色
    local character = self.Character
    if character then
        local characterId = character:GetId()
        local isSpecialRole = XDataCenter.GuildWarManager.CheckIsSpecialRole(characterId)
        local icon = false
        if isSpecialRole then
            icon = XDataCenter.GuildWarManager.GetSpecialRoleIcon(characterId)
            self.RImgGuildWarUP:SetRawImage(icon)
            self.PanelHighPriority.gameObject:SetActiveEx(true)
            return
        end
    end
    self.PanelHighPriority.gameObject:SetActiveEx(false)
end

return XGridCharacterGuildWarAssistantV2P6
