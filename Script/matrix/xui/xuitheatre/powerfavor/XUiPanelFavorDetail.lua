local XUiGridFavorDetail = require("XUi/XUiTheatre/PowerFavor/XUiGridFavorDetail")

local FavorCoin = XTheatreConfigs.TheatreFavorCoin

--肉鸽玩法势力详情界面
local XUiPanelFavorDetail = XClass(nil, "XUiPanelFavorDetail")

function XUiPanelFavorDetail:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self.RootUi = rootUi
    self:SetButtonCallBack()
    self:InitDynamicTable()
    self.TheatrePowerManager = XDataCenter.TheatreManager.GetPowerManager()
end

function XUiPanelFavorDetail:Show(powerId)
    self.PowerId = powerId
    self:Refresh()
    self.GameObject:SetActiveEx(true)
end

function XUiPanelFavorDetail:Refresh()
    self:UpdatePowerDetail()
    self:UpdateRewardList()
end

--势力好感度列表
function XUiPanelFavorDetail:UpdateRewardList()
    self:UpdateDynamicTable()
end

function XUiPanelFavorDetail:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelTaskStoryList)
    self.DynamicTable:SetProxy(XUiGridFavorDetail)
    self.DynamicTable:SetDelegate(self)
    self.GridTask.gameObject:SetActiveEx(false)
end

function XUiPanelFavorDetail:UpdateDynamicTable()
    local powerId = self.PowerId
    self.PowerFavorIdList = XTheatreConfigs.GetPowerFavorIdListByPowerId(powerId, true)
    self.DynamicTable:SetDataSource(self.PowerFavorIdList)
    self.DynamicTable:ReloadDataASync()
end

function XUiPanelFavorDetail:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self.RootUi)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.PowerFavorIdList[index])
    end
end

--势力详情
function XUiPanelFavorDetail:UpdatePowerDetail()
    local powerId = self.PowerId

    local icon = XTheatreConfigs.GetPowerConditionIcon(powerId)
    self.RImgIcon:SetRawImage(icon)

    self.TxtName.text = XTheatreConfigs.GetPowerConditionName(powerId)

    local curLv = self.TheatrePowerManager:GetPowerCurLv(powerId)
    local showLv = curLv    --生效等级从0开始显示
    self.TxtLv.text = XUiHelper.GetText("TheatreDecorationTipsLevel", showLv)

    local itemIcon = XItemConfigs.GetItemIconById(FavorCoin)
    self.RImgPrice:SetRawImage(itemIcon)

    local powerFavorId = XTheatreConfigs.GetTheatrePowerIdAndLvToId(powerId, showLv)
    local upgradeCostConfig = powerFavorId and XTheatreConfigs.GetPowerFavorUpgradeCost(powerFavorId)
    local upgradeCost = XDataCenter.ItemManager.GetCount(FavorCoin)
    self.TxtNewPrice.text = string.format("%s/%s", upgradeCost, upgradeCostConfig)

    local isMaxLv = self.TheatrePowerManager:IsPowerMaxLv(powerId)
    self.PanelPrice.gameObject:SetActiveEx(not isMaxLv)
end

function XUiPanelFavorDetail:Hide()
    self.GameObject:SetActiveEx(false)
end

function XUiPanelFavorDetail:IsShow()
    return self.GameObject.activeSelf
end

function XUiPanelFavorDetail:SetButtonCallBack()
    XUiHelper.RegisterClickEvent(self, self.BtnLevelUp, self.OnBtnLevelUpClick)
    XUiHelper.RegisterClickEvent(self, self.BtnJump, self.OnBtnJumpClick)
end

function XUiPanelFavorDetail:OnBtnJumpClick()
    XLuaUiManager.Open("UiTheatreFieldGuide", {XTheatreConfigs.FieldGuideIds.AllSkill, XTheatreConfigs.FieldGuideIds.Item}, nil, nil, nil, self.PowerId)
end

function XUiPanelFavorDetail:OnBtnLevelUpClick()
    local powerId = self.PowerId
    local curLv = self.TheatrePowerManager:GetPowerCurLv(powerId)
    local powerFavorId = XTheatreConfigs.GetTheatrePowerIdAndLvToId(powerId, curLv)
    self.TheatrePowerManager:RequestTheatrePowerFavorUpgrade(powerFavorId, function()
        self:Refresh()
    end)
end

return XUiPanelFavorDetail