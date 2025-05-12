---@class XPcgCharacter
local XPcgCharacter = XClass(nil, "XPcgCharacter")

function XPcgCharacter:Ctor()
    -- QTE被触发中
    ---@type boolean
    self.IsQte = false
    -- 战场站位(进关卡时候的站位，后续切换站位这个字段是不会更新)
    ---@type number
    self.Idx = 0
    -- 角色Id(配置表Id)
    ---@type number
    self.Id = 0
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

function XPcgCharacter:RefreshData(data)
    self.IsQte = data.IsQte or false
    self.Idx = data.Idx or 0
    self.Id = data.Id or 0
    self.Hp = data.Hp or 0
    self.Armor = data.Armor or 0
    self:RefreshTokensData(data.Tokens)
end

function XPcgCharacter:RefreshTokensData(tokenDatas)
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

function XPcgCharacter:GetsIsQte()
    return self.IsQte
end

function XPcgCharacter:GetIdx()
    return self.Idx
end

function XPcgCharacter:GetId()
    return self.Id
end

function XPcgCharacter:GetHp()
    return self.Hp
end

function XPcgCharacter:GetArmor()
    return self.Armor
end

function XPcgCharacter:GetTokens()
    return self.Tokens
end

return XPcgCharacter