local XUiBuffGrid = XClass(nil, "XUiBuffGrid")

---黄金矿工通用Buff格子
---@class XUiGoldenMinerBuffGrid
function XUiBuffGrid:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)

    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnBtnClick)

    if self.CountDownText then
        self.CountDownText.gameObject:SetActiveEx(false)
    end
    self.GameObject:SetActiveEx(true)
end

function XUiBuffGrid:Refresh(buffId)
    self:SetActive(true)
    self.BuffId = buffId
    local icon = XGoldenMinerConfigs.GetBuffIcon(buffId)
    if self.RawBuffIcon then
        self.RawBuffIcon:SetRawImage(icon)
    end
end

function XUiBuffGrid:SetActive(active)
    self.GameObject:SetActiveEx(active)
end

function XUiBuffGrid:OnBtnClick()
    XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_SHOP_OPEN_TIP, self.BuffId, nil, self.Transform.position.x)
end

return XUiBuffGrid