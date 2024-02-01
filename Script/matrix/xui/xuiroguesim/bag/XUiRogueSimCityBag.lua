---@class XUiRogueSimCityBag : XLuaUi
---@field private _Control XRogueSimControl
local XUiRogueSimCityBag = XLuaUiManager.Register(XLuaUi, "UiRogueSimCityBag")

function XUiRogueSimCityBag:OnAwake()
    self:RegisterUiEvents()
    self.GridCity.gameObject:SetActiveEx(false)
    ---@type XUiGridRogueSimCity[]
    self.GridCityList = {}
end

function XUiRogueSimCityBag:OnStart()
    -- 设置自动关闭
    self:SetAutoCloseInfo(self._Control:GetActivityEndTime(), function(isClose)
        if isClose then
            self._Control:HandleActivityEnd(true)
        end
    end)
end

function XUiRogueSimCityBag:OnEnable()
    self.Super.OnEnable(self)
    self:RefreshGridCity()
    -- 默认显示最上面
    if self.ScrollRect then
        self.ScrollRect.verticalNormalizedPosition = 1
    end
end

function XUiRogueSimCityBag:RefreshGridCity()
    local cityIds = self._Control.MapSubControl:GetOwnCityIds()
    -- 拥有数量
    self.TxtNum.text = #cityIds
    self.TxtNone.gameObject:SetActiveEx(XTool.IsTableEmpty(cityIds))
    for index, id in pairs(cityIds) do
        local grid = self.GridCityList[index]
        if not grid then
            local go = XUiHelper.Instantiate(self.GridCity, self.Content)
            grid = require("XUi/XUiRogueSim/Bag/XUiGridRogueSimCity").New(go, self)
            self.GridCityList[index] = grid
        end
        grid:Open()
        grid:Refresh(id)
    end
    for i = #cityIds + 1, #self.GridCityList do
        self.GridCityList[i]:Close()
    end
end

function XUiRogueSimCityBag:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
end

function XUiRogueSimCityBag:OnBtnBackClick()
    self:Close()
end

return XUiRogueSimCityBag
