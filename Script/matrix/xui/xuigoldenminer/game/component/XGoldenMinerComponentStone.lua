---@class XGoldenMinerComponentStone
local XGoldenMinerComponentStone = XClass(nil, "XGoldenMinerComponentStone")

function XGoldenMinerComponentStone:Ctor()
    ---该抓取物基本分数
    self.Score = 0

    ---该抓取物当前分数（受Buff影响）
    self.CurScore = 0

    ---该抓取物基本重量
    self.Weight = 0

    ---该抓取物当前实际重量（受Buff影响）
    self.CurWeight = 0

    self.BornDelayTime = 0

    self.AutoDestroyTime = 0

    self.BeDestroyTime = 0

    self.HideTime = 0
    
    ---抓取物对象根节点
    ---@type UnityEngine.Transform
    self.Transform = false

    ---未被抓是携带物根节点
    ---@type UnityEngine.Transform
    self.CarryItemParent = false

    ---被抓取时携带物根节点
    ---@type UnityEngine.Transform
    self.GrabCarryItemParent = false

    ---@type UnityEngine.Collider2D
    self.Collider = false

    ---@type UnityEngine.Collider2D
    self.BoomCollider = false

    ---@type XGoInputHandler
    self.GoInputHandler = false
end

return XGoldenMinerComponentStone