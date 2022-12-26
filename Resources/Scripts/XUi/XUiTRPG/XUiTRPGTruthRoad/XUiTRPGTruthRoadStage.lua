local XUiTRPGTruthRoadStage = XClass(nil, "XUiTRPGTruthRoadStage")

function XUiTRPGTruthRoadStage:Ctor(ui, rootUi, truthRoadGroupId, truthRoadId, clickCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self.RootUi = rootUi
    self.TruthRoadGroupId = truthRoadGroupId
    self.TruthRoadId = truthRoadId
    self.ClickCb = clickCb
    CsXUiHelper.RegisterClickEvent(self.BtnStage, function() self:OnClickBtnClick() end)
end

function XUiTRPGTruthRoadStage:Refresh()
    self:SetSelect(false)

    if self.RImgFightActiveNor then
        local icon = XTRPGConfigs.GetTruthRoadIcon(self.TruthRoadId)
        self.RImgFightActiveNor:SetRawImage(icon)
        self.RImgFightActiveNor.gameObject:SetActiveEx(true)
    end

    if self.TxtStageOrder then
        local name = XTRPGConfigs.GetTruthRoadName(self.TruthRoadId)
        self.TxtStageOrder.text = name
    end
end

function XUiTRPGTruthRoadStage:OnClickBtnClick()
    if self.ClickCb then
        self.ClickCb(self)
    end
end

function XUiTRPGTruthRoadStage:SetSelect(isSelect)
    self.ImageSelected.gameObject:SetActiveEx(isSelect)
end

function XUiTRPGTruthRoadStage:GetTruthRoadId()
    return self.TruthRoadId
end

return XUiTRPGTruthRoadStage