local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
---@class XUiTheatre3PropChoose : XLuaUi 迭变藏品
---@field _Control XTheatre3Control
local XUiTheatre3PropChoose = XLuaUiManager.Register(XLuaUi, "UiTheatre3PropChoose")

function XUiTheatre3PropChoose:OnAwake()
    self._Control:RegisterClickEvent(self, self.BtnNext, self.OnClickNext)
    self._Control:RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
end

function XUiTheatre3PropChoose:OnStart()
    self._PanelAsset = XUiHelper.NewPanelActivityAssetSafe({ XEnumConst.THEATRE3.Theatre3InnerCoin }, self.PanelSpecialTool, self, nil, function()
        self._Control:OpenAdventureTips(XEnumConst.THEATRE3.Theatre3InnerCoin)
    end)
    ---@type XDynamicTableNormal
    self.DynamicTable = XDynamicTableNormal.New(self.SViewRewardList)
    self.DynamicTable:SetProxy(require("XUi/XUiTheatre3/Adventure/Reward/XGridTheatre3PropChoose"), self)
    self.DynamicTable:SetDelegate(self)
    self.GridReward.gameObject:SetActiveEx(false)
    -- 道具选择
    local groupId = tonumber(self._Control:GetClientConfig("ChooseItemGroupId"))
    local items = self._Control:GetItemsByGroupId(groupId)
    self._Datas = {}
    table.insert(self._Datas, 0) -- 第一个位置为空格子
    for _, v in pairs(items) do
        --local itemConfig = self._Control:GetItemConfigById(v.ItemId) 策划说用不到了 现在初始道具选择只会在噩梦难度出现
        --if itemConfig.DifficultId == self._Control:GetAdventureCurDifficultyId() then
        table.insert(self._Datas, v.Id)
        --end
    end
    self.DynamicTable:SetDataSource(self._Datas)
    self.DynamicTable:ReloadDataASync(1)
    -- 压力值和图标
    local presure = self._Control:GetHistoryPressureValue()
    self.TxtNum.text = presure
    self:SetUiSprite(self.ImgPressure, self._Control:GetPressureIcon(presure))
    -- 刷新按钮状态
    self:RefreshUi()
end

function XUiTheatre3PropChoose:OnDestroy()
    XDataCenter.ItemManager.RemoveCountUpdateListener(self._PanelAsset)
end

function XUiTheatre3PropChoose:RefreshUi()
    self.BtnNext:SetButtonState(self._CurSelectItemId ~= nil and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
end

---@param grid XGridTheatre3PropChoose
function XUiTheatre3PropChoose:OnDynamicTableEvent(event, index, grid)
    if not grid then
        return
    end
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid.Transform.name = string.format("GridReward%s", index) -- 引导用
        grid:Refresh(self._Datas[index])
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self._CurSelectItemId = self._Datas[index]
        ---@type XGridTheatre3PropChoose[]
        local grids = self.DynamicTable:GetGrids()
        for k, v in pairs(grids) do
            v:SetSelect(k == index)
        end
        self:RefreshUi()
    end
end

function XUiTheatre3PropChoose:OnClickNext()
    -- 按钮在Disable状态下还能点击
    if self._CurSelectItemId then
        self._Control:SelectInitialItemRequest(self._CurSelectItemId)
    end
end

function XUiTheatre3PropChoose:OnBtnBackClick()
    self._Control:OpenTextTip(handler(self, self.Close), XUiHelper.ReadTextWithNewLineWithNotNumber("TipTitle"), XUiHelper.ReadTextWithNewLineWithNotNumber("Theatre3SettleRewardTip"))
end

return XUiTheatre3PropChoose