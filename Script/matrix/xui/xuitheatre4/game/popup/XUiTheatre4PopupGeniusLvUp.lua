local XUiGridTheatre4Genius = require("XUi/XUiTheatre4/Common/XUiGridTheatre4Genius")
local XUiTheatre4PopupGeniusLvUpColorGrid = require("XUi/XUiTheatre4/Game/Popup/XUiTheatre4PopupGeniusLvUpColorGrid")
---@class XUiTheatre4PopupGeniusLvUp : XLuaUi
---@field _Control XTheatre4Control
local XUiTheatre4PopupGeniusLvUp = XLuaUiManager.Register(XLuaUi, "UiTheatre4PopupGeniusLvUp")

function XUiTheatre4PopupGeniusLvUp:OnAwake()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick)
    self.GridLv.gameObject:SetActiveEx(false)
    self.GridGenius.gameObject:SetActiveEx(false)
    ---@type XUiGridTheatre4Genius[]
    self.GridGeniusList = {}
    ---@type XUiTheatre4PopupGeniusLvUpColorGrid[]
    self.GridLvList = {}
end

---@param colors { Color: number, NewLevel: number, OldLevel: number}[]
---@param talentIds number[]
function XUiTheatre4PopupGeniusLvUp:OnStart(colors, talentIds)
    self.Colors = colors
    self.TalentIds = talentIds
end

function XUiTheatre4PopupGeniusLvUp:OnEnable()
    self:RefreshLvUp()
    self:RefreshGenius()
    self:RefreshTitle()
end

-- 刷新颜色等级提升列表
function XUiTheatre4PopupGeniusLvUp:RefreshLvUp()
    if XTool.IsTableEmpty(self.Colors) then
        return
    end
    for index, data in pairs(self.Colors) do
        local grid = self.GridLvList[index]
        if not grid then
            local go = XUiHelper.Instantiate(self.GridLv, self.ListLvUp)
            grid = XUiTheatre4PopupGeniusLvUpColorGrid.New(go, self)
            self.GridLvList[index] = grid
        end
        grid:Open()
        grid:Refresh(data)
    end
    for i = #self.Colors + 1, #self.GridLvList do
        self.GridLvList[i]:Close()
    end
end

-- 刷新天赋列表
function XUiTheatre4PopupGeniusLvUp:RefreshGenius()
    if XTool.IsTableEmpty(self.TalentIds) then
        return
    end
    for index, talentId in pairs(self.TalentIds) do
        local grid = self.GridGeniusList[index]
        if not grid then
            local go = XUiHelper.Instantiate(self.GridGenius, self.GridGenius.transform.parent)
            grid = XUiGridTheatre4Genius.New(go, self)
            self.GridGeniusList[index] = grid
        end
        grid:Open()
        grid:Refresh(talentId)
    end
    for i = #self.TalentIds + 1, #self.GridGeniusList do
        self.GridGeniusList[i]:Close()
    end
end

function XUiTheatre4PopupGeniusLvUp:RefreshTitle()
    if self.TxtTitle then
        self.TxtTitle.gameObject:SetActiveEx(not XTool.IsTableEmpty(self.TalentIds))
    end
end

function XUiTheatre4PopupGeniusLvUp:OnBtnCloseClick()
    self._Control:CheckNeedOpenNextPopup(self.Name, true)
end

return XUiTheatre4PopupGeniusLvUp
