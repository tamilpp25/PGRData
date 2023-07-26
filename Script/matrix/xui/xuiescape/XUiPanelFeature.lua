local XUiGridBuff = XClass(nil, "XUiGridBuff")

function XUiGridBuff:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
    XUiHelper.RegisterClickEvent(self, self.RImgIcon:GetComponent("RawImage"), self.ShowInfo)
end

function XUiGridBuff:Refresh(showFightEventId)
    self.ShowFightEventId = showFightEventId
    local fightEventDetailConfig = XFubenConfigs.GetStageFightEventDetailsByStageFightEventId(showFightEventId)
    self.RImgIcon:SetRawImage(fightEventDetailConfig.Icon)
end

function XUiGridBuff:ShowInfo()
    local fightEventDetailConfig = XFubenConfigs.GetStageFightEventDetailsByStageFightEventId(self.ShowFightEventId)
    XUiManager.UiFubenDialogTip(fightEventDetailConfig.Name, fightEventDetailConfig.Description)
end

--环境图标控件
local XUiPanelFeature = XClass(nil, "XUiPanelFeature")

function XUiPanelFeature:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
    self:InitUi()
end

function XUiPanelFeature:InitUi()
    if self.GridBuff then
        self.GridBuff.gameObject:SetActiveEx(false)
    end
    self.PanelContent = XUiHelper.TryGetComponent(self.Transform, "Viewport/PanelContent")
    if XTool.UObjIsNil(self.PanelContent) then
        self.PanelContent = XUiHelper.TryGetComponent(self.Transform, "Viewport/PanelArchiveMonsterContent")
    end
    self.GridFeatureList = {}
end

function XUiPanelFeature:Refresh(fightEventIds)
    if not self.GridBuff or not self.PanelContent then
        return
    end

    fightEventIds = fightEventIds or {}
    local item
    for i, showFightEventId in ipairs(fightEventIds) do
        item = self.GridFeatureList[i]
        if not item then
            local gridBuff = i == 1 and self.GridBuff or XUiHelper.Instantiate(self.GridBuff, self.PanelContent)
            item = XUiGridBuff.New(gridBuff)
            self.GridFeatureList[i] = item
        end
        item:Refresh(showFightEventId)
        item.GameObject:SetActiveEx(true)
    end

    for i = #fightEventIds + 1, #self.GridFeatureList do
        self.GridFeatureList[i].GameObject:SetActiveEx(false)
    end
end

return XUiPanelFeature