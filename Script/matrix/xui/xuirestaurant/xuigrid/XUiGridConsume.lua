
local XUiGridConsume = XClass(nil, "XUiGridConsume")

local CsColor = CS.UnityEngine.Color

local ColorEnum = {
    Red = XUiHelper.Hexcolor2Color("FF9090"),
    White = CsColor.white
}

function XUiGridConsume:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
end

function XUiGridConsume:Refresh(areaType, id, count)
    self.GameObject:SetActiveEx(true)
    self.TxtCount.text = count
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    local product = viewModel:GetProduct(areaType, id)
    local enough = product:IsSufficient(count)
    self.RImgIcon:SetRawImage(product:GetProductIcon())
    self.TxtCount.color = enough and ColorEnum.White or ColorEnum.Red
end

return XUiGridConsume