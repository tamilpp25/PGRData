XDlcHuntChipConfigs = XDlcHuntChipConfigs or {}
local XDlcHuntChipConfigs = XDlcHuntChipConfigs

XDlcHuntChipConfigs.CHIP_GROUP_AMOUNT = 0

-- 一个芯片组可以装多少芯片
XDlcHuntChipConfigs.CHIP_GROUP_CHIP_AMOUNT = 9

XDlcHuntChipConfigs.CHIP_STAR_AMOUNT = 6

XDlcHuntChipConfigs.CHIP_MAIN_AMOUNT = 1

XDlcHuntChipConfigs.CHIP_SUB_AMOUNT = 8

XDlcHuntChipConfigs.CHIP_MAIN_CAPACITY = 9999

XDlcHuntChipConfigs.CHIP_SUB_CAPACITY = 9999

XDlcHuntChipConfigs.ITEM_CAPACITY = 9999

XDlcHuntChipConfigs.CHIP_DECOMPOSE_AMOUNT = 30
XDlcHuntChipConfigs.CHIP_DECOMPOSE_DURATION = 0.2 * XScheduleManager.SECOND

XDlcHuntChipConfigs.STAR = {
    FOUR = 1 << 4,
    FIVE = 1 << 5,
    ALL = 0xffff,
}

-- 下拉框中的筛选条件包括：星级，等级，突破，最近
XDlcHuntChipConfigs.CHIP_FILTER_TYPE = {
    STAR = 1,
    BREAKTHROUGH = 2,
    LEVEL = 3,
    RECENTLY = 4,
    EXP = 5,
    COST_BREAKTHROUGH = 6,
    End = 7,
}

-- 升序，降序
XDlcHuntChipConfigs.CHIP_FILTER_ORDER = {
    ASC = 1, -- 升序 ascending order
    DESC = 2, -- 降序 descending order
}

-- 忽略
XDlcHuntChipConfigs.CHIP_FILTER_IGNORE = {
    NONE = 0,
    EQUIP = 1 << 0, --已装备
    MAIN = 1 << 1, --主芯片
    SUB = 1 << 2, --从属芯片
    LOCK = 1 << 3, --上锁
    IN_USE = 1 << 4, --未使用在芯片组里
}

-- 芯片类型
XDlcHuntChipConfigs.CHIP_TYPE = {
    MAIN = 1, -- 主芯片
    SUB = 2, -- 从属芯片
}

XDlcHuntChipConfigs.COST_TYPE = {
    SAME_CHIP = 0, -- 相同芯片
    MAIN_CHIP = 1, -- 主芯片
    SUB_CHIP = 2, -- 副芯片
    ALL = 3, -- 任意芯片
}

XDlcHuntChipConfigs.UI_DETAIL_TAB = {
    None = 0,
    DETAIL = 1,
    LEVEL_UP = 2,
    BREAKTHROUGH = 3
}

--突破消耗的材料类型
XDlcHuntChipConfigs.BREAKTHROUGH_COST_TYPE = {
    -- 相同芯片（templateId、突破等级相同）
    SameChipTemplateId = 0;
    -- 任意主控
    AnyMainChip = 1;
    -- 任意从属
    AnySubChip = 2;
    -- 任意芯片
    AnyChip = 3;
}

XDlcHuntChipConfigs.UI_BATCH_TAB = {
    MAIN = 1,
    SUB = 2,
}

XDlcHuntChipConfigs.ASSISTANT_CHIP_FROM = {
    FRIEND = 1,
    TEAMMATE = 2,
    RANDOM = 3,
    CONFIG = 4,
}

---@type XConfig
local _ConfigChipShare

---@type XConfig
local _ConfigChipClient

---@type XConfig
local _ConfigChipBreakthrough

---@type XConfig
local _ConfigLevelUpTemplate

---@type XConfig
local _ConfigMagic

---@type XConfig
local _ConfigChipAssistant

function XDlcHuntChipConfigs.Init()
end

local function __InitConfigChipShare()
    if not _ConfigChipShare then
        _ConfigChipShare = XConfig.New("Share/DlcHunt/Chip/DlcHuntChip.tab", XTable.XTableDlcHuntChip, "Id")
    end
end

local function __InitConfigChipClient()
    if not _ConfigChipClient then
        _ConfigChipClient = XConfig.New("Client/DlcHunt/Chip/DlcHuntChipClient.tab", XTable.XTableDlcHuntChipClient, "Id")
    end
end

local function __InitConfigChipBreakthrough()
    if not _ConfigChipBreakthrough then
        _ConfigChipBreakthrough = XConfig.New("Share/DlcHunt/Chip/DlcHuntChipBreakthrough.tab", XTable.XTableDlcHuntChipBreakThrough, "Id")
    end
end

local function __InitConfigLevelUpTemplate()
    if not _ConfigLevelUpTemplate then
        _ConfigLevelUpTemplate = XConfig.New("Share/DlcHunt/Chip/DlcHuntChipLevelUpTemplate.tab", XTable.XTableDlcHuntChipLevelUpTemplate, "Id")
    end
end

local function __InitConfigMagic()
    if not _ConfigMagic then
        _ConfigMagic = XConfig.New("Client/DlcHunt/Chip/DlcHuntChipMagic.tab", XTable.XTableDlcHuntChipMagic, "Id")
    end
end

local function __InitConfigChipAssistant()
    if not _ConfigChipAssistant then
        _ConfigChipAssistant = XConfig.New("Share/DlcHunt/Chip/DlcHuntChipAssist.tab", XTable.XTableDlcHuntChipAssist, "Id")
    end
end

function XDlcHuntChipConfigs.IsExist(chipId)
    __InitConfigChipShare()
    return _ConfigChipShare:TryGetConfig(chipId) ~= nil
end

function XDlcHuntChipConfigs.GetChipQuality(chipId)
    __InitConfigChipShare()
    return _ConfigChipShare:GetProperty(chipId, "Quality")
end

function XDlcHuntChipConfigs.IsMainChip(chipId)
    __InitConfigChipShare()
    return _ConfigChipShare:GetProperty(chipId, "Type") == XDlcHuntChipConfigs.CHIP_TYPE.MAIN
end

function XDlcHuntChipConfigs.IsSubChip(chipId)
    __InitConfigChipShare()
    return _ConfigChipShare:GetProperty(chipId, "Type") == XDlcHuntChipConfigs.CHIP_TYPE.SUB
end

function XDlcHuntChipConfigs.GetChipType(chipId)
    __InitConfigChipShare()
    return _ConfigChipShare:GetProperty(chipId, "Type")
end

function XDlcHuntChipConfigs.GetChipModel(chipId)
    __InitConfigChipClient()
    return _ConfigChipClient:GetProperty(chipId, "Model")
end

function XDlcHuntChipConfigs.GetChipName(chipId)
    __InitConfigChipClient()
    return _ConfigChipClient:GetProperty(chipId, "Name")
end

function XDlcHuntChipConfigs.GetChipIcon(chipId)
    __InitConfigChipClient()
    return _ConfigChipClient:GetProperty(chipId, "IconPath")
end

function XDlcHuntChipConfigs.GetChipPriority(chipId)
    __InitConfigChipClient()
    return _ConfigChipClient:GetProperty(chipId, "Priority")
end

---@param chip XDlcHuntChip
function XDlcHuntChipConfigs.GetTextBreakthrough(chip)
    local config = XDlcHuntChipConfigs.GetChipBreakthroughConfig(chip:GetId(), chip:GetBreakthroughTimes())
    if not config then
        return ""
    end
    return config.ConsumeDes or ""
end

---@return DlcHuntChipBreakthroughCost[]
function XDlcHuntChipConfigs.GetCostBreakthrough(chip)
    local result = {}
    local config = XDlcHuntChipConfigs.GetChipBreakthroughConfig(chip:GetId(), chip:GetBreakthroughTimes())
    if not config then
        return result
    end
    for i = 1, config.CostCount do
        ---@class DlcHuntChipBreakthroughCost
        local cost = {
            Type = config.CostType,
            BreakthroughTimes = config.CostChipBreakTime,
            Star = config.CostChipQuality,
            Quality = config.CostChipQuality,
            Amount = 1, -- 数量总是1
        }
        result[#result + 1] = cost
    end
    return result
end

function XDlcHuntChipConfigs.GetChipBreakthroughConfig(chipId, breakthroughTimes)
    __InitConfigChipBreakthrough()
    local configsBreakthrough = _ConfigChipBreakthrough:GetConfigs()
    for i, config in pairs(configsBreakthrough) do
        if config.ChipId == chipId and config.BreakTimes == breakthroughTimes then
            return config
        end
    end
    return false
end

local _ChipMaxBreakthroughTimes = {}
function XDlcHuntChipConfigs.GetChipMaxBreakthroughTimes(chipId)
    if _ChipMaxBreakthroughTimes[chipId] then
        return _ChipMaxBreakthroughTimes[chipId]
    end
    local allConfig = XDlcHuntChipConfigs.GetChipAllBreakthroughConfig(chipId)
    local lastConfig = allConfig[#allConfig]
    local value = lastConfig and lastConfig.BreakTimes or 0
    _ChipMaxBreakthroughTimes[chipId] = value
    return value
end

function XDlcHuntChipConfigs.GetChipAllBreakthroughConfig(chipId)
    local result = {}
    __InitConfigChipBreakthrough()
    local configsBreakthrough = _ConfigChipBreakthrough:GetConfigs()
    for i, config in pairs(configsBreakthrough) do
        if config.ChipId == chipId then
            result[config.BreakTimes] = config
        end
    end
    return result
end

-- 所有突破属性的和
function XDlcHuntChipConfigs.GetChipAttrTableBreakthrough(chipId)
    local result = {}
    __InitConfigChipBreakthrough()
    local configsBreakthrough = _ConfigChipBreakthrough:GetConfigs()
    for i, config in pairs(configsBreakthrough) do
        if config.ChipId == chipId then
            local attribId = config.AttribId
            local attrTable = XDlcHuntAttrConfigs.GetAttrTable(attribId)
            result[config.BreakTimes] = attrTable
        end
    end
    return result
end

function XDlcHuntChipConfigs.GetChipAttrTable(chipId, level, breakthroughTimes)
    local attribId, attribLvUp
    local result = {}

    __InitConfigChipBreakthrough()
    local configsBreakthrough = _ConfigChipBreakthrough:GetConfigs()
    for i, config in pairs(configsBreakthrough) do
        if config.ChipId == chipId and config.BreakTimes == breakthroughTimes then
            attribId = config.AttribId
            attribLvUp = config.AttribPromotedId
            break
        end
    end
    if not attribId or not attribLvUp then
        return result
    end

    local attrTableBase = XDlcHuntAttrConfigs.GetAttrTable(attribId)
    local attrTableLvUp = XDlcHuntAttrConfigs.GetAttrTable(attribLvUp)
    for attrId, attrValue in pairs(attrTableBase) do
        result[attrId] = (result[attrId] or 0) + (attrValue or 0)
    end
    local ratio = level - 1
    for attrId, attrValue in pairs(attrTableLvUp) do
        result[attrId] = (result[attrId] or 0) + (attrValue or 0) * ratio
    end
    --result = attrTableBase + attrTableLvUp * (level - 1)
    return result
end

-- 属性成长值
function XDlcHuntChipConfigs.GetChipAttrTableLvUp(chipId, level, breakthroughTimes)
    local attribId, attribLvUp

    __InitConfigChipBreakthrough()
    local configsBreakthrough = _ConfigChipBreakthrough:GetConfigs()
    for i, config in pairs(configsBreakthrough) do
        if config.ChipId == chipId and config.BreakTimes == breakthroughTimes then
            attribId = config.AttribId
            attribLvUp = config.AttribPromotedId
            break
        end
    end
    if not attribId or not attribLvUp then
        return {}
    end

    local attrTableLvUp = XDlcHuntAttrConfigs.GetAttrTable(attribLvUp)
    return attrTableLvUp
end

function XDlcHuntChipConfigs.GetChipLevelUpConfig(chipId, breakthroughTimes)
    local result = {}
    __InitConfigChipBreakthrough()
    local configsBreakthrough = _ConfigChipBreakthrough:GetConfigs()
    local levelUpTemplateId
    for i, config in pairs(configsBreakthrough) do
        if config.ChipId == chipId and config.BreakTimes == breakthroughTimes then
            levelUpTemplateId = config.LevelUpTemplateId
            break
        end
    end
    if levelUpTemplateId then
        __InitConfigLevelUpTemplate()
        local configsLvUpTemplate = _ConfigLevelUpTemplate:GetConfigs()
        for i, config in pairs(configsLvUpTemplate) do
            if config.TemplateId == levelUpTemplateId then
                result[#result + 1] = config
            end
        end
    end
    return result
end

function XDlcHuntChipConfigs.GetChipMaxLevel(chipId, breakthroughTimes)
    local config = XDlcHuntChipConfigs.GetChipBreakthroughConfig(chipId, breakthroughTimes)
    return config and config.LevelLimit or 0
end

function XDlcHuntChipConfigs.GetChipLevelUpExp(chipId, level, breakthroughTimes)
    -- 取下一级
    level = level + 1
    local maxLevel = XDlcHuntChipConfigs.GetChipMaxLevel(chipId, breakthroughTimes)
    if level > maxLevel then
        level = maxLevel
    end

    local exp, allExp = 0, 0
    __InitConfigChipBreakthrough()
    local configsBreakthrough = _ConfigChipBreakthrough:GetConfigs()
    local levelUpTemplateId
    for i, config in pairs(configsBreakthrough) do
        if config.ChipId == chipId and config.BreakTimes == breakthroughTimes then
            levelUpTemplateId = config.LevelUpTemplateId
            break
        end
    end
    if levelUpTemplateId then
        __InitConfigLevelUpTemplate()
        local configsLvUpTemplate = _ConfigLevelUpTemplate:GetConfigs()
        for i, config in pairs(configsLvUpTemplate) do
            if config.TemplateId == levelUpTemplateId and config.Level == level then
                exp, allExp = config.Exp, config.AllExp
                break
            end
        end
    end
    return exp, allExp
end

---@param chip XDlcHuntChip
function XDlcHuntChipConfigs.GetChipResolveItem(chip)
    local chipId = chip:GetId()
    local breakthroughTimes = chip:GetBreakthroughTimes()
    local config = XDlcHuntChipConfigs.GetChipBreakthroughConfig(chipId, breakthroughTimes)
    local item = {
        ItemId = config.ResolveItem,
        ItemCount = config.ResolveItemCount
    }
    return item
end

---@param chip XDlcHuntChip
function XDlcHuntChipConfigs.GetChipGetOfferExp(chip)
    local chipId = chip:GetId()
    local breakthroughTimes = chip:GetBreakthroughTimes()
    local config = XDlcHuntChipConfigs.GetChipBreakthroughConfig(chipId, breakthroughTimes)
    local expBase = config.OfferExp
    local _, expLevelUp = chip:GetExpMaxWithThisLevel()
    return expBase + expLevelUp
end

function XDlcHuntChipConfigs.GetChipTypeByGroupPos(pos)
    if pos == 1 then
        return XDlcHuntChipConfigs.CHIP_TYPE.MAIN
    end
    return XDlcHuntChipConfigs.CHIP_TYPE.SUB
end

function XDlcHuntChipConfigs.IsMainChipByPos(pos)
    return XDlcHuntChipConfigs.GetChipTypeByGroupPos(pos) == XDlcHuntChipConfigs.CHIP_TYPE.MAIN
end

function XDlcHuntChipConfigs.GetMagicName(magicId)
    __InitConfigMagic()
    return _ConfigMagic:GetProperty(magicId, "Name")
end

function XDlcHuntChipConfigs.GetMagicDesc(magicId)
    __InitConfigMagic()
    return _ConfigMagic:GetProperty(magicId, "Desc"),
    _ConfigMagic:GetProperty(magicId, "Params")
end

function XDlcHuntChipConfigs.GetMagicType(magicId)
    __InitConfigMagic()
    return _ConfigMagic:GetProperty(magicId, "Type")
end

---@param chip XDlcHuntChip
function XDlcHuntChipConfigs.GetMagicEventIds(chip)
    local id = chip:GetId()
    local breakthroughTimes = chip:GetBreakthroughTimes()
    local config = XDlcHuntChipConfigs.GetChipBreakthroughConfig(id, breakthroughTimes)
    if not config then
        return {}
    end
    return config.MagicEventIds
end

---@param chip XDlcHuntChip
function XDlcHuntChipConfigs.GetMagicLevel(chip)
    local config = XDlcHuntChipConfigs.GetChipBreakthroughConfig(chip:GetId(), chip:GetBreakthroughTimes())
    if not config then
        return {}
    end
    return config.MagicLevel
end

---@param chip XDlcHuntChip
function XDlcHuntChipConfigs.GetChipQualityColor(chip)
    local star = chip:GetStarAmount()
    return XDlcHuntChipConfigs.GetQualityColor(star)
end

function XDlcHuntChipConfigs.GetQualityColor(star)
    if star == 3 then
        return XUiHelper.Hexcolor2Color("3e70bb")
    end
    if star == 4 then
        return XUiHelper.Hexcolor2Color("cc68c1")
    end
    if star == 5 then
        return XUiHelper.Hexcolor2Color("ff8d1e")
    end
    return XUiHelper.Hexcolor2Color("3e70bb")
end

function XDlcHuntChipConfigs.GetAssistantChipList()
    local list = {}
    __InitConfigChipAssistant()
    local configs = _ConfigChipAssistant:GetConfigs()
    local XDlcHuntChip = require("XEntity/XDlcHunt/XDlcHuntChip")
    for id, data in pairs(configs) do
        ---@type XDlcHuntChip
        local chip = XDlcHuntChip.New()
        chip:SetId(data.ChipId)
        chip:SetBreakthroughTimes(data.BreakTimes)
        chip:SetLevel(data.Level)
        chip:SetFromConfig()
        chip:SetUid(id)
        list[#list + 1] = chip
    end
    return list
end 