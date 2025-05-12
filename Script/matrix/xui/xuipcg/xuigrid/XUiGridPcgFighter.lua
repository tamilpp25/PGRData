---@class XUiGridPcgFighter : XUiNode
---@field private _Control XPcgControl
local XUiGridPcgFighter = XClass(XUiNode, "XUiGridPcgFighter")

-- 继承时重写
--[[
-- 标记UiObject列表
self.TokenObjs = {}
-- 标记数据列表
self.TokenDatas = {}
]]

function XUiGridPcgFighter:OnDestroy()
    self:KillHpTweener()
    self:KillArmorTweener()
end

-- 刷新怪物标记
function XUiGridPcgFighter:RefreshTokens()
    self.TokenObjs = self.TokenObjs or {}
    self.TokenDatas = self.TokenDatas or {}

    local CSInstantiate = CS.UnityEngine.Object.Instantiate
    for i, tokenData in ipairs(self.TokenDatas) do
        local tokenObj = self.TokenObjs[i]
        if not tokenObj then
            local go = CSInstantiate(self.GridToken.gameObject, self.GridToken.transform.parent)
            tokenObj = go:GetComponent(typeof(CS.UiObject))
            table.insert(self.TokenObjs, tokenObj)
        end
        local tokenCfg = self._Control:GetConfigToken(tokenData.Id)
        local layer = tokenData:GetLayer()
        local isShow = tokenCfg.IsShow == 1 and layer ~= 0
        tokenObj.gameObject:SetActiveEx(isShow)
        if isShow then
            tokenObj:GetObject("RImgToken"):SetRawImage(tokenCfg.Icon)
            tokenObj:GetObject("TxtTokenNum").text = "x" .. tostring(layer)
        end
    end

    -- 隐藏多余标记
    self.GridToken.gameObject:SetActiveEx(false)
    for i = #self.TokenDatas + 1, #self.TokenObjs do
        local tokenObj = self.TokenObjs[i]
        tokenObj.gameObject:SetActiveEx(false)
    end
end

-- 设置标记列表
function XUiGridPcgFighter:SetTokens(tokenDatas)
    ---@type XPcgToken[]
    self.TokenDatas = XTool.Clone(tokenDatas)
    self:RefreshTokens()
end

-- 设置单个标记
function XUiGridPcgFighter:SetToken(tokenId, tokenNum)
    local isNewToken = true
    local isAddLayer = false
    for _, tokenData in ipairs(self.TokenDatas) do
        if tokenData:GetId() == tokenId then
            if tokenNum > tokenData:GetLayer() then
                isAddLayer = true
            end
            tokenData:SetLayer(tokenNum)
            isNewToken = false
        end
    end
    if isNewToken then
        ---@type XPcgToken
        local tokenData = require("XModule/XPcg/XEntity/XPcgToken").New()
        tokenData:RefreshData({Id = tokenId, Layer = tokenNum})
        table.insert(self.TokenDatas, tokenData)
        isAddLayer = true
    end
    self:RefreshTokens()

    -- 单位身上Token层数增多时播特效，层数减少不用播
    if isAddLayer then
        self:PlayAnimTokenAddLayer(tokenId)
    end
end

-- 单位身上Token层数增多时播特效
function XUiGridPcgFighter:PlayAnimTokenAddLayer(tokenId)
    for _, tokenData in ipairs(self.TokenDatas) do
        if tokenId == tokenData:GetId() then
            local tokenCfg = self._Control:GetConfigToken(tokenId)
            if tokenCfg.IsShow ~= 1 then return end
            
            -- 增益buff
            if tokenCfg.EffectType == XEnumConst.PCG.TOKEN_EFFECT_TYPE.BUFF and self.Buff then
                self.Buff.gameObject:SetActive(false)
                self.Buff.gameObject:SetActive(true)
            -- 减益buff
            elseif tokenCfg.EffectType == XEnumConst.PCG.TOKEN_EFFECT_TYPE.DEBUFF and self.DeBuff then
                self.DeBuff.gameObject:SetActive(false)
                self.DeBuff.gameObject:SetActive(true)
            end
        end
    end
end

-- 隐藏Buff特效
function XUiGridPcgFighter:HideAllBuff()
    if self.Buff then
        self.Buff.gameObject:SetActive(false)
    end
    if self.DeBuff then
        self.DeBuff.gameObject:SetActive(false)
    end
end

-- 播放血量条动画
function XUiGridPcgFighter:PlayAnimHpSlider(slider, endValue, time, cb)
    self:KillHpTweener()
    self.HpTweener = CS.DG.Tweening.DOTween.To(
            function() return slider.fillAmount end, -- Getter
            function(value)                          -- Setter
                slider.fillAmount = value
            end,
            endValue,       -- End value
            time / 1000     -- Duration
    ):OnComplete(function()
        if cb then cb() end
    end)
end

-- 终止血量Tween动画
function XUiGridPcgFighter:KillHpTweener()
    if self.HpTweener and self.HpTweener:IsActive() then
        self.HpTweener:Kill()
    end
    self.HpTweener = nil
end

-- 播放护盾条动画
function XUiGridPcgFighter:PlayAnimArmorSlider(slider, endValue, time, cb)
    self:KillArmorTweener()
    self.ArmorTweener = CS.DG.Tweening.DOTween.To(
            function() return slider.fillAmount end, -- Getter
            function(value)                          -- Setter
                slider.fillAmount = value
            end,
            endValue,       -- End value
            time / 1000     -- Duration
    ):OnComplete(function()
        if cb then cb() end
    end)
end

-- 终止护甲Tween动画
function XUiGridPcgFighter:KillArmorTweener()
    if self.ArmorTweener and self.ArmorTweener:IsActive() then
        self.ArmorTweener:Kill()
    end
    self.ArmorTweener = nil
end

return XUiGridPcgFighter
