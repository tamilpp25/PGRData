local table = table
local tableInsert = table.insert

XDrawConfigs = XDrawConfigs or {}

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
    Destiny   = 2,
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
XDrawConfigs.DrawCapacityCheckType =
{
    Partner = 1 -- 伙伴
}

local TABLE_DRAW_PREVIEW = "Client/Draw/DrawPreview.tab"
local TABLE_DRAW_PREVIEW_GOODS = "Client/Draw/DrawPreviewGoods.tab"
local TABLE_DRAW_COMBINATIONS = "Client/Draw/DrawCombinations.tab"
local TABLE_DRAW_PROB = "Client/Draw/DrawProbShow.tab"
local TABLE_GROUP_RULE = "Client/Draw/DrawGroupRule.tab"
local TABLE_AIMPROBABILITY = "Client/Draw/DrawAimProbability.tab"
local TABLE_DRAW_SHOW = "Client/Draw/DrawShow.tab"
local TABLE_DRAW_NEWYEARSHOW = "Client/Draw/JPDrawNewYearShow.tab"
local TABLE_DRAW_CAMERA = "Client/Draw/DrawCamera.tab"
local TABLE_DRAW_TABS = "Client/Draw/DrawTabs.tab"
local TABLE_DRAW_SHOW_CHARACTER = "Client/Draw/DrawShowCharacter.tab"
local TABLE_DRAW_TYPE_CHANGE = "Client/Draw/DrawTypeChange.tab"
local TABLE_DRAW_SHOW_EFFECT = "Client/Draw/DrawShowEffect.tab"
local TABLE_DRAW_GROUP_RELATION = "Client/Draw/DrawGroupRelation.tab"
local TABLE_DRAW_SKIP = "Client/Draw/DrawSkip.tab"

local DrawPreviews = {}
local DrawCombinations = {}
local DrawProbs = {}
local DrawGroupRule = {}
local DrawAimProbability = {}
local DrawShow = {}
local DrawShowEffect = {}
local DrawCamera = {}
local DrawTabs = {}
local DrawShowCharacter = {}
local DrawTypeChangeCfg = {}
local DrawSubGroupDic = {}
local DrawGroupRelationCfg = {}
local DrawGroupRelationDic = {}
local DrawSkipCfg = {}
local DrawNewYearShow = {}

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
    DrawGroupRelationCfg = XTableManager.ReadByIntKey(TABLE_DRAW_GROUP_RELATION, XTable.XTableDrawGroupRelation, "NormalGroupId")
    DrawSkipCfg = XTableManager.ReadByIntKey(TABLE_DRAW_SKIP, XTable.XTableDrawSkip, "DrawGroupId")
    DrawNewYearShow = XTableManager.ReadByIntKey(TABLE_DRAW_NEWYEARSHOW, XTable.XTableDrawNewYearActivityShow, "Type")
    
    local previews = XTableManager.ReadByIntKey(TABLE_DRAW_PREVIEW, XTable.XTableDrawPreview, "Id")
    local previewGoods = XTableManager.ReadByIntKey(TABLE_DRAW_PREVIEW_GOODS, XTable.XTableRewardGoods, "Id")

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
    for _,typeChangeGroup in pairs(DrawTypeChangeCfg or {}) do
        for _,subGroupId in pairs(typeChangeGroup.SubGroupId or {}) do
            if not DrawSubGroupDic[subGroupId] then
                DrawSubGroupDic[subGroupId] = typeChangeGroup.MainGroupId
            end
        end
    end
end

function XDrawConfigs.SetGroupRelationDic()
    DrawGroupRelationDic = {}
    for _,data in pairs (DrawGroupRelationCfg)do
        if not DrawGroupRelationDic[data.NormalGroupId] then
            DrawGroupRelationDic[data.NormalGroupId] = data.DestinyGroupId
        else
            XLog.Error("Can Not Use Same GroupId for NormalGroupId .GroupId:"..data.NormalGroupId)
        end
        
        if not DrawGroupRelationDic[data.DestinyGroupId] then
            DrawGroupRelationDic[data.DestinyGroupId] = data.NormalGroupId
        else
            XLog.Error("Can Not Use Same GroupId for DestinyGroupId .GroupId:"..data.DestinyGroupId)
        end
    end
end

function XDrawConfigs.GetDrawGroupRelationDic()
    return DrawGroupRelationDic
end

function XDrawConfigs.GetDrawCombinations()
    return DrawCombinations
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

function XDrawConfigs.GetDrawNewYearShow()
    return DrawNewYearShow
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