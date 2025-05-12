local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiGridTheatre3Reward = require("XUi/XUiTheatre3/Adventure/Prop/XUiGridTheatre3Reward")

---@class XUiTheatre3TipReward : XLuaUi
---@field _Control XTheatre3Control
local XUiTheatre3TipReward = XLuaUiManager.Register(XLuaUi, "UiTheatre3TipReward")

function XUiTheatre3TipReward:OnAwake()
    self:RegisterUiEvents()
    self.GridCommon.gameObject:SetActive(false)
    self.PropGrid.gameObject:SetActive(false)
end

---@deprecated rewardGoodsList 通用奖励列表
---@deprecated innerItemList 肉鸽3.0物品列表
---@deprecated closeCb 关闭回调
function XUiTheatre3TipReward:OnStart(rewardGoodsList, innerItemList, closeCb)
    self.CancelCallback = closeCb
    ---@type XUiGridCommon[]
    self.RewardGoodItems = {}
    ---@type XUiGridTheatre3Reward[]
    self.InnerItems = {}
    self:Refresh(rewardGoodsList, innerItemList)
    self:CheckIsTimelimitGood(rewardGoodsList)
end

function XUiTheatre3TipReward:Refresh(rewardGoodsList, innerItemList)
    if not XTool.IsTableEmpty(rewardGoodsList) then
        rewardGoodsList = XRewardManager.MergeAndSortRewardGoodsList(rewardGoodsList)
        XUiHelper.CreateTemplates(self, self.RewardGoodItems, rewardGoodsList, XUiGridCommon.New, self.GridCommon, self.PanelRecycle, function(grid, data)
            grid:Refresh(data, nil, nil, false)
            XUiHelper.RegisterClickEvent(grid, grid.BtnClick, function()
                local templateId = (data.TemplateId and data.TemplateId > 0) and data.TemplateId or data.Id
                XLuaUiManager.Open("UiTheatre3Tips", templateId)
            end)
        end)
    end
    for i, itemId in pairs(innerItemList or {}) do
        local grid = self.InnerItems[i]
        if not grid then
            local go = XUiHelper.Instantiate(self.PropGrid, self.PanelRecycle)
            grid = XUiGridTheatre3Reward.New(go, self)
            self.InnerItems[i] = grid
        end
        grid:Open()
        grid:SetData(itemId, XEnumConst.THEATRE3.EventStepItemType.InnerItem)
        grid:ShowRed(false)
    end
end

function XUiTheatre3TipReward:CheckIsTimelimitGood(rewardGoodsList)
    if XTool.IsTableEmpty(rewardGoodsList) then
        return
    end
    for _, good in pairs(rewardGoodsList) do
        -- 是道具
        if XTypeManager.GetTypeById(good.TemplateId) == XArrangeConfigs.Types.Item then
            local itemData = XDataCenter.ItemManager.GetItemTemplate(good.TemplateId)
            -- 对应武器涂装
            if itemData.SubTypeParams[1] and XTypeManager.GetTypeById(itemData.SubTypeParams[1]) == XArrangeConfigs.Types.WeaponFashion then
                if itemData.SubTypeParams[2] and itemData.SubTypeParams[2] > 0 then
                    XUiManager.TipMsg(CS.XTextManager.GetText("WeaponFashionLimitGetInBag", itemData.Name, XUiHelper.GetTime(itemData.SubTypeParams[2], XUiHelper.TimeFormatType.ACTIVITY)))
                    break
                end
            end
        end
    end
end

function XUiTheatre3TipReward:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick)
end

function XUiTheatre3TipReward:OnBtnCloseClick()
    XLuaUiManager.CloseWithCallback(self.Name, self.CancelCallback)
end

return XUiTheatre3TipReward