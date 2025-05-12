local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiTheatre4PopupGetReward : XLuaUi
---@field private _Control XTheatre4Control
local XUiTheatre4PopupGetReward = XLuaUiManager.Register(XLuaUi, "UiTheatre4PopupGetReward")

function XUiTheatre4PopupGetReward:OnAwake()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick)
    self.GridCommon.gameObject:SetActiveEx(false)
    self.GridProp.gameObject:SetActiveEx(false)
    self.PanelRewardList.gameObject:SetActiveEx(true)
end

---@deprecated rewardGoodsList 通用奖励列表
---@deprecated itemList 肉鸽4物品列表
---@deprecated closeCb 关闭回调
---@param itemList { Id:number, Type:number, Count:number }[]
function XUiTheatre4PopupGetReward:OnStart(rewardGoodsList, itemList, closeCb)
    self.CloseCb = closeCb
    ---@type XUiGridCommon[]
    self.RewardGoodItems = {}
    ---@type XUiGridTheatre4Prop[]
    self.GridPropList = {}

    if not XTool.IsTableEmpty(itemList) then
        for i, itemData in pairs(itemList) do
            -- 解锁天赋-樊外窥梦，觉醒值获取弹窗数量没有算上加成
            if itemData.Type == XEnumConst.Theatre4.AssetType.AwakeningPoint or
                    itemData.Type == XEnumConst.Theatre4.AssetType.ColorCostPoint
            then
                local isRedBuyDeadIncreaseAvailable, effectId = self._Control.EffectSubControl:GetEffectRedBuyDeadIncreaseAvailable()
                if isRedBuyDeadIncreaseAvailable then
                    local params = self._Control.EffectSubControl:GetEffectParams(effectId)
                    if params and params[3] then
                        itemData.Count = math.floor(itemData.Count * (100 + params[3] / 100) / 100)
                    end
                end
            end
        end
    end
    
    self:Refresh(rewardGoodsList, itemList)
end

function XUiTheatre4PopupGetReward:Refresh(rewardGoodsList, itemList)
    if not XTool.IsTableEmpty(rewardGoodsList) then
        -- 合并奖励
        rewardGoodsList = XRewardManager.MergeAndSortRewardGoodsList(rewardGoodsList)
        for i, v in pairs(rewardGoodsList) do
            local item = self.RewardGoodItems[i]
            if not item then
                local go = XUiHelper.Instantiate(self.GridCommon, self.Content)
                item = XUiGridCommon.New(self, go)
                self.RewardGoodItems[i] = item
            end
            item:Refresh(v)
            XUiHelper.RegisterClickEvent(item, item.BtnClick, function()
                local templateId = (v.TemplateId and v.TemplateId > 0) and v.TemplateId or v.Id
                XLuaUiManager.Open("UiTheatre4PopupItemDetail", templateId)
            end)
        end
    end
    if not XTool.IsTableEmpty(itemList) then
        for i, itemData in pairs(itemList) do
            local item = self.GridPropList[i]
            if not item then
                local go = XUiHelper.Instantiate(self.GridProp, self.Content)
                item = require("XUi/XUiTheatre4/Common/XUiGridTheatre4Prop").New(go, self)
                self.GridPropList[i] = item
            end
            item:Open()
            item:Refresh(itemData)
        end
    end

    self:RefreshPosition()
end

function XUiTheatre4PopupGetReward:OnBtnCloseClick()
    if XTool.IsTableEmpty(self.GridPropList) then
        XLuaUiManager.CloseWithCallback(self.Name, self.CloseCb)
    else
        self._Control:CheckNeedOpenNextPopup(self.Name, true)
    end
end

function XUiTheatre4PopupGetReward:RefreshPosition()
    if self.Viewport then
        CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.Content)

        local contentWidth = self.Content.rect.width
        local viewportWidth = self.Viewport.rect.width
        
        if contentWidth > viewportWidth then
            local y = self.Content.anchoredPosition.y
            
            self.Content.anchoredPosition = Vector2(contentWidth / 2, y)
        end
    end
end

return XUiTheatre4PopupGetReward
