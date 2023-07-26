local XUiPlanetGridBuff = require("XUi/XUiPlanet/Explore/View/Stage/XUiPlanetGridBuff")

---@class XUiPlanetDetailItemPanel
local XUiPlanetDetailItemPanel = XClass(nil, "XUiPlanetDetailItemPanel")

function XUiPlanetDetailItemPanel:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.PanelBtn.gameObject:SetActiveEx(false)
end

---@param item XPlanetItem
function XUiPlanetDetailItemPanel:Update(item)
    self.RImgIcon:SetRawImage(item:GetIcon())
    self.ImgQuality.gameObject:SetActiveEx(false)
    --self.BtnClick
    self.TxtName.text = item:GetName()
    self.TxtTitle.text =item:GetDesc()
    local buffList = item:GetBuff()
    for _, buff in pairs(buffList) do
        local go = XUiHelper.Instantiate(self.ImgBuffBg01.gameObject, self.ImgBuffBg01.transform.parent)
        go.gameObject:SetActiveEx(true)
        local buffGrid = XUiPlanetGridBuff.New(go)
        buffGrid:Update(buff)
    end
    self.ImgBuffBg01.gameObject:SetActiveEx(false)
end

return XUiPlanetDetailItemPanel
