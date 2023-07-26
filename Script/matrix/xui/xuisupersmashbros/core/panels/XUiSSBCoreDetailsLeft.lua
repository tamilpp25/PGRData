--==============
--超限乱斗核心页签面板
--==============
local XUiSSBCoreDetailsLeft = XClass(nil, "XUiSSBCoreDetailsLeft")

function XUiSSBCoreDetailsLeft:Ctor(uiPrefab)
    XTool.InitUiObjectByUi(self, uiPrefab)
    self:InitPanels()
end

function XUiSSBCoreDetailsLeft:InitPanels()
    self:InitStarPanel()
end

function XUiSSBCoreDetailsLeft:InitStarPanel()
    local starScript = require("XUi/XUiSuperSmashBros/Core/Panels/XUiSSBCoreStarPanel")
    self.Stars = starScript.New(self.PanelStars)
end

function XUiSSBCoreDetailsLeft:Refresh(core)
    self.TxtName.text = core:GetName()
    self.RImgIcon:SetRawImage(core:GetIcon())
    self.Stars:ShowStar(core:GetStar())
    self.TxtGainNum.text = core:GetAtkLevel() + core:GetLifeLevel()
    local description = string.gsub(core:GetSkillDescription(), '"', '')
    description = string.gsub(description, '\\n', '\n')
    self.TxtDescription.text = description
end

return XUiSSBCoreDetailsLeft