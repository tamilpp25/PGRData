---@class XGoldenMinerComponentMussel
local XGoldenMinerComponentMussel = XClass(nil, "XGoldenMinerComponentMussel")

function XGoldenMinerComponentMussel:Ctor()
    self.Status = XGoldenMinerConfigs.GAME_MUSSEL_STATUS.NONE
    
    self.CanHide = true
    self.InitIsOpen = true
    self.IsGrabbed = false
    
    self.HideTime = 0
    self.OpenTime = 0
    self.CurTime = 0

    ---@type UnityEngine.Transform
    self.AnimOpen = false
    ---@type UnityEngine.Transform
    self.AnimClose = false
    ---@type UnityEngine.Transform
    self.GrabCarry = false
    ---@type UnityEngine.Collider2D
    self.OpenCollider = false
    ---@type UnityEngine.Collider2D
    self.CloseCollider = false
    ---@type XGoInputHandler
    self.OpenGoInputHandler = false
    ---@type XGoInputHandler
    self.CloseGoInputHandler = false
end

return XGoldenMinerComponentMussel