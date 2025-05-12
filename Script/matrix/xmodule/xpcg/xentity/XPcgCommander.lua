---@class XPcgCommander
local XPcgCommander = XClass(nil, "XPcgCommander")

function XPcgCommander:Ctor()
    -- 指挥官技能点
    ---@type number
    self.Energy = 0
    -- 当前剩余行动点
    ---@type number
    self.ActionPoint = 0
    -- 当前重启次数
    ---@type number
    self.Reboot = 0
    -- 目标怪物索引
    ---@type number
    self.TargetMonsterIdx = 0
    -- 血量
    ---@type number
    self.Hp = 0
    -- 护甲
    ---@type number
    self.Armor = 0
    -- 挂身上的token数据
    ---@type XPcgToken[]
    self.Tokens = {}
end

function XPcgCommander:RefreshData(data)
    self.Energy = data.Energy or 0
    self.ActionPoint = data.ActionPoint or 0
    self.Reboot = data.Reboot or 0
    self.TargetMonsterIdx = data.TargetMonsterIdx or 0
    self.Hp = data.Hp or 0
    self.Armor = data.Armor or 0
    self:RefreshTokensData(data.Tokens)
end

function XPcgCommander:RefreshTokensData(tokenDatas)
    self.Tokens = {}
    if not tokenDatas or #tokenDatas == 0 then return end

    local XPcgToken = require("XModule/XPcg/XEntity/XPcgToken")
    for _, tokenData in ipairs(tokenDatas) do
        ---@type XPcgToken
        local token = XPcgToken.New()
        token:RefreshData(tokenData)
        table.insert(self.Tokens, token)
    end
end

function XPcgCommander:GetEnergy()
    return self.Energy
end

function XPcgCommander:GetActionPoint()
    return self.ActionPoint
end

function XPcgCommander:GetReboot()
    return self.Reboot
end

function XPcgCommander:GetTargetMonsterIdx()
    return self.TargetMonsterIdx
end

function XPcgCommander:GetHp()
    return self.Hp
end

function XPcgCommander:GetArmor()
    return self.Armor
end

function XPcgCommander:GetTokens()
    return self.Tokens
end

return XPcgCommander