---@class XLuckyTenantRandomPool
local XLuckyTenantRandomPool = XClass(nil, "XLuckyTenantRandomPool")

function XLuckyTenantRandomPool:Ctor()
    self._TypeQuality = {}
    self._TypeQualityId = {}
    self._Type = {}
    self._Uid = 0
end

---@param model XLuckyTenantModel
function XLuckyTenantRandomPool:Init(model)
    local pieces = model:GetLuckyTenantChessConfigs()
    for i, config in pairs(pieces) do
        self._TypeQuality[config.Type] = self._TypeQuality[config.Type] or {}
        if not self._TypeQuality[config.Type][config.Quality] then
            self._Uid = self._Uid + 1
            self._TypeQuality[config.Type][config.Quality] = {}
            self._TypeQualityId[config.Type] = self._TypeQualityId[config.Type] or {}
            self._TypeQualityId[config.Type][config.Quality] = self._TypeQualityId[config.Type][config.Quality] or {}
        end
        local bucket = self._TypeQuality[config.Type][config.Quality]
        bucket[#bucket + 1] = config.Id
    end

    for i, config in pairs(pieces) do
        self._Type[config.Type] = self._Type[config.Type] or {}
        local bucket = self._Type[config.Type]
        bucket[#bucket + 1] = config.Id
    end
end

function XLuckyTenantRandomPool:GetRandomBucket(pieceType, pieceQuality)
    if not self._TypeQuality[pieceType] then
        return false
    end
    if not self._TypeQualityId[pieceType] then
        return false
    end

    local bucket = self._TypeQuality[pieceType][pieceQuality]
    local id = self._TypeQualityId[pieceType][pieceQuality]
    return bucket, id
end

function XLuckyTenantRandomPool:GetRandomPieceIdByType(type)
    local bucket = self._Type[type]
    if not bucket then
        return false
    end
    return bucket[math.random(1, #bucket)]
end

function XLuckyTenantRandomPool:GetRandomPieceIdByTypeExceptSelf(type, pieceIdExcept)
    local bucket = self._Type[type]
    if not bucket then
        return false
    end
    local index = math.random(1, #bucket)
    local pieceId = bucket[index]
    if pieceId == pieceIdExcept then
        index = math.random(1, #bucket - 1)
        if pieceId == pieceIdExcept then
            pieceId = bucket[#bucket]
        end
    end
    return pieceId
end

function XLuckyTenantRandomPool:GetRandomPieceIdBy2Type(type1, type2)
    local bucket1 = self._Type[type1]
    if not bucket1 then
        return self:GetRandomPieceIdByType(type2)
    end
    local bucket2 = self._Type[type2]
    if not bucket2 then
        return self:GetRandomPieceIdByType(type1)
    end
    local amount1 = #bucket1
    local amount2 = #bucket2
    local index = math.random(1, amount1 + amount2)
    if index == 0 then
        return false
    end
    if index > amount1 then
        return bucket2[index - amount1]
    end
    return bucket1[index]
end

function XLuckyTenantRandomPool:GetRandomPieceId(pieceType)
    local bucket = self._Type[pieceType]
    if bucket then
        return bucket[math.random(1, #bucket)]
    end
    return bucket
end

return XLuckyTenantRandomPool