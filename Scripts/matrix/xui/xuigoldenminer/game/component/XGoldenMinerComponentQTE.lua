---@class XGoldenMinerComponentQTE
local XGoldenMinerComponentQTE = XClass(nil, "XGoldenMinerComponentQTE")

function XGoldenMinerComponentQTE:Ctor()
    self.Status = XGoldenMinerConfigs.GAME_QTE_STATUS.NONE
    
    self.QTEGroupId = 0
    self.Time = 0
    self.CurTime = 0
    self.ClickCount = 0
    self.CurClickCount = 0
    self.WaitTime = 0
    
    ---@type UnityEngine.UI.RawImage
    self.QTEIcon = false
    ---@type UnityEngine.Transform
    self.AnimClick = false
    self.IsCanAnimClick = true
    ---@type UnityEngine.Transform
    self.ProgressPanel = false
    ---@type UnityEngine.UI.Image
    self.ProgressFillImage = false
    
    self.SpeedRate = 1
    self.AddScore = 0
    self.AddItemId = 0
    self.AddBuff = 0
end

return XGoldenMinerComponentQTE