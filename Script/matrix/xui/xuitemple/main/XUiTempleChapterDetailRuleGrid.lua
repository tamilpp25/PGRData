---@class XUiTempleChapterDetailRuleGrid : XUiNode
---@field _Control XTempleControl
local XUiTempleChapterDetailRuleGrid = XClass(XUiNode, "UiTempleChapterDetailRuleGrid")

function XUiTempleChapterDetailRuleGrid:OnStart()
    self:AddBtnListener()
end

---@param data XTempleGameUiDataRule
function XUiTempleChapterDetailRuleGrid:Update(data)
    self.Text.text = data.Name
    if self.GridAffix then
        self.GridAffix:SetSprite(data.Bg)
    end
    self.Text.color = XUiHelper.Hexcolor2Color(data.TextColor)
end

--region Ui - BtnListener
function XUiTempleChapterDetailRuleGrid:AddBtnListener()
    XUiHelper.RegisterClickEvent(self, self.Button, self.OnClick)
end
--endregion

function XUiTempleChapterDetailRuleGrid:OnClick()
    XLuaUiManager.Open("UiTempleAffixDetail")
end

return XUiTempleChapterDetailRuleGrid