--关卡的特性图标控件
local XUiPanelStageFeature = XClass(nil, "XUiPanelStageFeature")

function XUiPanelStageFeature:Ctor(uiRoot, ui)
    self.UiRoot = uiRoot
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
    self:InitUi()
end

function XUiPanelStageFeature:InitUi()
    self.GameObject:SetActiveEx(true)
    self.GridBuff.gameObject:SetActiveEx(false)
    self.GridFeatureList = {}
end

function XUiPanelStageFeature:Refresh(stageId)
    local showFightEventIds = XFubenCoupleCombatConfig.GetStageShowFightEventIds(stageId)
    local fightEventDetailConfig
    local item

    for i, showFightEventId in ipairs(showFightEventIds) do
        fightEventDetailConfig = XFubenConfigs.GetStageFightEventDetailsByStageFightEventId(showFightEventId)
        item = self.GridFeatureList[i]
        if not item then
            item = CS.UnityEngine.Object.Instantiate(self.GridBuff, self.PanelContent)
            self.GridFeatureList[i] = item
            CsXUiHelper.RegisterClickEvent(item:Find("RImgIcon"):GetComponent("RawImage"), function() self:ShowInfo(showFightEventId) end)
        end

        item:Find("RImgIcon"):GetComponent("RawImage"):SetRawImage(fightEventDetailConfig.Icon)
        item.gameObject:SetActiveEx(true)
    end

    for i = #showFightEventIds + 1, #self.GridFeatureList do
        self.GridFeatureList[i].gameObject:SetActiveEx(false)
    end
end

function XUiPanelStageFeature:ShowInfo(showFightEventId)
    local fightEventDetailConfig = XFubenConfigs.GetStageFightEventDetailsByStageFightEventId(showFightEventId)
    XUiManager.UiFubenDialogTip(fightEventDetailConfig.Name, fightEventDetailConfig.Description)
end

return XUiPanelStageFeature