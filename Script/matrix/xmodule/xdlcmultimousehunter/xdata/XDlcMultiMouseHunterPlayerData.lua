local XDlcPlayerCustomData = require("XModule/XDlcRoom/XCustomDataBase/XDlcPlayerCustomData")

---@class XDlcMultiMouseHunterPlayerData : XDlcPlayerCustomData
local XDlcMultiMouseHunterPlayerData = XClass(XDlcPlayerCustomData, "XDlcMultiMouseHunterPlayerData")

function XDlcMultiMouseHunterPlayerData:GetTitleId()
    return self._TitleId or 0
end

---@param other XDlcMultiMouseHunterPlayerData
function XDlcMultiMouseHunterPlayerData:_Clone(other)
    self._TitleId = other:GetTitleId()
end

function XDlcMultiMouseHunterPlayerData:_InitWithRoomData(roomData)
    local titleId = roomData.DlcMultiplayerTitle
    
    if XTool.IsNumberValid(titleId) then
        self._TitleId = titleId
    end
end

function XDlcMultiMouseHunterPlayerData:_InitWithWorldData(worldData)
    local titleId = worldData.MultiplayerData.DlcMultiplayerTitle

    if XTool.IsNumberValid(titleId) then
        self._TitleId = titleId
    end
end

function XDlcMultiMouseHunterPlayerData:_ClearData()
    self._TitleId = nil
end

return XDlcMultiMouseHunterPlayerData