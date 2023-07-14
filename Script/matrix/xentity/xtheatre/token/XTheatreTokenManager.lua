local XTheatreToken = require("XEntity/XTheatre/Token/XTheatreToken")
local XAdventureSkill = require("XEntity/XTheatre/Adventure/XAdventureSkill")

local Default = {
    _SkillIllustratedBook = {}, --已解锁的技能图鉴字典，存的是TheatreSkill表的Id
    _Keepsakes = {}, --已解锁的信物
    _UnlockTokenLevelDic = {}, --已解锁的信物的当前等级字典
    _UnlockTokenCurLvToIdDic = {}, --已解锁的当前等级的信物对应的TheatreItem表的Id
    _SkillPowerAndPosToSkillIdDic = {}, --已解锁的核心技能当前势力和位置对应的TheatreSkill表的Id（相同势力相同位置的核心技能只会存最高等级的Id）
}

-- 信物（道具）和技能图鉴管理
local XTheatreTokenManager = XClass(nil, "XTheatreTokenManager")

function XTheatreTokenManager:Ctor()
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
end

function XTheatreTokenManager:UpdateData(data)
    self:UpdateSkillPowerAndPosToSkillIdDic(data.SkillIllustratedBook)

    if not self.TokenDic then
        self:InitAllToken()
    end

    for _, v in ipairs(data.Keepsakes) do
        self:UpdateKeepsake(v)
    end
end

function XTheatreTokenManager:UpdateSkillPowerAndPosToSkillIdDic(skillIllustratedBook)
    local powerId
    local pos
    local curTheatreSkillId
    local curSkillLv    --已存在字典里的技能等级
    local skillLv

    for _, theatreSkillId in pairs(skillIllustratedBook) do
        self._SkillIllustratedBook[theatreSkillId] = true

        powerId = XTheatreConfigs.GetTheatreSkillPowerId(theatreSkillId)
        pos = XTheatreConfigs.GetTheatreSkillPos(theatreSkillId)
        if XTool.IsNumberValid(pos) then
            if not self._SkillPowerAndPosToSkillIdDic[powerId] then
                self._SkillPowerAndPosToSkillIdDic[powerId] = {}
            end

            curTheatreSkillId = self._SkillPowerAndPosToSkillIdDic[powerId][pos]
            curSkillLv = curTheatreSkillId and XTheatreConfigs.GetTheatreSkillLv(curTheatreSkillId) or 0
            skillLv = XTheatreConfigs.GetTheatreSkillLv(theatreSkillId)
            if curSkillLv < skillLv then
                self._SkillPowerAndPosToSkillIdDic[powerId][pos] = theatreSkillId
            end
        end
    end
end

function XTheatreTokenManager:UpdateKeepsake(keepsakeData)
    table.insert(self._Keepsakes, keepsakeData)

    if not self.TokenDic or not self.TokenKeepsakeIdAndLvDic then
        self:InitAllToken()
    end

    local keepsakeId = keepsakeData.KeepsakeId  --信物id, TheatreItem表的KeepsakeId
    local lv = keepsakeData.Lv
    local theatreItemId = self.TokenKeepsakeIdAndLvDic[keepsakeId][lv]
    local theatreKeepsake = theatreItemId and self.TokenDic[theatreItemId]
    if not theatreKeepsake then
        return
    end

    theatreKeepsake:UpdateData(keepsakeData)
    if not self._UnlockTokenLevelDic[keepsakeId] or self._UnlockTokenLevelDic[keepsakeId] < lv then
        self._UnlockTokenLevelDic[keepsakeId] = lv
        self._UnlockTokenCurLvToIdDic[keepsakeId] = theatreKeepsake:GetId()
    end
end

--更新等级和携带信物战斗次数
function XTheatreTokenManager:UpdateKeepsakeLv(data)
    if not self.TokenDic or not self.TokenKeepsakeIdAndLvDic then
        self:InitAllToken()
    end

    local keepsakeId = data.KeepsakeId  --信物id, TheatreItem表的KeepsakeId
    local lv = data.Lv
    local theatreItemId = self.TokenKeepsakeIdAndLvDic[keepsakeId][lv]
    local theatreKeepsake = theatreItemId and self.TokenDic[theatreItemId]
    if not theatreKeepsake then
        return
    end

    theatreKeepsake:UpdateData(data)
    if not self._UnlockTokenLevelDic[keepsakeId] or self._UnlockTokenLevelDic[keepsakeId] < lv then
        self._UnlockTokenLevelDic[keepsakeId] = lv
        self._UnlockTokenCurLvToIdDic[keepsakeId] = theatreKeepsake:GetId()
    end

    self:UpdateCurAdventureToken(data)
end

function XTheatreTokenManager:UpdateCurAdventureToken(data)
    --更新局内携带中的信物
    local adventureManager = XDataCenter.TheatreManager.GetCurrentAdventureManager()
    if not adventureManager then
        return
    end

    local currToken = adventureManager:GetCurrentToken()
    if not currToken then
        return
    end

    local curKeepsakeId = currToken:GetKeepsakeId()
    if curKeepsakeId ~= data.KeepsakeId then
        return
    end

    local tokenId = XDataCenter.TheatreManager.GetTokenManager():GetTokenId(data.KeepsakeId)
    adventureManager:UpdateCurrentToken(XTheatreToken.New(tokenId))
end

function XTheatreTokenManager:InitAllToken()
    if self.TokenList and self.TokenDic and self.TokenKeepsakeIdAndLvDic then
        return
    end

    self.TokenList = {}
    self.TokenDic = {}
    self.TokenKeepsakeIdAndLvDic = {}   --TheatreItem表的KeepsakeId和等级，对应的TheatreItem表Id
    local configs = XTheatreConfigs.GetTheatreItem()
    for id, v in pairs(configs) do
        local template = XTheatreToken.New(id)
        self.TokenDic[id] = template
        table.insert(self.TokenList, template)

        if XTool.IsNumberValid(v.KeepsakeId) then
            if not self.TokenKeepsakeIdAndLvDic[v.KeepsakeId] then
                self.TokenKeepsakeIdAndLvDic[v.KeepsakeId] = {}
            end
            self.TokenKeepsakeIdAndLvDic[v.KeepsakeId][v.Lv] = id
        end
    end
end

--获得所有信物和道具
--isOnlyShowCurLevelToken：是否只显示当前等级且已激活的信物
function XTheatreTokenManager:GetAllToken(isOnlyShowCurLevelToken)
    if not self.TokenList then
        self:InitAllToken()
    end

    local isInsertKeepsakeDic = {}
    local tokenList = {}
    if not isOnlyShowCurLevelToken then
        for _, token in ipairs(self.TokenList) do
            --信物已激活时只显示当前等级，未激活显示最低等级
            local keepsakeId = token:GetKeepsakeId()
            if (not token:IsToken()) or 
                (not self._UnlockTokenCurLvToIdDic[keepsakeId] and XTheatreConfigs.GetTheatreMinLvTheatreItemId(keepsakeId) == token:GetId()) or 
                self._UnlockTokenCurLvToIdDic[keepsakeId] == token:GetId() then
                    table.insert(tokenList, token)
            end
        end
    else
        for _, token in ipairs(self.TokenList) do
            if token:IsToken() and self._UnlockTokenCurLvToIdDic[token:GetKeepsakeId()] == token:GetId() then
                table.insert(tokenList, token)
            end
        end
    end

    table.sort(tokenList, function(tokenA, tokenB)
        --已解锁优先
        local isActiveA = tokenA:IsActive()
        local isActiveB = tokenB:IsActive()
        if isActiveA ~= isActiveB then
            return isActiveA
        end

        --按照类型由小到大排序
        local typeA = tokenA:GetType()
        local typeB = tokenB:GetType()
        if typeA ~= typeB then
            return typeA < typeB
        end

        return tokenA:GetId() < tokenB:GetId()
    end)

    return tokenList
end

--返回和势力Id相同的技能列表，powerId为0或nil时返回所有技能Id
function XTheatreTokenManager:GetSkillTemplateList(powerId)
    local isFilter = XTool.IsNumberValid(powerId)
    local config = XTheatreConfigs.GetTheatreSkill()
    local skillTemplateList = {}
    for _, v in pairs(config) do
        if not isFilter or v.PowerId == powerId then
            table.insert(skillTemplateList, XAdventureSkill.New(v.Id))
        end
    end

    table.sort(skillTemplateList, function(a, b)
        local idA = a:GetId()
        local idB = b:GetId()

        --是否已解锁
        local isActiveA = self:IsActiveSkill(idA)
        local isActiveB = self:IsActiveSkill(idB)
        if isActiveA ~= isActiveB then
            return isActiveA
        end

        --是否核心增益
        local skillTypeA = a:GetSkillType()
        local skillTypeB = b:GetSkillType()
        if skillTypeA ~= skillTypeB then
            if skillTypeA == XTheatreConfigs.SkillType.Core then
                return true
            end
            if skillTypeB == XTheatreConfigs.SkillType.Core then
                return false
            end
        end

        --势力由小到大
        local powerIdA = a:GetPowerId()
        local powerIdB = b:GetPowerId()
        if powerIdA ~= powerIdB then
            return powerIdA < powerIdB
        end

        return idA < idB
    end)
    return skillTemplateList
end

function XTheatreTokenManager:IsActiveSkill(theatreSkillId)
    if self._SkillIllustratedBook[theatreSkillId] then
        return true
    end

    --比激活的相同势力相同位置的核心技能等级小的都判断激活
    local powerId = XTheatreConfigs.GetTheatreSkillPowerId(theatreSkillId)
    local pos = XTheatreConfigs.GetTheatreSkillPos(theatreSkillId)
    local activeTheatreSkillId = self:GetTheatreSkillIdByPowerIdAndPos(powerId, pos)
    if activeTheatreSkillId then
        local activeSkillLv = XTheatreConfigs.GetTheatreSkillLv(activeTheatreSkillId)
        local skillLv = XTheatreConfigs.GetTheatreSkillLv(theatreSkillId)
        if skillLv <= activeSkillLv then
            return true
        end
    end

    --局内激活技能
    local adventureManager = XDataCenter.TheatreManager.GetCurrentAdventureManager()
    if adventureManager then
        local currSkills = adventureManager:GetCurrentSkills()
        for _, adventureSkill in ipairs(currSkills) do
            if adventureSkill:GetId() == theatreSkillId then
                return true
            end
        end
    end
    return false
end

function XTheatreTokenManager:GetTheatreSkillIdByPowerIdAndPos(powerId, pos)
    if not XTool.IsNumberValid(powerId) or not XTool.IsNumberValid(pos) then
        return
    end
    return self._SkillPowerAndPosToSkillIdDic[powerId] and self._SkillPowerAndPosToSkillIdDic[powerId][pos]
end

function XTheatreTokenManager:IsActiveToken(theatreItemId)
    if not self.TokenDic then
        self:InitAllToken()
    end
    local token = self.TokenDic[theatreItemId]
    return token and token:IsActive() or false
end

-- 检查是否有指定信物
-- id : 信物Id，若不传直接判断是否有任意信物
function XTheatreTokenManager:CheckHasToken(id)
    if id then
        return self:IsActiveToken(id)
    end
    return not XTool.IsTableEmpty(self._Keepsakes)
end

function XTheatreTokenManager:GetTokenId(keepsakeId)
    return self._UnlockTokenCurLvToIdDic[keepsakeId]
end

return XTheatreTokenManager