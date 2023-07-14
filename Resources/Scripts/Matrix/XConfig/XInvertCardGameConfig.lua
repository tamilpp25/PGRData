local tableInsert = table.insert

XInvertCardGameConfig = XInvertCardGameConfig or {}

XInvertCardGameConfig.InvertCardGameStageStatusType = {
    Lock = 0, -- 锁定状态
    Process = 1, -- 进行状态
    Finish = 2, -- 完成状态
}

XInvertCardGameConfig.InvertCardGameRewardTookState = {
    NotFinish = 1, -- 未完成
    NotTook = 2, -- 完成未领取
    Took = 3, -- 已领取
}

XInvertCardGameConfig.InvertCardGameCardState = {
    Back = 1, -- 背面
    Front = 2, -- 正面
    Finish = 3, -- 完成（消失状态）
}

XInvertCardGameConfig.HitFaceHelpState = {
    NotHit = 0,
    Hited = 1,
}

-- 开始游戏状态
XInvertCardGameConfig.InvertCardGameStartStage = {
    NotStart = 0, -- 没点击开始
    Started = 1, -- 开始过了
}

XInvertCardGameConfig.INVERT_CARD_GAME_HELP_HIT_KEY = "INVERT_CARD_GAME_HELP_HIT_KEY" -- 游戏帮助打脸键
XInvertCardGameConfig.INVERT_CARD_GAME_START_STATE_KEY = "INVERT_CARD_GAME_START_STATE_KEY" -- 开始状态信息键

local INVERT_CARD_GAME_PATH = "Share/MiniActivity/InvertCardGame/InvertCardGame.tab"
local INVERT_CARD_STAGE_PATH = "Share/MiniActivity/InvertCardGame/InvertCardStage.tab"
local INVERT_CARD_CARD_PATH = "Share/MiniActivity/InvertCardGame/InvertCard.tab"

local InvertCardGameTemplates = {}
local InvertCardStageTemplates = {}
local InvertCardGameCardTemplates = {}

function XInvertCardGameConfig.Init()
    InvertCardGameTemplates = XTableManager.ReadByIntKey(INVERT_CARD_GAME_PATH, XTable.XTableInvertCardGame, "Id")
    InvertCardStageTemplates = XTableManager.ReadByIntKey(INVERT_CARD_STAGE_PATH, XTable.XTableInvertCardStage, "Id")
    InvertCardGameCardTemplates = XTableManager.ReadByIntKey(INVERT_CARD_CARD_PATH, XTable.XTableInvertCard, "Id")
end

function XInvertCardGameConfig.GetInvertCardGameTemplateById(id)
    if not InvertCardGameTemplates or not InvertCardGameTemplates[id] then
        XLog.Error("Can't Find Invert Card Game Template By Id:"..id.." Please Check "..INVERT_CARD_GAME_PATH)
        return nil
    end

    return InvertCardGameTemplates[id]
end

function XInvertCardGameConfig.GetActivityTimeId(id)
    local gameTemplate = XInvertCardGameConfig.GetInvertCardGameTemplateById(id)
    if not gameTemplate then
        return nil
    end

    return gameTemplate.TimeId
end

function XInvertCardGameConfig.GetConsumeItemId(id)
    local gameTemplate = XInvertCardGameConfig.GetInvertCardGameTemplateById(id)
    if not gameTemplate then
        return nil
    end

    return gameTemplate.ItemId
end

function XInvertCardGameConfig.GetHelpId(id)
    local gameTemplate = XInvertCardGameConfig.GetInvertCardGameTemplateById(id)
    if not gameTemplate then
        return nil
    end

    return gameTemplate.HelpId
end

function XInvertCardGameConfig.GetStorySkipId(id)
    local gameTemplate = XInvertCardGameConfig.GetInvertCardGameTemplateById(id)
    if not gameTemplate then
        return nil
    end

    return gameTemplate.StorySkipId
end

function XInvertCardGameConfig.GetActivityStageIds(id)
    local gameTemplate = XInvertCardGameConfig.GetInvertCardGameTemplateById(id)
    if not gameTemplate then
        return nil
    end

    return gameTemplate.ActivityStageIds
end

function XInvertCardGameConfig.GetInvertCardStageTemplateById(id)
    if not InvertCardStageTemplates or not InvertCardStageTemplates[id] then
        XLog.Error("Can't Find Invert Card Stage Template By Id:"..id.." Please Check "..INVERT_CARD_STAGE_PATH)
        return nil
    end

    return InvertCardStageTemplates[id]
end

function XInvertCardGameConfig.GetStageNameById(id)
    local stageTemplate = XInvertCardGameConfig.GetInvertCardStageTemplateById(id)
    if not stageTemplate then
        return nil
    end

    return stageTemplate.Name
end

function XInvertCardGameConfig.GetStageRowAndColumnCountById(id)
    local stageTemplate = XInvertCardGameConfig.GetInvertCardStageTemplateById(id)
    if not stageTemplate then
        return nil
    end

    return stageTemplate.RowCount, stageTemplate.ColumnCount
end

function XInvertCardGameConfig.GetStageContainCardsById(id)
    local stageTemplate = XInvertCardGameConfig.GetInvertCardStageTemplateById(id)
    if not stageTemplate then
        return nil
    end

    return stageTemplate.ContainCards
end

function XInvertCardGameConfig.GetStageCostCoinNumById(id)
    local stageTemplate = XInvertCardGameConfig.GetInvertCardStageTemplateById(id)
    if not stageTemplate then
        return nil
    end

    return stageTemplate.CostCoinNum
end

function XInvertCardGameConfig.GetStageMaxCostNumById(id)
    local stageTemplate = XInvertCardGameConfig.GetInvertCardStageTemplateById(id)
    if not stageTemplate then
        return nil
    end

    return stageTemplate.MaxCostNum
end

function XInvertCardGameConfig.GetStageTargetNumById(id)
    local stageTemplate = XInvertCardGameConfig.GetInvertCardStageTemplateById(id)
    if not stageTemplate then
        return nil
    end

    return stageTemplate.TargetNum
end

function XInvertCardGameConfig.GetStageFinishProgressById(id)
    local stageTemplate = XInvertCardGameConfig.GetInvertCardStageTemplateById(id)
    if not stageTemplate then
        return nil
    end

    return stageTemplate.FinishProgress
end

function XInvertCardGameConfig.GetStageRewardsById(id)
    local stageTemplate = XInvertCardGameConfig.GetInvertCardStageTemplateById(id)
    if not stageTemplate then
        return nil
    end

    return stageTemplate.Rewards
end

function XInvertCardGameConfig.GetStageMaxOnCardsNumById(id)
    local stageTemplate = XInvertCardGameConfig.GetInvertCardStageTemplateById(id)
    if not stageTemplate then
        return nil
    end

    return stageTemplate.MaxOnCardsNum
end

function XInvertCardGameConfig.GetStageFailedPunishNumById(id)
    local stageTemplate = XInvertCardGameConfig.GetInvertCardStageTemplateById(id)
    if not stageTemplate then
        return nil
    end

    return stageTemplate.FailedPunishNum
end

function XInvertCardGameConfig.GetInvertCardTemplateById(id)
    if not InvertCardGameCardTemplates or not InvertCardGameCardTemplates[id] then
        XLog.Error("Can't Find Invert Card Template By Id:"..id.." Please Check "..INVERT_CARD_CARD_PATH)
        return nil
    end

    return InvertCardGameCardTemplates[id]
end

function XInvertCardGameConfig.GetCardBaseIconById(id)
    local cardTemplate = XInvertCardGameConfig.GetInvertCardTemplateById(id)
    if not cardTemplate then
        return nil
    end

    return cardTemplate.BaseIcon
end