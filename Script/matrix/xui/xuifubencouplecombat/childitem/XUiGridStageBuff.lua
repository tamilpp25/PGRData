--关卡详情界面的词缀控件
local XUiGridStageBuff = XClass(nil, "XUiGridStageBuff")

function XUiGridStageBuff:Ctor(uiRoot, ui)
    self.UiRoot = uiRoot
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)

    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnBtnClick)
end

function XUiGridStageBuff:Refresh(showFightEventId)
    self.ShowFightEventId = showFightEventId

    local cfg = XFubenConfigs.GetStageFightEventDetailsByStageFightEventId(showFightEventId)
    self.RImgIconBuff:SetRawImage(cfg.Icon)
end

function XUiGridStageBuff:OnBtnClick()
    local showFightEventId = self.ShowFightEventId
    XLuaUiManager.Open("UiCoupleCombatStageSkillTips", showFightEventId)
end

return XUiGridStageBuff