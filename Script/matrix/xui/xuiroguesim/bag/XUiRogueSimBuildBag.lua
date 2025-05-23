local XUiGridRogueSimBuild = require("XUi/XUiRogueSim/Common/XUiGridRogueSimBuild")
---@class XUiRogueSimBuildBag : XLuaUi
---@field private _Control XRogueSimControl
local XUiRogueSimBuildBag = XLuaUiManager.Register(XLuaUi, "UiRogueSimBuildBag")

function XUiRogueSimBuildBag:OnAwake()
    self:RegisterUiEvents()
    self.GridBuild.gameObject:SetActiveEx(false)
    ---@type XUiGridRogueSimBuild[]
    self.GridBuildList = {}
end

function XUiRogueSimBuildBag:OnStart()
    -- 设置自动关闭
    self:SetAutoCloseInfo(self._Control:GetActivityEndTime(), function(isClose)
        if isClose then
            self._Control:HandleActivityEnd(true)
        end
    end)
end

function XUiRogueSimBuildBag:OnEnable()
    self.Super.OnEnable(self)
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
            grid = XUiGridRogueSimBuild.New(go, self)
            self.GridBuildList[index] = grid
        end
        grid:Open()
        grid:Refresh(id)
    end
    for i = #buildIds + 1, #self.GridBuildList do
        self.GridBuildList[i]:Close()
    end
end

function XUiRogueSimBuildBag:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
end

function XUiRogueSimBuildBag:OnBtnBackClick()
    self:Close()
end

return XUiRogueSimBuildBag
