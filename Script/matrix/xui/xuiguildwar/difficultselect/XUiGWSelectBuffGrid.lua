
local XUiGWSelectBuffGrid = XClass(nil, "XUiGWSelectBuffGrid")

function XUiGWSelectBuffGrid:Ctor(prefab)
    XTool.InitUiObjectByUi(self, prefab)
    XUiHelper.RegisterClickEvent(self, self.RImgIcon, function() self:OnClick() end)
    if self.BtnBuff then
        XUiHelper.RegisterClickEvent(self, self.BtnBuff, function() self:OnClick() end)    
    end
end

function XUiGWSelectBuffGrid:Refresh(fightEventId, allFightEventId)
    if not fightEventId or (fightEventId == 0) then return nil end
    local cfg = XFubenConfigs.GetStageFightEventDetailsByStageFightEventId(fightEventId)
    if not cfg then return nil end
    -- 虽然会导致每个grid都重复创建list, 但相比代码在grid外要方便
    local cfgList = {}
    for i = 1, #allFightEventId do
        local id = allFightEventId[i]
        local c = XFubenConfigs.GetStageFightEventDetailsByStageFightEventId(id)
        if c then
            cfgList[#cfgList + 1] = c
        end
    end
    self.BuffList = cfgList
    --
    self.RImgIcon:SetRawImage(cfg.Icon)
    if self.TxtLv then
        self.TxtLv.gameObject:SetActiveEx(false)
    end
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