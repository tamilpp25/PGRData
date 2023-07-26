--######################## XUiExchangeTargetItem ########################
local XUiExchangeTargetItem = XClass(nil, "XUiExchangeTargetItem")

function XUiExchangeTargetItem:Ctor(ui)
    XUiHelper.InitUiClass(self, ui)
    -- 重定义 begin
    self.BtnItemDetail = self.ImgBtn
    self.TxtGetCount = self.CostNum
    self.RImgIcon = self.CardImg
    -- 重定义 end
    self.Data = nil
    self:RegisterUiEvents()
end

--[[
    data : {
        TemplateId, -- 物品id
        GetCount,   -- 获得数量
        CustomIcon, -- 自定义图标
    }
]]
function XUiExchangeTargetItem:SetData(data)
    self.Data = data
    self.RImgIcon:SetRawImage(data.CustomIcon or XEntityHelper.GetItemIcon(data.TemplateId))
    self.TxtGetCount.text = data.GetCount
end

--######################## 私有方法 ########################

function XUiExchangeTargetItem:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnItemDetail, self.OnBtnItemDetailClicked)
end

function XUiExchangeTargetItem:OnBtnItemDetailClicked()
    XLuaUiManager.Open("UiTip", self.Data.TemplateId)
end

return XUiExchangeTargetItem