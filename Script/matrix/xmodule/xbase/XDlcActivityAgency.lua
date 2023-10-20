local XFubenActivityAgency = require("XModule/XBase/XFubenActivityAgency")
local XDlcRoom = require("XModule/XDlcRoom/XEntity/XDlcRoom")
local XDlcWorldFight = require("XModule/XDlcRoom/XDlcWorldFight/XDlcWorldFight")

---@class XDlcActivityAgency : XFubenActivityAgency
local XDlcActivityAgency = XClass(XFubenActivityAgency, "XDlcActivityAgency")

function XDlcActivityAgency:DlcCheckClickHrefCanEnter(roomId, worldId, createTime)
    if not self:ExCheckInTime() then
        return false
    end

    if XTime.GetServerNowTimestamp() > createTime + CS.XGame.Config:GetInt("RoomHrefDisableTime") then
        XUiManager.TipText("RoomHrefDisabled")
        return false
    end 

    return true
end

function XDlcActivityAgency:DlcGetRoomProxy()
    return XDlcRoom.New()
end

function XDlcActivityAgency:DlcGetFightEvent()
    return XDlcWorldFight.New()
end

return XDlcActivityAgency