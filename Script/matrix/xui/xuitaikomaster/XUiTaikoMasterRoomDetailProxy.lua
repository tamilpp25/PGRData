local XRobot = require("XEntity/XRobot/XRobot")
local XUiBattleRoomRoleDetailDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoomRoleDetailDefaultProxy")
local XUiTaikoMasterRoomDetailProxy = XClass(XUiBattleRoomRoleDetailDefaultProxy, "XUiTaikoMasterRoomDetailProxy")

function XUiTaikoMasterRoomDetailProxy:GetEntities(characterType)
    local robotIdList = XFubenConfigs.GetStageTypeRobot(XDataCenter.FubenManager.StageType.TaikoMaster)
    local robots = {}
    for _, robotId in ipairs(robotIdList) do
        if characterType == XRobotManager.GetRobotCharacterType(robotId) then
            table.insert(robots, XRobot.New(robotId))
        end
    end
    return robots
end

function XUiTaikoMasterRoomDetailProxy:AOPRefreshOperationBtnsBefore(ui)
    ui.BtnPartner.gameObject:SetActiveEx(false)
    ui.BtnFashion.gameObject:SetActiveEx(false)
    ui.BtnConsciousness.gameObject:SetActiveEx(false)
    ui.BtnWeapon.gameObject:SetActiveEx(false)
    return true
end

function XUiBattleRoomRoleDetailDefaultProxy:CheckIsNeedPractice()
    return false
end

return XUiTaikoMasterRoomDetailProxy