local pairs = pairs
local type = type

local table = table
local tableInsert = table.insert

XAttribManager = XAttribManager or {}

-- 属性id获取接口
local AddNumericIdInterfaces = {}
local AddPromotedIdInterfaces = {}
local AddGrowRateIdInterfaces = {}

local FPS = CS.XFightConfig.FPS
local FPS_FIX = fix(FPS)
local FPS_RECIPROCAL_FIX = CS.XFightConfig.FpsReciprocal
local RADIAN_PER_ANGLE_FIX = fix.deg2rad

local AttribCount = XNpcAttribType.End
local RunSpeedIndex = XNpcAttribType.RunSpeed
local WalkSpeedIndex = XNpcAttribType.WalkSpeed
local SquatSpeedIndex = XNpcAttribType.SquatSpeed
local SprintSpeedIndex = XNpcAttribType.SprintSpeed
local TurnRoundSpeedIndex = XNpcAttribType.TurnRoundSpeed
local BallIntervalIndex = XNpcAttribType.BallInterval
local DodgeEnergyAutoRecoveryIndex = XNpcAttribType.DodgeEnergyAutoRecovery

local DEFAULT_VALUE = 0
local AttribTemplates = {}
local AttribPromotedTemplates = {}
local AttribGrowRateTemplates = {}
local AttribReviseTemplates = {}
local AttribGroupTemplates = {}
local AttribAbilityTemplate = {}

--属性名字配置表
local AttribDescTemplates = {}
-- local NpcTemplates = {}
---属性id接口注册
---@param inter function
function XAttribManager.RegisterGrowRateIdInterface(inter)
    tableInsert(AddGrowRateIdInterfaces, inter)
end

---@param inter function
function XAttribManager.RegisterNumericIdInterface(inter)
    tableInsert(AddNumericIdInterfaces, inter)
end

---@param inter function
function XAttribManager.RegisterPromotedIdInterface(inter)
    tableInsert(AddPromotedIdInterfaces, inter)
end

---属性计算
local function CreateAttribArray(isInit)
    local array = {}
    -- 初始化时默认不申请全部内存，改用字典
    if isInit then
        for _ = 1, AttribCount - 1 do
            tableInsert(array, fix.zero)
        end
    end
    return array
end

---将配置转换成fix数组
---@param template table 属性配置
---@return fix[] fix数组
local function GetAttribArray(template)
    local attribs = CreateAttribArray()

    for k, v in pairs(XNpcAttribType) do
        if template[k] and template[k] ~= DEFAULT_VALUE then
            attribs[v] = template[k]
        end
    end

    return attribs
end


---初始化属性配置
---@param template table 原有配置
---@return fix[] 属性配置fix只读数组
local function InitAttribTemplates(template)
    local attribTemplates = {}
    for k, v in pairs(template) do
        attribTemplates[k] = GetAttribArray(v)
    end

    return XReadOnlyTable.Create(attribTemplates)
end

---加载属性配置
local function LoadAttribConfig()
    AttribGroupTemplates = XAttribConfigs.GetAttribGroupTemplates()
    AttribReviseTemplates = XAttribConfigs.GetAttribReviseTemplates()
    -- NpcTemplates = XAttribConfigs.GetNpcTemplates()
    AttribDescTemplates = XAttribConfigs.GetAttribDescTemplates()
    AttribAbilityTemplate = XAttribConfigs.GetAttribAbilityTemplate()

    AttribTemplates = XAttribConfigs.GetAttribTemplates()--InitAttribTemplates(XAttribConfigs.GetAttribTemplates())
    AttribPromotedTemplates = XAttribConfigs.GetAttribPromotedTemplates()
    AttribGrowRateTemplates = XAttribConfigs.GetAttribGrowRateTemplates()
end

local function GetAttribTemplate(attribId)
    local attribs = AttribTemplates[attribId]
    if not attribs then
        XLog.Error("XAttribManager GetAttribTemplate Error: can not found attrib template, Id is " .. attribId, AttribTemplates)
        return XCode.AttribManagerGetAttribTemplateNotFound, nil
    end

    attribs = GetAttribArray(attribs)

    return XCode.Success, attribs
end

local function GetAttribPromotedTemplate(attribId)
    local attribs = AttribPromotedTemplates[attribId]
    if not attribs then
        XLog.Error("XAttribManager GetAttribPromotedTemplate Error: can not found attrib template, Id is " .. attribId)
        return XCode.AttribManagerGetPromotedAttribTemplateNotFound, nil
    end

    attribs = GetAttribArray(attribs)

    return XCode.Success, attribs
end

local function GetAttribGrowRateTemplate(attribId)
    local attribs = AttribGrowRateTemplates[attribId]
    if not attribs then
        XLog.Error("XAttribManager GetAttribGrowRateTemplate Error: can not found attrib template, Id is " .. attribId)
        return XCode.AttribManagerGetGrowRateAttribTemplateNotFound, nil
    end

    attribs = GetAttribArray(attribs)

    return XCode.Success, attribs
end

local function GetAttribGroupTemplate(id)
    local attribGroup = AttribGroupTemplates[id]
    if not attribGroup then
        XLog.Error("XAttribManager GetAttribGroupTemplate Error: can not found attrib group template, Id is " .. id)
        return XCode.AttribGroupNotFound, nil
    end

    return XCode.Success, attribGroup
end

---属性计算
---属性加法
---@param attribs1 fix[] 原属性数组
---@param attribs2 fix[] 增加属性数组
local function DoAddAttribs(attribs1, attribs2)
    for k, v in pairs(attribs2) do
        if attribs1[k] then
            attribs1[k] = attribs1[k] + attribs2[k]
        else
            attribs1[k] = attribs2[k]
        end
    end
end

---属性成长(原属性 + 成长属性 * 培养等级)
---@param attribs1 fix[] 原属性数组
---@param attribs2 fix[] 成长属性数组
---@param trainedLevel number 培养等级
local function DoPromotedAttribs(attribs1, attribs2, trainedLevel)
    if trainedLevel <= 0 then
        return
    end

    trainedLevel = fix(trainedLevel)

    for k, v in pairs(attribs2) do
        if attribs1[k] then
            attribs1[k] = attribs1[k] + attribs2[k] * trainedLevel
        else
            attribs1[k] = attribs2[k] * trainedLevel
        end
    end
end

---属性加成(原属性 + 原属性 * 加成属性)
---@param attribs1 fix[] 原属性数组
---@param attribs2 fix[] 加成属性数组
local function DoGrowRateAttribs(attribs1, attribs2)
    for k, v in pairs(attribs2) do
        if attribs1[k] then
            attribs1[k] = attribs1[k] + attribs1[k] * attribs2[k]
        else
            attribs1[k] = attribs1[k] * attribs2[k]
        end
    end
end

---属性修正(原属性 * (1 + 修正系数))
---@param attrib fix 原属性
---@param factor fix 修正系数
---@return fix 修正后属性
local function DoReviseAttrib(attrib, factor)
    if not attrib then
        attrib = DEFAULT_VALUE
    end
    return attrib * (fix.one + factor);
end

---获取总加成属性
---@param attribIds table 属性加成id列表
---@return XCode,fix[] 状态码和属性数组
local function GetTotalGrowRateAttribs(attribIds)
    local attribs = CreateAttribArray()

    for _, id in pairs(attribIds) do
        local code, readAttribs = GetAttribGrowRateTemplate(id)
        if code ~= XCode.Success then
            return code, nil
        end

        DoAddAttribs(attribs, readAttribs)
    end

    return XCode.Success, attribs
end

---获取总属性数值叠加
---@param attribIds table 叠加属性id列表
---@return XCode,fix[] 状态码和属性数组
local function GetTotalNumericAttribs(attribIds)
    local attribs = CreateAttribArray()

    for _, id in pairs(attribIds) do
        local code, readAttribs = GetAttribTemplate(id)
        if code ~= XCode.Success then
            return code, nil
        end

        DoAddAttribs(attribs, readAttribs)
    end

    return XCode.Success, attribs
end

---获取总成长属性
---@param attribIds table 成长属性id列表
---@param trainedLevels table 培养等级列表
---@return XCode, fix[] 状态码和属性数组
local function GetTotalPromotedAttribs(attribIds, trainedLevels)
    local attribs = CreateAttribArray()
    if #trainedLevels ~= #attribIds then
        XLog.Error("XAttribManager GetTotalPromotedAttribs Error: trainedLevels array length is not equal to template id array length")
        return XCode.AttribManagerGetTotalPromotedAttribsParamArrayError, nil
    end

    local length = #trainedLevels
    for i = 1, length do
        local level = trainedLevels[i]
        if level <= 0 then
            XLog.Error("XAttribManager GetTotalPromotedAttribs Error: level is smaller than 1, level is " .. level)
            return XCode.AttribManagerGetTotalPromotedAttribsLevelError, nil
        end

        local code, readAttribs = GetAttribPromotedTemplate(attribIds[i])
        if code ~= XCode.Success then
            return code, nil
        end

        DoPromotedAttribs(attribs, readAttribs, level)
    end

    return XCode.Success, attribs
end

---属性数组修正
---@param attribs fix[] 属性数组
---@param reviseId number 修正id
---@return XCode 状态码
local function ReviseAttribs(attribs, reviseId)
    local template = AttribReviseTemplates[reviseId]
    if not template then
        XLog.Error("XAttribManager.ReviseAttribs error: can not found template, reviseId is " .. reviseId);
        return XCode.AttribReviseTemplateNotFound
    end

    for i = 1, #template.AttribTypes do
        local attribIndex = template.AttribTypes[i]
        attribs[attribIndex] = DoReviseAttrib(attribs[attribIndex], template.Values[i]);
    end

    return XCode.Success
end

---将属性数组从fix转换成XAttrib
---@param attribs fix[] fix属性数组
---@return XAttrib[] XAttrib属性数组
local function Fix2XAttrib(attribs)
    local xAttribs = {}
    for attribIndex = 1, AttribCount - 1 do
        local xAttrib
        if attribs[attribIndex] then
            xAttrib = CS.XAttrib.Ctor(FixToInt(attribs[attribIndex]))
        else
            xAttrib = CS.XAttrib()
        end
        tableInsert(xAttribs, xAttrib)
    end

    --- 特殊处理
    xAttribs[RunSpeedIndex]:SetBase(FixToInt(attribs[RunSpeedIndex] * fix.thousand / FPS_FIX))
    xAttribs[WalkSpeedIndex]:SetBase(FixToInt(attribs[WalkSpeedIndex] * fix.thousand / FPS_FIX))
    xAttribs[SquatSpeedIndex]:SetBase(FixToInt(attribs[SquatSpeedIndex] * fix.thousand / FPS_FIX))
    xAttribs[SprintSpeedIndex]:SetBase(FixToInt(attribs[SprintSpeedIndex] * fix.thousand / FPS_FIX))
    xAttribs[TurnRoundSpeedIndex]:SetBase(FixToInt(attribs[TurnRoundSpeedIndex] * FPS_RECIPROCAL_FIX * RADIAN_PER_ANGLE_FIX * fix.thousand))
    xAttribs[BallIntervalIndex]:SetBase(FixToInt(attribs[BallIntervalIndex] * FPS_FIX))
    xAttribs[DodgeEnergyAutoRecoveryIndex]:SetBase(FixToInt(attribs[DodgeEnergyAutoRecoveryIndex] * FPS_RECIPROCAL_FIX))

    --- CS数组下标从0开始,补一位
    tableInsert(xAttribs, 1, CS.XAttrib())

    return xAttribs
end

---获取npc基础属性
---@param npcTemplate table npc配置
---@param level number 等级
---@return XCode,fix[] 状态码和属性数组
local function GetNpcBaseAttribs(npcTemplate, level)
    local code, baseAttribs = GetAttribTemplate(npcTemplate.AttribId)
    if code ~= XCode.Success then
        return code, nil
    end

    local attribs = CreateAttribArray()
    DoAddAttribs(attribs, baseAttribs)

    --- 出生等级为1，培养等级=等级 - 1
    local trainedLevel = level - 1

    if npcTemplate.PromotedId and npcTemplate.PromotedId > 0 and trainedLevel > 0 then
        local promotedAttribs
        code, promotedAttribs = GetAttribPromotedTemplate(npcTemplate.PromotedId)
        if code ~= XCode.Success then
            return code, nil
        end

        DoPromotedAttribs(attribs, promotedAttribs, trainedLevel)
    end

    return XCode.Success, attribs
end

---获取npc基础属性
---@param npcTemplate table npc配置
---@param level number 等级
---@param reviseId number 修正系数id
---@return XCode,fix[] 状态码和属性数组
local function GetNpcBaseAttribsWithReviseId(npcTemplate, level, reviseId)
    local code, attribs = GetNpcBaseAttribs(npcTemplate, level)
    if code ~= XCode.Success then
        return code, nil
    end

    if reviseId and reviseId > 0 then
        code = ReviseAttribs(attribs, reviseId)
        if code ~= XCode.Success then
            return code, nil
        end
    end

    return XCode.Success, attribs
end

---获取npc基础属性
---@param npcTemplateId number npc配置id
---@param level number 等级
---@return XCode,fix[] 状态码和属性数组
local function GetNpcBaseAttribsByNpcId(npcTemplateId, level)
    local npcTemplate = CS.XNpcManager.GetNpcTemplate(npcTemplateId)
    if not npcTemplate then
        XLog.Error("XAttribManager GetNpcBaseAttribsByNpcId Error: can not found npc template, npc Id is " .. npcTemplateId)
        return XCode.AttribManagerGetNpcAttribNpcNotFound, nil
    end

    return GetNpcBaseAttribs(npcTemplate, level)
end

---获取npc基础属性
---@param npcTemplateId number npc配置id
---@param level number 等级
---@param reviseId number 修正系数id
---@return XCode,fix[] 状态码和属性数组
local function GetNpcBaseAttribsByNpcIdWithReviseId(npcTemplateId, level, reviseId)
    local npcTemplate = CS.XNpcManager.GetNpcTemplate(npcTemplateId)
    if not npcTemplate then
        XLog.Error("XAttribManager GetNpcBaseAttribsByNpcIdWithReviseId Error: can not found npc template, npc Id is " .. npcTemplateId)
        return XCode.AttribManagerGetNpcAttribNpcNotFound, nil
    end

    return GetNpcBaseAttribsWithReviseId(npcTemplate, level, reviseId)
end

---获取属性加成id列表
---@param npcData userdata npc数据
---@return XCode,table 状态码和属性id列表
local function GetGrowRateAttribIds(npcData)
    local attribIds = {}
    for _, inter in pairs(AddGrowRateIdInterfaces) do
        local code = inter(npcData, attribIds)
        if code ~= XCode.Success then
            return code, nil
        end
    end

    if npcData.AttribGroupList then
        local attribGroupList = npcData.AttribGroupList
        if type(attribGroupList) == "userdata" then
            attribGroupList = XTool.CsList2LuaTable(attribGroupList)
        end

        if #attribGroupList > 0 then
            for _, id in pairs(attribGroupList) do
                local code, group = GetAttribGroupTemplate(id)
                if code ~= XCode.Success then
                    return code, nil
                end

                if group.AttribGrowRateId > 0 then
                    tableInsert(attribIds, group.AttribGrowRateId)
                end
            end
        end
    end

    return XCode.Success, attribIds
end

---获取属性叠加id列表
---@param npcData userdata npc数据
---@return XCode,table 状态码和属性id列表
local function GetNumericAttribIds(npcData)
    local attribIds = {}
    for _, inter in pairs(AddNumericIdInterfaces) do
        local code = inter(npcData, attribIds)
        if code ~= XCode.Success then
            return code, nil
        end
    end

    if npcData.AttribGroupList then
        local attribGroupList = npcData.AttribGroupList
        if type(attribGroupList) == "userdata" then
            attribGroupList = XTool.CsList2LuaTable(attribGroupList)
        end

        if #attribGroupList > 0 then
            for _, id in pairs(attribGroupList) do
                local code, group = GetAttribGroupTemplate(id)
                if code ~= XCode.Success then
                    return code, nil
                end

                if group.AttribId > 0 then
                    tableInsert(attribIds, group.AttribId)
                end
            end
        end
    end

    return XCode.Success, attribIds
end

---获取属性成长id列表和培养等级列表
---@param npcData userdata npc数据
---@return XCode,table,table 状态码和属性id列表、培养等级列表
local function GetPromotedAttribIds(npcData)
    local attribIds = {}
    local levels = {}

    for _, inter in pairs(AddPromotedIdInterfaces) do
        local code = inter(npcData, attribIds, levels)
        if code ~= XCode.Success then
            return code, nil, nil
        end
    end

    return XCode.Success, attribIds, levels
end

---属性加成计算
---@param npcData userdata npc数据
---@param attribs fix[] 属性数组
---@return XCode 状态码
local function DoAddGrowRateAttribs(npcData, attribs)
    local code, attribIds = GetGrowRateAttribIds(npcData)
    if code ~= XCode.Success then
        return code
    end

    local growRateAttribs
    code, growRateAttribs = GetTotalGrowRateAttribs(attribIds)
    if code ~= XCode.Success then
        return code
    end

    DoGrowRateAttribs(attribs, growRateAttribs)

    return XCode.Success
end

---属性叠加计算
---@param npcData userdata npc数据
---@param attribs fix[] 属性数组
---@return XCode 状态码
local function DoAddNumericAttribs(npcData, attribs)
    local code, attribIds = GetNumericAttribIds(npcData)
    if code ~= XCode.Success then
        return code
    end

    local numericAttribs
    code, numericAttribs = GetTotalNumericAttribs(attribIds)
    if code ~= XCode.Success then
        return code
    end

    DoAddAttribs(attribs, numericAttribs)

    return XCode.Success
end

---属性成长计算
---@param npcData userdata npc数据
---@param attribs fix[] 属性数组
---@return XCode 状态码
local function DoAddPromotedAttribs(npcData, attribs)
    local code, attribIds, levels = GetPromotedAttribIds(npcData)
    if code ~= XCode.Success then
        return code
    end

    local promotedAttribs
    code, promotedAttribs = GetTotalPromotedAttribs(attribIds, levels)
    if code ~= XCode.Success then
        return code
    end

    DoAddAttribs(attribs, promotedAttribs)

    return XCode.Success
end

---获取npc属性
---@param npcData userdata npc数据
---@return XCode,fix[] 状态码和属性数组
local function GetNpcAttribs(npcData)
    local attribs
    local characterData = npcData.Character

    local code, npcId = XFightCharacterManager.GetNpcId(characterData)
    if code ~= XCode.Success then
        return code, nil
    end

    code, attribs = GetNpcBaseAttribsByNpcId(npcId, characterData.Level)
    if code ~= XCode.Success then
        return code, nil
    end

    --- 属性加成只针对基础属性，需要第一个计算
    code = DoAddGrowRateAttribs(npcData, attribs)
    if code ~= XCode.Success then
        return code, nil
    end

    code = DoAddNumericAttribs(npcData, attribs)
    if code ~= XCode.Success then
        return code, nil
    end

    code = DoAddPromotedAttribs(npcData, attribs)
    if code ~= XCode.Success then
        return code, nil
    end

    if npcData.AttribReviseId and npcData.AttribReviseId > 0 then
        code = ReviseAttribs(attribs, npcData.AttribReviseId)
        if code ~= XCode.Success then
            return code, nil
        end
    end

    return XCode.Success, attribs
end

local function TryGetNpcBaseAttribs(npcTemplateId, level, reviseId)
    local code, attribs = GetNpcBaseAttribsByNpcIdWithReviseId(npcTemplateId, level, reviseId)
    if code ~= XCode.Success then
        XLog.Error("TryGetNpcBaseAttribs error: code is ", code)
        return nil
    end

    return Fix2XAttrib(attribs)
end

local function TryGetNpcAttribs(npcData)
    local code, attribs = GetNpcAttribs(npcData)
    if code ~= XCode.Success then
        XLog.Error("TryGetNpcAttribs error: code is ", code)
        return nil
    end

    return Fix2XAttrib(attribs)
end

--region 装备属性
--获取单个装备基础属性
--包括 突破属性, 成长属性
local function GetNpcEquipBaseAttribs(npcData, equipSite)
    local attribIds = {}
    local code = XFightEquipManager.AddBreakthroughAttribIdByEquipSite(npcData, equipSite, attribIds)
    if (code ~= XCode.Success) then
        return code
    end

    local attribs = CreateAttribArray(true)
    local numericAttribs
    code, numericAttribs = GetTotalNumericAttribs(attribIds)
    if code ~= XCode.Success then
        return code
    end

    DoAddAttribs(attribs, numericAttribs)

    attribIds = {}
    local trainedLevels = {}
    XFightEquipManager.AddPromotedAttribIdByEquipSite(npcData, equipSite, attribIds, trainedLevels)

    local promotedAttribs
    code, promotedAttribs = GetTotalPromotedAttribs(attribIds, trainedLevels)
    if code ~= XCode.Success then
        return code
    end

    DoAddAttribs(attribs, promotedAttribs)

    return XCode.Success, attribs
end

local function TryGetNpcEquipBaseAttribs(npcData, equipSite)
    local code, attribs = GetNpcEquipBaseAttribs(npcData, equipSite)
    if code ~= XCode.Success then
        return
    end
    return Fix2XAttrib(attribs)
end
--endregion 装备属性

-------------------------------------------------------------------------------------------
XAttribManager.GetAttribAbility = function(attribs)
    if not attribs then
        return
    end

    local ability = fix.zero
    for k, attr in pairs(attribs) do
        local attribKey = XAttribManager.GetAttribKeyByIndex(k)
        local template = AttribAbilityTemplate[attribKey]
        if template and template.Ability > fix.zero then
            ability = ability + attr * template.Ability
        end
    end

    return FixToInt(ability)
end

XAttribManager.GetPartnerAttribAbility = function(attribs)
    if not attribs then
        return
    end

    local ability = fix.zero
    for k, attr in pairs(attribs) do
        local attribKey = XAttribManager.GetAttribKeyByIndex(k)
        local template = AttribAbilityTemplate[attribKey]
        if template and template.PartnerAbility > fix.zero then
            ability = ability + attr * template.PartnerAbility
        end
    end

    return FixToInt(ability)
end

XAttribManager.GetAttribGroupTemplate = GetAttribGroupTemplate

---------------------------------------客户端特有方法---------------------------------------
---获取合并属性数组(fix结构)
---@param numericIds table 数值加成id列表
---@param promotedIds table 等级提升id列表
---@param trainedLevels table 等级列表
---@return fix[] fix数组
function XAttribManager.GetMergeAttribs(numericIds, promotedIds, trainedLevels)
    local attribs = CreateAttribArray()
    if #numericIds > 0 then
        local code, numericAttribs = GetTotalNumericAttribs(numericIds)
        if code ~= XCode.Success then
            return
        end

        DoAddAttribs(attribs, numericAttribs)
    end

    if (trainedLevels and promotedIds) and (#promotedIds > 0 and #trainedLevels > 0) then
        local code, promotedAttribs = GetTotalPromotedAttribs(promotedIds, trainedLevels)
        if code ~= XCode.Success then
            return
        end

        DoAddAttribs(attribs, promotedAttribs)
    end

    return attribs
end

---获取基础属性数组
---@param attribId number|table 属性id或者属性id列表
---@return fix[] 属性fix数组
function XAttribManager.GetBaseAttribs(attribId)
    local attribIdList = {}

    if type(attribId) ~= "table" then
        tableInsert(attribIdList, attribId)
    else
        attribIdList = attribId
    end

    local code, attribs = GetTotalNumericAttribs(attribIdList)
    if code ~= XCode.Success then
        return nil
    end

    return attribs
end

---获取等级提升属性数组
---@param attribId number|table 属性id或者属性id列表
---@param level number|table 等级或者等级列表
---@return fix[] 属性fix数组
function XAttribManager.GetPromotedAttribs(attribId, level)
    local attribIds = {}
    local levels = {}

    if type(attribId) ~= "table" then
        tableInsert(attribIds, attribId)
    else
        attribIds = attribId
    end

    if not level then
        for _ = 1, #attribIds do
            tableInsert(levels, 1)
        end
    elseif type(level) ~= "table" then
        tableInsert(levels, level)
    else
        levels = level
    end

    local code, attribs = GetTotalPromotedAttribs(attribIds, levels)
    if code ~= XCode.Success then
        return nil
    end

    return attribs
end

---获取提升比例属性数组
---@param attribId number|table 属性id或者属性id列表
---@return fix[] 属性fix数组
function XAttribManager.GetGrowRateAttribs(attribId)
    local attribIdList = {}

    if type(attribId) ~= "table" then
        tableInsert(attribIdList, attribId)
    else
        attribIdList = attribId
    end

    local code, attribs = GetTotalGrowRateAttribs(attribIdList)
    if code ~= XCode.Success then
        return nil
    end

    return attribs
end

function XAttribManager.GetAttribNameByIndex(index)
    local template = AttribDescTemplates[index]
    if not template then
        return
    end
    return template.Name
end

function XAttribManager.GetAttribKeyByIndex(index)
    local template = AttribDescTemplates[index]
    if not template then
        return
    end
    return template.Attrib
end

---获取npc属性
---@param npcData table npc数据
---@return table fix属性数组
XAttribManager.GetNpcAttribs = function(npcData)
    local code, attribs = GetNpcAttribs(npcData)
    if code ~= XCode.Success then
        return nil
    end

    return attribs
end

--============
--属性加值
--============
XAttribManager.DoAddAttribsByAttrAndAddId = function(attr, attrId)
    local attr1 = XAttribManager.GetAttribByAttribId(attrId)
    DoAddAttribs(attr, attr1)
end

XAttribManager.GetAttribByAttribId = function(attribId)
    local code, baseAttribs = GetAttribTemplate(attribId)
    if code then return baseAttribs end
    return nil
end

XAttribManager.TryGetAttribGroupTemplate = function(id)
    local code, template = GetAttribGroupTemplate(id)
    if code ~= XCode.Success then
        XLog.Error("XAttribManager.GetAttribGroupTemplate error: code is ", code)
        return nil
    end

    return template
end

---获取npc基础属性
XAttribManager.GetNpcBaseAttribsByNpcIdWithReviseId = function(npcTemplateId, level, reviseId)
    local code, attribs = GetNpcBaseAttribsByNpcIdWithReviseId(npcTemplateId, level, reviseId)
    if code ~= XCode.Success then
        return nil
    end

    return attribs
end

-------------------------------------Partner相关----------------------------------------------------
-- 伙伴属性id获取接口
local AddPartnerNumericIdInterfaces = {}
local AddPartnerPromotedIdInterfaces = {}

function XAttribManager.RegisterPartnerNumericIdInterface(inter)
    tableInsert(AddPartnerNumericIdInterfaces, inter)
end

function XAttribManager.RegisterPartnerPromotedIdInterface(inter)
    tableInsert(AddPartnerPromotedIdInterfaces, inter)
end

---获取Partner基础属性
local function GetPartnerBaseAttribs(partnerData, attribs)
    local partnerEntity = XDataCenter.PartnerManager.CreatePartnerEntityByPartnerData(partnerData)

    if partnerEntity then
        return XCode.PartnerTemplateNotFound
    end
    local code, baseAttribs = GetAttribTemplate(partnerEntity:GetBaseAttribId())
    if code ~= XCode.Success then
        return code, nil
    end
    DoAddAttribs(attribs, baseAttribs)
    return XCode.Success
end

---获取属性叠加id列表
local function GetPartnerNumericAttribIds(partnerData)
    local attribIds = {}
    for _, inter in pairs(AddPartnerNumericIdInterfaces) do
        local code = inter(partnerData, attribIds)
        if code ~= XCode.Success then
            return code, nil
        end
    end

    return XCode.Success, attribIds
end

---获取属性成长id列表和培养等级列表
local function GetPartnerPromotedAttribIds(partnerData)
    local attribIds = {}
    local levels = {}

    for _, inter in pairs(AddPartnerPromotedIdInterfaces) do
        local code = inter(partnerData, attribIds, levels)
        if code ~= XCode.Success then
            return code, nil, nil
        end
    end

    return XCode.Success, attribIds, levels
end

---属性叠加计算
local function DoAddPartnerNumericAttribs(partnerData, attribs)
    local code, attribIds = GetPartnerNumericAttribIds(partnerData)
    if code ~= XCode.Success then
        return code
    end

    local numericAttribs
    code, numericAttribs = GetTotalNumericAttribs(attribIds)
    if code ~= XCode.Success then
        return code
    end

    DoAddAttribs(attribs, numericAttribs)

    return XCode.Success
end

---属性成长计算
local function DoAddPartnerPromotedAttribs(partnerData, attribs)
    local code, attribIds, levels = GetPartnerPromotedAttribIds(partnerData)
    if code ~= XCode.Success then
        return code
    end

    local promotedAttribs
    code, promotedAttribs = GetTotalPromotedAttribs(attribIds, levels)
    if code ~= XCode.Success then
        return code
    end

    DoAddAttribs(attribs, promotedAttribs)
    return XCode.Success
end

---获取Partner属性
local function GetPartnerAttribs(partnerData)
    local attribs = CreateAttribArray()

    local code = DoAddPartnerNumericAttribs(partnerData, attribs)
    if code ~= XCode.Success then
        return code, nil
    end

    code = DoAddPartnerPromotedAttribs(partnerData, attribs)
    if code ~= XCode.Success then
        return code, nil
    end

    return XCode.Success, attribs
end

local function TryGetPartnerAttribs(partnerData)
    local code, attribs = GetPartnerAttribs(partnerData)
    if code ~= XCode.Success then
        XLog.Error("TryGetPartnerAttribs error: code is ", code)
        return nil
    end

    return Fix2XAttrib(attribs)
end

------------------------------------------------------------------------------------------
---------------------------------------客户端特有方法---------------------------------------
local _IsInited

function XAttribManager.Init()
    CS.XFightDelegate.GetNpcBaseAttrib = TryGetNpcBaseAttribs
    CS.XFightDelegate.GetNpcAttrib = TryGetNpcAttribs
    CS.XFightDelegate.GetPartnerAttrib = TryGetPartnerAttribs
    CS.XFightDelegate.GetNpcEquipBaseAttrib = TryGetNpcEquipBaseAttribs
    LoadAttribConfig()

    _IsInited = true
    XEventManager.DispatchEvent(XEventId.EVENT_ATTRIBUTE_MANAGER_INIT)
end

function XAttribManager.IsInited()
    return _IsInited
end