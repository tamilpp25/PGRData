local CHIP_FILTER_TYPE = XDlcHuntChipConfigs.CHIP_FILTER_TYPE
local CHIP_FILTER_IGNORE = XDlcHuntChipConfigs.CHIP_FILTER_IGNORE

---@class XDlcHuntChip
local XDlcHuntChip = XClass(nil, "XDlcHuntChip")

function XDlcHuntChip:Ctor()
    --唯一id
    self._Uid = false
    --配置id
    self._Id = false
    self._BreakthroughTimes = 0
    self._Level = 1
    self._CreateTime = 0
    self._IsLock = false
    self._Exp = 0
    self._PlayerId = false
    self._PlayerName = ""
    self._FromType = 0
end

function XDlcHuntChip:Reset()
    self._Uid = false
    self._Id = false
    self._BreakthroughTimes = 0
    self._Level = 1
    self._CreateTime = 0
    self._IsLock = false
    self._Exp = 0
    self._PlayerId = false
    self._PlayerName = ""
    self._FromType = 0
end

---@alias XDlcChipData {Id:number,TemplateId:number,Level:number,Exp:number,Breakthrough:number,IsLock:boolean,CreateTime:number}
---@param data XDlcChipData
function XDlcHuntChip:SetData(data)
    if not data then
        self:Reset()
        return
    end
    self._Uid = data.Id
    self._Id = data.TemplateId
    self._Level = data.Level
    self._Exp = data.Exp
    self._BreakthroughTimes = data.Breakthrough
    self._IsLock = data.IsLock
    self._CreateTime = data.CreateTime
end

function XDlcHuntChip:IsMyChip()
    return self._PlayerId == XPlayer.Id
            and self._FromType == 0
end

function XDlcHuntChip:SetUid(uid)
    self._Uid = uid
end

function XDlcHuntChip:IsEmpty()
    return not XDlcHuntChipConfigs.IsExist(self:GetId())
end

function XDlcHuntChip:GetId()
    return self._Id
end

function XDlcHuntChip:SetId(id)
    self._Id = id
end

function XDlcHuntChip:GetLevel()
    return self._Level
end

function XDlcHuntChip:SetLevel(level)
    self._Level = level
end

function XDlcHuntChip:GetBreakthroughTimes()
    return self._BreakthroughTimes
end

function XDlcHuntChip:SetBreakthroughTimes(breakthroughTimes)
    self._BreakthroughTimes = breakthroughTimes
end

function XDlcHuntChip:GetName()
    return XDlcHuntChipConfigs.GetChipName(self:GetId())
end

function XDlcHuntChip:GetIcon()
    return XDlcHuntChipConfigs.GetChipIcon(self:GetId())
end

--排序规则：
--a）默认排序：星级→突破次数→等级→芯片ID大小
--b）当选择 星级/突破/等级 时，在默认排序外再嵌套一层，优先以选择的来排序
--c）最近：记录的芯片获取的时间
function XDlcHuntChip:GetPriority(filterType)
    filterType = filterType or CHIP_FILTER_TYPE.STAR
    if filterType == CHIP_FILTER_TYPE.RECENTLY then
        return self:GetCreateTime()
    end

    local star = self:GetStarAmount()
    local breakthroughTimes = self:GetBreakthroughTimes()
    local level = self:GetLevel()
    local id = self:GetId()
    -- bug by zlb 如果id的值较大后，就会出问题~~
    if filterType == CHIP_FILTER_TYPE.STAR then
        local result = 0
        result = result | star

        result = result << 6
        result = result | breakthroughTimes

        result = result << 6
        result = result | level

        result = result << 27
        result = result | id

        return result
    end
    if filterType == CHIP_FILTER_TYPE.BREAKTHROUGH then
        local result = 0
        result = result | breakthroughTimes

        result = result << 6
        result = result | star

        result = result << 6
        result = result | level

        result = result << 27
        result = result | id

        return result
    end
    if filterType == CHIP_FILTER_TYPE.LEVEL then
        local result = 0
        result = result | level

        result = result << 6
        result = result | star

        result = result << 6
        result = result | breakthroughTimes

        result = result << 27
        result = result | id

        return result
    end
    if filterType == CHIP_FILTER_TYPE.EXP then
        local exp = self:GetOfferExp()
        local result = 0
        result = result | exp

        result = result << 6
        result = result | (0x3f - star)

        result = result << 27
        result = result | id

        result = result << 6
        result = result | self:GetUid()

        return result
    end
    if filterType == CHIP_FILTER_TYPE.COST_BREAKTHROUGH then
        local result = 0
        result = result | (0x3f - breakthroughTimes)

        result = result << 6
        result = result | (0x3f - level)

        result = result << 27
        result = result | (0x7ffffff - id)

        return result
    end
    XLog.Error("[XDlcHuntChip] filter type is undefined")
    return self:GetId()
end

function XDlcHuntChip:GetAttrTable()
    return XDlcHuntChipConfigs.GetChipAttrTable(self:GetId(), self:GetLevel(), self:GetBreakthroughTimes())
end

function XDlcHuntChip:GetAttrTableLvUp()
    return XDlcHuntChipConfigs.GetChipAttrTableLvUp(self:GetId(), self:GetLevel(), self:GetBreakthroughTimes())
end

function XDlcHuntChip:GetAttrValue(attrId)
    local attrTable = self:GetAttrTable()
    return attrTable[attrId] or 0
end

function XDlcHuntChip:GetAttrTableBreakthrough()
    return XDlcHuntChipConfigs.GetChipAttrTableBreakthrough(self:GetId())
end

function XDlcHuntChip:GetStarAmount()
    return XDlcHuntChipConfigs.GetChipQuality(self:GetId())
end

function XDlcHuntChip:GetFightingPower()
    return XDlcHuntAttrConfigs.GetFightingPower(self:GetAttrTable())
end

function XDlcHuntChip:GetCreateTime()
    return self._CreateTime
end

function XDlcHuntChip:IsMaxLevel()
    return self:GetLevel() >= XDlcHuntChipConfigs.GetChipMaxLevel(self:GetId(), self:GetBreakthroughTimes())
end

function XDlcHuntChip:GetMaxLevel()
    return XDlcHuntChipConfigs.GetChipMaxLevel(self:GetId(), self:GetBreakthroughTimes())
end

function XDlcHuntChip:GetTextBreakthrough()
    return XDlcHuntChipConfigs.GetTextBreakthrough(self)
end

function XDlcHuntChip:GetMaxBreakthroughTimes()
    return XDlcHuntChipConfigs.GetChipMaxBreakthroughTimes(self:GetId())
end

function XDlcHuntChip:IsMaxBreakthroughTimes()
    return self:GetBreakthroughTimes() >= self:GetMaxBreakthroughTimes()
end

---@param condition XDlcHuntFilterCondition
function XDlcHuntChip:IsMatch(condition)
    if condition.Ignore & CHIP_FILTER_IGNORE.SUB ~= 0 then
        if not self:IsSubChip() then
            return false
        end
    end
    if condition.Ignore & CHIP_FILTER_IGNORE.MAIN ~= 0 then
        if not self:IsMainChip() then
            return false
        end
    end
    if condition.Ignore & CHIP_FILTER_IGNORE.EQUIP ~= 0 then
        local groupId = condition.ChipGroupId
        local group = XDataCenter.DlcHuntChipManager.GetChipGroup(groupId)
        if group then
            return not group:IsContain(self)
        end
    end
    if condition.Ignore & CHIP_FILTER_IGNORE.LOCK ~= 0 then
        if self:IsLock() then
            return false
        end
    end
    if condition.Ignore & CHIP_FILTER_IGNORE.IN_USE ~= 0 then
        if self:IsInUse() then
            return false
        end
    end
    local conditionStar = 1 << self:GetStarAmount()
    if condition.Star & conditionStar == 0 then
        return false
    end
    return true
end

function XDlcHuntChip:IsMainChip()
    return XDlcHuntChipConfigs.IsMainChip(self:GetId())
end

function XDlcHuntChip:IsSubChip()
    return XDlcHuntChipConfigs.IsSubChip(self:GetId())
end

function XDlcHuntChip:GetType()
    return XDlcHuntChipConfigs.GetChipType(self:GetId())
end

function XDlcHuntChip:IsLock()
    return self._IsLock
end

function XDlcHuntChip:SetIsLock(value)
    self._IsLock = value
end

function XDlcHuntChip:IsInUse()
    local groups = XDataCenter.DlcHuntChipManager.GetAllChipGroup()
    for id, chipGroup in pairs(groups) do
        if chipGroup:IsContain(self) then
            return true
        end
    end
    return false
end

function XDlcHuntChip:GetUid()
    return self._Uid
end

---@param chip XDlcHuntChip
function XDlcHuntChip:Equals(chip)
    if not chip then
        return false
    end
    return self:GetUid() == chip:GetUid()
            and self:GetPlayerId() == chip:GetPlayerId()
            and self:GetFromType() == chip:GetFromType()
end

---@return {ItemId:number, ItemCount:number}
function XDlcHuntChip:GetDecomposeResult()
    return XDlcHuntChipConfigs.GetChipResolveItem(self)
end

function XDlcHuntChip:GetModel()
    return XDlcHuntChipConfigs.GetChipModel(self:GetId())
end

function XDlcHuntChip:GetOfferExp()
    return XDlcHuntChipConfigs.GetChipGetOfferExp(self)
end

function XDlcHuntChip:GetExp()
    return self._Exp
end

function XDlcHuntChip:SetExp(exp)
    self._Exp = exp
end

function XDlcHuntChip:GetExpMaxToNextLevel()
    return XDlcHuntChipConfigs.GetChipLevelUpExp(self:GetId(), self:GetLevel(), self:GetBreakthroughTimes())
end

function XDlcHuntChip:GetExpMaxWithThisLevel()
    return XDlcHuntChipConfigs.GetChipLevelUpExp(self:GetId(), self:GetLevel() - 1, self:GetBreakthroughTimes())
end

function XDlcHuntChip:GetExpMaxWithMaxLevel()
    return XDlcHuntChipConfigs.GetChipLevelUpExp(self:GetId(), math.huge, self:GetBreakthroughTimes())
end

---@return DlcHuntChipBreakthroughCost[]
function XDlcHuntChip:GetCostBreakthrough()
    return XDlcHuntChipConfigs.GetCostBreakthrough(self)
end

function XDlcHuntChip:GetIconBreakthrough()
    local breakthroughTimes = self:GetBreakthroughTimes()
    return XDlcHuntConfigs.GetIconBreakthrough(breakthroughTimes)
end

-- 反色系的突破图标
function XDlcHuntChip:GetIconBreakthroughColorInverse()
    local breakthroughTimes = self:GetBreakthroughTimes()
    return XDlcHuntConfigs.GetIconBreakthrough2(breakthroughTimes)
end

function XDlcHuntChip:IsValid()
    local uid = self:GetUid()
    if XDataCenter.DlcHuntChipManager.GetChip(uid) then
        return true
    end
    return false
end

function XDlcHuntChip:GetMagicEventIds()
    local magicEventIds = XDlcHuntChipConfigs.GetMagicEventIds(self)
    return magicEventIds
end

function XDlcHuntChip:GetMagicLevel()
    local magicLevel = XDlcHuntChipConfigs.GetMagicLevel(self)
    return magicLevel
end

function XDlcHuntChip:GetMagicDesc()
    local magicEventIds = self:GetMagicEventIds()
    local result = {}
    for i = 1, #magicEventIds do
        local magicId = magicEventIds[i]
        local name = XDlcHuntChipConfigs.GetMagicName(magicId)
        local type = XDlcHuntChipConfigs.GetMagicType(magicId)
        local desc, descParams = XDlcHuntChipConfigs.GetMagicDesc(magicId)
        local descWithParam = CS.XTextManager.FormatString(desc, table.unpack(descParams))
        result[#result + 1] = {
            Name = name,
            Desc = descWithParam,
            DescWithoutValue = desc,
            Params = descParams,
            Type = type
        }
    end
    return result
end

function XDlcHuntChip:GetMagicDescIncludePreview()
    local result = {}

    local magicDesc = self:GetMagicDesc()
    local magic = magicDesc[1]
    if magic then
        result[1] = magic
        magic.IsActive = true
    end

    local magic2 = magicDesc[2]
    local isActive = true
    if not self:IsMaxBreakthroughTimes() then
        local chipVirtual = self:Clone()
        for i = 1, 9999 do
            -- 找下一级
            chipVirtual:SetBreakthroughTimes(self:GetBreakthroughTimes() + i)
            local magicDescVirtual = chipVirtual:GetMagicDesc()
            magic2 = magicDescVirtual[2]
            if magic2 then
                isActive = false
                break
            end
            if chipVirtual:IsMaxBreakthroughTimes() then
                break
            end
        end
    end
    if magic2 then
        result[#result + 1] = magic2
        magic2.IsActive = isActive
    end
    return result
end

function XDlcHuntChip:GetColor()
    return XDlcHuntChipConfigs.GetChipQualityColor(self)
end

function XDlcHuntChip:SetPlayerId(playerId)
    self._PlayerId = playerId
end

-- 不来自玩家，来自配置
function XDlcHuntChip:SetFromConfig()
    self:SetPlayerId(-1)
    self:SetPlayerName("")
    self:SetFromType(XDlcHuntChipConfigs.ASSISTANT_CHIP_FROM.CONFIG)
end

function XDlcHuntChip:IsFromConfig()
    return self:GetPlayerId() == -1
            and self:GetPlayerName() == ""
end

function XDlcHuntChip:SetPlayerName(playerName)
    self._PlayerName = playerName
end

function XDlcHuntChip:GetPlayerId()
    return self._PlayerId
end

function XDlcHuntChip:GetPlayerName()
    return self._PlayerName
end

-- 可作为支援芯片
function XDlcHuntChip:IsCanAssistant()
    return self:IsMainChip()
end

-- 已设置为支援芯片
function XDlcHuntChip:HasSetAsAssistantChip2Others()
    local chipAssistant = XDataCenter.DlcHuntChipManager.GetAssistantChip2Others()
    return self:Equals(chipAssistant)
end

function XDlcHuntChip:SetFromType(fromType)
    self._FromType = fromType
end

function XDlcHuntChip:GetFromType()
    return self._FromType
end

function XDlcHuntChip:GetAssistantPoint()
    if self._FromType == XDlcHuntChipConfigs.ASSISTANT_CHIP_FROM.FRIEND then
        return XDlcHuntConfigs.GetAssistantPointFromFriend()
    end
    if self._FromType == XDlcHuntChipConfigs.ASSISTANT_CHIP_FROM.TEAMMATE then
        return XDlcHuntConfigs.GetAssistantPointFromTeammate()
    end
    if self._FromType == XDlcHuntChipConfigs.ASSISTANT_CHIP_FROM.RANDOM then
        return XDlcHuntConfigs.GetAssistantPointFromRandom()
    end
    return 0
end

function XDlcHuntChip:GetEffect()
    return XDlcHuntConfigs.GetChipEffect(self:GetStarAmount())
end

function XDlcHuntChip:_GetUiSubEffect()
    return XDlcHuntConfigs.GetChipSubEffect(self:GetStarAmount())
end

function XDlcHuntChip:_GetUiMainEffect()
    return XDlcHuntConfigs.GetChipMainEffect(self:GetStarAmount())
end

function XDlcHuntChip:GetEffectUiChipMain()
    if self:IsMainChip() then
        return self:_GetUiMainEffect()
    end
    return self:_GetUiSubEffect()
end

function XDlcHuntChip:IsVirtual()
    return self._Uid <= 0
end

---@return XDlcHuntChip
function XDlcHuntChip:Clone()
    local chip = XDlcHuntChip.New()
    chip._Uid = self._Uid
    chip._Id = self._Id
    chip._BreakthroughTimes = self._BreakthroughTimes
    chip._Level = self._Level
    chip._CreateTime = self._CreateTime
    chip._IsLock = self._IsLock
    chip._Exp = self._Exp
    chip._PlayerId = self._PlayerId
    chip._PlayerName = self._PlayerName
    return chip
end

return XDlcHuntChip