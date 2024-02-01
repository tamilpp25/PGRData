local XUiSelectCharacterBase = require("XUi/XUiSelectCharacterBase/XUiSelectCharacterBase")

---@class XUiSelectAssistanceGuildWar:XUiSelectCharacterBase
local XUiSelectAssistanceGuildWar = XLuaUiManager.Register(XUiSelectCharacterBase, "UiSelectAssistanceGuildWar")

--local supportData = {
--    CanSupportCancel = true,
--    HideBtnRecommend = true,
--    CheckInSupportCb = function(characterId)
--        return XDataCenter.GuildWarManager.GetAssistantCharacterId() == characterId
--    end,
--    SetCharacterCb = function(characterId)
--        XLuaUiManager.Close("UiCharacter")
--        XDataCenter.GuildWarManager.SendAssistant(characterId)
--        return true
--    end,
--    CancelCharacterCb = function(characterId)
--        XLuaUiManager.Close("UiCharacter")
--        XDataCenter.GuildWarManager.CancelAssistant(characterId)
--    end,
--    --显示高优先级图标
--    CheckHighPriority = function(characterId)
--        -- 特攻角色
--        local isSpecialRole = XDataCenter.GuildWarManager.CheckIsSpecialRole(characterId)
--        local icon = false
--        if isSpecialRole then
--            icon = XDataCenter.GuildWarManager.GetSpecialRoleIcon(characterId)
--        end
--        return isSpecialRole, icon
--    end
--}

function XUiSelectAssistanceGuildWar:RefreshMid()
    local character = self.CurCharacter
    if character then
        local characterId = character:GetId()
        if XDataCenter.GuildWarManager.GetAssistantCharacterId() == characterId then
            self.BtnJoin.gameObject:SetActiveEx(false)
            self.BtnQuit.gameObject:SetActiveEx(true)
            return
        end
    end
    self.BtnJoin.gameObject:SetActiveEx(true)
    self.BtnQuit.gameObject:SetActiveEx(false)
end

function XUiSelectAssistanceGuildWar:OnBtnJoinClick()
    local character = self.CurCharacter
    if character then
        local characterId = character:GetId()
        XDataCenter.GuildWarManager.SendAssistant(characterId)
        self.Super.Close(self)
    end
end

function XUiSelectAssistanceGuildWar:OnBtnQuitClick()
    local character = self.CurCharacter
    if character then
        local characterId = character:GetId()
        XDataCenter.GuildWarManager.CancelAssistant(characterId)
        self.Super.Close(self)
    end
end

function XUiSelectAssistanceGuildWar:OnEnableCb()
    local characterId = XDataCenter.GuildWarManager.GetAssistantCharacterId()
    if characterId and characterId > 0 then
        self.PanelFilter:DoSelectCharacter(characterId)
    end
end

function XUiSelectAssistanceGuildWar:GetGridProxy()
    local XGridCharacterGuildWarAssistantV2P6 = require("XUi/XUiCharacterV2P6/Grid/XGridCharacterGuildWarAssistantV2P6")
    return XGridCharacterGuildWarAssistantV2P6
end

return XUiSelectAssistanceGuildWar
