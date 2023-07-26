local XUiPlanetRunningAction = require("XUi/XUiPlanet/Fight/Action/XUiPlanetRunningAction")

---@class XUiPlanetRunningActionAttack:XUiPlanetRunningAction
local XUiPlanetRunningActionAttack = XClass(XUiPlanetRunningAction, "XUiPlanetRunningActionAttack")

function XUiPlanetRunningActionAttack:Ctor()
    self.ActionType = CS.XPlanetRunning.XPlanetRunningFight.XPlanetRunningActionType.Attack
    self.LauncherId = 0
    self.TargetId = 0
    self.IsPlayingTimeline = false
end

function XUiPlanetRunningActionAttack:Set(objAction)
    XUiPlanetRunningActionAttack.Super.Set(self, objAction)
    self.LauncherId = objAction.LauncherId
    self.TargetId = objAction.TargetId
    self.Hurt = objAction.Value
    self.IsCritical = objAction.IsCritical
end

return XUiPlanetRunningActionAttack