---@class XGoldenMinerEntityStone
local XGoldenMinerEntityStone = XClass(nil, "XGoldenMinerEntityStone")

function XGoldenMinerEntityStone:Ctor()
    self.Status = XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.NONE

    ---@type XGoldenMinerMapStoneData
    self.Data = false

    ---@type XGoldenMinerEntityStone
    self.CarryStone = false
    
    ---@type XGoldenMinerComponentMove
    self.Move = false

    ---@type XGoldenMinerComponentTimeLineAnim
    self.Anim = false

    ---@type XGoldenMinerComponentStone
    self.Stone = false
    
    ---@type XGoldenMinerComponentMouse
    self.Mouse = false
    
    ---@type XGoldenMinerComponentQTE
    self.QTE = false

    ---@type XGoldenMinerComponentMussel
    self.Mussel = false
    
    ---@type XGoldenMinerComponentDirectionPoint
    self.HookDirectionPoint = false

    ---额外参数
    ---@type number[]
    self.AdditionValue = {}
end

return XGoldenMinerEntityStone