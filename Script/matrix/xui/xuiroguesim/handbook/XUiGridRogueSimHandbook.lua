---@class XUiGridRogueSimHandbook : XUiNode
---@field private _Control XRogueSimControl
local XUiGridRogueSimHandbook = XClass(XUiNode, "XUiGridRogueSimHandbook")

function XUiGridRogueSimHandbook:OnStart()

end

function XUiGridRogueSimHandbook:Refresh(illType, config, isUnlock)
    local isProp = illType == XEnumConst.RogueSim.IllustrateType.Props
    self.GridPorp.gameObject:SetActiveEx(isProp)
    local isBuilding = illType == XEnumConst.RogueSim.IllustrateType.Build
    self.GridBulid.gameObject:SetActiveEx(isBuilding)
    local isNew = self.Parent:IsShowRed(config.Id)

    if isProp then
        if not self.PropGrid then
            local XUiGridRogueSimProp = require("XUi/XUiRogueSim/Common/XUiGridRogueSimProp")
            self.PropGrid = XUiGridRogueSimProp.New(self.GridPorp, self)
        end
        self.PropGrid:Open()
        self.PropGrid:Refresh(config.Id)
        self.PropGrid:ShowLock(not isUnlock)
        self.PropGrid:ShowNew(isNew)
    end

    if isBuilding then
        if not self.BuildingGrid then
            local XUiGridRogueSimBuild = require("XUi/XUiRogueSim/Common/XUiGridRogueSimBuild")
            self.BuildingGrid = XUiGridRogueSimBuild.New(self.GridBulid, self)
        end
        self.BuildingGrid:Open()
        self.BuildingGrid:RefreshByBuildId(config.Id)
        self.BuildingGrid:ShowLock(not isUnlock)
        self.BuildingGrid:ShowNew(isNew)
    end
end

function XUiGridRogueSimHandbook:Recycle()
    if self.PropGrid then
        self.PropGrid:Close()
    end
    if self.BuildingGrid then
        self.BuildingGrid:Close()
    end
end

return XUiGridRogueSimHandbook