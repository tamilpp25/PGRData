local XUiSelectCharacterBase = require("XUi/XUiSelectCharacterBase/XUiSelectCharacterBase")
---@class XUiSelectCharacterStrongholdSupport:XUiSelectCharacterBase
local XUiSelectCharacterStrongholdSupport = XLuaUiManager.Register(XUiSelectCharacterBase, "UiSelectCharacterStrongholdSupport")

function XUiSelectCharacterStrongholdSupport:OnStartCb(supportData)
    self.SupportData = supportData
end

function XUiSelectCharacterStrongholdSupport:GetRefreshFun()
    return function (index, grid, char)
        grid:SetData(char, index)
        grid:UpdateSupportAbandoned(self.SupportData)
    end
end

function XUiSelectCharacterStrongholdSupport:RefreshMid()
    local characterId = self.CurCharacter.Id
    local supportData = self.SupportData
    local showSupport = not supportData.CheckInSupportCb(characterId)
    self.BtnJoin.gameObject:SetActiveEx(showSupport)

    local showSupportCancel = supportData.CanSupportCancel and supportData.CheckInSupportCb(characterId)
    self.BtnQuit.gameObject:SetActiveEx(showSupportCancel)
end

function XUiSelectCharacterStrongholdSupport:OnBtnJoinClick()
    local characterId = self.CurCharacter.Id
    XEventManager.DispatchEvent(XEventId.EVENT_CHARACTER_SUPPORT, characterId)

    if self.SupportData then
        if self.SupportData.SetCharacterCb then
            local cb = function() self:Close() end
            if not self.SupportData.SetCharacterCb(characterId, cb, self.SupportData.OldCharacterId) then return end
        end
    else
        self:Close()
    end
end

function XUiSelectCharacterStrongholdSupport:OnBtnQuitClick()
    local characterId = self.CurCharacter.Id
    if not self.SupportData then
        return
    end

    if not self.SupportData.CancelCharacterCb then
        return
    end
    
    self.SupportData.CancelCharacterCb(characterId)
    self:Close()
end

return XUiSelectCharacterStrongholdSupport
