---@class XUiRogueSimChoose : XLuaUi
---@field private _Control XRogueSimControl
local XUiRogueSimChoose = XLuaUiManager.Register(XLuaUi, "UiRogueSimChoose")

function XUiRogueSimChoose:OnAwake()
    self.PanelBuildOption.gameObject:SetActiveEx(false)
    self.PanelPropOption.gameObject:SetActiveEx(false)
end

---@deprecated id 奖励唯一Id
function XUiRogueSimChoose:OnStart(id, isProp)
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

function XUiRogueSimChoose:OnGetEvents()
    return {
        XEventId.EVENT_GUIDE_START,
    }
end

function XUiRogueSimChoose:OnNotify(event, ...)
    if event == XEventId.EVENT_GUIDE_START then
        self._Control:SaveGuideIsTriggerById(...)
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
