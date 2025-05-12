local XSGCafeBuff = require("XModule/XSkyGardenCafe/Entity/Effect/XSGCafeBuff")

---@class XSGCafeResourceTransformBuff : XSGCafeBuff 资源转化
local XSGCafeResourceTransformBuff = XClass(XSGCafeBuff, "XSGCafeResourceTransformBuff")

function XSGCafeResourceTransformBuff:ApplyMotion(isPreview)
    if not self._Card then
        XLog.Error("该Buff必须绑定在卡牌上 BuffId = ", self._BuffId)
        return
    end
    local param1 = self._Params[1]
    local param2 = self._Params[2]
    local battleInfo = self._Model:GetBattleInfo()

    local isSelf = param1 == 1 --消耗自身
    local isChange = param1 == 2 --本回合增量
    local ratio = self._Params[3]
    self._Way = param2
    self._IsSelf = isSelf
    if param2 == 1 then
        --销量转好评
        local score = 0
        if isSelf then
            score = self._Params[4]
            score = math.min(score, battleInfo:GetTotalScore())
            local review = score * ratio
            self._Card:AddFinalReview(review, isPreview)
            self._Card:AddBasicCoffee(-score, isPreview)
            self._Value1 = -score
            self._Value2 = review

        elseif isChange then
            score = battleInfo:GetAddScore()
            if score >= 0 then
                score = 0
            else
                local abs = math.abs(score)
                local min = math.min(abs, self._Params[4])
                score = min
            end
            local review = score * ratio
            self._Value1 = review
            self._Card:AddFinalReview(review, isPreview)
        end
        if isPreview then
            self._PreviewCount = self._PreviewCount + 1
        else
            self:AddEffectCount()
        end
        
    elseif param2 == 2 then
        --好评转销量
        local review = 0
        if isSelf then
            review = self._Params[4]
            review = math.min(review, battleInfo:GetTotalReview())
            local score = review * ratio
            self._Card:AddFinalReview(-review, isPreview)
            self._Card:AddBasicCoffee(score, isPreview)
            self._Value1 = -review
            self._Value2 = score

        elseif isChange then
            review = battleInfo:GetAddReview()
            if review >= 0 then
                review = 0
            else
                local abs = math.abs(review)
                local min = math.min(abs, self._Params[4])
                review = min
            end
            local score = review * ratio
            self._Value1 = score
            self._Card:AddFinalCoffee(score, isPreview)
        end
        if isPreview then
            self._PreviewCount = self._PreviewCount + 1
        else
            self:AddEffectCount()
        end
    end
end

function XSGCafeResourceTransformBuff:PreviewApplyMotion()
    self:ApplyMotion(true)
end

function XSGCafeResourceTransformBuff:RemoveMotion()
    if not self._Card then
        XLog.Error("该Buff必须绑定在卡牌上 BuffId = ", self._BuffId)
        return
    end
    if self._Way == 1 then --销量转好评
        if self._IsSelf then
            self._Card:AddBasicCoffee(-self._Value1, false)
            self._Card:AddFinalReview(-self._Value2, false)
        else
            self._Card:AddFinalReview(-self._Value1, false)
        end

    elseif self._Way == 2 then --好评转销量
        if self._IsSelf then
            self._Card:AddFinalReview(-self._Value1, false)
            self._Card:AddBasicCoffee(-self._Value2, false)
        else
            self._Card:AddBasicCoffee(-self._Value1, false)
        end
    end
end

function XSGCafeResourceTransformBuff:AddBuffArgs()
    if not self._Card then
        return
    end
    local addValue, subValue
    if self._IsSelf then
        addValue = self._Value2
        subValue = self._Value1
    else
        addValue = self._Value1
        subValue = -self._Value1
    end

    self._Card:AddBuffArgs(1101, subValue)
    self._Card:AddBuffArgs(1102, addValue)
end

return XSGCafeResourceTransformBuff