local XUiPurchasePayListItem = XClass(nil, "XUiPurchasePayListItem")
local TextManager = CS.XTextManager
local Application = CS.UnityEngine.Application
local Platform = Application.platform
local RuntimePlatform = CS.UnityEngine.RuntimePlatform

function XUiPurchasePayListItem:Ctor(ui,uiRoot)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot
    XTool.InitUiObject(self)
    self.PanelLabel.gameObject:SetActive(false)
end

function XUiPurchasePayListItem:Init(uiRoot,parent)
    self.UiRoot = uiRoot
    self.Parent = parent
end

-- 更新数据
function XUiPurchasePayListItem:OnRefresh(itemData)
    if not itemData then
        return
    end

    self.ItemData = itemData
    self.CurState = false
    self:SetSelectState(false)
    self:SetData()
end

function XUiPurchasePayListItem:SetData()
     self.TxtCzsl.text = self.ItemData.Name
    self.TxtContent.text = self.ItemData.Desc
    if self.ItemData.Icon then
        local assetpath = XPurchaseConfigs.GetIconPathByIconName(self.ItemData.Icon)
        if assetpath and assetpath.AssetPath then
            self.ImgCz:SetRawImage(assetpath.AssetPath,function()self.ImgCz:SetNativeSize()end)
        end
    end

    self.TxtYuan.text = self.ItemData.Amount

end

function XUiPurchasePayListItem:OnSelectState(state)
    if self.CurState == state then
        return
    end

    self.CurState = state
    self:SetSelectState(state)
end

function XUiPurchasePayListItem:SetSelectState(state)
    self.ImgSelectCz.gameObject:SetActive(state)
end

function XUiPurchasePayListItem:OnClick()
    self.CurState = not self.CurState
    self:SetSelectState(self.CurState)
end

return XUiPurchasePayListItem