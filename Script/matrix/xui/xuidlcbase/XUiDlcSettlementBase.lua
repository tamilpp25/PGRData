---@class XUiDlcSettlementBase : XLuaUi
local XUiDlcSettlementBase = XClass(XLuaUi, "XUiDlcSettlementBase")

function XUiDlcSettlementBase:Close()
    if XMVCA.XDlcRoom:IsCouldRebuildRoom() then
        XMVCA.XDlcRoom:RebuildRoom()
    else
        XUiDlcSettlementBase.Super.Close(self)
    end
end

return XUiDlcSettlementBase
