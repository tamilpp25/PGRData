---@class XUiRogueSimProduce : XLuaUi
---@field private _Control XRogueSimControl
---@field private AssetPanel XUiPanelRogueSimAsset
---@field private BtnPopulation XUiComponent.XUiButton
---@field private ProduceGroup XUiButtonGroup
local XUiRogueSimProduce = XLuaUiManager.Register(XLuaUi, "UiRogueSimProduce")

function XUiRogueSimProduce:OnAwake()
    self:RegisterUiEvents()
    self.GridProduce.gameObject:SetActiveEx(false)
    ---@type XUiGridRogueSimProduce[]
    self.GridProduceList = {}
    -- 当前选中的货物id
    self.CurSelectCommodityId = 0
end

function XUiRogueSimProduce:OnStart()
    -- 显示资源
    self.AssetPanel = require("XUi/XUiRogueSim/Common/XUiPanelRogueSimAsset").New(
        self.PanelAsset,
        self,
        XEnumConst.RogueSim.ResourceId.Gold,
        XEnumConst.RogueSim.CommodityIds)
    self.AssetPanel:Open()
    self:InitView()
end

function XUiRogueSimProduce:OnEnable()
    self.CurSelectCommodityId = self._Control.ResourceSubControl:GetProductCommodityId()
    self:RefreshPopulation()
    self:RefreshProduce()
    self:RefreshBtnYes()
end

function XUiRogueSimProduce:InitView()
    -- 内容
    self.TxtTips.text = self._Control:GetClientConfig("ProduceContent")
end

-- 刷新人口
function XUiRogueSimProduce:RefreshPopulation()
    local id = XEnumConst.RogueSim.ResourceId.Population
    -- 图片
    self.BtnPopulation:SetSprite(self._Control.ResourceSubControl:GetResourceIcon(id))
    -- 数量
    local count = self._Control.ResourceSubControl:GetResourceOwnCount(id)
    self.BtnPopulation:SetNameByGroup(1, string.format("+%d", count))
    -- 名称
    self.BtnPopulation:SetNameByGroup(0, self._Control.ResourceSubControl:GetResourceName(id))
end

-- 刷新货物
function XUiRogueSimProduce:RefreshProduce()
    local btnTags = {}
    local curIndex = -1
    local produceIds = XEnumConst.RogueSim.CommodityIds
    for index, id in ipairs(produceIds) do
        local grid = self.GridProduceList[index]
        if not grid then
            local go = XUiHelper.Instantiate(self.GridProduce, self.ProduceList)
            grid = require("XUi/XUiRogueSim/Produce/XUiGridRogueSimProduce").New(go, self)
            self.GridProduceList[index] = grid
        end
        grid:Open()
        grid:Refresh(id)
        btnTags[index] = grid:GetBtnToggle()
        if XTool.IsNumberValid(self.CurSelectCommodityId) and self.CurSelectCommodityId == id then
            curIndex = index
        end
    end
    for i = #produceIds + 1, #self.GridProduceList do
        self.GridProduceList[i]:Close()
    end
    self.ProduceGroup:Init(btnTags, function(index) self:OnBtnToggleClick(index) end)
    if curIndex > 0 then
        self.ProduceGroup:SelectIndex(curIndex)
    end
end

function XUiRogueSimProduce:OnBtnToggleClick(index)
    if self.CurSelectIndex == index then
        return
    end
    self.CurSelectIndex = index
    self.CurSelectCommodityId = XEnumConst.RogueSim.CommodityIds[index]
    self:RefreshBtnYes()
end

function XUiRogueSimProduce:RefreshBtnYes()
    local isExceedLimit = false
    if XTool.IsNumberValid(self.CurSelectCommodityId) then
        isExceedLimit = self._Control.ResourceSubControl:CheckCommodityIsExceedLimit(self.CurSelectCommodityId)
    end
    self.BtnYes:SetDisable(not XTool.IsNumberValid(self.CurSelectCommodityId) or isExceedLimit)
end

function XUiRogueSimProduce:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick)
    XUiHelper.RegisterClickEvent(self, self.BtnYes, self.OnBtnYesClick)
    XUiHelper.RegisterClickEvent(self, self.BtnPopulation, self.OnBtnPopulationClick)
end

function XUiRogueSimProduce:OnBtnCloseClick()
    self:Close()
end

function XUiRogueSimProduce:OnBtnPopulationClick()
    local id = XEnumConst.RogueSim.ResourceId.Population
    XLuaUiManager.Open("UiRogueSimComponent", XEnumConst.RogueSim.BubbleType.Population, self.BtnPopulation.transform, id)
end

function XUiRogueSimProduce:OnBtnYesClick()
    if not XTool.IsNumberValid(self.CurSelectCommodityId) then
        XUiManager.TipMsg(self._Control:GetClientConfig("ProduceBtnYesTips", 1))
        return
    end
    -- 选择id和当前id相同
    local commodityId = self._Control.ResourceSubControl:GetProductCommodityId()
    if self.CurSelectCommodityId == commodityId then
        self:Close()
        return
    end
    -- 超出储存上限
    if self._Control.ResourceSubControl:CheckCommodityIsExceedLimit(self.CurSelectCommodityId) then
        local tips = self._Control:GetClientConfig("ProduceBtnYesTips", 3)
        local name = self._Control.ResourceSubControl:GetCommodityName(self.CurSelectCommodityId)
        XUiManager.TipMsg(string.format(tips, name))
        return
    end
    -- 预估产量超出储存上限
    if self._Control.ResourceSubControl:CheckProduceRateIsExceedLimit(self.CurSelectCommodityId) then
        local title = self._Control:GetClientConfig("ProduceDialogTitle", 1)
        local content = self._Control:GetClientConfig("ProduceBtnYesTips", 2)
        self._Control:ShowCommonTip(title, content, nil, function()
            self:ProduceRequest()
        end)
        return
    end
    self:ProduceRequest()
end

function XUiRogueSimProduce:ProduceRequest()
    self._Control:RogueSimCommoditySetupProduceRequest(self.CurSelectCommodityId, function()
        XUiManager.PopupLeftTip(self._Control:GetClientConfig("ProduceChangeContent"))
        self:Close()
    end)
end

return XUiRogueSimProduce
