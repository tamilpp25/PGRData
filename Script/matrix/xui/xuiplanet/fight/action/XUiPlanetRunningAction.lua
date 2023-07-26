---@class XUiPlanetRunningAction
local XUiPlanetRunningAction = XClass(nil, "XUiPlanetRunningAction")

function XUiPlanetRunningAction:Ctor()
    self.ActionType = CS.XPlanetRunning.XPlanetRunningFight.XPlanetRunningActionType.None
    self.Duration = 0
    self.Status = XPlanetExploreConfigs.ATTACK_STATUS.NONE
end

function XUiPlanetRunningAction:Set(objAction)
    self.ActionType = objAction.ActionType
end

return XUiPlanetRunningAction