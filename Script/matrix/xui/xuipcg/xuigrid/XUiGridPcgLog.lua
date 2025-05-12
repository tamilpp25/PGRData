---@class XUiGridPcgLog : XUiNode
---@field private _Control XPcgControl
local XUiGridPcgLog = XClass(XUiNode, "XUiGridPcgLog")

function XUiGridPcgLog:OnStart()
    self.TxtCommanderDesc.gameObject:SetActiveEx(false)
    self.TxtMonsterDesc.gameObject:SetActiveEx(false)
    
    self.CommanderShowTxtList = {}       -- 指挥官当前显示的文本
    self.CommanderRecycleTxtList = {}    -- 指挥官回收的文本列表
    self.MonsterShowTxtList = {}       -- 怪物当前显示的文本
    self.MonsterRecycleTxtList = {}    -- 怪物回收的文本列表
end

function XUiGridPcgLog:OnEnable()
    
end

function XUiGridPcgLog:OnDisable()
    
end

function XUiGridPcgLog:OnDestroy()

end

-- 设置数据
function XUiGridPcgLog:SetData(roundLog)
    ---@type XPcgRoundLog
    self.RoundLog = roundLog
    self:Refresh()
end

-- 刷新界面
function XUiGridPcgLog:Refresh()
    self:RecycleAllTxt()
    
    -- 回合
    local roundTxt = self._Control:GetClientConfig("RoundTxt")
    self.TxtRound.text = string.format(roundTxt, self.RoundLog:GetRoundId())
    
    -- 指挥官
    self.CommanderEffectShowDic = {}
    local commanderEffectSettles = self.RoundLog:GetCommanderEffectSettles()
    local isShowCommander = #commanderEffectSettles > 0
    self.TagCommander.gameObject:SetActiveEx(isShowCommander)
    if isShowCommander then
        for _, effectSettle in ipairs(commanderEffectSettles) do
            -- Effect描述
            local effectId = effectSettle.EffectId
            if effectId ~= 0 then
                local effectShowDesc = self._Control:GetEffectShowDesc(effectId)
                if not self.CommanderEffectShowDic[effectId] and not string.IsNilOrEmpty(effectShowDesc) then
                    local txtComponent = self:GetCommanderTxt()
                    txtComponent.text = effectShowDesc
                    self.CommanderEffectShowDic[effectId] = true
                end
            end
            
            -- 效果
            local txt = self:GetEffectSettleDesc(effectSettle)
            if not string.IsNilOrEmpty(txt) then
                local txtComponent = self:GetCommanderTxt()
                txtComponent.text = txt
            end
        end
    end
    
    -- 怪物
    self.MonsterEffectShowDic = {}
    local monsterEffectSettles = self.RoundLog:GetMonsterEffectSettles()
    local isShowMonster = #monsterEffectSettles > 0
    self.TagMonster.gameObject:SetActiveEx(isShowMonster)
    if isShowMonster then
        for _, effectSettle in ipairs(monsterEffectSettles) do
            -- Effect描述
            local effectId = effectSettle.EffectId
            if effectId ~= 0 then
                local effectShowDesc = self._Control:GetEffectShowDesc(effectId)
                if not self.MonsterEffectShowDic[effectId] and not string.IsNilOrEmpty(effectShowDesc) then
                    local txtComponent = self:GetMonsterTxt()
                    txtComponent.text = effectShowDesc
                    self.MonsterEffectShowDic[effectId] = true
                end
            end

            -- 效果
            local txt = self:GetEffectSettleDesc(effectSettle)
            if not string.IsNilOrEmpty(txt) then
                local txtComponent = self:GetMonsterTxt()
                txtComponent.text = txt
            end
        end
    end
end

-- 获取指挥官文本
function XUiGridPcgLog:GetCommanderTxt()
    local txt = nil
    local lastIndex = #self.CommanderRecycleTxtList
    if lastIndex > 0 then
        txt = self.CommanderRecycleTxtList[lastIndex]
        table.remove(self.CommanderRecycleTxtList, lastIndex)
    else
        txt = CS.UnityEngine.Object.Instantiate(self.TxtCommanderDesc, self.TxtCommanderDesc.transform.parent)
        txt.requestImage = XMVCA.XPcg.RichTextImageCallBack
    end
    txt.gameObject:SetActiveEx(true)
    txt.transform:SetAsLastSibling()
    table.insert(self.CommanderShowTxtList, txt)
    return txt
end

-- 获取怪物文本
function XUiGridPcgLog:GetMonsterTxt()
    local txt = nil
    local lastIndex = #self.MonsterRecycleTxtList
    if lastIndex > 0 then
        txt = self.MonsterRecycleTxtList[lastIndex]
        table.remove(self.MonsterRecycleTxtList, lastIndex)
    else
        txt = CS.UnityEngine.Object.Instantiate(self.TxtMonsterDesc, self.TxtMonsterDesc.transform.parent)
        txt.requestImage = XMVCA.XPcg.RichTextImageCallBack
    end
    txt.gameObject:SetActiveEx(true)
    txt.transform:SetAsLastSibling()
    table.insert(self.MonsterShowTxtList, txt)
    return txt
end

-- 回收所有文本
function XUiGridPcgLog:RecycleAllTxt()
    if #self.CommanderShowTxtList > 0 then
        for _, txt in ipairs(self.CommanderShowTxtList) do
            txt.gameObject:SetActiveEx(false)
            table.insert(self.CommanderRecycleTxtList, txt)
        end
    end
    if #self.MonsterShowTxtList > 0 then
        for _, txt in ipairs(self.MonsterShowTxtList) do
            txt.gameObject:SetActiveEx(false)
            table.insert(self.MonsterRecycleTxtList, txt)
        end
    end
end

-- 获取效果结算文本
---@param settle XPcgEffectSettle
function XUiGridPcgLog:GetEffectSettleDesc(settle)
    local EFFECT_SETTLE_TYPE = XEnumConst.PCG.EFFECT_SETTLE_TYPE
    local type = settle.EffectSettleType
    local logFormat = self._Control:GetClientConfig("EffectSettleLog"..type)
    if type == EFFECT_SETTLE_TYPE.DAMAGE then
        local damage = settle:GetParam1()
        local targetType1 = settle:GetParam2()
        local targetId1 = settle:GetParam3()
        local targetType2 = settle:GetParam5()
        local targetId2 = settle:GetParam6()
        local name1 = self:GetTargetName(targetType1, targetId1)
        local name2 = self:GetTargetName(targetType2, targetId2)
        return string.format(logFormat, name1, name2, damage)
        
    elseif type == EFFECT_SETTLE_TYPE.HP_CHANGE or type == EFFECT_SETTLE_TYPE.ARMOR_CHANGE then
        local val = settle:GetParam1()
        local targetType = settle:GetParam2()
        local targetId = settle:GetParam3()
        local name = self:GetTargetName(targetType, targetId)
        return string.format(logFormat, name, val)
        
    elseif type == EFFECT_SETTLE_TYPE.ACTION_POINT_CHANGE then
        local val = settle:GetParam1()
        return string.format(logFormat, val)
        
    elseif type == EFFECT_SETTLE_TYPE.CHARACTER_POS_CHANGE then
        local characterId = settle:GetParam1()
        local characterCfg = self._Control:GetConfigCharacter(characterId)
        return string.format(logFormat, characterCfg.Name)
        
    elseif type == EFFECT_SETTLE_TYPE.CARD_POOL_CHANGE then
        local cardId = settle:GetParam1()
        if cardId == 0 then
            return self._Control:GetClientConfig("NoValidCardTips")
        end
        local cardPos1 = settle:GetParam2()
        local cardPos2 = settle:GetParam3()
        local cardCfg = self._Control:GetConfigCards(cardId)
        local cardPosName1 = self:GetCardPosName(cardPos1)
        local cardPosName2 = self:GetCardPosName(cardPos2)
        return string.format(logFormat, cardCfg.Name, cardPosName1, cardPosName2)
        
    elseif type == EFFECT_SETTLE_TYPE.TOKEN_CHANGE then
        local targetType = settle:GetParam1()
        local targetId = settle:GetParam2()
        local tokenId = settle:GetParam3()
        local tokenNum = settle:GetParam4()
        local tokenCfg = self._Control:GetConfigToken(tokenId)
        local name = self:GetTargetName(targetType, targetId)
        local isShow = self._Control:GetTokenIsShow(tokenId) -- 不分token配置不显示
        if not isShow then 
            return 
        end
        return string.format(logFormat, name, tokenCfg.Name, tokenNum)
        
    elseif type == EFFECT_SETTLE_TYPE.MONSTER_CHANGE then
        local monsterIds = settle:GetParams()
        local nameStr = ""
        for _, monsterId in ipairs(monsterIds) do
            if monsterId ~= 0 then
                local monsterCfg = self._Control:GetConfigMonster(monsterId)
                nameStr = string.IsNilOrEmpty(nameStr) and monsterCfg.Name or (nameStr .. ", " .. monsterCfg.Name)
            end
        end
        return string.format(logFormat, nameStr)
        
    elseif type == EFFECT_SETTLE_TYPE.HAND_POOL_SORT then
        return logFormat
    elseif type == EFFECT_SETTLE_TYPE.ADJUST_CARD_POOL_ORDER then
        local cardPos = settle:GetParam1()
        local cardId = settle:GetParam2()
        local moveIdx = XMVCA.XPcg:ConvertCSharpIndexToLuaIndex(settle:GetParam4())
        if cardPos == XEnumConst.PCG.CARD_POS_TYPE.HAND then
            local cardCfg = self._Control:GetConfigCards(cardId)
            return string.format(logFormat, cardCfg.Name, tostring(moveIdx))
        end
    elseif type == EFFECT_SETTLE_TYPE.DROP_HAND_CARDS then
        local cardList = settle:GetCardList()
        local nameStr = self:GetCardListName(cardList)
        return string.format(logFormat, nameStr)
    elseif type == EFFECT_SETTLE_TYPE.ADD_HAND_CARDS then
        local cardPos = settle:GetParam1()
        local cardList = settle:GetCardList()
        local nameStr = self:GetCardListName(cardList)
        local cardPosName = self:GetCardPosName(cardPos)
        if #cardList > 0 and cardPos == XEnumConst.PCG.CARD_POS_TYPE.HAND then
            return string.format(logFormat, nameStr, cardPosName)
        else
            return -- 不需要显示日志
        end
    end
    return logFormat
end

-- 获取卡牌列表名称
function XUiGridPcgLog:GetCardListName(cardList)
    local nameStr = ""
    for _, cardId in ipairs(cardList) do
        local cardCfg = self._Control:GetConfigCards(cardId)
        nameStr = string.IsNilOrEmpty(nameStr) and cardCfg.Name or (nameStr .. ", " .. cardCfg.Name)
    end
    return nameStr
end

-- 获取目标名称，包括指挥官、怪物、角色
function XUiGridPcgLog:GetTargetName(targetType, id)
    if targetType == XEnumConst.PCG.TARGET_TYPE.COMMANDER then
        return self._Control:GetClientConfig("CommanderName")
    elseif targetType == XEnumConst.PCG.TARGET_TYPE.MONSTER then
        local monsterCfg = self._Control:GetConfigMonster(id)
        return monsterCfg.Name
    elseif targetType == XEnumConst.PCG.TARGET_TYPE.CHARACTER then
        local cfg = self._Control:GetConfigCharacter(id)
        return cfg.Name
    end
end

-- 获取卡牌位置名称
function XUiGridPcgLog:GetCardPosName(pos)
    return self._Control:GetClientConfig("CardPos", pos + 1) -- 服务器从0开始定Id
end

return XUiGridPcgLog
