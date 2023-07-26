local CONDITION_COLOR = {
    [true] = CS.UnityEngine.Color.black,
    [false] = CS.UnityEngine.Color.red,
}

local XUiGridCostItem = XClass(nil, "XUiGridCostItem")

function XUiGridCostItem:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi

    self:InitAutoScript()
end

function XUiGridCostItem:Refresh(itemId, needCount)
    self.ItemId = itemId
    self.NeedCount = needCount

    self:InitItemInfo()
    self:UpdateHaveCount()

    XDataCenter.ItemManager.AddCountUpdateListener(itemId, function()
        self:UpdateHaveCount()
    end, self.TxtHaveCount)
end

function XUiGridCostItem:InitItemInfo()
    local goodsShowParams = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(self.ItemId)

    self.RImgIcon:SetRawImage(goodsShowParams.Icon)
    XUiHelper.SetQualityIcon(self.RootUi, self.ImgQuality, goodsShowParams.Quality)
    self.TxtNeedCount.text = "/" .. self.NeedCount
end

function XUiGridCostItem:UpdateHaveCount()
    local haveCount = XDataCenter.ItemManager.GetCount(self.ItemId)

    self.TxtHaveCount.text = haveCount
    self.TxtHaveCount.color = CONDITION_COLOR[haveCount >= self.NeedCount]
end

function XUiGridCostItem:InitAutoScript()
    XTool.InitUiObject(self)
    self:AutoAddListener()
end

function XUiGridCostItem:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiGridCostItem:RegisterClickEvent函数参数错误：参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiGridCostItem:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiGridCostItem:AutoAddListener()
    self:RegisterClickEvent(self.BtnClick, self.OnBtnClickClick)
end

function XUiGridCostItem:OnBtnClickClick()
    XLuaUiManager.Open("UiTip", XDataCenter.ItemManager.GetItem(self.ItemId))
end

return XUiGridCostItem