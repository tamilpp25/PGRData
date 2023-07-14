---@class XTheatre3Settle
local XTheatre3Settle = XClass(nil, "XUiTheatre3Settlement")

function XTheatre3Settle:Ctor()
    ---结局ID
    self.EndId = 0
    ---完成节点数
    self.NodeCount = 0
    ---战斗节点数
    self.FightNodeCount = 0
    ---完成章节数
    self.ChapterCount = 0
    ---道具总数量
    self.TotalItemCount = 0
    ---装备总数量
    self.TotalEquipCount = 0
    ---套装总数量
    self.TotalSuitCount = 0
    ---完成节点数——分数
    self.NodeCountScore = 0
    ---战斗节点数——分数
    self.FightNodeCountScore = 0
    ---完成章节数——分数
    self.ChapterCountScore = 0
    ---道具总数量——分数
    self.TotalItemCountScore = 0
    ---装备总数量——分数
    self.TotalEquipCountScore = 0
    ---套装总数量——分数
    self.TotalSuitCountScore = 0
    ---结局倍率
    self.EndFactor = ""
    ---积分合计
    self.TotalScore = 0
    ---本局获得BP经验
    self.BPExp = 0
    ---本局获得天赋经验
    self.StrengthPoint = 0
    ---本局拥有道具
    self.Items = {}
    ---上阵过的角色
    ---@type XTheatre3Character[]
    self.BattleCharacters = {}
    ---本局解锁藏品ID
    ---@type number[]
    self.CurUnlockItemId = {}
    ---已解锁装备ID
    ---@type number[]
    self.CurUnlockEquipId = {}
    ---是否需要在返回主界面时显示弹框
    self.IsNeedShowTip = false
end

function XTheatre3Settle:CheckIsEnding()
    return XTool.IsNumberValid(self.EndId)
end

function XTheatre3Settle:IsShowSettle()
    return XTool.IsNumberValid(self.NodeCount)
end

function XTheatre3Settle:NotifyTheatre3Settle(data)
    self.EndId = data.EndId
    self.NodeCount = data.NodeCount
    self.FightNodeCount = data.FightNodeCount
    self.ChapterCount = data.ChapterCount
    self.TotalItemCount = data.TotalItemCount
    self.TotalEquipCount = data.TotalEquipCount
    self.TotalSuitCount = data.TotalSuitCount
    self.NodeCountScore = data.NodeCountScore
    self.FightNodeCountScore = data.FightNodeCountScore
    self.ChapterCountScore = data.ChapterCountScore
    self.TotalItemCountScore = data.TotalItemCountScore
    self.TotalEquipCountScore = data.TotalEquipCountScore
    self.TotalSuitCountScore = data.TotalSuitCountScore
    self.EndFactor = data.EndFactor
    self.TotalScore = data.TotalScore
    self.BPExp = data.BPExp
    self.StrengthPoint = data.StrengthPoint
    self.CurUnlockItemId = data.CurUnlockItemId
    self.CurUnlockEquipId = data.CurUnlockEquipId
    self.IsNeedShowTip = true
    self.Items = data.Items
    self.BattleCharacters = {}
    for _, v in pairs(data.Characters) do
        if v.ExpTemp > 0 then
            table.insert(self.BattleCharacters, v)
        end
    end
end

return XTheatre3Settle