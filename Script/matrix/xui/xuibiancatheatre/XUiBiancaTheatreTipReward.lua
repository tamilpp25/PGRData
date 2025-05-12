local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiBiancaTheatreItemGrid = require("XUi/XUiBiancaTheatre/Common/XUiBiancaTheatreItemGrid")

--肉鸽2.0奖励弹窗
local XUiBiancaTheatreTipReward = XLuaUiManager.Register(XLuaUi, "UiBiancaTheatreTipReward")

function XUiBiancaTheatreTipReward:OnAwake()
    self:AddListener()
end

--horizontalNormalizedPosition：水平滚动位置，以 0 到 1 之间的值表示，0 表示位于左侧
function XUiBiancaTheatreTipReward:OnStart(closeCb, rewardGoodsList, title, sureCb, horizontalNormalizedPosition, theatreItemIdList)
    self.RewardGoodItems = {}
    self.TheatreItems = {}
    self.GridCommon.gameObject:SetActive(false)
    if title then
        self.TxtTitle.text = title
    end
    self.OkCallback = sureCb
    self.CancelCallback = closeCb
    self:Refresh(rewardGoodsList, horizontalNormalizedPosition, theatreItemIdList)

    self:CheckIsTimelimitGood(rewardGoodsList)
    if not XTool.IsTableEmpty(theatreItemIdList) then
        -- 入场音效
        XDataCenter.BiancaTheatreManager.PlayGetRewardSound(nil, 2)
    end
end

function XUiBiancaTheatreTipReward:OnEnable()
    
end

function XUiBiancaTheatreTipReward:AddListener()
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
end

function XUiBiancaTheatreTipReward:OnBtnCloseClick()
    self:Close()
    if self.CancelCallback then
        self.CancelCallback()
    end
end

function XUiBiancaTheatreTipReward:Refresh(rewardGoodsList, horizontalNormalizedPosition, theatreItemIdList)
    if not XTool.IsTableEmpty(rewardGoodsList) then
        rewardGoodsList = XRewardManager.MergeAndSortRewardGoodsList(rewardGoodsList)
        XUiHelper.CreateTemplates(self, self.RewardGoodItems, rewardGoodsList, XUiGridCommon.New, self.GridCommon, self.PanelRecycle, function(grid, data)
            grid:Refresh(data, nil, nil, false)
            XUiHelper.RegisterClickEvent(grid, grid.BtnClick, function()
                XLuaUiManager.Open("UiBiancaTheatreTips", data)
            end)
        end)
    end
    
    for i, theatreItemId in ipairs(theatreItemIdList or {}) do
        local theatreItem = self.TheatreItems[i]
        if not theatreItem then
            theatreItem = XUiBiancaTheatreItemGrid.New(XUiHelper.Instantiate(self.GridCommon, self.PanelRecycle))
            XUiHelper.RegisterClickEvent(theatreItem, theatreItem.BtnClick, function()
                XLuaUiManager.Open("UiBiancaTheatreTips", {TheatreItemId = theatreItem:GetTheatreItemId()})
            end)
            self.TheatreItems[i] = theatreItem
        end
        theatreItem:Refresh(theatreItemId)
    end

    if horizontalNormalizedPosition then
        self.ScrView.horizontalNormalizedPosition = horizontalNormalizedPosition
    end
end

function XUiBiancaTheatreTipReward:CheckIsTimelimitGood(rewardGoodsList)
    if XTool.IsTableEmpty(rewardGoodsList) then
        return
    end
    for _, good in pairs(rewardGoodsList) do
        if XArrangeConfigs.GetType(good.TemplateId) == XArrangeConfigs.Types.Item then -- 是道具
            local itemData = XDataCenter.ItemManager.GetItemTemplate(good.TemplateId)
            if itemData.SubTypeParams[1] and XArrangeConfigs.GetType(itemData.SubTypeParams[1]) == XArrangeConfigs.Types.WeaponFashion then -- 对应武器涂装
                if itemData.SubTypeParams[2] and itemData.SubTypeParams[2] > 0 then
                    XUiManager.TipMsg(CS.XTextManager.GetText("WeaponFashionLimitGetInBag", itemData.Name,XUiHelper.GetTime(itemData.SubTypeParams[2], XUiHelper.TimeFormatType.ACTIVITY)))
                    break
                end
            end
        end
    end
end

function XUiBiancaTheatreTipReward:Close()
    self:EmitSignal("Close")
    self.Super.Close(self)
end