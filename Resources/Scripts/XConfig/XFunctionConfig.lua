XFunctionConfig = XFunctionConfig or {}

local tableInsert = table.insert
--XFunctionManager.OpenCondition = {
--    Default = 0, -- 默认
--    TeamLevel = 1, -- 战队等级
--    FinishSection = 2, -- 通关副本
--    FinishTask = 3, -- 完成任务
--    FinishNoob = 4, -- 完成新手
--    Main = 5, -- 掉线返回主界面
--}

-- XFunctionManager.OpenHint = {
--     TeamLevelToOpen,
--     CopyToOpen,
--     FinishToOpen
-- }

local FunctionalOpenTemplates = {}  --功能开启表
local SecondaryFunctionalTemplates = {}  --二级功能配置
local SkipFunctionalTemplates = {}  --跳转功能表
-- local MainAdTemplates = {}          --广告栏
local MainActivitySkipTemplates = {} --活动便捷入口
local ShieldFuncTemplates = {}      -- 功能对应的界面名称
local OpenList = {}

local SHARE_FUNCTIONAL_OPEN = "Share/Functional/FunctionalOpen.tab"
local TABLE_SECONDARY_FUNCTIONAL_PATH = "Client/Functional/SecondaryFunctional.tab"
local TABLE_SKIP_FUNCTIONAL_PATH = "Client/Functional/SkipFunctional.tab"
--local TABLE_MAIN_AD = "Client/Functional/MainAd.tab"
local TABLE_MAIN_ACTIVITY_SKIP_PATH = "Client/Functional/MainActivitySkip.tab"
local TABLE_SHIELD_FUNC_PATH = "Client/Functional/ShieldFuncList.tab"

function XFunctionConfig.Init()
    FunctionalOpenTemplates = {}
    OpenList = {}
    SecondaryFunctionalTemplates = XTableManager.ReadByIntKey(TABLE_SECONDARY_FUNCTIONAL_PATH, XTable.XTableSecondaryFunctional, "Id")
    SkipFunctionalTemplates = XTableManager.ReadByIntKey(TABLE_SKIP_FUNCTIONAL_PATH, XTable.XTableSkipFunctional, "SkipId")
    MainActivitySkipTemplates = XTableManager.ReadByIntKey(TABLE_MAIN_ACTIVITY_SKIP_PATH, XTable.XTableMainActivitySkip, "Id")
    ShieldFuncTemplates = XTableManager.ReadByIntKey(TABLE_SHIELD_FUNC_PATH, XTable.XTableShieldFunc, "Id")

    local listOpenFunctional = XTableManager.ReadByIntKey(SHARE_FUNCTIONAL_OPEN, XTable.XTableFunctionalOpen, "Id")
    for k, v in pairs(listOpenFunctional) do
        -- Check IsHasCondition
        for _, id in pairs(v.Condition) do
            if id ~= 0 then
                FunctionalOpenTemplates[k] = v
                tableInsert(OpenList, k)
                break
            end
        end
    end

    table.sort(OpenList, function(a, b)
        if FunctionalOpenTemplates[a].Priority ~= FunctionalOpenTemplates[b].Priority then
            return FunctionalOpenTemplates[a].Priority < FunctionalOpenTemplates[b].Priority
        end
    end)
    OpenList = XReadOnlyTable.Create(OpenList)

    --local mainAdTemplates = XTableManager.ReadByIntKey(TABLE_MAIN_AD, XTable.XTableMainAd, "Id")
    --for _, v in pairs(mainAdTemplates) do
    --    if not MainAdTemplates[v.ChannelId] then
    --        MainAdTemplates[v.ChannelId] = {}
    --    end
    --
    --    tableInsert(MainAdTemplates[v.ChannelId], v)
    --end
    --MainAdTemplates = XReadOnlyTable.Create(MainAdTemplates)
end

function XFunctionConfig.GetFuncOpenCfg(id)
    return FunctionalOpenTemplates[id]
end

function XFunctionConfig.GetSkipFuncCfg(id)
    return SkipFunctionalTemplates[id]
end

function XFunctionConfig.GetMainActSkipCfg(id)
    return MainActivitySkipTemplates[id]
end

function XFunctionConfig.GetShieldFuncUiName(id)
    if ShieldFuncTemplates[id] then
        return ShieldFuncTemplates[id].UiName
    else
        return {}
    end
end

function XFunctionConfig.GetOpenList()
    return OpenList
end

function XFunctionConfig.GetSecondaryFunctionalList()
    local list = {}
    for _, v in pairs(SecondaryFunctionalTemplates) do
        tableInsert(list, v)
    end
    --排序优先级
    tableSort(list, function(a, b)
        if a.Priority ~= b.Priority then
            return a.Priority < b.Priority
        end
    end)
    return list
end

function XFunctionConfig.GetSkipList(id)
    return SkipFunctionalTemplates[id]
end


--function XFunctionConfig.GetUiName(id)
--    local uiName = SkipFunctionalTemplates[id].UiName
--    if uiName == nil then
--        XLog.Error("XFunctionConfig.GetUiName error: can not found UiName, id = " .. id)
--    end
--    return uiName
--end

function XFunctionConfig.GetExplain(id)
    local explain = SkipFunctionalTemplates[id].Explain
    if explain == nil then
        XLog.Error("XFunctionConfig.GetExplain error: can not found Explain, id = " .. id)
    end
    return explain
end

function XFunctionConfig.GetParamId(id)
    local paramId = SkipFunctionalTemplates[id].ParamId
    if paramId == nil then
        XLog.Error("XFunctionConfig.GetParamId error: can not found ParamId, id = " .. id)
    end
    return paramId
end

function XFunctionConfig.GetIsShowExplain(id)
    local isShowExplain = SkipFunctionalTemplates[id].IsShowExplain
    if isShowExplain == nil then
        XLog.Error("XFunctionConfig.GetIsShowExplain error: can not found isShowExplain, id = " .. id)
    end
    return isShowExplain
end

--获取功能开启提醒方式
function XFunctionConfig.GetOpenHint(id)
    return FunctionalOpenTemplates[id].Hint
end

--获取功能名字
function XFunctionConfig.GetFunctionalName(id)
    return FunctionalOpenTemplates[id].Name
end

--获取功能类型
function XFunctionConfig.GetFunctionalType(id)
    return FunctionalOpenTemplates[id].Type
end

--获取npc名字
--function XFunctionConfig.GetNpcName(id)
--    return FunctionalOpenTemplates[id].NpcName
--end

--获取npc头像
--function XFunctionConfig.GetNpcHandIcon(id)
--    return FunctionalOpenTemplates[id].NpcHandIcon
--end

--获取npc半身像
--function XFunctionConfig.GetNpcHalfIcon(id)
--    return FunctionalOpenTemplates[id].NpcHalfIcon
--end

--function XFunctionConfig.GetSkipToActivityIcon()
--    return MainActivitySkipTemplates[1].Icon
--end

--function XFunctionManager.HandlerUiOpen(show, uiName)
--    if show then
--        if uiName ~= "UiHud" and uiName ~= "UiLogin" then
--            XFunctionManager.CheckOpen()
--        end
--    end
--end

--功能开启
--function XFunctionManager.GetFunctionOpenList(id)
--    --获取表
--    local openList = FunctionalOpenTemplates[id]
--    if openList == nil then
--        return
--    end
--    return openList
--end

-- 获取广告图列表
--function XFunctionManager.GetMainAdList()
--    local channelId = 0
--
--    if XUserManager.Channel == XUserManager.CHANNEL.HERO then
--        channelId = CS.XHeroSdkAgent.GetChannelId()
--    end
--
--    local list = {}
--    local templates = MainAdTemplates[channelId]
--
--    if not templates then
--        templates = MainAdTemplates[0]
--    end
--
--    for _, v in pairs(templates) do
--        tableInsert(list, v)
--    end
--
--    tableSort(list, function(a, b)
--        if a.Priority ~= b.Priority then
--            return a.Priority < b.Priority
--        end
--    end)
--
--    return list
--end