local table = table
local tableInsert = table.insert

XDrawConfigs = XDrawConfigs or {}

XDrawConfigs.ModelType = {
    Role = 1,
    Weapon = 2,
    Partner = 3
}

XDrawConfigs.CombinationsTypes = {
    Normal    = 1,
    Aim        = 2,
    NewUp        = 3,
    Furniture    = 4,
    CharacterUp = 5,
    EquipSuit    = 6,
}

XDrawConfigs.DrawSetType = {
    Normal    = 1,
    Destiny = 2,
}

XDrawConfigs.RareRank = {
    A = 1,
    S = 2,
}

XDrawConfigs.RuleType = {
    Tab = 0,
    Normal = 1,
    Lotto = 2,
}

XDrawConfigs.GroupType = {
    Normal = 1,
    Destiny = 2,
}

---
--- 卡池可掉落的奖励类型
XDrawConfigs.DrawCapacityCheckType = {
    Partner = 1 -- 伙伴
}

XDrawConfigs.DrawTargetActivityNone = 999

XDrawConfigs.DrawTargetTipType = { 
    Open = 1,
    Close = 2,
    Update = 3,
}

local TABLE_DRAW_PREVIEW = "Client/Draw/DrawPreview.tab"
local TABLE_DRAW_PREVIEW_GOODS = "Client/Draw/DrawPreviewGoods.tab"
local TABLE_DRAW_COMBINATIONS = "Client/Draw/DrawCombinations.tab"
local TABLE_DRAW_PROB = "Client/Draw/DrawProbShow.tab"
local TABLE_GROUP_RULE = "Client/Draw/DrawGroupRule.tab"
local TABLE_AIMPROBABILITY = "Client/Draw/DrawAimProbability.tab"
local TABLE_DRAW_SHOW = "Client/Draw/DrawShow.tab"
local TABLE_DRAW_CAMERA = "Client/Draw/DrawCamera.tab"
local TABLE_DRAW_TABS = "Client/Draw/DrawTabs.tab"
local TABLE_DRAW_SHOW_CHARACTER = "Client/Draw/DrawShowCharacter.tab"
local TABLE_DRAW_TYPE_CHANGE = "Client/Draw/DrawTypeChange.tab"
local TABLE_DRAW_SHOW_EFFECT = "Client/Draw/DrawShowEffect.tab"
local TABLE_DRAW_SHOW_PICTURE = "Client/Draw/DrawShowPicture.tab"
local TABLE_DRAW_WAFER_SHOW = "Client/Draw/DrawWaferShow.tab"
local TABLE_DRAW_GROUP_RELATION = "Client/Draw/DrawGroupRelation.tab"
local TABLE_DRAW_SKIP = "Client/Draw/DrawSkip.tab"
local TABLE_DRAW_SCENE = "Client/Draw/DrawScene.tab"
local TABLE_DRAW_ACTIVITY_TARGET_SHOW = "Client/Draw/DrawActivityTargetShow.tab"
local TABLE_DRAW_ACTIVITY_TARGET_ROLE_BG = "Client/Draw/DrawActivityTargetRoleBg.tab"
local TABLE_DRAW_CLIENT_CONFIG = "Client/Draw/DrawClientConfig.tab"
local TABLE_DRAW_TICKET = "Share/DrawTicket/DrawTicket.tab"

local DrawPreviews = {}
local DrawCombinations = {}
local DrawProbs = {}
local DrawGroupRule = {}
local DrawAimProbability = {}
local DrawShow = {}
local DrawShowEffect = {}
local DrawShowPicture = {}
local DrawWaferShow = {}
local DrawCamera = {}
local DrawTabs = {}
local DrawShowCharacter = {}
local DrawTypeChangeCfg = {}
local DrawSubGroupDic = {}
local DrawGroupRelationCfg = {}
local DrawGroupRelationDic = {}
local DrawSkipCfg = {}
local DrawSceneCfg = {}
local DrawTicketCfg = {}
---@type XTableDrawActivityTargetShow[]
local DrawActivityTargetShowCfg = {}
---@type XTableDrawActivityTargetRoleBg[]
local DrawActivityTargetRoleBgCfg = {}
---@type XTableDrawClientConfig[]
local DrawClientCfg = {}

function XDrawConfigs.Init()
    DrawCombinations = XTableManager.ReadByIntKey(TABLE_DRAW_COMBINATIONS, XTable.XTableDrawCombinations, "Id")
    DrawGroupRule = XTableManager.ReadByIntKey(TABLE_GROUP_RULE, XTable.XTableDrawGroupRule, "Id")
    DrawShow = XTableManager.ReadByIntKey(TABLE_DRAW_SHOW, XTable.XTableDrawShow, "Type")
    DrawCamera = XTableManager.ReadByIntKey(TABLE_DRAW_CAMERA, XTable.XTableDrawCamera, "Id")
    DrawTabs = XTableManager.ReadByIntKey(TABLE_DRAW_TABS, XTable.XTableDrawTabs, "Id")
    DrawShowCharacter = XTableManager.ReadByIntKey(TABLE_DRAW_SHOW_CHARACTER, XTable.XTableDrawShowCharacter, "Id")
    DrawAimProbability = XTableManager.ReadByIntKey(TABLE_AIMPROBABILITY, XTable.XTableDrawAimProbability, "Id")
    DrawTypeChangeCfg = XTableManager.ReadByIntKey(TABLE_DRAW_TYPE_CHANGE, XTable.XTableDrawTypeChange, "MainGroupId")
    DrawShowEffect = XTableManager.ReadByIntKey(TABLE_DRAW_SHOW_EFFECT, XTable.XTableDrawShowEffect, "EffectGroupId")
    DrawShowPicture = XTableManager.ReadByIntKey(TABLE_DRAW_SHOW_PICTURE, XTable.XTableDrawShowPicture, "GroupId")
    DrawWaferShow = XTableManager.ReadByIntKey(TABLE_DRAW_WAFER_SHOW, XTable.XTableDrawWaferShow, "Id")
    DrawGroupRelationCfg = XTableManager.ReadByIntKey(TABLE_DRAW_GROUP_RELATION, XTable.XTableDrawGroupRelation, "NormalGroupId")
    DrawSkipCfg = XTableManager.ReadByIntKey(TABLE_DRAW_SKIP, XTable.XTableDrawSkip, "DrawGroupId")
    DrawSceneCfg = XTableManager.ReadByIntKey(TABLE_DRAW_SCENE, XTable.XTableDrawScene, "Id")
    DrawTicketCfg = XTableManager.ReadByIntKey(TABLE_DRAW_TICKET,XTable.XTableDrawTicket, "Id")
    DrawActivityTargetShowCfg = XTableManager.ReadByIntKey(TABLE_DRAW_ACTIVITY_TARGET_SHOW,XTable.XTableDrawActivityTargetShow, "Id")
    DrawActivityTargetRoleBgCfg = XTableManager.ReadByIntKey(TABLE_DRAW_ACTIVITY_TARGET_ROLE_BG,XTable.XTableDrawActivityTargetRoleBg, "Quality")
    DrawClientCfg = XTableManager.ReadByStringKey(TABLE_DRAW_CLIENT_CONFIG,XTable.XTableDrawClientConfig, "Key")
    
    local previews = XTableManager.ReadAllByIntKey(TABLE_DRAW_PREVIEW, XTable.XTableDrawPreview, "Id")
    local previewGoods = XTableManager.ReadAllByIntKey(TABLE_DRAW_PREVIEW_GOODS, XTable.XTableRewardGoods, "Id")

    for drawId, preview in pairs(previews) do
        local upGoodsIds = preview.UpGoodsId
        local upGoods = {}
        for i = 1, #upGoodsIds do
            tableInsert(upGoods, XRewardManager.CreateRewardGoodsByTemplate(previewGoods[upGoodsIds[i]]))
        end

        local goodsIds = preview.GoodsId
        local goods = {}
        for i = 1, #goodsIds do
            tableInsert(goods, XRewardManager.CreateRewardGoodsByTemplate(previewGoods[goodsIds[i]]))
        end

        local drawPreview = {}
        drawPreview.UpGoods = upGoods
        drawPreview.Goods = goods
        DrawPreviews[drawId] = drawPreview
    end

    local drawProbList = XTableManager.ReadByIntKey(TABLE_DRAW_PROB, XTable.XTableDrawProbShow, "Id")
    for _, v in pairs(drawProbList) do
        if not DrawProbs[v.DrawId] then
            DrawProbs[v.DrawId] = {}
        end
        tableInsert(DrawProbs[v.DrawId], v)
    end

    XDrawConfigs.SetDrawSubGroupDic()
    XDrawConfigs.SetGroupRelationDic()
end

function XDrawConfigs.SetDrawSubGroupDic()
    for _, typeChangeGroup in pairs(DrawTypeChangeCfg or {}) do
        for _, subGroupId in pairs(typeChangeGroup.SubGroupId or {}) do
            if not DrawSubGroupDic[subGroupId] then
                DrawSubGroupDic[subGroupId] = typeChangeGroup.MainGroupId
            end
        end
    end
end

function XDrawConfigs.SetGroupRelationDic()
    DrawGroupRelationDic = {}
    for _, data in pairs(DrawGroupRelationCfg) do
        if not DrawGroupRelationDic[data.NormalGroupId] then
            DrawGroupRelationDic[data.NormalGroupId] = data.DestinyGroupId
        else
            XLog.Error("Can Not Use Same GroupId for NormalGroupId .GroupId:" .. data.NormalGroupId)
        end

        if not DrawGroupRelationDic[data.DestinyGroupId] then
            DrawGroupRelationDic[data.DestinyGroupId] = data.NormalGroupId
        else
            XLog.Error("Can Not Use Same GroupId for DestinyGroupId .GroupId:" .. data.DestinyGroupId)
        end
    end
end

function XDrawConfigs.GetDrawGroupRelationDic()
    return DrawGroupRelationDic
end

function XDrawConfigs.GetDrawCombinations()
    return DrawCombinations
end

function XDrawConfigs.GetDrawIdByTemplateIdAndCombinationsTypes(templateId, type)
    for drawId, config in pairs(DrawCombinations) do
        if config.Type == type then
            local goods = config.GoodsId or {}
            for _, goodId in ipairs(goods) do
                if goodId == templateId then
                    return drawId
                end
            end
        end
    end
end

function XDrawConfigs.GetDrawGroupRule()
    return DrawGroupRule
end

function XDrawConfigs.GetDrawAimProbability()
    return DrawAimProbability
end

function XDrawConfigs.GetDrawShow()
    return DrawShow
end

---
--- 获取'drawGroupId'卡组的跳转ID数组
function XDrawConfigs.GetDrawSkipList(drawGroupId)
    if DrawSkipCfg[drawGroupId] then
        return DrawSkipCfg[drawGroupId].SkipId
    end
    return {}
end

function XDrawConfigs.GetDrawShowCharacter()
    return DrawShowCharacter
end

function XDrawConfigs.GetDrawCamera()
    return DrawCamera
end

function XDrawConfigs.GetDrawTabs()
    return DrawTabs
end

function XDrawConfigs.GetDrawPreviews()
    return DrawPreviews
end

function XDrawConfigs.GetDrawProbs()
    return DrawProbs
end

function XDrawConfigs.GetDrawTypeChangeCfg()
    return DrawTypeChangeCfg
end

function XDrawConfigs.GetDrawGroupRelationCfg()
    return DrawGroupRelationCfg
end

function XDrawConfigs.GetDrawTypeChangeCfgById(id)
    return DrawTypeChangeCfg[id]
end

function XDrawConfigs.GetDrawSubGroupDic()
    return DrawSubGroupDic
end

function XDrawConfigs.GetDrawTabById(id)
    if not DrawTabs[id] then
        XLog.Error("Client/Draw/DrawTabs.tab Id = " .. id .. " Is Null")
    end
    return DrawTabs[id]
end

function XDrawConfigs.GetDrawGroupRuleById(id)
    if not DrawGroupRule[id] then
        XLog.Error("Client/Draw/DrawGroupRule.tab Id = " .. id .. " Is Null")
    end
    return DrawGroupRule[id]
end

function XDrawConfigs.GetDrawShowEffectById(id)
    if not DrawShowEffect[id] then
        XLog.Error("Client/Draw/DrawShowEffect.tab Id = " .. id .. " Is Null")
    end
    return DrawShowEffect[id]
end

function XDrawConfigs.GetDrawShowPictureById(id)
    if not DrawShowPicture[id] then
        XLog.Error("Client/Draw/DrawShowPicture.tab Id = " .. id .. " Is Null")
    end
    return DrawShowPicture[id]
end

function XDrawConfigs.GetDrawWaferShowById(id)
    if not DrawWaferShow[id] then
        XLog.Error("Client/Draw/DrawWaferShow.tab Id = " .. id .. " Is Null")
        return nil
    end
    return DrawWaferShow[id]
end

function XDrawConfigs.GetOpenUpEffect(id)
    return XDrawConfigs.GetDrawShowEffectById(id).PanelOpenUp
end

function XDrawConfigs.GetOpenDownEffect(id)
    return XDrawConfigs.GetDrawShowEffectById(id).PanelOpenDown
end

function XDrawConfigs.GetCardShowOffEffect(id)
    return XDrawConfigs.GetDrawShowEffectById(id).PanelCardShowOff
end

function XDrawConfigs.GetOpenBoxEffect(id)
    return XDrawConfigs.GetDrawShowEffectById(id).EffectOpenBox
end

function XDrawConfigs.GetSkipEffect(id)
    return XDrawConfigs.GetDrawShowEffectById(id).SkipEffect
end

-- 获取底座特效
function XDrawConfigs.GetCarriageEffect(id)
    return XDrawConfigs.GetDrawShowEffectById(id).CarriageEffect
end

-- 获取线特效
function XDrawConfigs.GetFloorEffect(id)
    return XDrawConfigs.GetDrawShowEffectById(id).FloorEffect
end

-- 获取光圈特效
function XDrawConfigs.GetApertureEffect(id)
    return XDrawConfigs.GetDrawShowEffectById(id).ApertureEffect
end

-- 获取卡片开始特效
function XDrawConfigs.GetCardEffectStart(id)
    return XDrawConfigs.GetDrawShowEffectById(id).CardEffectStart
end

-- 获取卡片特效
function XDrawConfigs.GetCardEffect(id)
    return XDrawConfigs.GetDrawShowEffectById(id).CardEffect
end

-- 获取卡片特效音效
function XDrawConfigs.GetCardEffectSound(id)
    return XDrawConfigs.GetDrawShowEffectById(id).CardEffectSound
end

function XDrawConfigs.GetDrawCardBg(id)
    return XDrawConfigs.GetDrawShowPictureById(id).Bg
end

function XDrawConfigs.GetDrawCardHalfBg(id)
    return XDrawConfigs.GetDrawShowPictureById(id).HalfBg
end

function XDrawConfigs.GetDrawCardNameBg(id)
    return XDrawConfigs.GetDrawShowPictureById(id).NameBg
end

function XDrawConfigs.GetDrawSceneCfg(id)
    return DrawSceneCfg[id]
end 

function XDrawConfigs.GetDrawTicketCfg(id)
    return DrawTicketCfg[id]
end

function XDrawConfigs.GetDrawTicketWorldDesc(id)
    local cfg = XDrawConfigs.GetDrawTicketCfg(id)
    return cfg.WorldDescription
end

function XDrawConfigs.GetDrawTicketDesc(id)
    local cfg = XDrawConfigs.GetDrawTicketCfg(id)
    return cfg.Description
end

--region DrawActivityTargetShow
function XDrawConfigs.GetDrawActivityTargetShowCfg(activityId)
    return DrawActivityTargetShowCfg[activityId]
end

function XDrawConfigs.GetDrawActivityTargetShowTabDesc(activityId)
    return XDrawConfigs.GetDrawActivityTargetShowCfg(activityId).TabDesc
end

function XDrawConfigs.GetDrawActivityTargetShowTitleList(activityId)
    return XDrawConfigs.GetDrawActivityTargetShowCfg(activityId).Title
end

function XDrawConfigs.GetDrawActivityTargetShowDescList(activityId)
    return XDrawConfigs.GetDrawActivityTargetShowCfg(activityId).Desc
end

function XDrawConfigs.GetDrawActivityTargetShowBannerPrefab(activityId)
    return XDrawConfigs.GetDrawActivityTargetShowCfg(activityId).BannerPrefab
end

function XDrawConfigs.GetDrawActivityTargetShowActiveTipTxt(activityId)
    return XDrawConfigs.GetDrawActivityTargetShowCfg(activityId).ActiveTipTxt
end

function XDrawConfigs.GetDrawActivityTargetShowRuleTipTxt(activityId)
    return XDrawConfigs.GetDrawActivityTargetShowCfg(activityId).RuleTipTxt
end
--endregion

--region DrawActivityTargetRoleBg
function XDrawConfigs.GetDrawActivityTargetRoleBgCfg(quality)
    return DrawActivityTargetRoleBgCfg[quality]
end

function XDrawConfigs.GetDrawActivityTargetRoleBgUrl(quality)
    return XDrawConfigs.GetDrawActivityTargetRoleBgCfg(quality).BgUrl
end

function XDrawConfigs.GetDrawActivityTargetRoleProbabilityBgUrl(quality)
    return XDrawConfigs.GetDrawActivityTargetRoleBgCfg(quality).ProbabilityBgUrl
end
--endregion

--region DrawClientConfig
function XDrawConfigs.GetDrawClientConfig(key, index)
    index = index or 1
    return DrawClientCfg[key].ValueList[index]
end
--endregion