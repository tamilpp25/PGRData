XTableManager = XTableManager or {}

local rawget = rawget
local pairs = pairs
local tonumber = tonumber
local tostring = tostring
local math = math
local mathFloor = math.floor
local string = string
local stringFind = string.find
local stringSub = string.sub
local stringGmatch = string.gmatch
local stringSplit = string.Split
local table = table
local tableInsert = table.insert

local loadFileProfiler = XGame.Profiler:CreateChild("LoadTableFile")
local readTabFileProfiler = XGame.Profiler:CreateChild("ReadTabFile")
--只读标志
local NeedSetReadonly = CS.XLuaEngine.LuaReadonlyTableMode ~= CS.XMode.Release
--只读元表
local ReadOnlyTable = {
    __newindex = function()
        XLog.Error("attempt to update a readonly table")
    end
}

local WhiteTable = {
    ["Share/Condition/Condition.tab"] = 1,
    ["Share/Player/HonorLevel.tab"] = 1,
    ["Client/ResourceLut/Model/Model.tab"] = 1,
    ["Share/Fashion/Fashion.tab"] = 1,
    ["Share/Fuben/Experiment/BattleExperiment.tab"] = 1,

    --|  |--NotifyTask [Count: 1, Time: 65.00 ms]: -1734165120
    ["Share/Task/Task.tab"] = 1,

    --|  |--NotifyStageData [Count: 1, Time: 733.79 ms]: -666193280
    ["Share/Fuben/Stage.tab"] = 1,
    ["Share/Fuben/MainLine/ChapterMain.tab"] = 1,
    ["Share/Fuben/MainLine/Chapter.tab"] = 1,
    ["Share/Fuben/MainLine/Treasure.tab"] = 1,
    ["Share/Fuben/Daily/DailyDungeonData.tab"] = 1,
    ["Share/Fuben/UrgentEvent/UrgentEvent.tab"] = 1,
    ["Share/Fuben/BossSingle/BossSingleSection.tab"] = 1,
    ["Share/Fuben/BossSingle/BossSingleStage.tab"] = 1,
    ["Share/Fuben/BossOnline/BossOnlineSection.tab"] = 1,
    ["Share/Fuben/Bfrt/BfrtGroup.tab"] = 1,
    ["Share/BountyTask/BountyTask.tab"] = 1,
    ["Share/Fuben/Prequel/Chapter.tab"] = 1,
    ["Share/Fuben/Prequel/Cover.tab"] = 1,
    ["Share/Fuben/Arena/AreaStage.tab"] = 1,
    ["Share/Fuben/Experiment/ExperimentLevel.tab"] = 1,
    ["Share/Fuben/Explore/ExploreNode.tab"] = 1,
    ["Share/Fuben/FubenBranch/FubenBranchSection.tab"] = 1,
    ["Share/Fuben/BossActivity/BossSection.tab"] = 1,
    ["Share/Fuben/BossActivity/BossChallenge.tab"] = 1,
    ["Share/Fuben/Practice/PracticeChapter.tab"] = 1,
    ["Share/Fuben/Festival/FestivalActivity.tab"] = 1,
    ["Share/Fuben/BabelTower/BabelTowerActivity.tab"] = 1,
    ["Share/Fuben/RepeatChallenge/RepeatChallengeActivity.tab"] = 1,
    ["Share/Fuben/RepeatChallenge/RepeatChallengeChapter.tab"] = 1,
    ["Share/Fuben/RogueLike/RogueLikeNode.tab"] = 1,
    ["Share/Fuben/Assign/AssignChapter.tab"] = 1,
    ["Share/Fuben/Assign/AssignGroup.tab"] = 1,
    ["Share/Fuben/ArenaOnline/ArenaOnlineStage.tab"] = 1,
    ["Share/Fuben/StageMultiplayerLevelControl.tab"] = 1,
    ["Share/Fuben/ExtraChapter/ChapterExtra.tab"] = 1,
    ["Share/Fuben/ExtraChapter/ChapterExtraDetails.tab"] = 1,
    ["Share/Fuben/ExtraChapter/ChapterExtraStarTreasure.tab"] = 1,
    ["Share/Fuben/SpecialTrain/Chapter.tab"] = 1,
    ["Share/Fuben/InfestorExplore/ExploreNode.tab"] = 1,
    ["Share/Fuben/InfestorExplore/InfestorActivity.tab"] = 1,
    ["Share/Fuben/Expedition/ExpeditionStage.tab"] = 1,
    ["Share/Fuben/Expedition/ExpeditionChapter.tab"] = 1,
    ["Share/Fuben/WorldBoss/WorldBossAttributeArea.tab"] = 1,
    ["Share/Fuben/WorldBoss/WorldBossBossArea.tab"] = 1,
    ["Share/Fuben/Rpg/RpgStage.tab"] = 1,
    ["Share/Fuben/MaintainerAction/MaintainerActionConfig.tab"] = 1,
    ["Share/Fuben/MaintainerAction/MaintainerActionLevel.tab"] = 1,
    ["Share/TRPG/Boss/TRPGBoss.tab"] = 1,
    ["Share/TRPG/TRPGFunction.tab"] = 1,
    ["Share/TRPG/SecondMain/TRPGSecondMain.tab"] = 1,
    ["Share/TRPG/SecondMain/TRPGSecondMainStage.tab"] = 1,
    ["Share/Fuben/NieR/NieRChapter.tab"] = 1,
    ["Share/Fuben/NieR/NieRCharacter.tab"] = 1,
    ["Share/Fuben/NieR/NieRRepeatableStage.tab"] = 1,
    ["Share/Fuben/NieR/NieRActivity.tab"] = 1,
    ["Share/Fuben/ZhouMu/ZhouMuChapter.tab"] = 1,
    ["Share/Fuben/Teaching/TeachingActivity.tab"] = 1,
    ["Share/ChessPursuit/ChessPursuitBoss.tab"] = 1,
    ["Share/Fuben/Hack/HackStage.tab"] = 1,
    ["Share/Fuben/Hack/HackChapter.tab"] = 1,
    ["Share/Fuben/PartnerTeaching/PartnerTeachingChapter.tab"] = 1,
    ["Share/Fuben/Reform/ReformStage.tab"] = 1,
    ["Share/Fuben/KillZone/KillZoneStage.tab"] = 1,
    ["Share/Fuben/FashionStory/FashionStory.tab"] = 1,
    ["Share/Fuben/CoupleCombat/CoupleCombatChapter.tab"] = 1,
    ["Share/Fuben/CoupleCombat/CoupleCombatStage.tab"] = 1,

    --|  |--NotifyArchiveMonsterRecord [Count: 1, Time: 29.42 ms]: -1491350400
    ["Share/Archive/Monster.tab"] = 1,
    ["Share/Archive/MonsterInfo.tab"] = 1,
    ["Share/Archive/MonsterSetting.tab"] = 1,

    --|  |--NotifyCharacterDataList [Count: 1, Time: 243.18 ms]: 742671616
    ["Share/Fight/Npc/Npc"] = 1,
    ["Share/Attrib/AttribDesc.tab"] = 1,
    ["Share/Attrib/AttribAbility.tab"] = 1,
    ["Share/Equip/WeaponSkill.tab"] = 1,
    ["Share/Equip/EquipSuit.tab"] = 1,
    ["Share/Equip/EquipSuitEffect.tab"] = 1,


    ["Share/Character/Character.tab"] = 1,
    -- ["Share/Character/LevelUpTemplate/1.tab"] = 1, -- 
}

--默认类型
local DefaultOfType = {
    ["int"] = 0,
    ["float"] = 0,
    ["string"] = nil,
    ["bool"] = false,
    ["fix"] = fix.zero,
}

local ToInt = function(value)
    return mathFloor(value)
end

local ToFloat = function(value)
    return tonumber(value)
end

local ToString = function(value)
    return tostring(value)
end

local ToBool = function(value)
    return tonumber(value) ~= 0 and true or false
end

local ToFix = function(value)
    return FixParse(value)
end

local LIST_FLAG = 1
local DICTIONARY_FLAG = 2

local ValueFunc = {
    ["int"] = ToInt,
    ["float"] = ToFloat,
    ["string"] = ToString,
    ["bool"] = ToBool,
    ["fix"] = ToFix,
}

local KeyFunc = {
    ["int"] = ToInt,
    ["string"] = ToString,
}

local GetSingleValueNew = function(type, value)
    local func = ValueFunc[type]
    if not func then
        return
    end

    if not value or #value == 0 then
        return nil
    end

    return func(value)
end

local GetSingleValue = function(type, value)
    local func = ValueFunc[type]
    if not func then
        return
    end

    if not value or #value == 0 then
        return DefaultOfType[type]
    end

    return func(value)
end

local GetContainerValue = function(type, value)
    local func = ValueFunc[type]
    if not func then
        return
    end

    if not value or #value == 0 then
        return
    end

    return func(value)
end

local GetDictionaryKey = function(type, value)
    local func = KeyFunc[type]
    if not func then
        return
    end

    if not value or #value == 0 then
        return
    end

    return func(value)
end

local IsDictionary = function(paramConfig)
    return paramConfig.Type == DICTIONARY_FLAG
end

local IsList = function(paramConfig)
    return paramConfig.Type == LIST_FLAG
end

local IsTable = function(pramsConfig)
    return IsDictionary(pramsConfig) or IsList(pramsConfig)
end

local EmptyTable = {}

-- type func end--
local READ_KEY_TYPE = {
    INT = 0,
    STRING = 1
}

local Split = function(str)
    local arr = {}
    for v in stringGmatch(str, '[^\t]*') do
        tableInsert(arr, v)
    end
    return arr
end

local CreateColElems = function(tableConfig)
    local elems = {}
    for key, paramConfig in pairs(tableConfig) do
        if IsTable(paramConfig) then
            elems[key] = {}
        else
            elems[key] = DefaultOfType[paramConfig.ValueType]
        end
    end

    return elems
end

local ReadWithContext = function(context, tableConfig, keyType, identifier, path)
    local file = assert(context)
    local iter = stringSplit(file, "\r\n") --每一行内容
    local names = Split(iter[1])-- 表头
    local keys = {} --存储某一列字典类型的键值
    local cols = #names
    local keyIndexTable = {}
    local j = 1

    -- 表头解析和检查
    for i = 1, cols do
        local name = names[i]
        local key
        local startIndex = stringFind(name, "[[]")
        if startIndex and startIndex > 0 then
            local endIndex = stringFind(name, "[]]")
            if startIndex ~= endIndex and endIndex == #name then-- 处理数组表头
                key = stringSub(name, startIndex + 1, endIndex - 1) --Dic key Array[2]中的 2
                name = stringSub(name, 1, startIndex - 1)
                names[i] = name --Id Name Array[1] Array[2] ->Id Name Array Array
                if not keyIndexTable[name] then
                    keyIndexTable[name] = j
                    j = j + 1
                end
            else
                XLog.Error("XTableManager.ReadTabFile 函数错误, 读取数据失败, 路径是 = " .. path .. ", 名字 = " .. name .. ", 开始索引 = " .. startIndex .. ", 结束索引 = " .. endIndex)
                return
            end
        else
            keyIndexTable[name] = j
            j = j + 1
        end


        -- 检查属性是否有配置
        local paramConfig = tableConfig[name]
        if not paramConfig then
            goto continue
        end

        -- 字典类型处理
        if IsDictionary(paramConfig) then
            if not key then
                XLog.Error("XTableManager.ReadTabFile 函数错误: 读取数据失败，路径 = " .. path .. ", name = " .. name)
                return
            end

            local ret = GetDictionaryKey(paramConfig.KeyType, key) --Array[key] 吧key转成目标类型
            if not ret then
                XLog.Error("XTableManager.ReadTabFile 函数错误: 读取数据失败，路径 = " .. path .. ", name = " .. name .. ", type = " .. paramConfig.KeyType .. ", key = " .. key)
                return
            end

            keys[i] = ret
        end

        :: continue ::
    end
    ---每一个表对应一个元表
    local metaTable = {}

    metaTable.__index = function(tbl, keyIndex)
        local idx = keyIndexTable[keyIndex]

        if not idx or not tbl then
            return nil
        end

        local result = rawget(tbl, idx)
        local resultType = tableConfig[keyIndex]

        if not resultType then
            XLog.Error(string.format("找不到键值 Key:%s 请检查该键值和表头是否匹配", keyIndex))
        end

        if not result then
            if resultType and IsTable(resultType) then
                result = EmptyTable
            else
                result = DefaultOfType[resultType.ValueType]
            end
        end

        return result
    end

    metaTable.__newindex = function()
        XLog.Error("attempt to update a readonly table")
    end

    metaTable.__metatable = "readonly table"


    metaTable.__pairs = function(t)
        local function stateless_iter(tbl, key)
            local nk = next(tbl, key)

            if nk and type(nk) == "string" then
                local k = keyIndexTable[nk]
                local nv = t[k] or t[nk]
                return nk, nv
            end
        end

        return stateless_iter, tableConfig, nil
    end

    local tab = {}
    local index = 1
    local lineCount = #iter
    for i = 2, lineCount do -- 遍历每一行表内容
        local line = iter[i]

        if not line or #line == 0 then
            goto nextLine
        end

        local elemArray = {}
        local elems = {} --CreateColElems(tableConfig) --存储每一列类型的默认值
        local tmpElems = Split(line) --分割每一行内容，\t
        --如果表头长度和内容长度匹配不上
        if #tmpElems ~= cols then
            XLog.Warning("XTableManager.ReadTabFile warning: cols not match, path = " .. path .. ", row = " .. index .. ", cols = " .. cols .. ", cells length = " .. #tmpElems)
        end

        for i2 = 1, cols do
            local name = names[i2] --表头键值
            local value = tmpElems[i2] -- 单元格内容
            local paramConfig = tableConfig[name] --单元格类型

            if paramConfig then
                --如果是列表
                if IsList(paramConfig) then   -- 数组
                    value = GetContainerValue(paramConfig.ValueType, value) --单元格字符串转换成目标类型
                    if not elems[name] or not next(elems[name]) then
                        elems[name] = {}
                        if NeedSetReadonly then
                            setmetatable(elems[name], ReadOnlyTable)
                        end
                    end

                    if value then
                        local len = #elems[name]
                        rawset(elems[name], len + 1, value)
                    end
                elseif IsDictionary(paramConfig) then     -- 字典
                    value = GetContainerValue(paramConfig.ValueType, value)
                    if not elems[name] or not next(elems[name]) then
                        elems[name] = {}

                        if NeedSetReadonly then
                            setmetatable(elems[name], ReadOnlyTable)
                        end
                    end

                    if value then
                        local key = keys[i2]
                        rawset(elems[name], key, value)
                    end
                else
                    elems[name] = GetSingleValueNew(paramConfig.ValueType, value)
                end

                elemArray[keyIndexTable[name]] = elems[name]
                --else
                --- XLog.Warning(string.format("表格%s 没有导出XTable.lua ,没找到Key：%s", path, name))
            end
        end


        if identifier then
            local mainKey = elems[identifier]
            if not mainKey then
                XLog.Warning("表格有空行, path = " .. path .. ", row = " .. index .. ", cols = " .. cols .. ", cells length = " .. #tmpElems)
                goto nextLine
            end

            local id = keyType == READ_KEY_TYPE.STRING and tostring(mainKey) or mathFloor(mainKey)
            if tab[id] then
                XLog.Error("表格有重复键值, path = " .. path .. ", row = " .. index .. ", cols = " .. cols .. ", key = " .. id .. ", cells length = " .. #tmpElems)
                goto nextLine
            end
            tab[id] = elemArray
        else
            tab[index] = elemArray
        end

        setmetatable(elemArray, metaTable)

        index = index + 1

        :: nextLine ::
    end

    return tab
end

local ReadTabFile = function(path, tableConfig, keyType, identifier)
    loadFileProfiler:Start()
    local context = CS.XTableManager.Load(path)
    loadFileProfiler:Stop()

    readTabFileProfiler:Start()
    local content = ReadWithContext(context, tableConfig, keyType, identifier, path)
    readTabFileProfiler:Stop()

    return content
end

function XTableManager.ReadByIntKeyWithContent(context, xtable, identifier)
    return ReadWithContext(context, xtable, READ_KEY_TYPE.INT, identifier, "unknown")
end

function XTableManager.ReadByStringKeyWithContent(context, xtable, identifier)
    return ReadWithContext(context, xtable, READ_KEY_TYPE.STRING, identifier, "unknown")
end

local TableCache = {}

function XTableManager.ReleaseTableCache()
    for k, v in pairs(TableCache) do
        if not WhiteTable[k] then
            TableCache[k] = nil
        end
    end
end

function XTableManager.ReadByIntKey(path, xtable, identifier)
    local tab = {}

    local tableHandle = XTableManager.ReadByIntKeyInner(path, xtable, identifier)
    TableCache[path] = tableHandle

    local len = #tableHandle

    local mate = {}
    mate.__index = function(tab, key)
        if not key then
            return nil
        end

        local _ = TableCache[path]

        if not _ then
            _ = XTableManager.ReadByIntKeyInner(path, xtable, identifier)
            TableCache[path] = _
        end

        local data = _[key]
        return data
    end

    mate.__newindex = function()
        XLog.Error("attempt to update a readonly table")
    end

    mate.__metatable = "readonly table"

    mate.__len = function(t)
        return len
    end

    mate.__pairs = function(t)
        local _ = TableCache[path]

        if not _ then
            _ = XTableManager.ReadByIntKeyInner(path, xtable, identifier)
            TableCache[path] = _
        end


        local function stateless_iter(tbl, key)
            local nk, nv = next(tbl, key)
            return nk, nv
        end

        return stateless_iter, _, nil
    end

    setmetatable(tab, mate)
    return tab
end



function XTableManager.ReadByStringKey(path, xtable, identifier)
    local tab = {}

    local tableHandle = XTableManager.ReadByStringKeyInner(path, xtable, identifier)

    TableCache[path] = tableHandle

    local len = #tableHandle

    local mate = {}
    mate.__index = function(tab, key)
        if not key then
            return nil
        end

        local _ = TableCache[path]

        if not _ then
            _ = XTableManager.ReadByStringKeyInner(path, xtable, identifier)
            TableCache[path] = _
        end

        local data = _[key]
        return data
    end

    mate.__newindex = function()
        XLog.Error("attempt to update a readonly table")
    end

    mate.__metatable = "readonly table"

    mate.__len = function(t)
        return len
    end

    mate.__pairs = function(t)
        local _ = TableCache[path]

        if not _ then
            _ = XTableManager.ReadByStringKeyInner(path, xtable, identifier)
            TableCache[path] = _
        end


        local function stateless_iter(tbl, key)
            local nk, nv = next(tbl, key)
            return nk, nv
        end

        return stateless_iter, _, nil
    end

    setmetatable(tab, mate)
    return tab
end

function XTableManager.ReadByIntKeyInner(path, xtable, identifier)
    if path == nil or #path == 0 then
        XLog.Error("XTableManager ReadByIntKey 函数错误, 表的路径不能为空Path: " .. xtable)
        return
    end

    if xtable == nil then
        XLog.Error("XTableManager ReadByIntKey 函数错误, 配置表需要在xtable中定义相应的字段, 路径是: " .. path)
        return
    end

    if string.EndsWith(path, ".tab") then
        return ReadTabFile(path, xtable, READ_KEY_TYPE.INT, identifier)
    end

    local paths = CS.XTableManager.GetPaths(path)
    local mergeTable = {}

    XTool.LoopCollection(paths, function(tmpPath)
        local t = ReadTabFile(tmpPath, xtable, READ_KEY_TYPE.INT, identifier)
        for k, v in pairs(t) do
            if mergeTable[k] then
                XLog.Error("XTableManager ReadByIntKey 函数错误, 配置表项键值重复检查配置表, 路径: " .. tmpPath .. ", identifier: " .. identifier .. ", key: " .. k)
                return
            end
            mergeTable[k] = v
        end
    end)

    return mergeTable
end

function XTableManager.ReadByStringKeyInner(path, xtable, identifier)
    if path == nil or #path == 0 then
        XLog.Error("XTableManager ReadByStringKey 函数错误, 配置表的路径不能为空, path: " .. path)
        return
    end

    if xtable == nil then
        XLog.Error("XTableManager ReadByStringKey 函数错误, 必须根据此配置表在xtable中定义相应的字段, 配置表路径: " .. path)
        return
    end

    if identifier == nil or #identifier == 0 then
        XLog.Error("XTableManager ReadByStringKey 函数错误, 参数identifier不能为空, path: " .. path)
        return
    end

    if string.EndsWith(path, ".tab") then
        return ReadTabFile(path, xtable, READ_KEY_TYPE.STRING, identifier)
    end

    local paths = CS.XTableManager.GetPaths(path)
    local mergeTable = {}

    XTool.LoopCollection(paths, function(tmpPath)
        local t = ReadTabFile(tmpPath, xtable, READ_KEY_TYPE.STRING, identifier)
        for k, v in pairs(t) do
            if mergeTable[k] then
                XLog.Error("XTableManager ReadByStringKey函数错误, 配置表项键值重复检查配置表, 路径: " .. tmpPath .. ", identifier: " .. identifier .. ", key: " .. k)
                return
            end
            mergeTable[k] = v
        end
    end)

    return mergeTable
end

function XTableManager.ReadArray(path, xtable, identifier)
    return XTableManager.ReadByIntKey(path, xtable)
end