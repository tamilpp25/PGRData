---@class XUiRogueSimBuildBag : XLuaUi
---@field private _Control XRogueSimControl
local XUiRogueSimBuildBag = XLuaUiManager.Register(XLuaUi, "UiRogueSimBuildBag")

function XUiRogueSimBuildBag:OnAwake()
    self:RegisterUiEvents()
    self.GridBuild.gameObject:SetActiveEx(false)
    ---@type XUiGridRogueSimBuild[]
    self.GridBuildList = {}
end

function XUiRogueSimBuildBag:OnEnable()
    self:RefreshGridBuild()
    -- 默认显示最上面
    if self.ScrollRect then
        self.ScrollRect.verticalNormalizedPosition = 1
    end
end

function XUiRogueSimBuildBag:RefreshGridBuild()
    local buildIds = self._Control.MapSubControl:GetOwnBuildingIds()
    -- 拥有数量
    self.TxtNum.text = #buildIds
    for index, id in pairs(buildIds) do
        local grid = self.GridBuildList[index]
        if not grid then
            local go = XUiHelper.Instantiate(self.GridBuild, self.Content)
            grid = require("XUi/XUiRogueSim/Common/XUiGridRogueSimBuild").New(go, self, handler(self, self.OnBtnGoBuyClick))
            self.GridBuildList[index] = grid
        end
        grid:Open()
        grid:Refresh(id)
        grid:SetBuyActive()
    end
    for i = #buildIds + 1, #self.GridBuildList do
        self.GridBuildList[i]:Close()
    end
end

function XUiRogueSimBuildBag:OnBtnGoBuyClick(id)
    local isBuy = self._Control.MapSubControl:CheckBuildingIsBuyById(id)
    if isBuy then
        return
    end
    self._Control:GoBuyBuilding(self.Name, id)
end

function XUiRogueSimBuildBag:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
end

function XUiRogueSimBuildBag:OnBtnBackClick()
    self:Close()
end

return XUiRogueSimBuildBag
