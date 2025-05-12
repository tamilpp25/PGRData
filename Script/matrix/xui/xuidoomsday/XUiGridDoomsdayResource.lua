local XUiGridDoomsdayResource = XClass(nil, "XUiGridDoomsdayResource")

local TXT_COLOR = {
    Red = XUiHelper.Hexcolor2Color("EF1717") ,
}

function XUiGridDoomsdayResource:Ctor(stageId)
    self.StageId = stageId
    self.StageData = XDataCenter.DoomsdayManager.GetStageData(stageId)
end

function XUiGridDoomsdayResource:Init()
    self.RImgTool1 = self.RImgTool1 or XUiHelper.TryGetComponent(self.Transform, "RImgTool1", "RawImage")
    self.TxtTool1 = self.TxtTool1 or XUiHelper.TryGetComponent(self.Transform, "TxtTool1", "Text")
    self.TxtConsume = self.TxtConsume or XUiHelper.TryGetComponent(self.Transform, "PanelConsume/TxtConsume", "Text")
    self.PanelConsume = self.TxtConsume and self.TxtConsume.transform.parent or nil
    self.TxtTool1Color = self.TxtTool1.color
    XUiHelper.RegisterClickEvent(self, self.Transform, self.OnClick)
end

function XUiGridDoomsdayResource:Refresh(resourceId)
    local resource = XDataCenter.DoomsdayManager.GetStageData(self.StageId):GetResource(resourceId)
    self.RImgTool1:SetRawImage(XDoomsdayConfigs.ResourceConfig:GetProperty(resourceId, "Icon"))
    self.Parent:BindViewModelPropertiesToObj(
        resource,
        function(count, consume)
            self.TxtTool1.text = count
            local exhausted = count == 0 or count + consume <= 0
            self.TxtTool1.color = exhausted and TXT_COLOR.Red or self.TxtTool1Color

            if self.TxtConsume then
                self.TxtConsume.text = XDoomsdayConfigs.GetNumberText(consume, false, false, false, XUiHelper.GetText("DoomsdayUnitDaily"))
            end

            if self.PanelConsume then
                self.PanelConsume.gameObject:SetActiveEx(consume ~= 0)
            end
        end,
        "_Count",
        "_Consume"
    )
end

function XUiGridDoomsdayResource:OnClick()
    XLuaUiManager.Open("UiDoomsdayResource", self.StageId)
end

return XUiGridDoomsdayResource
