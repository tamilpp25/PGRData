---------------PanelTeam-------------
local XUiPanelTeam = XClass(nil, "XUiPanelTeam")

function XUiPanelTeam:Ctor(ui)
    if XTool.UObjIsNil(ui) then
        return
    end
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self:Init()
end

function XUiPanelTeam:Init()
    self.BtnTeam = XUiHelper.TryGetComponent(self.Transform, "BtnTeam", "XUiButton")
    self.TxtRoleNumber = XUiHelper.TryGetComponent(self.Transform, "TxtRoleNumber", "Text")
    self.TxtStarNumber = XUiHelper.TryGetComponent(self.Transform, "PanelLv/TxtNumber", "Text")
    XUiHelper.RegisterClickEvent(self, self.BtnTeam, handler(self, self.OpenTeamMassage))

    self.AdventureManager = XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager()
end

function XUiPanelTeam:Refresh()
    self.recruitRoleCount = self.AdventureManager:GetRolesCount()
    --已招募的角色数量
    if self.TxtRoleNumber then
        self.TxtRoleNumber.text = self.recruitRoleCount
    end
    --羁绊总星数
    if self.TxtStarNumber then
        self.TxtStarNumber.text = self.AdventureManager:GetRolesStarCount()
    end
end

--打开角色信息界面
function XUiPanelTeam:OpenTeamMassage()
    if not XTool.IsNumberValid(self.recruitRoleCount) then
        XUiManager.TipError(XBiancaTheatreConfigs.GetClientConfig("NotRoles"))
        return
    end
    XLuaUiManager.Open("UiBiancaTheatreMainMassage")
end


---------------PanelLeftInformation-------------
local XUiBiancaTheatreItemGrid = require("XUi/XUiBiancaTheatre/Common/XUiBiancaTheatreItemGrid")
local XUiPanelLeftInformation = XClass(nil, "XUiPanelLeftInformation")
local GRID_PROP_COUNT = 3   --可显示的道具格子数

function XUiPanelLeftInformation:Ctor(ui)
    if XTool.UObjIsNil(ui) then
        return
    end
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self:Init()
end

function XUiPanelLeftInformation:Init()
    self.Btn = self.GameObject:GetComponent("XUiButton")
    self.UnitTeamIcon = XUiHelper.TryGetComponent(self.Transform, "PanelRanks/Icon", "Image")
    self.SelectTeamIcon = XUiHelper.TryGetComponent(self.Transform, "PanelRanks/PanelRanks/RImgIcon", "RawImage")
    self.ItemIcon = XUiHelper.TryGetComponent(self.Transform, "PanelProp/GameObject/Icon", "Image")
    self.ItemCount = XUiHelper.TryGetComponent(self.Transform, "PanelProp/GameObject/TxtNumber", "Text")
    for i = 1, GRID_PROP_COUNT do
        local obj = XUiHelper.TryGetComponent(self.Transform, "PanelProp/GridProp" .. i .. "/GridBiancaPopUp")
        self["ItemGrid" .. i] = XUiBiancaTheatreItemGrid.New(obj)

        self["GridProp" .. i] = XUiHelper.TryGetComponent(self.Transform, "PanelProp/GridProp" .. i)
    end

    XUiHelper.RegisterClickEvent(self, self.Btn, handler(self, self.OpenProp))
end

function XUiPanelLeftInformation:Refresh()
    local adventureManager = XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager()
    local theatreItemList = adventureManager:GetItemList()
    
    --分队指示图标
    if self.UnitTeamIcon then
        self.UnitTeamIcon:SetSprite(XBiancaTheatreConfigs.GetClientConfig("UnitIcon", 1))
    end
    --选择的分队图标
    if self.SelectTeamIcon then
        local teamId = adventureManager:GetCurTeamId()
        if XTool.IsNumberValid(teamId) then
            self.SelectTeamIcon:SetRawImage(XBiancaTheatreConfigs.GetTeamIcon(teamId))
        end
    end
    --道具指示图标
    if self.ItemIcon then
        self.ItemIcon:SetSprite(XBiancaTheatreConfigs.GetClientConfig("UnitIcon", 2))
    end
    --道具图鉴数量
    local totalCount = #theatreItemList
    if self.ItemCount then
        self.ItemCount.text = totalCount
    end
    --道具格子
    local gridProp
    local itemGrid
    local theatreItem
    for i = 1, GRID_PROP_COUNT do
        itemGrid = self["ItemGrid" .. i]
        theatreItem = theatreItemList[i]
        if itemGrid and theatreItem then
            itemGrid:Refresh(theatreItem:GetItemId())
        end
        gridProp = self["GridProp" .. i]
        if gridProp then
            gridProp.gameObject:SetActiveEx(theatreItem and true or false)
        end
    end
end

--打开已获取道具列表
function XUiPanelLeftInformation:OpenProp()
    XLuaUiManager.Open("UiBiancaTheatreBureauTeam")
end



---------------肉鸽2.0 下方通用显示面板-------------
local XUiBiancaTheatrePanelDown = XClass(nil, "XUiBiancaTheatrePanelDown")

function XUiBiancaTheatrePanelDown:Ctor(ui)
    self.Gameobject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:Init()
end

function XUiBiancaTheatrePanelDown:Init()
    self.PanelLeftInformation = XUiPanelLeftInformation.New(self.PanelLeftInformation)
    self.PanelTeam = XUiPanelTeam.New(self.PanelTeam)
end

function XUiBiancaTheatrePanelDown:Refresh()
    self.PanelLeftInformation:Refresh()
    self.PanelTeam:Refresh()
end

return XUiBiancaTheatrePanelDown