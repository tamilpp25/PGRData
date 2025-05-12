local XUiGridTheatre4Genius = require("XUi/XUiTheatre4/Common/XUiGridTheatre4Genius")
---@class XUiGridTheatre4PopupBuildGenius : XUiNode
---@field private _Control XTheatre4Control
local XUiGridTheatre4PopupBuildGenius = XClass(XUiNode, "XUiGridTheatre4PopupBuildGenius")

---@param talentId number 天赋Id
function XUiGridTheatre4PopupBuildGenius:Refresh(talentId)
    self.TalentId = talentId
    self:RefreshTalent()
    self.TxtDetail.text = self._Control:GetColorTalentDesc(talentId)
end

-- 刷新天赋
function XUiGridTheatre4PopupBuildGenius:RefreshTalent()
    if not self.PanelGridGenius then
        ---@type XUiGridTheatre4Genius
        self.PanelGridGenius = XUiGridTheatre4Genius.New(self.GridGenius, self)
    end
    self.PanelGridGenius:Open()
    self.PanelGridGenius:Refresh(self.TalentId)
end

return XUiGridTheatre4PopupBuildGenius
