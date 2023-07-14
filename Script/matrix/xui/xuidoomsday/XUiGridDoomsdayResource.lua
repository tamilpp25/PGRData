local XUiGridDoomsdayResource = XClass(nil, "XUiGridDoomsdayResource")

function XUiGridDoomsdayResource:Ctor(stageId)
    self.StageId = stageId
end

function XUiGridDoomsdayResource:Init()
    self.RImgTool1 = self.RImgTool1 or XUiHelper.TryGetComponent(self.Transform, "RImgTool1", "RawImage")
    self.TxtTool1 = self.TxtTool1 or XUiHelper.TryGetComponent(self.Transform, "TxtTool1", "Text")
end

function XUiGridDoomsdayResource:Refresh(resourceId)
    local resource = XDataCenter.DoomsdayManager.GetStageData(self.StageId):GetResource(resourceId)
    self.RImgTool1:SetRawImage(XDoomsdayConfigs.ResourceConfig:GetProperty(resourceId, "Icon"))
    self.Parent:BindViewModelPropertyToObj(
        resource,
        function(count)
            self.TxtTool1.text = count
        end,
        "_Count"
    )
end

return XUiGridDoomsdayResource
