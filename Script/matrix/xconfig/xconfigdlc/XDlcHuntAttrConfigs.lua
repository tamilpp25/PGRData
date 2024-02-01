local FixToInt = FixToInt

XDlcHuntAttrConfigs = XDlcHuntAttrConfigs or {}

XDlcHuntAttrConfigs.ATTR_TYPE = {
    Fighting = 1, --战斗
    --...其他的是系统用type，没什么大用
}

XDlcHuntAttrConfigs.ATTR_GROUP = {
    ATTACK_DEFENSE = 1,
    ATTACK_LIFE = 2,
}

-- 固定显示部分属性
XDlcHuntAttrConfigs.ATTR_TYPE_STR = {
    Attack = "Attack",
    Life = "Life",
    Defense = "Defense",
}

---@type XConfig
local _ConfigAttrib

---@type XConfig
local _ConfigAttrDesc

---@type XConfig
local _ConfigAttrType

function XDlcHuntAttrConfigs.Init()
end

local function __InitConfigAttrib()
    if not _ConfigAttrib then
        _ConfigAttrib = XConfig.New("Share/DlcHunt/Attrib/AttribBase", XTable.XTableAttribBase, "Id")
    end
end

local function __InitConfigAttrDesc()
    if not _ConfigAttrDesc then
        local xtable = XTable.XTableDlcHuntAttribDesc
        xtable.Power.ValueType = "float"
        _ConfigAttrDesc = XConfig.New("Share/DlcHunt/Attrib/DlcHuntAttribDesc.tab", xtable, "Name")
    end
end

local function __InitConfigAttrType()
    if not _ConfigAttrType then
        _ConfigAttrType = XConfig.New("Client/DlcHunt/Attrib/DlcHuntAttrType.tab", XTable.XTableDlcHuntAttrType, "AttrType")
    end
end

function XDlcHuntAttrConfigs.GetAttrTable(attribId)
    __InitConfigAttrib()
    return _ConfigAttrib:GetConfig(attribId)
end

function XDlcHuntAttrConfigs.GetAttrName(id)
    __InitConfigAttrDesc()
    return _ConfigAttrDesc:GetProperty(id, "Des") or "???"
end

function XDlcHuntAttrConfigs.GetAttrNameEn(id)
    __InitConfigAttrDesc()
    return _ConfigAttrDesc:GetProperty(id, "DescEn") or "???"
end

function XDlcHuntAttrConfigs.GetAttrPriority(id)
    -- 固定显示部分属性
    if id == XDlcHuntAttrConfigs.ATTR_TYPE_STR.Attack then
        return 3
    end
    if id == XDlcHuntAttrConfigs.ATTR_TYPE_STR.Life then
        return 2
    end
    if id == XDlcHuntAttrConfigs.ATTR_TYPE_STR.Defense then
        return 1
    end
    __InitConfigAttrDesc()
    local priority = _ConfigAttrDesc:GetProperty(id, "Id") or 0
    return -priority
end

-- 属性转战斗力的系数
local function GetRatioFightingPower(attrId)
    __InitConfigAttrDesc()
    return _ConfigAttrDesc:TryGetProperty(attrId, "Power")
end

-- 为什么要加这个判断，因为配置Id也被放在attrTable里了
function XDlcHuntAttrConfigs.IsAttr(attrId)
    __InitConfigAttrDesc()
    local config = _ConfigAttrDesc:TryGetConfig(attrId)
    return config ~= nil
end

function XDlcHuntAttrConfigs.IsFightingAttr(attrId)
    __InitConfigAttrDesc()
    local config = _ConfigAttrDesc:TryGetConfig(attrId)
    return config and config.Type == XDlcHuntAttrConfigs.ATTR_TYPE.Fighting
end

function XDlcHuntAttrConfigs.IsSystemAttr(attrId)
    __InitConfigAttrDesc()
    local config = _ConfigAttrDesc:TryGetConfig(attrId)
    return config and config.Type ~= XDlcHuntAttrConfigs.ATTR_TYPE.Fighting
end

-- 战斗力
function XDlcHuntAttrConfigs.GetFightingPower(attrTable)
    local fightingPower = 0
    for attrId, attrValue in pairs(attrTable) do
        if XDlcHuntAttrConfigs.IsAttr(attrId) then
            local ratio, isExist = GetRatioFightingPower(attrId)
            if isExist then
                fightingPower = fightingPower + ratio * attrValue
            end
        end
    end
    return math.floor(fightingPower)
end

local function IsPercent(attrId)
    __InitConfigAttrDesc()
    return _ConfigAttrDesc:GetProperty(attrId, "IsPercent")
end

function XDlcHuntAttrConfigs.GetValueWithPercent(attrId, attrValue, keepDecimals)
    if keepDecimals then
        attrValue = string.format("%.2f", attrValue)
    else
        attrValue = math.floor(attrValue + 0.5)
    end
    if IsPercent(attrId) then
        -- (attrValue / 100).."%"
        return XUiHelper.GetText("DlcHuntPercent", attrValue / 100)
    end
    return attrValue
end

function XDlcHuntAttrConfigs.GetNameAttrType(attrType)
    __InitConfigAttrType()
    return _ConfigAttrType:GetProperty(attrType, "Des")
end

function XDlcHuntAttrConfigs.GetAttrType(attrId)
    __InitConfigAttrDesc()
    return _ConfigAttrDesc:GetProperty(attrId, "Type")
end

function XDlcHuntAttrConfigs.GetNameAttrTypeByAttrId(attrId)
    local attrType = XDlcHuntAttrConfigs.GetAttrType(attrId)
    return XDlcHuntAttrConfigs.GetNameAttrType(attrType)
end

function XDlcHuntAttrConfigs.MergeAttrTable(table1, table2)
    local result = {}
    for attrId, attrValue in pairs(table1) do
        result[attrId] = result[attrId] or 0 + attrValue
    end
    for attrId, attrValue in pairs(table2) do
        result[attrId] = result[attrId] or 0 + attrValue
    end
    return result
end 