local pairs = pairs
local table = table
local tableInsert = table.insert

XMagicSkillManager = XMagicSkillManager or {}

local GetResonanceSkillLevelInterface
local GetSkillLevelInterfaces = {}
local GetMagicLevelInterfaces = {}
local GetBornMagicLevelInterfaces = {}

---获取技能等级集合
---@param npcData userdata npc数据
---@return XCode,table 状态码和技能等级集合
local function GetSkillLevelMap(npcData)
    local levelMap = {}

    for _, inter in pairs(GetSkillLevelInterfaces) do
        local code = inter(npcData, levelMap)
        if code ~= XCode.Success then
            return code, nil
        end
    end

    return XCode.Success, levelMap
end

---获取魔法等级集合
---@param npcData userdata npc数据
---@return XCode,table 状态码和魔法等级集合
local function GetMagicLevelMap(npcData)
    local levelMap = {}

    for _, inter in pairs(GetMagicLevelInterfaces) do
        local code = inter(npcData, levelMap)
        if code ~= XCode.Success then
            return code, nil
        end
    end

    return XCode.Success, levelMap
end

---获取出生魔法等级集合
---@param npcData userdata npc数据
---@return XCode,table 状态码和出生魔法等级集合
local function GetBornMagicLevelMap(npcData)
    local levelMap = {}

    for _, inter in pairs(GetBornMagicLevelInterfaces) do
        local code = inter(npcData, levelMap)
        if code ~= XCode.Success then
            return code, nil
        end
    end

    return XCode.Success, levelMap
end

local function TryGetSkillLevelMap(npcData)
    local code, levelMap = GetSkillLevelMap(npcData)
    if code ~= XCode.Success then
        return nil
    end

    return levelMap
end

local function TryGetMagicLevelMap(npcData)
    local code, levelMap = GetMagicLevelMap(npcData)
    if code ~= XCode.Success then
        return nil
    end

    return levelMap
end

local function TryGetBornMagicLevelMap(npcData)
    local code, levelMap = GetBornMagicLevelMap(npcData)
    if code ~= XCode.Success then
        return nil
    end

    return levelMap
end

function XMagicSkillManager.GetResonanceSkillLevelMap(npcData)
    return GetResonanceSkillLevelInterface(npcData)
end

function XMagicSkillManager.RegisterResonanceSkillLevelInterface(inter)
    GetResonanceSkillLevelInterface = inter
end

function XMagicSkillManager.RegisterSkillLevelInterface(inter)
    tableInsert(GetSkillLevelInterfaces, inter)
end

function XMagicSkillManager.RegisterMagicLevelInterface(inter)
    tableInsert(GetMagicLevelInterfaces, inter)
end

function XMagicSkillManager.RegisterBornMagicLevelInterface(inter)
    tableInsert(GetBornMagicLevelInterfaces, inter)
end

---------------------------------------伙伴相关----------------------------------
local GetPartnerSkillLevelInterfaces = {}
local GetPartnerMagicLevelInterfaces = {}
local GetPartnerBornMagicLevelInterfaces = {}

---获取技能等级集合
local function GetPartnerSkillLevelMap(partnerData)
    local levelMap = {}

    for _, inter in pairs(GetPartnerSkillLevelInterfaces) do
        local code = inter(partnerData, levelMap)
        if code ~= XCode.Success then
            return code, nil
        end
    end

    return XCode.Success, levelMap
end

---获取魔法等级集合

local function GetPartnerMagicLevelMap(partnerData)
    local levelMap = {}

    for _, inter in pairs(GetPartnerMagicLevelInterfaces) do
        local code = inter(partnerData, levelMap)
        if code ~= XCode.Success then
            return code, nil
        end
    end

    return XCode.Success, levelMap
end

---获取出生魔法等级集合

local function GetPartnerBornMagicLevelMap(partnerData)
    local levelMap = {}

    for _, inter in pairs(GetPartnerBornMagicLevelInterfaces) do
        local code = inter(partnerData, levelMap)
        if code ~= XCode.Success then
            return code, nil
        end
    end

    return XCode.Success, levelMap
end

local function TryGetPartnerSkillLevelMap(partnerData)
    local code, levelMap = GetPartnerSkillLevelMap(partnerData)
    if code ~= XCode.Success then
        return nil
    end

    return levelMap
end

local function TryGetPartnerMagicLevelMap(partnerData)
    local code, levelMap = GetPartnerMagicLevelMap(partnerData)
    if code ~= XCode.Success then
        return nil
    end

    return levelMap
end

local function TryGetPartnerBornMagicLevelMap(partnerData)
    local code, levelMap = GetPartnerBornMagicLevelMap(partnerData)
    if code ~= XCode.Success then
        return nil
    end

    return levelMap
end

function XMagicSkillManager.RegisterPartnerSkillLevelInterface(inter)
    tableInsert(GetPartnerSkillLevelInterfaces, inter)
end

function XMagicSkillManager.RegisterPartnerMagicLevelInterface(inter)
    tableInsert(GetPartnerMagicLevelInterfaces, inter)
end

function XMagicSkillManager.RegisterPartnerBornMagicLevelInterface(inter)
    tableInsert(GetPartnerBornMagicLevelInterfaces, inter)
end
---------------------------------------------------------------------------------
function XMagicSkillManager.Init()
    CS.XFightDelegate.GetNpcSkillLevelMap = TryGetSkillLevelMap
    CS.XFightDelegate.GetNpcMagicLevelMap = TryGetMagicLevelMap
    CS.XFightDelegate.GetNpcBornMagicLevelMap = TryGetBornMagicLevelMap
    
    CS.XFightDelegate.GetPartnerSkillLevelMap = TryGetPartnerSkillLevelMap
    CS.XFightDelegate.GetPartnerMagicLevelMap = TryGetPartnerMagicLevelMap
    CS.XFightDelegate.GetPartnerBornMagicLevelMap = TryGetPartnerBornMagicLevelMap
end