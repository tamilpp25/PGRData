---@class XUiRogueSimChoose : XLuaUi
---@field private _Control XRogueSimControl
local XUiRogueSimChoose = XLuaUiManager.Register(XLuaUi, "UiRogueSimChoose")

---@deprecated id 奖励唯一Id
function XUiRogueSimChoose:OnStart(id, isProp)
    -- 显示资源
    self.AssetPanel = require("XUi/XUiRogueSim/Common/XUiPanelRogueSimAsset").New(
        self.PanelAsset,
        self,
        XEnumConst.RogueSim.ResourceId.Gold,
        XEnumConst.RogueSim.CommodityIds)
    self.AssetPanel:Open()
    self.Id = id
    self.IsProp = isProp
    self.ImgBuild.gameObject:SetActiveEx(not isProp)
    self.ImgProp.gameObject:SetActiveEx(isProp)
end

function XUiRogueSimChoose:OnEnable()
    if self.IsProp then
        self:OpenPropOption()
    else
        self:OpenBuildOption()
    end
end

function XUiRogueSimChoose:OpenBuildOption()
    if not self.BuildOption then
        ---@type XUiPanelRogueSimBuildOption
        self.BuildOption = require("XUi/XUiRogueSim/Choose/XUiPanelRogueSimBuildOption").New(self.PanelBuildOption, self)
    end
    self.BuildOption:Open()
    self.BuildOption:Refresh(self.Id)
end

function XUiRogueSimChoose:OpenPropOption()
    if not self.PropOption then
        ---@type XUiPanelRogueSimPropOption
        self.PropOption = require("XUi/XUiRogueSim/Choose/XUiPanelRogueSimPropOption").New(self.PanelPropOption, self)
    end
    self.PropOption:Open()
    self.PropOption:Refresh(self.Id)
end

return XUiRogueSimChoose
