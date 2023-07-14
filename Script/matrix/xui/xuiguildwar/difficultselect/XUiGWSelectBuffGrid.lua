
local XUiGWSelectBuffGrid = XClass(nil, "XUiGWSelectBuffGrid")

function XUiGWSelectBuffGrid:Ctor(prefab)
    XTool.InitUiObjectByUi(self, prefab)
    XUiHelper.RegisterClickEvent(self, self.RImgIcon, function() self:OnClick() end)
end

function XUiGWSelectBuffGrid:Refresh(fightEventId)
    if not fightEventId or (fightEventId == 0) then return nil end
    local cfg = XFubenConfigs.GetStageFightEventDetailsByStageFightEventId(fightEventId)
    if not cfg then return nil end
    self.BuffList = {cfg}
    self.RImgIcon:SetRawImage(cfg.Icon)
end

function XUiGWSelectBuffGrid:OnClick()
    XLuaUiManager.Open("UiCommonStageEvent", self.BuffList)
end

function XUiGWSelectBuffGrid:Hide()
    self.GameObject:SetActiveEx(false)
end

function XUiGWSelectBuffGrid:Show()
    self.GameObject:SetActiveEx(true)
end

return XUiGWSelectBuffGrid