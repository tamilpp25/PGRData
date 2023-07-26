local XUiGridDoomsdayBuildingSelect = require("XUi/XUiDoomsday/XUiGridDoomsdayBuildingSelect")

local XUiDoomsdayBuild = XLuaUiManager.Register(XLuaUi, "UiDoomsdayBuild")

function XUiDoomsdayBuild:OnAwake()
    self:AutoAddListener()
end

function XUiDoomsdayBuild:OnStart(stageId, defaultSelectBuildingCfgId, closeCb)
    self.StageId = stageId
    self.CloseCb = closeCb
    self.DefaultSelectBuildingCfgId = defaultSelectBuildingCfgId

    self.BuildingCfgIds = XDoomsdayConfigs.StageConfig:GetProperty(stageId, "BuildingIds")
end

function XUiDoomsdayBuild:OnEnable()
    self:UpdateView()
end

function XUiDoomsdayBuild:AutoAddListener()
    self.BtnTanchuangClose.CallBack = handler(self, self.Close)
    self.BtnConfirm.CallBack = handler(self, self.OnClickBtnConfirm)
end

function XUiDoomsdayBuild:UpdateView()
    local stageData = XDataCenter.DoomsdayManager.GetStageData(self.StageId)

    self:RefreshTemplateGrids(
        self.GridEnvironment,
        self.BuildingCfgIds,
        self.EnvirGridsContent,
        function()
            return XUiGridDoomsdayBuildingSelect.New(self.StageId, handler(self, self.OnClickBuilding))
        end
    )

    local condition
    if XTool.IsNumberValid(self.DefaultSelectBuildingCfgId) then
        condition = function(index, cfgId) 
            return self.DefaultSelectBuildingCfgId == cfgId
        end
    else
        condition = function(index, cfgId) 
            return not self:GetGrid(index).ReachLimit
        end
    end

    for index, buildingCfgId in ipairs(self.BuildingCfgIds) do
        if condition(index, buildingCfgId) then
            self:OnClickBuilding(buildingCfgId)
            break
        end
    end
end

function XUiDoomsdayBuild:OnClickBuilding(buildingCfgId)
    self.SelectBuildingCfgId = buildingCfgId

    for index, inId in pairs(self.BuildingCfgIds) do
        self:GetGrid(index):SetSelect(inId == buildingCfgId)
    end
end

function XUiDoomsdayBuild:OnClickBtnConfirm()
    local stageData = XDataCenter.DoomsdayManager.GetStageData(self.StageId)
    local buildingCfgId = self.SelectBuildingCfgId

    local costResourceList = XDoomsdayConfigs.GetBuildingConstructResourceInfos(buildingCfgId)
    for index, resourceInfo in pairs(costResourceList) do
        if not stageData:CheckResourceCount(resourceInfo.Id, resourceInfo.Count) then
            XUiManager.TipText("DoomsdayBuildingSelectLackResource")
            return
        end
    end

    self:Close()
    if self.CloseCb then
        self.CloseCb(buildingCfgId)
    end
end

return XUiDoomsdayBuild
