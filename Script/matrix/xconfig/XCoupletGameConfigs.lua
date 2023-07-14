local tableInsert = table.insert

XCoupletGameConfigs = XCoupletGameConfigs or {}

XCoupletGameConfigs.CouPletStatus = {
    Incomplete = 0,
    Complete = 1,
}

XCoupletGameConfigs.PlayVideoState = {
    UnPlay = 0,
    Played = 1,
}

XCoupletGameConfigs.HitFaceHelpState = {
    NotHit = 0,
    Hited = 1,
}

XCoupletGameConfigs.HitFaceVideoState = {
    UnPlay = 0,
    Played = 1,
}

-- XCoupletGameConfigs.COUPLET_GAME_DATA_KEY = "COUPLET_GAME_DATA_KEY" -- 对联游戏本地数据键
XCoupletGameConfigs.COUPLET_GAME_HELP_HIT_KEY = "COUPLET_GAME_HELP_HIT_KEY" -- 对联游戏帮助打脸键
XCoupletGameConfigs.COUPLET_GAME_VIDEO_HIT_KEY = "COUPLET_GAME_VIDEO_HIT_KEY" -- 对联游戏打脸剧情键
XCoupletGameConfigs.PLAY_VIDEO_STATE_KEY = "COUPLET_PLAY_VIDEO_STATE_KEY" -- 剧情播放信息键

local COUPLET_ACTIVITY_BASE_PATH = "Share/MiniActivity/CoupletGame/CoupletActivityBase.tab"
local COUPLET_PATH = "Share/MiniActivity/CoupletGame/Couplet.tab"
local COUPLET_WORD_PATH = "Share/MiniActivity/CoupletGame/CoupletWord.tab"

local ActivityBaseTemplates = {}
local CoupletTemplates = {}
local CoupletTemplatesWithAct = {}
local CoupletWordTemplates = {}
local DownWordArrList = {}

function XCoupletGameConfigs.Init()
    ActivityBaseTemplates = XTableManager.ReadByIntKey(COUPLET_ACTIVITY_BASE_PATH, XTable.XTableCoupletActivityBase, "Id")
    CoupletTemplates = XTableManager.ReadByIntKey(COUPLET_PATH, XTable.XTableCouplet, "Id")
    CoupletWordTemplates = XTableManager.ReadByIntKey(COUPLET_WORD_PATH, XTable.XTabelCoupletWord, "Id")
    for _, coupletTemplet in ipairs(CoupletTemplates) do
        if coupletTemplet.ActivityId then
            if not CoupletTemplatesWithAct[coupletTemplet.ActivityId] then
                CoupletTemplatesWithAct[coupletTemplet.ActivityId] = {}
            end
        end

        if CoupletTemplatesWithAct[coupletTemplet.ActivityId] then
            tableInsert(CoupletTemplatesWithAct[coupletTemplet.ActivityId], coupletTemplet)
        end
    end
    for _, coupletTemplate in pairs(CoupletTemplates) do
        if DownWordArrList[coupletTemplate.Id] == nil then
            DownWordArrList[coupletTemplate.Id] = {}
        end
        local downWordIdStrList = coupletTemplate.DownWordId
        for _, downWordIdStr in ipairs(downWordIdStrList) do
            local downWordIdArr = string.ToIntArray(downWordIdStr)
            tableInsert(DownWordArrList[coupletTemplate.Id], downWordIdArr)
        end
    end
end

function XCoupletGameConfigs.GetCoupletBaseActivityById(id)
    if not ActivityBaseTemplates or not next(ActivityBaseTemplates) or not ActivityBaseTemplates[id] then
        return
    end

    return ActivityBaseTemplates[id]
end

function XCoupletGameConfigs.GetCoupletTemplatesByActId(actId)
    if not CoupletTemplatesWithAct or not next(CoupletTemplatesWithAct) or not CoupletTemplatesWithAct[actId] then
        return
    end

    return CoupletTemplatesWithAct[actId]
end

function XCoupletGameConfigs.GetCoupletTemplateById(id)
    if not CoupletTemplates or not next(CoupletTemplates) or not CoupletTemplates[id] then
        return
    end

    return CoupletTemplates[id]
end

function XCoupletGameConfigs.GetCoupletWordImageById(wordId)
    if not CoupletWordTemplates or not next(CoupletWordTemplates) or not CoupletWordTemplates[wordId] then
        return
    end

    return CoupletWordTemplates[wordId].WordImageUrl
end

function XCoupletGameConfigs.GetCoupletUpWordsId(coupletId)
    if not CoupletTemplates or not next(CoupletTemplates) or not CoupletTemplates[coupletId] then
        return
    end

    return CoupletTemplates[coupletId].UpWordId
end

function XCoupletGameConfigs.GetCoupletBatch(coupletId)
    if not CoupletTemplates or not CoupletTemplates[coupletId] then
        return
    end

    return CoupletTemplates[coupletId].BatchUrl
end

function XCoupletGameConfigs.GetCoupletDefaultBatch(coupletId)
    if not CoupletTemplates or not CoupletTemplates[coupletId] then
        return
    end

    return CoupletTemplates[coupletId].DefaultBatchUrl
end

function XCoupletGameConfigs.GetCoupletUpImgUrl(coupletId)
    if not CoupletTemplates or not CoupletTemplates[coupletId] then
        return
    end

    return CoupletTemplates[coupletId].UpImgUrl
end

function XCoupletGameConfigs.GetCoupletDownImgUrl(coupletId)
    if not CoupletTemplates or not CoupletTemplates[coupletId] then
        return
    end

    return CoupletTemplates[coupletId].DownImgUrl
end

function XCoupletGameConfigs.GetCoupletDownIdArr(coupletId, Index)
    if not DownWordArrList or not DownWordArrList[coupletId] then
        return
    end

    local coupletDownWordArr = DownWordArrList[coupletId]
    if coupletDownWordArr and next(coupletDownWordArr) then
        return coupletDownWordArr[Index]
    end
end