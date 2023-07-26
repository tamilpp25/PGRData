-- 通用道具显示按钮控件
local XUiCommonAsset = XClass(nil, "XUiCommonAsset")

XUiCommonAsset.ShowType = {
        BagItem = 1, -- 填入Item表的道具
        BagPoint = 2, -- 填入Item表的数值道具(如体力),显示格式为 "当前值/最大值"
        RecoverPoint = 3, -- 不填入Item表的数值道具(如体力),显示格式为 "当前值/最大值"
        UniqueItem = 4, -- 不填入Item表的道具，各个功能使用自己专有的道具时可使用
    }

local TypeName = {
        [1] = "BagItem",
        [2] = "BagPoint",
        [3] = "RecoverPoint",
        [4] = "UniqueItem"
    }

function XUiCommonAsset:Ctor(ui, assetData)
    XTool.InitUiObjectByUi(self, ui)
    self:SetData(assetData)
end

function XUiCommonAsset:SetData(assetData)
    if not assetData then
        self.GameObject:SetActiveEx(false)
        return
    end
    self.AssetData = assetData
    self.GameObject:SetActiveEx(true)
    local typeName = TypeName[self.AssetData.ShowType]
    if typeName and self["Set" .. typeName .. "Data"] then
        self["Set" .. typeName .. "Data"](self)
    end
end

function XUiCommonAsset:SetBagItemData()
    local item = XDataCenter.ItemManager.GetItem(self.AssetData.ItemId)
    self.ImgIcon:SetRawImage(item.Template.Icon)
    self:RefreshTextByItemCount(XDataCenter.ItemManager.GetCount(self.AssetData.ItemId))
    XDataCenter.ItemManager.AddCountUpdateListener(
        self.AssetData.ItemId,
        function()
            self:RefreshTextByItemCount(XDataCenter.ItemManager.GetCount(self.AssetData.ItemId))
        end,
        self
        )
    self.BtnDetail.gameObject:SetActiveEx(true)
    self.BtnDetail.CallBack = function() self:OnBtnDetailClickByBagItem() end
end

function XUiCommonAsset:SetRecoverPointData()
    if self.AssetData.Icon then
        self.ImgIcon:SetRawImage(self.AssetData.Icon)
        self.ImgIcon.gameObject:SetActiveEx(true)
    else
        self.ImgIcon.gameObject:SetActiveEx(false)
    end
    self:RefreshTextByPoint(self.AssetData.GetCountFunc(), self.AssetData.GetMaxCountFunc())
    XEventManager.BindEvent(self.GameObject, self.AssetData.ChangeEventId,
        function()
            self:RefreshTextByPoint(self.AssetData.GetCountFunc(), self.AssetData.GetMaxCountFunc())
        end
    ) 
    self.BtnDetail.gameObject:SetActiveEx(self.AssetData.OnClick ~= nil)
    self.BtnDetail.CallBack = function() self:OnBtnDetailClickByUniqueItem() end
end

function XUiCommonAsset:RefreshTextByItemCount(itemCount)
    self.TxtCount.text = itemCount
end

function XUiCommonAsset:RefreshTextByPoint(itemCount, maxCount)
    self.TxtCount.text = itemCount .. "/" .. maxCount
end

function XUiCommonAsset:OnBtnDetailClickByBagItem()
    XLuaUiManager.Open("UiTip", self.AssetData.ItemId, true, nil)
end

function XUiCommonAsset:OnBtnDetailClickByUniqueItem()
    if self.AssetData.OnClick then
        self.AssetData.OnClick()
    else
        return
    end
end

return XUiCommonAsset