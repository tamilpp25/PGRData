---@class XGoldenMinerComponentTimeLineAnim
local XGoldenMinerComponentTimeLineAnim = XClass(nil, "XGoldenMinerComponentTimeLineAnim")

function XGoldenMinerComponentTimeLineAnim:Ctor()
    ---@type UnityEngine.Transform
    self.AnimRoot = false
    
    self.CurAnimDuration = 0
    
    self.CurAnim = XGoldenMinerConfigs.GAME_ANIM.NONE
    
    ---@type function
    self.FinishCallBack = false

    self.BePlayAnim = XGoldenMinerConfigs.GAME_ANIM.NONE
    
    ---@type function
    self.BeFinishCallBack = false
    
    self.IsBreakCurPlay = false
end

return XGoldenMinerComponentTimeLineAnim