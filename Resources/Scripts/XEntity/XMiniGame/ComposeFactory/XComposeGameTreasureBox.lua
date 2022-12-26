-- 组合小游戏奖励宝箱
local XComposeGameTreasureBox = XClass(nil, "XComposeGameTreasureBox")

--==========构造函数，初始化，实体操作==========
--==================
--构造函数
--@param Progress:对应的宝箱列表对象
--@param Schedule:宝箱对应进度
--@param RewardId:宝箱奖励ID
--@param IsReceive:是否已领取
--==================
function XComposeGameTreasureBox:Ctor(Progress, Schedule, RewardId, IsReceive)
    self.Progress = Progress
    self:Init(Schedule, RewardId, IsReceive)
end
--==================
--初始化
--@param Schedule:宝箱对应进度
--@param RewardId:宝箱奖励ID
--@param IsReceive:是否已领取
--==================
function XComposeGameTreasureBox:Init(Schedule, RewardId, IsReceive)
    self.Schedule = Schedule or 0
    self.RewardId = RewardId or 0
    self.IsReceive = IsReceive == true
end
--=================== END =====================

--=================对外接口(Get,Set,Check等接口)================
--==================
--获取进度
--==================
function XComposeGameTreasureBox:GetSchedule()
    return self.Schedule or 0
end
--==================
--获取奖励ID
--==================
function XComposeGameTreasureBox:GetRewardId()
    return self.RewardId or 0
end
--==================
--检查是否可领取奖励
--==================
function XComposeGameTreasureBox:CheckCanReceive()
    return self.Progress:GetCurrentSchedule() >= self:GetSchedule() and not self:CheckIsReceive()
end
--==================
--检查是否已领取奖励
--==================
function XComposeGameTreasureBox:CheckIsReceive()
    return self.IsReceive
end
--==================
--设置领取奖励状态
--==================
function XComposeGameTreasureBox:SetIsReceive(isReceive)
    self.IsReceive = isReceive
end
--=================== END =====================
return XComposeGameTreasureBox