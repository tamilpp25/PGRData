---@class XUiRogueSimChoose : XLuaUi
---@field private _Control XRogueSimControl
local XUiRogueSimChoose = XLuaUiManager.Register(XLuaUi, "UiRogueSimChoose")

function XUiRogueSimChoose:OnAwake()
    self.PanelBuildOption.gameObject:SetActiveEx(false)
    self.PanelPropOption.gameObject:SetActiveEx(false)
end

---@param id number 奖励唯一Id
function XUiRogueSimChoose:OnStart(id)
    self.Id = id
    self.ImgBuild.gameObject:SetActiveEx(false)
    self.ImgProp.gameObject:SetActiveEx(true)
end

function XUiRogueSimChoose:OnEnable()
    self:OpenPropOption()
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

function XUiRogueSimChoose:OpenPropOption()
    if not self.PropOption then
        ---@type XUiPanelRogueSimPropOption
        self.PropOption = require("XUi/XUiRogueSim/Choose/XUiPanelRogueSimPropOption").New(self.PanelPropOption, self)
    end
    self.PropOption:Open()
    self.PropOption:Refresh(self.Id)
end

return XUiRogueSimChoose
