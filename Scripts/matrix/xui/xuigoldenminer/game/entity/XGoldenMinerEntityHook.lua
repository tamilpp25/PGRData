---@class XGoldenMinerEntityHook
local XGoldenMinerEntityHook = XClass(nil, "XGoldenMinerEntityHook")

function XGoldenMinerEntityHook:Ctor()
    ---@type XGoldenMinerComponentHook
    self.Hook = false

    ---@type XGoldenMinerEntityStone[]
    self.HookGrabbedStoneList = {}

    ---@type XGoldenMinerEntityStone[]
    self.HookGrabbingStoneList = {}

    ---@type XGoldenMinerEntityStone[]
    self.HookHitStoneList = {}
    
    ---@type XGoldenMinerComponentTimeLineAnim
    self.Anim = false
end

return XGoldenMinerEntityHook