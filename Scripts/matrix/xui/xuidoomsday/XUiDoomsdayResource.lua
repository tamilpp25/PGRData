

local XUiDoomsdayResource = XLuaUiManager.Register(XLuaUi, "UiDoomsdayResource")

function XUiDoomsdayResource:OnAwake()
    self:InitCb()
end 

function XUiDoomsdayResource:InitCb()
    self.BtnTanchuangClose.CallBack = function() self:Close() end
end 

function XUiDoomsdayResource:OnStart(stageId)
    self.StageId = stageId
    
    self:InitView()
end 

function XUiDoomsdayResource:InitView()
    
    local stageData = XDataCenter.DoomsdayManager.GetStageData(self.StageId)
    local unit = XUiHelper.GetText("DoomsdayUnitDaily")
    self:RefreshTemplateGrids(
            self.GridResource,
            XDoomsdayConfigs.GetResourceIds(),
            self.ResourceContent,
            nil,
            "ResourceGrids",
            function(grid, resourceId)
                local resource = stageData:GetResource(resourceId)
                grid.TxtMessage.text = stageData:GetResourceConsumeDesc(resourceId)
                grid.TxtConsume.text = XDoomsdayConfigs.GetNumberText(resource:GetProperty("_Consume"), false, false, true, unit)
                grid.TxtStock.text = resource:GetProperty("_Count")
                grid.RImgTool1:SetRawImage(XDoomsdayConfigs.ResourceConfig:GetProperty(resourceId, "Icon"))
            end
    )
end 