local XUiPanelRefitQuick = XClass(nil, "XUiPanelRefitQuick")

function XUiPanelRefitQuick:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.GridRoomList = {}
    self.CreateCount = 0

    XTool.InitUiObject(self)
    self:AddListener()
    self:Init()
end

function XUiPanelRefitQuick:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiPanelRefitQuick:RegisterClickEvent函数参数错误：参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiPanelRefitQuick:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiPanelRefitQuick:AddListener()
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnRefit, self.OnBtnRefitClick)
    self:RegisterClickEvent(self.BtnSingleCreate, self.OnBtnCreateClick)
    self:RegisterClickEvent(self.BtnCreate, self.OnBtnCreateClick)
    self:RegisterClickEvent(self.BtnBuy, self.OnBtnBuyClick)
    self:RegisterClickEvent(self.BtnDraw, self.OnBtnDrawClick)
    self:RegisterClickEvent(self.BtnPreview, self.OnBtnPreviewClick)
    self:RegisterClickEvent(self.BtnPreviewSingle, self.OnBtnPreviewClick)
end

function XUiPanelRefitQuick:Init()
    self.GameObject:SetActiveEx(false)
end

function XUiPanelRefitQuick:Close()
    self.GameObject:SetActiveEx(false)
end

function XUiPanelRefitQuick:Refresh(furnitur)
    self:Open(furnitur)
end

function XUiPanelRefitQuick:UpdateTxtDrawingCount(TargetId)
    if not TargetId then
        return
    elseif TargetId == self.Config.PicId then
        self:Refresh(self.Furnitur)
    end
end

function XUiPanelRefitQuick:OnGetFurniture()
    self:Refresh(self.Furnitur)
end

function XUiPanelRefitQuick:Open(furnitur)
    self.Furnitur = furnitur
    self.Config = XFurnitureConfigs.GetFurnitureTemplateById(furnitur.ConfigId)
    self.PanelRefit.gameObject:SetActiveEx(self.Config.PicId > 0)
    self.PanelRefitSingle.gameObject:SetActiveEx(self.Config.PicId <= 0)

    self:SetTitle()
    if self.Config.PicId > 0 then
        self:SetRefit()
    else
        self:SetRefitSingle()
    end

    self.GameObject:SetActiveEx(true)
end

function XUiPanelRefitQuick:SetTitle()
    self.TxtTile.text = self.Config.Name
end

function XUiPanelRefitQuick:SetRefit()
    local isBindDorm = self.Furnitur.ConnectDormId > 0
    -- 基础类型
    local typeCfg = XFurnitureConfigs.GetFurnitureTypeById(self.Config.TypeId)
    self.RImgFurnitureType:SetRawImage(typeCfg.TypeIcon)
    self.TxtFurnitureTypeName.text = typeCfg.CategoryName
    self.TxtFurnitureTypeCount.gameObject:SetActiveEx(isBindDorm)

    -- 图纸
    local draftId = self.Config.PicId
    local icon = XDataCenter.ItemManager.GetItemIcon(draftId)
    local name = XDataCenter.ItemManager.GetItemName(draftId)
    self.RImgDrawing:SetRawImage(icon)
    self.TxtDrawingName.text = name
    self.TxtDrawingCount.gameObject:SetActiveEx(isBindDorm)

    -- 目标
    self.RImgPreview:SetRawImage(self.Config.Icon)
    self.TxtPreviewName.text = self.Config.Name
    self.TxtPreviewCount.gameObject:SetActiveEx(isBindDorm)

    -- 处理绑定了宿舍
    if isBindDorm then
        -- 基础类型
        local baseAllCount = self.Furnitur.Count
        local typeId = self.Config.TypeId
        local baseCurList = XDataCenter.FurnitureManager.GetFurnitureCategoryIds({ typeId }, nil, true, nil, nil, true)
        local baseCurCount = #baseCurList
        self:SetCountText(self.TxtFurnitureTypeCount, baseCurCount, baseAllCount)
        self.CreateCount = baseAllCount > baseCurCount and baseAllCount - baseCurCount or 0

        -- 图纸
        local draftAllcount = self.Furnitur.Count * self.Config.PicNum
        local draftCurCount = XDataCenter.ItemManager.GetCount(draftId)
        self:SetCountText(self.TxtDrawingCount, draftCurCount, draftAllcount)

        -- 目标
        self:SetCountText(self.TxtPreviewCount, self.Furnitur.TargetCount, self.Furnitur.Count)
    end
end

function XUiPanelRefitQuick:SetRefitSingle()
    local isBindDorm = self.Furnitur.ConnectDormId > 0
    self.RImgPreviewSingle:SetRawImage(self.Config.Icon)
    self.TxtPreviewSingleName.text = self.Config.Name
    self.TxtPreviewSingleCount.gameObject:SetActiveEx(isBindDorm)

    if isBindDorm then
        self:SetCountText(self.TxtPreviewSingleCount, self.Furnitur.TargetCount, self.Furnitur.Count)
        self.CreateCount = self.Furnitur.Count > self.Furnitur.TargetCount and self.Furnitur.Count - self.Furnitur.TargetCount or 0
    end
end

function XUiPanelRefitQuick:SetCountText(text, curCount, allCount)
    if allCount > curCount then
        text.text = CS.XTextManager.GetText("DormRefitCountNotEnough", curCount, allCount)
    else
        text.text = CS.XTextManager.GetText("DormRefitCountEnough", curCount, allCount)
    end
end

--------------------------------- 点击事件相关(Start) ---------------------------------
function XUiPanelRefitQuick:OnBtnCloseClick()
    self:Close()
end

-- 快捷改造
function XUiPanelRefitQuick:OnBtnRefitClick()
    if XDataCenter.FurnitureManager.CheckFurnitureSlopLimit() then
        XLuaUiManager.Open("UiFurnitureCreateDetail")
        return
    end
    local gainType = XFurnitureConfigs.GainType.Refit
    local draftId = self.Config.PicId
    local furnitureTypeId = self.Config.TypeId
    self:Close()
    XLuaUiManager.Open("UiFurnitureBuild", gainType, draftId, furnitureTypeId)
end

-- 快捷建造
function XUiPanelRefitQuick:OnBtnCreateClick()
    if XDataCenter.FurnitureManager.IsFurnitureCreatePosFull() then
        XUiManager.TipText("FurnitureBuildingListFull")
        return
    end
    if XDataCenter.FurnitureManager.CheckFurnitureSlopLimit() then
        XLuaUiManager.Open("UiFurnitureCreateDetail")
        return
    end

    local minConsume, _ = XFurnitureConfigs.GetFurnitureCreateMinAndMax()
    local currentOwn = XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.FurnitureCoin)
    local costCoin = self.CreateCount * minConsume
    if costCoin > currentOwn then
        XUiManager.TipMsg(CS.XTextManager.GetText("FurnitureZeroCoin"))
        return
    end

    XLuaUiManager.Open("UiFurnitureCreate", self.Config.TypeId, self.CreateCount, nil, function()
        XLuaUiManager.PopThenOpen("UiFurnitureBuild")
    end)
end

-- 快捷购买
function XUiPanelRefitQuick:OnBtnBuyClick()
    local configId = self.Config.PicId
    local data = XDataCenter.ItemManager.GetAllBuyAssetTemplate()

    -- 判断配置表是否存在该图纸快捷购买数据
    if not data[configId] then
        XUiManager.TipMsg(CS.XTextManager.GetText("ShopNoGoodsDesc"), XUiManager.UiTipType.Tip)
    else
        XLuaUiManager.Open("UiBuyAsset", configId)
    end
end

-- 点击图纸详情
function XUiPanelRefitQuick:OnBtnDrawClick()
    local data = XDataCenter.ItemManager.GetItem(self.Config.PicId)
    local hideSkipBtn = true
    XLuaUiManager.Open("UiTip", data, hideSkipBtn)
end

-- 改造目标点击详情
function XUiPanelRefitQuick:OnBtnPreviewClick()
    XLuaUiManager.Open("UiDormFieldGuideDes", self.Config)
end
--------------------------------- 点击事件相关(End) ---------------------------------
return XUiPanelRefitQuick