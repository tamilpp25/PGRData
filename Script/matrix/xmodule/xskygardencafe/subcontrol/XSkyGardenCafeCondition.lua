
---@class XSkyGardenCafeCondition : XControl
---@field private _Model XSkyGardenCafeModel
---@field private _MainControl XSkyGardenCafeControl
local XSkyGardenCafeCondition = XClass(XControl, "XSkyGardenCafeCondition")

local OpType = {
    --小于
    Less = 1,
    --等于
    Equal = 1 << 1,
    --大于
    Great = 1 << 2,
}

local OpList = {
    OpType.Great | OpType.Equal,
    OpType.Less | OpType.Equal,
    OpType.Great,
    OpType.Less,
    OpType.Equal,
}

local function CheckOp(checkOp, sub)
    local temp
    if sub < 0 then
        temp = OpType.Less
    elseif sub == 0 then
        temp = OpType.Equal
    else
        temp = OpType.Great
    end
    return (checkOp & temp) ~= 0
end


function XSkyGardenCafeCondition:OnInit()
    self._Func = {
        [1] = function(template, ...)
            return self:CheckResource(template, ...)
        end,
        [2] = function(template, ...) 
            return self:CheckCardInDeal(template, ...)
        end,
        [10001] = function(template, ...) --检测使用了大于等于指定数量
            return self:CheckDealCount(template, ...)
        end,
        [10002] = function(template, ...) --检测使用了指定卡牌
            return self:CheckDealHasTarget(template, ...)
        end,
        [10003] = function(template, ...) --检测回合时机
            return self:CheckRoundState(template, ...)
        end,
        [10004] = function(template, ...) --检测出牌区下标
            return self:CheckDealIndex(template, ...)
        end,
        [10005] = function(template, ...) --检测卡牌资源改变
            return self:CheckCardResourceChange(template, ...)
        end,
        [10006] = function(template, ...) --检测回合资源是否满足
            return self:CheckCardResourceSatisfy(template, ...)
        end,
        [10007] = function(template, ...) --检测手牌数是否满足
            return self:CheckDeckCount(template, ...)
        end,
        [10008] = function(template, ...) --检测回合数是否相等
            return self:CheckRoundEqual(template, ...)
        end,
        [10009] = function(template, ...) --检查抽卡
            return self:CheckDrawCard(template, ...)
        end,
        [10010] = function(template, ...) --检查当前卡Buff是否触发
            return self:CheckCardBuffEffect(template, ...)
        end,
    }
end

function XSkyGardenCafeCondition:OnRelease()
    self._Func = nil
end

function XSkyGardenCafeCondition:CheckCondition(conditionId, ...)
    local template = self._Model:GetConditionTemplate(conditionId)
    local func = self._Func[template.Type]
    if not func then
        XLog.Error("未实现类型：" .. template.Type .. "的条件检测函数！")
        return false, ""
    end
    return func(template, ...)
end

--- 检测资源是否满足
---@param template XTableSGCafeCondition  
---@return boolean, string
--------------------------
function XSkyGardenCafeCondition:CheckResource(template, ...)
    local target = template.Params[3]
    local count = 0
    local type = template.Params[1]
    local op = OpList[template.Params[2]]
    -- 销量
    if type == 1 then
        local battle = self._Model:GetBattleInfo()
        count = battle and battle:GetScore() or 0
    elseif type == 2 then --好感度
        local battle = self._Model:GetBattleInfo()
        count = battle and battle:GetReview() or 0
    elseif type == 3 then
        local battle = self._Model:GetBattleInfo()
        count = battle and battle:GetDealLimit() or 0
    end
    
    return CheckOp(op, count, target), template.Desc
end

--- 检测某张卡是否在出牌区
---@param template XTableSGCafeCondition
---@return boolean, string
--------------------------
function XSkyGardenCafeCondition:CheckCardInDeal(template, ...)
    local cardId = template.Params[1]
    local game = self._MainControl:GetBattle()
    if not game then
        XLog.Error("请先进入战斗！！！")
        return false, template.Desc
    end
    local dealCards = game:GetRoundEntity():GetDealCardEntities()
    if XTool.IsTableEmpty(dealCards) then
        return false, template.Desc
    end

    for _, card in pairs(dealCards) do
        if card:GetCardId() == cardId then
            return true, template.Desc
        end
    end
    return false, template.Desc
end

---@param template XTableSGCafeCondition
function XSkyGardenCafeCondition:CheckDealCount(template, card, isPreview, ...)
    local cardEntities = self._MainControl:GetBattle():GetRoundEntity():GetDealCardEntities()
    local count = cardEntities and #cardEntities or 0
    return count >= template.Params[1], template.Desc
end

---@param template XTableSGCafeCondition
function XSkyGardenCafeCondition:CheckDealHasTarget(template, card, isPreview, ...)
    local cardEntities = self._MainControl:GetBattle():GetRoundEntity():GetDealCardEntities()
    if not XTool.IsTableEmpty(cardEntities) then
        local targetId = template.Params[1]
        for _, c in pairs(cardEntities) do
            if c:GetCardId() == targetId then
                return true, template.Desc
            end
        end
    end
    return false, template.Desc
end

---@param template XTableSGCafeCondition
function XSkyGardenCafeCondition:CheckRoundState(template, card, isPreview, ...)
    local roundState = self._MainControl:GetBattle():GetRoundEntity():GetRoundState()
    return roundState == template.Params[1], template.Desc
end

---@param template XTableSGCafeCondition
---@param card XSkyGardenCafeCardEntity
function XSkyGardenCafeCondition:CheckDealIndex(template, card, isPreview, ...)
    local cardId = template.Params[1]
    local index
    if isPreview then
        index = self._MainControl:GetBattle():GetRoundEntity():GetNextDealIndex()
    else
        if cardId <= 0 then
            index = self._MainControl:GetBattle():GetRoundEntity():GetDealCardIndexByCard(card)
        else
            index = self._MainControl:GetBattle():GetRoundEntity():GetDealCardIndexByCardId(cardId)
        end
    end
   
    if not index or index < 0 then
        return false, template.Desc
    end
    local checkType = template.Params[2]
    if checkType == 1 then --指定位置
        return index == template.Params[3], template.Desc
    elseif checkType == 2 then --位置区间
        return index >= template.Params[3] and index < template.Params[4], template.Desc
    end
    return false, template.Desc
end

---@param template XTableSGCafeCondition
---@param card XSkyGardenCafeCardEntity
function XSkyGardenCafeCondition:CheckCardResourceChange(template, card, isPreview, ...)
    local checkType = template.Params[1]
    local changeValue1
    local changeValue2
    local cardId = card:GetCardId()
    if checkType == 1 then --销量
        local origin = self._Model:GetCustomerCoffee(cardId)
        changeValue1 = card:GetTotalCoffee(isPreview) - origin
    elseif checkType == 2 then --好评
        local origin = self._Model:GetCustomerReview(cardId)
        changeValue2 = card:GetTotalReview(isPreview) - origin
    elseif checkType == 3 then --任意
        local origin1 = self._Model:GetCustomerCoffee(cardId)
        changeValue1 = card:GetTotalCoffee(isPreview) - origin1
        local origin2 = self._Model:GetCustomerReview(cardId)
        changeValue2 = card:GetTotalReview(isPreview) - origin2
    end
    
    local param2 = template.Params[2]
    --任意变动
    if param2 == 1 then
        if changeValue1 and changeValue1 ~= 0 then
            return true, template.Desc 
        end
        if changeValue2 and changeValue2 ~= 0 then
            return true, template.Desc
        end
        return false, template.Desc
    end
    local op = OpList[template.Params[3]]
    if changeValue1 and CheckOp(op, changeValue1 - template.Params[4]) then
        return true, template.Desc
    end
    if changeValue2 and CheckOp(op, changeValue2 - template.Params[4]) then
        return true, template.Desc
    end
    return false, template.Desc
end

---@param template XTableSGCafeCondition
function XSkyGardenCafeCondition:CheckCardResourceSatisfy(template, card, isPreview, ...)
    local checkType = template.Params[1]
    local param2 = template.Params[2]
    local isCurrent = param2 == 3
    local changeValue1
    local changeValue2
    
    local battleInfo = self._Model:GetBattleInfo()
    if checkType == 1 then --销量
        changeValue1 = isCurrent and battleInfo:GetTotalScore() or battleInfo:GetAddScore()
    elseif checkType == 2 then --好评
        changeValue2 = isCurrent and battleInfo:GetTotalReview() or battleInfo:GetAddReview()
    elseif checkType == 3 then --任意
        changeValue1 = isCurrent and battleInfo:GetTotalScore() or battleInfo:GetAddScore()
        changeValue2 = isCurrent and battleInfo:GetTotalReview() or battleInfo:GetAddReview()
    end
    
    --任意变动
    if param2 == 1 then
        if changeValue1 and changeValue1 ~= 0 then
            return true, template.Desc
        end
        if changeValue2 and changeValue2 ~= 0 then
            return true, template.Desc
        end
        return false, template.Desc
    end

    local op = OpList[template.Params[3]]
    if changeValue1 and CheckOp(op, changeValue1 - template.Params[4]) then
        return true, template.Desc
    end
    if changeValue2 and CheckOp(op, changeValue2 - template.Params[4]) then
        return true, template.Desc
    end
    return false, template.Desc
end

---@param template XTableSGCafeCondition
function XSkyGardenCafeCondition:CheckDeckCount(template, card, isPreview, ...)
    local param1 = template.Params[1]
    local op = OpList[template.Params[2]]
    if param1 == 1 then --与当前手牌数进行比较
        local count = self._MainControl:GetBattle():GetBattleInfo():GetDeckLimit(self._Model:GetMaxDeckCount())
        return CheckOp(op, count - template.Params[3]), template.Desc
    elseif param1 == 2 then --与关卡初始手牌比较
        local stageId = self._MainControl:GetBattle():GetStageId()
        local count  = self._Model:GetMaxCustomer(stageId)
        return CheckOp(op, count - template.Params[3]), template.Desc
    end
    return false, template.Desc
end

---@param template XTableSGCafeCondition
function XSkyGardenCafeCondition:CheckRoundEqual(template, card, isPreview, ...)
    local round = self._Model:GetBattleInfo():GetRound()
    return round == template.Params[1], template.Desc
end

---@param template XTableSGCafeCondition
---@param drawCardType number
---@param cards XSkyGardenCafeCardEntity[]
function XSkyGardenCafeCondition:CheckDrawCard(template, card, isPreview, drawCardType, cards, ...)
    local isAny = template.Params[1] == 3
    if not isAny and drawCardType ~= template.Params[1] then
        return false, template.Desc
    end
    local param2 = template.Params[2]

    if param2 == 0 then
        return true, template.Desc
    elseif param2 == 1 then --判断数量
        local count = cards and #cards or 0
        return count >= template.Params[3] and count < template.Params[4]
    elseif param2 == 2 then --判断指定牌
        if not XTool.IsTableEmpty(cards) then
            local targetId = template.Params[3]
            for _, c in pairs(cards) do
                if targetId == c:GetCardId() then
                    return true, template.Desc
                end
            end
        end
    elseif param2 == 3 then --判断类型
        if not XTool.IsTableEmpty(cards) then
            local targetType = template.Params[3]
            for _, c in pairs(cards) do
                if c:GetCardType() == targetType then
                    return true, template.Desc
                end
            end
        end
    elseif param2 == 4 then --判断稀有度
        local targetQ = template.Params[3]
        for _, c in pairs(cards) do
            if c:GetCardQuality() == targetQ then
                return true, template.Desc
            end
        end
    end

    return false, template.Desc
end

---@param template XTableSGCafeCondition
---@param card XSkyGardenCafeCardEntity
function XSkyGardenCafeCondition:CheckCardBuffEffect(template, card, isPreview, ...)
    if not card then
        return false, template.Desc
    end
    local buffId, count = template.Params[1], template.Params[2]
    return card:IsBuffEffect(buffId, count), template.Desc
end

return XSkyGardenCafeCondition