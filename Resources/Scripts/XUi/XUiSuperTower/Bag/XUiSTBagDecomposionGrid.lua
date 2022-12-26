--===========================
--超级爬塔背包分解插件控件
--===========================
local XUiSTBagDecomposionGrid = XClass(nil, "XUiSTBagDecomposionGrid")

function XUiSTBagDecomposionGrid:Ctor(uiGameObject, onClickCallBack)
    self:Init(uiGameObject, onClickCallBack)
end

function XUiSTBagDecomposionGrid:Init(uiGameObject, onClickCallBack)
    XTool.InitUiObjectByUi(self, uiGameObject)
    if onClickCallBack then
        self.OnClickCb = onClickCallBack
    end
    XUiHelper.RegisterClickEvent(self, self.BtnClick, function()
            self:OnClick()
        end)
end

function XUiSTBagDecomposionGrid:RefreshData(decomposionData) 
    self.ItemId = decomposionData.ItemId
    self.RImgIcon:SetRawImage(XDataCenter.ItemManager.GetItemIcon(self.ItemId))
    local quality = XDataCenter.ItemManager.GetItemQuality(self.ItemId)
    local qualityPath = XArrangeConfigs.GeQualityPath(quality)
    self.ImgQuality:SetSprite(qualityPath)
    self.TxtCount.text = CS.XTextManager.GetText("STBagDecomposionNum", decomposionData.Count)
end

function XUiSTBagDecomposionGrid:OnClick()
    if not self.ItemId then return end
    XLuaUiManager.Open("UiTip", self.ItemId)
end

return XUiSTBagDecomposionGrid