---@class XUiTheatre4LvRewardBattlePassGrid : XUiNode
---@field TxtGroupGrid XUiComponent.XUiTextGroup
---@field RImgNormal UnityEngine.UI.RawImage
---@field RImgRare UnityEngine.UI.RawImage
---@field Normal UnityEngine.RectTransform
---@field NormaLight UnityEngine.RectTransform
---@field Rare UnityEngine.RectTransform
---@field RareLight UnityEngine.RectTransform
---@field Disable UnityEngine.RectTransform
---@field _Control XTheatre4Control
local XUiTheatre4LvRewardBattlePassGrid = XClass(XUiNode, "XUiTheatre4LvRewardBattlePassGrid")

-- region 生命周期

function XUiTheatre4LvRewardBattlePassGrid:OnStart()
    self._Entity = nil
    self._ClickTime = 0
end

-- endregion

function XUiTheatre4LvRewardBattlePassGrid:SetAlpha(alpha)
    self:_InitCanvasGroup()
    if not XTool.UObjIsNil(self._CanvasGroup) then
        self._CanvasGroup.alpha = alpha
    end
end

function XUiTheatre4LvRewardBattlePassGrid:PlayEnableAnimation()
    self:PlayAnimation("LvRewardPanelGridEnable", function()
        self:SetAlpha(1)
    end)
end

function XUiTheatre4LvRewardBattlePassGrid:OnTouch()
    if not self._Entity then
        return
    end
    -- CD冷却
    local nowTime = CS.XTimerManager.Ticks / CS.System.TimeSpan.TicksPerSecond
    if nowTime - self._ClickTime < self._Control:GetButtonCoolTime() then
        return
    end
    self._ClickTime = nowTime
    
    if self._Entity:IsCanReceive() then
        self._Control:BattlePassGetRewardRequest(XEnumConst.Theatre4.BattlePassGetRewardType.GetOnce,
            self._Entity:GetConfig():GetLevel(), function(rewardGoodsList)
                XLuaUiManager.Open("UiTheatre4PopupGetReward", rewardGoodsList)
                self:Refresh(self._Entity)
            end)
    else
        local itemId = self._Entity:GetItemId()

        if XTool.IsNumberValid(itemId) then
            XLuaUiManager.Open("UiTheatre4PopupItemDetail", itemId)
        end
    end

end

---@param entity XTheatre4BattlePassEntity
function XUiTheatre4LvRewardBattlePassGrid:Refresh(entity)
    if not entity or entity:IsEmpty() then
        self:Close()
        return
    end

    self._Entity = entity

    local reward = entity:GetReward()
    local config = entity:GetConfig()
    local goodsShowParams = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(reward.TemplateId)
    local name = nil
    local isDisplay = config:GetIsDisplay()

    if goodsShowParams.RewardType == XArrangeConfigs.Types.Character then
        name = goodsShowParams.TradeName
    else
        name = goodsShowParams.Name
    end

    self:_ChangeState(isDisplay)
    if isDisplay then
        self.RImgRare:SetRawImage(goodsShowParams.BigIcon)
    else
        self.RImgNormal:SetRawImage(goodsShowParams.BigIcon)
    end

    self.TxtGroupGrid:SetNameByGroup(0, config:GetLevel())
    self.TxtGroupGrid:SetNameByGroup(1, name)
    self.TxtGroupGrid:SetNameByGroup(2, "")
    self.TxtGroupGrid:SetNameByGroup(3, "x" .. reward.Count)
end

---@param entity XTheatre4BattlePassEntity
function XUiTheatre4LvRewardBattlePassGrid:IsEquals(entity)
    if self._Entity and entity then
        return self._Entity:IsEquals(entity)
    end

    return false
end

function XUiTheatre4LvRewardBattlePassGrid:IsSpecial()
    if self._Entity and not self._Entity:IsEmpty() then
        return self._Entity:GetConfig():GetIsDisplay()
    end

    return false
end

function XUiTheatre4LvRewardBattlePassGrid:GetLevel()
    if self._Entity then
        local config = self._Entity:GetConfig()

        return config:GetLevel()
    end

    return 0
end

-- region 私有方法

function XUiTheatre4LvRewardBattlePassGrid:_ChangeState(isDisplay)
    self.Normal.gameObject:SetActiveEx(not isDisplay)
    self.Rare.gameObject:SetActiveEx(isDisplay)

    if self._Entity:IsReceived() then
        self.NormaLight.gameObject:SetActiveEx(false)
        self.RareLight.gameObject:SetActiveEx(false)
        self.Disable.gameObject:SetActiveEx(true)
    elseif self._Entity:IsCanReceive() then
        self.NormaLight.gameObject:SetActiveEx(not isDisplay)
        self.RareLight.gameObject:SetActiveEx(isDisplay)
        self.Disable.gameObject:SetActiveEx(false)
    else
        self.NormaLight.gameObject:SetActiveEx(false)
        self.RareLight.gameObject:SetActiveEx(false)
        self.Disable.gameObject:SetActiveEx(false)
    end
end

function XUiTheatre4LvRewardBattlePassGrid:_InitCanvasGroup()
    if XTool.UObjIsNil(self._CanvasGroup) then
        self._CanvasGroup = self.Transform:GetComponent(typeof(CS.UnityEngine.CanvasGroup))
    end
end

-- endregion

return XUiTheatre4LvRewardBattlePassGrid
