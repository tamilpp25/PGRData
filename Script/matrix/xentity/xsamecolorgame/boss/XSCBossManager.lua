local SCBoss = require("XEntity/XSameColorGame/Boss/XSCBoss")

---@class XSCBossManager
local XSCBossManager = XClass(nil, "XSCBossManager")

function XSCBossManager:Ctor()
    self.BossDic = {}
    -- XSCBoss
    self.CurrentChallengeBoss = nil
end

-- data : List<XSameColorGameBossRecord>
function XSCBossManager:InitWithServerData(data)
    local boss
    for _, bossData in ipairs(data) do
        boss = self:GetBoss(bossData.BossId)
        boss:InitWithServerData(bossData)
    end
end

function XSCBossManager:SetCurrentChallengeBoss(value)
    self.CurrentChallengeBoss = value
end

function XSCBossManager:GetCurrentChallengeBoss()
    return self.CurrentChallengeBoss
end

---获取所有boss
---@return XSCBoss[]
function XSCBossManager:GetBosses(checkIsTime)
    if checkIsTime == nil then checkIsTime = false end
    local bossConfigDic = XSameColorGameConfigs.GetBossConfigDic()
    local result = {}
    local boss
    for id, config in pairs(bossConfigDic) do
        boss = self:GetBoss(id)
        if checkIsTime then
            if boss:GetIsInTime() then
                table.insert(result, boss)
            end
        else
            table.insert(result, boss)
        end
    end
    -- 排序，按id字段从小到大排序
    table.sort(result, function(bossA, bossB)
        return bossA:GetId() < bossB:GetId()
    end)
    return result
end

-- 根据id获取指定boss
function XSCBossManager:GetBoss(id)
    local result = self.BossDic[id]
    if result == nil then
        result = SCBoss.New(id)
        self.BossDic[id] = result
    end
    return result
end

return XSCBossManager