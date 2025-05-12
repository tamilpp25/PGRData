local XUiGridTheatre4Genius = require("XUi/XUiTheatre4/Common/XUiGridTheatre4Genius")
local XUiGridTheatre4Prop = require("XUi/XUiTheatre4/Common/XUiGridTheatre4Prop")
---@class XUiTheatre4PopupUnlock : XLuaUi
---@field _Control XTheatre4Control
local XUiTheatre4PopupUnlock = XLuaUiManager.Register(XLuaUi, "UiTheatre4PopupUnlock")

function XUiTheatre4PopupUnlock:OnAwake()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick)
    self.GridGenius.gameObject:SetActiveEx(false)
    self.GridProp.gameObject:SetActiveEx(false)
    self.RewardTitleSet2.gameObject:SetActiveEx(false)
    self.RewardTitle.gameObject:SetActiveEx(false)
    ---@type XUiGridTheatre4Genius[]
    self.GridGeniusList = {}
    ---@type XUiGridTheatre4Prop[]
    self.GridPropList = {}
end

---@param talentIds number[]
---@param itemData { UId:number, Id:number, Type:number, Count:number }[]
function XUiTheatre4PopupUnlock:OnStart(talentIds, itemData)
    self:RefreshGenius(talentIds)
    self:RefreshProp(itemData)
end

-- 刷新天赋
function XUiTheatre4PopupUnlock:RefreshGenius(talentIds)
    if XTool.IsTableEmpty(talentIds) then
        return
    end
    self.RewardTitleSet2.gameObject:SetActiveEx(true)
    for index, talentId in pairs(talentIds) do
        local grid = self.GridGeniusList[index]
        if not grid then
            local go = XUiHelper.Instantiate(self.GridGenius, self.Grid)
            grid = XUiGridTheatre4Genius.New(go, self)
            self.GridGeniusList[index] = grid
        end
        grid:Open()
        grid:Refresh(talentId)
    end
    for i = #talentIds + 1, #self.GridGeniusList do
        self.GridGeniusList[i]:Close()
    end
end

-- 刷新藏品
function XUiTheatre4PopupUnlock:RefreshProp(itemData)
    if XTool.IsTableEmpty(itemData) then
        return
    end
    self.RewardTitle.gameObject:SetActiveEx(true)
    for index, data in pairs(itemData) do
        local grid = self.GridPropList[index]
        if not grid then
            local go = XUiHelper.Instantiate(self.GridProp, self.Grid)
            grid = XUiGridTheatre4Prop.New(go, self)
            self.GridPropList[index] = grid
        end
        grid:Open()
        grid:Refresh(data)
    end
    for i = #itemData + 1, #self.GridPropList do
        self.GridPropList[i]:Close()
    end
end

function XUiTheatre4PopupUnlock:OnBtnCloseClick()
    self:Close()
end

return XUiTheatre4PopupUnlock
