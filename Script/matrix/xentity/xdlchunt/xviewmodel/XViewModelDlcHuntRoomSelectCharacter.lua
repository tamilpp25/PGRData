local XViewModelDlcHuntCharacter = require("XEntity/XDlcHunt/XViewModel/XViewModelDlcHuntCharacter")

---@class XViewModelDlcHuntRoomSelectCharacter:XViewModelDlcHuntCharacter
local XViewModelDlcHuntRoomSelectCharacter = XClass(XViewModelDlcHuntCharacter, "XViewModelDlcHuntRoomSelectCharacter")

function XViewModelDlcHuntRoomSelectCharacter:RequestFight(...)
    local character = self:GetCharacter()
    if not character then
        return
    end
    XDataCenter.DlcRoomManager.ReqSelectCharacter(character:GetCharacterId())
end

function XViewModelDlcHuntRoomSelectCharacter:OnStart()
end

function XViewModelDlcHuntRoomSelectCharacter:OnDestroy()
end

return XViewModelDlcHuntRoomSelectCharacter