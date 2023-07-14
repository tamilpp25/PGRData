local tableInsert = table.insert

local TABLE_CLICKCLEAR_GAME_PATH = "Share/ClickClearGame/ClickClearGame.tab"
local TABLE_CLICKCLEAR_GAME_STAGE_PATH = "Share/ClickClearGame/ClickClearGameStage.tab"
local TABLE_CLICKCLEAR_PAGE_PATH = "Client/ClickClearGame/ClickClearPage.tab"
local TABLE_CLICKCLEAR_ROW_PATH = "Client/ClickClearGame/ClickClearRow.tab"
local TABLE_CLICKCLEAR_HEAD_PATH = "Client/ClickClearGame/ClickClearHead.tab"

local GameTemplates = {}
local GameStageTemplates = {}
local PageTemplates = {}
local RowTemplates = {}
local HeadTemplates = {}
local HeadTypeList = {}

XClickClearGameConfigs = XClickClearGameConfigs or {}

function XClickClearGameConfigs.Init()
    GameTemplates = XTableManager.ReadByIntKey(TABLE_CLICKCLEAR_GAME_PATH, XTable.XTableClickClearGame, "Id")
    GameStageTemplates = XTableManager.ReadByIntKey(TABLE_CLICKCLEAR_GAME_STAGE_PATH, XTable.XTableClickClearGameStage, "Id")
    PageTemplates = XTableManager.ReadByIntKey(TABLE_CLICKCLEAR_PAGE_PATH, XTable.XTableClickClearPage, "Id")
    RowTemplates = XTableManager.ReadByIntKey(TABLE_CLICKCLEAR_ROW_PATH, XTable.XTableClickClearRow, "Id")
    HeadTemplates = XTableManager.ReadByIntKey(TABLE_CLICKCLEAR_HEAD_PATH, XTable.XTableClickClearHead, "Id")

    for i,v in pairs(HeadTemplates) do
        local type = v.Type
        if not HeadTypeList[type] then
            HeadTypeList[type] = {}
        end
        
        tableInsert(HeadTypeList[type], i)
    end
end

function XClickClearGameConfigs.GetGameTemplates()
    return GameTemplates
end

function XClickClearGameConfigs.GetGameStageTemplates()
    return GameStageTemplates
end

function XClickClearGameConfigs.GetGameStageTemplateById(id)
    if not GameStageTemplates or #GameStageTemplates <= 0 then
        return nil
    end

    return GameStageTemplates[id]
end

function XClickClearGameConfigs.GetPageTemplateById(id)
    if not PageTemplates or #PageTemplates <= 0 then
        return nil
    end

    return PageTemplates[id]
end

function XClickClearGameConfigs.GetRowTemplateById(id)
    if not RowTemplates or #RowTemplates <= 0 then
        return nil
    end

    return RowTemplates[id]
end

function XClickClearGameConfigs.GetHeadTemplateById(id)
    if not HeadTemplates or #HeadTemplates <= 0 then
        return nil
    end

    return HeadTemplates[id]
end

function XClickClearGameConfigs.GetHeadTypeListByType(type)
    if not HeadTypeList or #HeadTypeList <= 0 or not HeadTypeList[type] then
        return nil
    end

    return HeadTypeList[type]
end