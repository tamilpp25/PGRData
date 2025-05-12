local XUiTheatre4PopupInheritGrid = require("XUi/XUiTheatre4/System/Collection/XUiTheatre4PopupInheritGrid")

---@class XUiTheatre4PopupInherit : XLuaUi
---@field _Control XTheatre4Control
local XUiTheatre4PopupInherit = XLuaUiManager.Register(XLuaUi, "UiTheatre4PopupInherit")

function XUiTheatre4PopupInherit:Ctor()
    ---@type XUiTheatre4PopupInheritGrid[]
    self._GridList = {}
end

function XUiTheatre4PopupInherit:OnAwake()
    self:BindExitBtns()
    self.TxtTitle.text = XUiHelper.GetText("Theatre4SelectCollection")
    self.TxtNum.text = "0/1"
    self.ListOption.gameObject:SetActiveEx(true)
    self.GridPropCard.gameObject:SetActiveEx(false)
end

function XUiTheatre4PopupInherit:OnEnable()
    self:Update()
end

function XUiTheatre4PopupInherit:Update()
    self._Control.SetControl:UpdateCollection()
    local collections = self._Control.SetControl:GetUiData().Collection.CollectionList
    for i = 1, #collections do
        local grid = self._GridList[i]
        if not grid then
            local ui = XUiHelper.Instantiate(self.GridPropCard, self.GridPropCard.transform.parent)
            grid = XUiTheatre4PopupInheritGrid.New(ui, self)
        end
        local data = collections[i]
        grid:Open()
        grid:Update(data)
    end
    for i = #collections + 1, #self._GridList do
        local grid = self._GridList[i]
        grid:Close()
    end
    self:PlayPropAnimation()
end

function XUiTheatre4PopupInherit:PlayPropAnimation()
    local grids = self._GridList

    if not XTool.IsTableEmpty(grids) then
        for _, grid in pairs(grids) do
            if grid and grid:IsNodeShow() then
                grid:SetAlpha(0)
            end
        end
        
        XLuaUiManager.SetMask(true, self.Name)
        RunAsyn(function()
            for _, grid in pairs(grids) do
                if grid and grid:IsNodeShow() then
                    grid:PlayPropCardAnimation()
                    
                    asynWaitSecond(0.04)
                end
            end
            XLuaUiManager.SetMask(false, self.Name)
        end)
    end
end

return XUiTheatre4PopupInherit