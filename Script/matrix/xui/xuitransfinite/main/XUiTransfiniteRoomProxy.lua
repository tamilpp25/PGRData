local XUiBattleRoleRoomDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoleRoomDefaultProxy")

local XUiTransfiniteRoomProxy = XClass(XUiBattleRoleRoomDefaultProxy, "XUiTransfiniteRoomProxy")

function XUiTransfiniteRoomProxy:AOPOnStartAfter(ui)
    ui.BtnEnterFight:SetNameByGroup(0, XUiHelper.GetText("ConfirmText"))
end

function XUiTransfiniteRoomProxy:AOPOnClickFight(ui)
    ui:Close()
    return true
end

return XUiTransfiniteRoomProxy
