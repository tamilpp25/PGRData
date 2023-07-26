local tableInsert = table.insert

XFightPartnerManager = XFightPartnerManager or {}

local function Awake()
end

-----------------------------------------Attribs Begin---------------------------------------
---突破属性成长加成
local function DoAddBreakthroughPromotedAttribId(partnerData, attribIds, trainedLevels)
    local partnerEntity = XDataCenter.PartnerManager.CreatePartnerEntityByPartnerData(partnerData)

    if not partnerEntity then
        return XCode.PartnerTemplateNotFound
    end

    local trainedLevel = (partnerData.PreLevel or partnerEntity:GetLevel()) - 1
    local attribPromotedId = partnerEntity:GetBreakthroughAttribPromotedId()
    if trainedLevel > 0 and attribPromotedId > 0 then
        tableInsert(attribIds, attribPromotedId)
        tableInsert(trainedLevels, trainedLevel)
    end

    return XCode.Success
end

---突破基础属性加成
local function DoAddBreakthroughAttribId(partnerData, attribIds)
    local partnerEntity = XDataCenter.PartnerManager.CreatePartnerEntityByPartnerData(partnerData)

    if not partnerEntity then
        return XCode.PartnerTemplateNotFound
    end

    local attribId = partnerEntity:GetBreakthroughAttribId()
    if attribId > 0 then
        tableInsert(attribIds, attribId)
    end

    return XCode.Success
end

---添加角色星数属性id
---当前品质，从1星累加到当前星
local function DoAddStarAttribId(partnerData, attribIds)
    local partnerEntity = XDataCenter.PartnerManager.CreatePartnerEntityByPartnerData(partnerData)
  
    if not partnerEntity then
        return XCode.PartnerTemplateNotFound
    end

    for quality = partnerEntity:GetInitQuality(), partnerEntity:GetQuality() do
        local starAttrIds = partnerEntity:GetQualityStarAttribId(quality)
        local maxStar = #starAttrIds
        
        if quality == partnerEntity:GetQuality() then
            maxStar = partnerEntity:GetCanActivateStarCount()
        end
        
        for i = 1, maxStar do
            local attribId = starAttrIds[i]
            if attribId > 0 then
                tableInsert(attribIds, attribId)
            end
        end
    end

    return XCode.Success
end

---添加角色进化属性id
local function DoAddEvolutionAttribId(partnerData, attribIds)
    local partnerEntity = XDataCenter.PartnerManager.CreatePartnerEntityByPartnerData(partnerData)
   
    if not partnerEntity then
        return XCode.PartnerTemplateNotFound
    end

    local attribId = partnerEntity:GetQualityEvolutionAttribId()
    if attribId > 0 then
        tableInsert(attribIds, attribId)
    end

    return XCode.Success
end

--- 属性计算
--- 1、突破提供基础属性
--- 2、升星提供属性
--- 3、进化提供属性
local function GetNumericAttribId(partnerData, attribIds)
    local code
    
    code = DoAddBreakthroughAttribId(partnerData, attribIds)
    if code ~= XCode.Success then
        return code
    end

    code = DoAddStarAttribId(partnerData, attribIds)
    if code ~= XCode.Success then
        return code
    end
    
    code = DoAddEvolutionAttribId(partnerData, attribIds)
    if code ~= XCode.Success then
        return code
    end

    return XCode.Success
end

--- 属性计算
--- 1、只要突破提供基础属性
local function GetBreakthroughNumericAttribId(partnerData, attribIds)
    local code

    code = DoAddBreakthroughAttribId(partnerData, attribIds)
    if code ~= XCode.Success then
        return code
    end
    return XCode.Success
end

--- 属性成长加成
--- 1、突破提供加成
local function GetPromotedAttribId(partnerData, attribIds, trainedLevels)
    local code = DoAddBreakthroughPromotedAttribId(partnerData, attribIds, trainedLevels)
    if code ~= XCode.Success then
        return code
    end

    return XCode.Success
end

-----------------------------------------Attribs End-----------------------------------------
-----------------------------------------Skill Begin-----------------------------------------
---伙伴主动技能集合
local function SetPartnerMainSkillLevel(partnerData, levelMap)
    local partnerEntity = XDataCenter.PartnerManager.CreatePartnerEntityByPartnerData(partnerData)
    if not partnerEntity then
        return XCode.PartnerTemplateNotFound
    end

    local mainSkillGroupEntityDic = partnerEntity:GetMainSkillGroupEntityDic()
    for _, groupEntity in pairs(mainSkillGroupEntityDic or {}) do
        if groupEntity:GetIsCarry() then
            local skillLevel = groupEntity:GetLevel()
            local subSkillIds = groupEntity:GetActiveSkillSubSkillId()
            for _,subSkillId in pairs(subSkillIds or {}) do
                if not levelMap[subSkillId] or levelMap[subSkillId] < skillLevel then
                    levelMap[subSkillId] = skillLevel
                end
            end
        end
    end
    
    return XCode.Success
end

---伙伴被动技能集合
local function SetPartnerPassiveSkillLevel(partnerData, levelMap)
    local partnerEntity = XDataCenter.PartnerManager.CreatePartnerEntityByPartnerData(partnerData)
    if not partnerEntity then
        return XCode.PartnerTemplateNotFound
    end

    local passiveSkillGroupEntityDic = partnerEntity:GetPassiveSkillGroupEntityDic()
    for _, groupEntity in pairs(passiveSkillGroupEntityDic or {}) do
        if groupEntity:GetIsCarry() then
            local skillLevel = groupEntity:GetLevel()
            local subSkillIds = groupEntity:GetActiveSkillSubSkillId()
            for _,subSkillId in pairs(subSkillIds or {}) do
                if not levelMap[subSkillId] or levelMap[subSkillId] < skillLevel then
                    levelMap[subSkillId] = skillLevel
                end
            end
        end
    end

    return XCode.Success
end

--- 技能等级
--- 1、伙伴主动技能加成
--- 2、伙伴被动技能加成
local function GetSkillLevel(partnerData, levelMap)
    local code

    code = SetPartnerMainSkillLevel(partnerData, levelMap)
    if code ~= XCode.Success then
        return code
    end

    code = SetPartnerPassiveSkillLevel(partnerData, levelMap)
    if code ~= XCode.Success then
        return code
    end

    return XCode.Success
end
-----------------------------------------Skill End-----------------------------------------
-----------------------------------------Magic Begin-----------------------------------------
---伙伴主动魔法集合
local function SetPartnerMainMagicLevel(partnerData, levelMap)
    local partnerEntity = XDataCenter.PartnerManager.CreatePartnerEntityByPartnerData(partnerData)
    if not partnerEntity then
        return XCode.PartnerTemplateNotFound
    end

    local mainSkillGroupEntityDic = partnerEntity:GetMainSkillGroupEntityDic()
    for _, groupEntity in pairs(mainSkillGroupEntityDic or {}) do
        if groupEntity:GetIsCarry() then
            local skillLevel = groupEntity:GetLevel()
            local subMagicIds = groupEntity:GetActiveSkillSubMagicId()
            for _,subMagicId in pairs(subMagicIds or {}) do
                if not levelMap[subMagicId] or levelMap[subMagicId] < skillLevel then
                    levelMap[subMagicId] = skillLevel
                end
            end
        end
    end

    return XCode.Success
end

---伙伴被动魔法集合
local function SetPartnerPassiveMagicLevel(partnerData, levelMap)
    local partnerEntity = XDataCenter.PartnerManager.CreatePartnerEntityByPartnerData(partnerData)
    if not partnerEntity then
        return XCode.PartnerTemplateNotFound
    end

    local passiveSkillGroupEntityDic = partnerEntity:GetPassiveSkillGroupEntityDic()
    for _, groupEntity in pairs(passiveSkillGroupEntityDic or {}) do
        if groupEntity:GetIsCarry() then
            local skillLevel = groupEntity:GetLevel()
            local subMagicIds = groupEntity:GetActiveSkillSubMagicId()
            for _,subMagicId in pairs(subMagicIds or {}) do
                if not levelMap[subMagicId] or levelMap[subMagicId] < skillLevel then
                    levelMap[subMagicId] = skillLevel
                end
            end
        end
    end

    return XCode.Success
end

--- 魔法等级
--- 1、伙伴主动魔法加成
--- 2、伙伴被动魔法加成
local function GetMagicLevel(partnerData, levelMap)
    local code

    code = SetPartnerMainMagicLevel(partnerData, levelMap)
    if code ~= XCode.Success then
        return code
    end

    code = SetPartnerPassiveMagicLevel(partnerData, levelMap)
    if code ~= XCode.Success then
        return code
    end

    return XCode.Success
end
-----------------------------------------Magic End-----------------------------------------
-----------------------------------------BornMagic Begin-----------------------------------------
---伙伴主动出生魔法集合
local function SetPartnerMainBornMagicLevel(partnerData, levelMap)
    local partnerEntity = XDataCenter.PartnerManager.CreatePartnerEntityByPartnerData(partnerData)
    if not partnerEntity then
        return XCode.PartnerTemplateNotFound
    end

    local mainSkillGroupEntityDic = partnerEntity:GetMainSkillGroupEntityDic()
    for _, groupEntity in pairs(mainSkillGroupEntityDic or {}) do
        if groupEntity:GetIsCarry() then
            local skillLevel = groupEntity:GetLevel()
            local bornMagicIds = groupEntity:GetActiveSkillBornMagic()
            for _,bornMagicId in pairs(bornMagicIds or {}) do
                if not levelMap[bornMagicId] or levelMap[bornMagicId] < skillLevel then
                    levelMap[bornMagicId] = skillLevel
                end
            end
        end
    end

    return XCode.Success
end

---伙伴被动出生魔法集合
local function SetPartnerPassiveBornMagicLevel(partnerData, levelMap)
    local partnerEntity = XDataCenter.PartnerManager.CreatePartnerEntityByPartnerData(partnerData)
    if not partnerEntity then
        return XCode.PartnerTemplateNotFound
    end

    local passiveSkillGroupEntityDic = partnerEntity:GetPassiveSkillGroupEntityDic()
    for _, groupEntity in pairs(passiveSkillGroupEntityDic or {}) do
        if groupEntity:GetIsCarry() then
            local skillLevel = groupEntity:GetLevel()
            local bornMagicIds = groupEntity:GetActiveSkillBornMagic()
            for _,bornMagicId in pairs(bornMagicIds or {}) do
                if not levelMap[bornMagicId] or levelMap[bornMagicId] < skillLevel then
                    levelMap[bornMagicId] = skillLevel
                end
            end
        end
    end

    return XCode.Success
end

--- 魔法等级
--- 1、伙伴主动出生魔法加成
--- 2、伙伴被动出生魔法加成
local function GetBornMagicLevel(partnerData, levelMap)
    local code

    code = SetPartnerMainBornMagicLevel(partnerData, levelMap)
    if code ~= XCode.Success then
        return code
    end

    code = SetPartnerPassiveBornMagicLevel(partnerData, levelMap)
    if code ~= XCode.Success then
        return code
    end

    return XCode.Success
end

-----------------------------------------BornMagic End-----------------------------------------
local function RegisterInterfaces()
    XAttribManager.RegisterPartnerNumericIdInterface(GetNumericAttribId)
    XAttribManager.RegisterPartnerPromotedIdInterface(GetPromotedAttribId)
    
    XMagicSkillManager.RegisterPartnerSkillLevelInterface(GetSkillLevel)
    XMagicSkillManager.RegisterPartnerMagicLevelInterface(GetMagicLevel)
    XMagicSkillManager.RegisterPartnerBornMagicLevelInterface(GetBornMagicLevel)
end

function XFightPartnerManager.Init()
    Awake()
    RegisterInterfaces()
end

---------------------------------------客户端特有方法---------------------------------------
local function DoGetPartnerAttribIds(partnerData, numericIds, promotedIds, trainedLevels)
    GetNumericAttribId(partnerData, numericIds)
    GetPromotedAttribId(partnerData, promotedIds, trainedLevels)
end

function XFightPartnerManager.GetPartnerAttribs(partnerData, preLevel)
    local numericIds = {}
    local trainedLevels = {}
    local promotedIds = {}
    local data = XTool.Clone(partnerData)
    data.Level = preLevel and preLevel or data.Level
    DoGetPartnerAttribIds(data, numericIds, promotedIds, trainedLevels)
    return XAttribManager.GetMergeAttribs(numericIds, promotedIds, trainedLevels)
end