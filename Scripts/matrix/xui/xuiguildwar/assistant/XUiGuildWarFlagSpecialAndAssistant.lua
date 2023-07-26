---@class XUiGuildWarFlagSpecialAndAssistant@ 特攻角色和支援角色标记
local XUiGuildWarFlagSpecialAndAssistant = XClass(nil, "UiGuildWarFlagSpecialAndAssistant")

function XUiGuildWarFlagSpecialAndAssistant:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
end

---@param  member XGuildWarMember
function XUiGuildWarFlagSpecialAndAssistant:Update(member)
    if not member then
        self.GameObject:SetActiveEx(false)
        return
    end
    self.GameObject:SetActiveEx(true)

    -- 特攻图标
    local characterId = member:GetEntityId()
    local isSpecialRole = XDataCenter.GuildWarManager.CheckIsSpecialRole(
                              characterId)
    self.PanelGuildwarUP.gameObject:SetActiveEx(isSpecialRole)
    if isSpecialRole then
        local icon = XDataCenter.GuildWarManager.GetSpecialRoleIcon(characterId)
        self.RImgGuildwarUP:SetRawImage(icon)
    end
    self.PanelGuildwarSupport.gameObject:SetActiveEx(member:IsAssitant())
end

return XUiGuildWarFlagSpecialAndAssistant
