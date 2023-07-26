--肉鸽玩法信物格子
local XUiGridToken = XClass(nil, "XUiGridToken")

function XUiGridToken:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self.RootUi = rootUi
    self:AddListener()
end

function XUiGridToken:Refresh(keepsakeId)
    local icon = XTheatreConfigs.GetTheatreKeepsakeIcon(keepsakeId)
    self.RImgIcon:SetRawImage(icon)

    self.ImgQuality.gameObject:SetActiveEx(false)
    self.PanelSite.gameObject:SetActiveEx(false)
    self.TxtCount.text = ""
end

function XUiGridToken:AddListener()
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnBtnClickClick)
end

--打开物品详情
function XUiGridToken:OnBtnClickClick()
    
end

return XUiGridToken