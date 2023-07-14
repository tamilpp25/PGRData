--据点战词缀控件
local XUiGridEchelonStageBuff = XClass(nil, "XUiGridEchelonStageBuff")

function XUiGridEchelonStageBuff:Ctor(uiRoot, ui)
    self.UiRoot = uiRoot
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)

    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnBtnClick)
end

function XUiGridEchelonStageBuff:Refresh(showFightEventId, echelonId)
    self.ShowFightEventId = showFightEventId
    self.EchelonId = echelonId

    local cfg = XFubenConfigs.GetStageFightEventDetailsByStageFightEventId(showFightEventId)
    self.RImgIcon:SetRawImage(cfg.Icon)
end

function XUiGridEchelonStageBuff:OnBtnClick()
    local echelonId = self.EchelonId
    local showFightEventIds = XDataCenter.BfrtManager.GetEchelonInfoShowFightEventIds(echelonId)
    local buffCfgList = {}
    for _, eventId in ipairs(showFightEventIds) do
        table.insert(buffCfgList, XFubenConfigs.GetStageFightEventDetailsByStageFightEventId(eventId))
    end
    XLuaUiManager.Open("UiCommonStageEvent", buffCfgList)
end

return XUiGridEchelonStageBuff