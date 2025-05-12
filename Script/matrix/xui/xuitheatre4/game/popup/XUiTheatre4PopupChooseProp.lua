local XUiGridTheatre4PropCard = require("XUi/XUiTheatre4/Common/XUiGridTheatre4PropCard")
local XUiTheatre4ColorResource = require("XUi/XUiTheatre4/System/Resources/XUiTheatre4ColorResource")
---@class XUiTheatre4PopupChooseProp : XLuaUi
---@field _Control XTheatre4Control
---@field CurSelectGrid XUiGridTheatre4PropCard
local XUiTheatre4PopupChooseProp = XLuaUiManager.Register(XLuaUi, "UiTheatre4PopupChooseProp")

function XUiTheatre4PopupChooseProp:OnAwake()
    self:RegisterUiEvents()
    self:InitColour()
    self.GridPropCard.gameObject:SetActiveEx(false)
    ---@type XUiGridTheatre4PropCard[]
    self.GridItemList = {}
end

function XUiTheatre4PopupChooseProp:InitColour()
    ---@type XUiTheatre4ColorResource
    self.PanelColour = XUiTheatre4ColorResource.New(self.ListColour, self, function(colorId)
        XLuaUiManager.Open("UiTheatre4Genius", colorId)
    end)
    self.PanelColour:Open()
end

---@param id number 事务id 自增Id
function XUiTheatre4PopupChooseProp:OnStart(id)
    self.Id = id
end

function XUiTheatre4PopupChooseProp:OnEnable()
    self:RefreshNum()
    self:RefreshBuildPoint()
    self:RefreshItemList()
    self:SetAllAlpha()
    self:PlayAnimation("PopupEnable", function()
        self:PlayPropCardAnimation()
    end)
end

-- 刷新选择数量
function XUiTheatre4PopupChooseProp:RefreshNum()
    -- 剩余可选择数量
    -- local selectTimes = self._Control:GetTransactionSelectTimes(self.Id)
    -- local selectLimit = self._Control:GetTransactionSelectLimit(self.Id)
    -- self.TxtNum.text = string.format("%d/%d", selectTimes, selectLimit)
    self.TxtNum.gameObject:SetActiveEx(false)
end

-- 刷新建筑点信息
function XUiTheatre4PopupChooseProp:RefreshBuildPoint()
    -- 建造点图片
    local bpIcon = self._Control.AssetSubControl:GetAssetIcon(XEnumConst.Theatre4.AssetType.BuildPoint)
    if bpIcon then
        self.ImgEnergy:SetSprite(bpIcon)
    end
    -- 建造点数量
    self.TxtEnergyNum.text = self._Control.AssetSubControl:GetAssetCount(XEnumConst.Theatre4.AssetType.BuildPoint)
end

-- 刷新藏品列表
function XUiTheatre4PopupChooseProp:RefreshItemList()
    ---@type { Reward:XTheatre4Asset, Index:number }[]
    local rewardDataList = self._Control:GetTransactionRewardDataList(self.Id)
    if XTool.IsTableEmpty(rewardDataList) then
        return
    end
    for i, rewardData in pairs(rewardDataList) do
        local grid = self.GridItemList[i]
        if not grid then
            local go = XUiHelper.Instantiate(self.GridPropCard, self.ListOption)
            grid = XUiGridTheatre4PropCard.New(go, self, handler(self, self.OnSelectCallback), handler(self, self.OnYesCallback))
            self.GridItemList[i] = grid
        end
        grid:Open()
        grid:Refresh({ Id = rewardData.Reward:GetId(), Type = rewardData.Reward:GetType(), Index = rewardData.Index })
        grid:SetReplaceCallback(Handler(self, self.OnReplaceCallback))
        grid:SetSellCallback(Handler(self, self.OnSellCallback))
    end
    for i = #rewardDataList + 1, #self.GridItemList do
        self.GridItemList[i]:Close()
    end
end

-- 选择回调
---@param grid XUiGridTheatre4PropCard
function XUiTheatre4PopupChooseProp:OnSelectCallback(grid)
    if self.CurSelectGrid then
        if self.CurSelectGrid:GetIndex() == grid:GetIndex() then
            return
        end
        self.CurSelectGrid:SetIsSelect(false)
        self.CurSelectGrid:SetBtnYes(false)
        self.CurSelectGrid:SetBtnSell(false)
        self.CurSelectGrid:SetBtnContrast(false)
        self.CurSelectGrid:SetImgNow(false)
    end

    local itemCount = self._Control:GetItemCountAndLimit()

    grid:SetIsSelect(true)
    grid:SetBtnYes(true)
    grid:SetBtnSell(true)
    grid:SetBtnContrast(itemCount ~= 0)
    self.CurSelectGrid = grid
end

-- 确认回调
function XUiTheatre4PopupChooseProp:OnYesCallback(index)
    -- 检查藏品是否达到上限
    if self._Control:CheckItemMaxLimit() then
        local title = XUiHelper.GetText("Theatre4PopupCommonTitle")
        local content = XUiHelper.GetText("Theatre4ChoosePropLimitContent")

        self._Control:ShowCommonPopup(title, content, function()
            local grid = self.GridItemList[index]

            if grid then
                grid:OpenReplacePopup()
            end
        end)

        return
    end
    self:ConfirmItem(index)
end

-- 领取藏品
function XUiTheatre4PopupChooseProp:ConfirmItem(index)
    -- 选择藏品
    local operateType = XEnumConst.Theatre4.ItemRewardOperateType.Awards
    self._Control:ConfirmItemRequest(self.Id, operateType, index, 0, function()
        self._Control:CheckNeedOpenNextPopup(self.Name, true)
    end)
end

function XUiTheatre4PopupChooseProp:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBuild, self.OnBtnBuildClick)
    XUiHelper.RegisterClickEvent(self, self.BtnBag, self.OnBtnBagClick)
    XUiHelper.RegisterClickEvent(self, self.BtnCharacter, self.OnBtnCharacterClick)
    self._Control:RegisterClickEvent(self, self.BtnMap, self.OnBtnMapClick)
end

-- 建造弹框
function XUiTheatre4PopupChooseProp:OnBtnBuildClick()
    ---@type UnityEngine.RectTransform
    local rectTransform = self.BtnBuild:GetComponent("RectTransform")
    XLuaUiManager.Open("UiTheatre4BubbleBuild", rectTransform.position, rectTransform.sizeDelta, false)
end

-- 背包
function XUiTheatre4PopupChooseProp:OnBtnBagClick()
    XLuaUiManager.Open("UiTheatre4Bag")
end

-- 角色
function XUiTheatre4PopupChooseProp:OnBtnCharacterClick()
    -- 打开角色面板
    self._Control:OpenCharacterPanel()
end

-- 替换回调
function XUiTheatre4PopupChooseProp:OnReplaceCallback(index, uid)
    if XTool.IsNumberValid(uid) then
        local operateType = XEnumConst.Theatre4.ItemRewardOperateType.Awards
        self._Control:ConfirmItemRequest(self.Id, operateType, index, uid, function()
            XLuaUiManager.Remove("UiTheatre4PopupReplace")
            self._Control:CheckNeedOpenNextPopup(self.Name, true)
        end)
    else
        XLuaUiManager.Close("UiTheatre4PopupReplace")
    end
end

-- 回收回调
function XUiTheatre4PopupChooseProp:OnSellCallback(index)
    -- 回收藏品
    local operateType = XEnumConst.Theatre4.ItemRewardOperateType.Recycling
    self._Control:ConfirmItemRequest(self.Id, operateType, index, 0, function()
        self._Control:CheckNeedOpenNextPopup(self.Name, true)
    end)
end

function XUiTheatre4PopupChooseProp:PlayPropCardAnimation()
    local grids = self.GridItemList

    if not XTool.IsTableEmpty(grids) then
        XLuaUiManager.SetMask(true, self.Name)
        RunAsyn(function()
            for _, grid in pairs(grids) do
                if grid and grid:IsNodeShow() then
                    grid:PlayPropCardAnimation()

                    asynWaitSecond(0.04)
                end
            end
            XLuaUiManager.SetMask(false, self.Name)
        end)
    end
end

function XUiTheatre4PopupChooseProp:SetAllAlpha()
    local grids = self.GridItemList

    if not XTool.IsTableEmpty(grids) then
        for _, grid in pairs(grids) do
            if grid and grid:IsNodeShow() then
                grid:SetAlpha(0)
            end
        end
    end
end

function XUiTheatre4PopupChooseProp:OnBtnMapClick()
    self._Control:ShowViewMapPanel(XEnumConst.Theatre4.ViewMapType.SelectItem)
    XEventManager.DispatchEvent(XEventId.EVENT_THEATRE4_RESTRICT_FOCUS)
end

function XUiTheatre4PopupChooseProp:GetPopupArgs()
    return { self.Id }
end

return XUiTheatre4PopupChooseProp
