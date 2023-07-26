local XUiTRPGTruthRoadSecondMainStage = XClass(nil, "XUiTRPGTruthRoadSecondMainStage")

function XUiTRPGTruthRoadSecondMainStage:Ctor(ui, rootUi, secondMainStageId, clickCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self.RootUi = rootUi
    self.SecondMainStageId = secondMainStageId
    self.ClickCb = clickCb
    CsXUiHelper.RegisterClickEvent(self.BtnStage, function() self:OnClickBtnClick() end)
end

function XUiTRPGTruthRoadSecondMainStage:Refresh()
    self:SetSelect(false)
    local secondMainStageId = self:GetSecondMainStageId()

    if self.RImgFightActiveNor then
        local icon = XTRPGConfigs.GetSecondMainStageIcon(secondMainStageId)
        self.RImgFightActiveNor:SetRawImage(icon)
        self.RImgFightActiveNor.gameObject:SetActiveEx(true)
    end

    if self.TxtStageOrder then
        local name = XTRPGConfigs.GetSecondMainStageName(secondMainStageId)
        self.TxtStageOrder.text = name
    end
end

function XUiTRPGTruthRoadSecondMainStage:OnClickBtnClick()
    if self.ClickCb then
        self.ClickCb(self)
    end
end

function XUiTRPGTruthRoadSecondMainStage:SetSelect(isSelect)
    self.ImageSelected.gameObject:SetActiveEx(isSelect)
end

function XUiTRPGTruthRoadSecondMainStage:GetSecondMainStageId()
    return self.SecondMainStageId
end

return XUiTRPGTruthRoadSecondMainStage