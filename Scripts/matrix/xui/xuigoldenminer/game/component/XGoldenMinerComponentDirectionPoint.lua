---@class XGoldenMinerComponentDirectionPoint
local XGoldenMinerComponentDirectionPoint = XClass(nil, "XGoldenMinerComponentDirectionPoint")

function XGoldenMinerComponentDirectionPoint:Ctor()
    self.AngleList = {}
    
    self.AngleTimeList = {}
    
    self.CurAngleIndex = 0
    
    self.CurTime = 0
    
    ---@type UnityEngine.Transform
    self.AngleTransform = false
    ---@type UnityEngine.UI.Image
    self.FillImage = false
end

return XGoldenMinerComponentDirectionPoint