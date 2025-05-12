-- 待办事务
---@class XTheatre4Transaction
local XTheatre4Transaction = XClass(nil, "XTheatre4Transaction")

function XTheatre4Transaction:Ctor()
    -- 事务id 自增Id
    self.Id = 0
    -- 类型
    self.Type = 0
    -- 对应类型事务相关配置Id
    self.ConfigId = 0
    -- 内容参数
    ---@type number[]
    self.Params = {}
    -- 可招募角色
    ---@type XTheatre4CharacterData[]
    self.Characters = {}
    -- 掉落
    ---@type XTheatre4Asset[]
    self.Rewards = {}
    -- 已选下标
    ---@type number[]
    self.SelectIds = {}
    -- 最大可选次数
    self.SelectLimit = 0
    -- 剩余可选次数
    self.SelectTimes = 0
    -- 剩余刷新次数
    self.RefreshTimes = 0
    -- 最大刷新次数
    self.RefreshLimit = 0
end

-- 服务端通知
function XTheatre4Transaction:NotifyTransactionData(data)
    self.Id = data.Id or 0
    self.Type = data.Type or 0
    self.ConfigId = data.ConfigId or 0
    self.Params = data.Params or {}
    self:UpdateCharacters(data.Characters)
    self:UpdateRewards(data.Rewards)
    self.SelectIds = data.SelectIds or {}
    self.SelectLimit = data.SelectLimit or 0
    self.SelectTimes = data.SelectTimes or 0
    self.RefreshTimes = data.RefreshTimes or 0
    self.RefreshLimit = data.RefreshLimit or 0
end

function XTheatre4Transaction:UpdateCharacters(data)
    self.Characters = {}
    if not data then
        return
    end
    for k, v in pairs(data) do
        self:AddCharacter(k, v)
    end
end

function XTheatre4Transaction:AddCharacter(index, data)
    if not data then
        return
    end
    ---@type XTheatre4CharacterData
    local character = require("XModule/XTheatre4/XEntity/XTheatre4CharacterData").New()
    character:NotifyCharacterData(data)
    self.Characters[index] = character
end

function XTheatre4Transaction:UpdateRewards(data)
    self.Rewards = {}
    if not data then
        return
    end
    for k, v in pairs(data) do
        self:AddReward(k, v)
    end
end

function XTheatre4Transaction:AddReward(index, data)
    if not data then
        return
    end
    ---@type XTheatre4Asset
    local reward = require("XModule/XTheatre4/XEntity/XTheatre4Asset").New()
    reward:NotifyAssetData(data)
    self.Rewards[index] = reward
end

-- 添加已选下标
function XTheatre4Transaction:AddSelectId(index)
    table.insert(self.SelectIds, index)
end

-- 事务id
function XTheatre4Transaction:GetId()
    return self.Id
end

-- 获取类型
function XTheatre4Transaction:GetType()
    return self.Type
end

-- 获取配置Id
function XTheatre4Transaction:GetConfigId()
    return self.ConfigId
end

-- 获取内容参数
function XTheatre4Transaction:GetParams()
    return self.Params
end

-- 获取可招募角色
---@return XTheatre4CharacterData[]
function XTheatre4Transaction:GetCharacters()
    return self.Characters
end

-- 获取掉落
---@return XTheatre4Asset[]
function XTheatre4Transaction:GetRewards()
    return self.Rewards
end

-- 获取已选下标
function XTheatre4Transaction:GetSelectIds()
    return self.SelectIds
end

-- 获取最大可选次数
function XTheatre4Transaction:GetSelectLimit()
    return self.SelectLimit
end

-- 获取剩余可选次数
function XTheatre4Transaction:GetSelectTimes()
    return self.SelectTimes
end

-- 获取剩余刷新次数
function XTheatre4Transaction:GetRefreshTimes()
    return self.RefreshTimes
end

-- 获取最大刷新次数
function XTheatre4Transaction:GetRefreshLimit()
    return self.RefreshLimit
end

return XTheatre4Transaction
