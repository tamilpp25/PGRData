---@class XGoldenMinerComponentTimeLineAnim:XEntity
---@field _OwnControl XGoldenMinerGameControl
local XGoldenMinerComponentTimeLineAnim = XClass(XEntity, "XGoldenMinerComponentTimeLineAnim")

--region Override
function XGoldenMinerComponentTimeLineAnim:OnInit()
    ---@type UnityEngine.Transform
    self.AnimRoot = false
    
    self.CurAnimDuration = 0
    
    self.CurAnim = XEnumConst.GOLDEN_MINER.GAME_ANIM.NONE
    
    ---@type function
    self.FinishCallBack = false

    self.BePlayAnim = XEnumConst.GOLDEN_MINER.GAME_ANIM.NONE
    
    ---@type function
    self.BeFinishCallBack = false
    
    self.IsBreakCurPlay = false
end

function XGoldenMinerComponentTimeLineAnim:OnRelease()
    self.AnimRoot = nil
    self.FinishCallBack = nil
    self.BeFinishCallBack = nil
end
--endregion

return XGoldenMinerComponentTimeLineAnim