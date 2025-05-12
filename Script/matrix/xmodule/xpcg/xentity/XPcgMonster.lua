---@class XPcgMonster
local XPcgMonster = XClass(nil, "XPcgMonster")

function XPcgMonster:Ctor()
    -- 战场站位
    ---@type number
    self.Idx = 0
    -- 怪物Id(配置表Id)
    ---@type number
    self.Id = 0
    -- 血量
    ---@type number
    self.Hp = 0
    -- 护甲
    ---@type number
    self.Armor = 0
    -- 怪物行为预览列表
    ---@type XPcgBehaviorPreview[]
    self.BehaviorPreviews = {}
    -- 挂身上的token数据
    ---@type XPcgToken[]
    self.Tokens = {}
end

function XPcgMonster:RefreshData(data)
    self.Idx = data.Idx or 0
    self.Id = data.Id or 0
    self.Hp = data.Hp or 0
    self.Armor = data.Armor or 0
    self:RefreshBehaviorPreviews(data.BehaviorPreviews)
    self:RefreshTokensData(data.Tokens)
end

function XPcgMonster:RefreshBehaviorPreviews(behaviorDatas)
    self.BehaviorPreviews = {}
    if not behaviorDatas or #behaviorDatas == 0 then return end

    local XBehaviorPreview = require("XModule/XPcg/XEntity/XPcgBehaviorPreview")
    for _, data in ipairs(behaviorDatas) do
        ---@type XPcgBehaviorPreview
        local behavior = XBehaviorPreview.New()
        behavior:RefreshData(data)
        table.insert(self.BehaviorPreviews, behavior)
    end
end

function XPcgMonster:RefreshTokensData(tokenDatas)
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

function XPcgMonster:GetIdx()
    return self.Idx
end

function XPcgMonster:GetId()
    return self.Id
end

function XPcgMonster:GetHp()
    return self.Hp
end

function XPcgMonster:GetArmor()
    return self.Armor
end

function XPcgMonster:GetTokens()
    return self.Tokens
end

function XPcgMonster:GetBehaviorPreviews()
    return self.BehaviorPreviews
end

return XPcgMonster
