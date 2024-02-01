local XUiTemplePhotoGrid = require("XUi/XUiTemple/Main/XUiTemplePhotoGrid")

---@class XUiTemplePhoto : XLuaUi
---@field _Control XTempleControl
local XUiTemplePhoto = XLuaUiManager.Register(XLuaUi, "UiTemplePhoto")

function XUiTemplePhoto:Ctor()
    ---@type XTempleUiControl
    self._UiControl = self._Control:GetUiControl()

    ---@type XUiTemplePhotoGrid[]
    self._Grids = {}

    self._DataAsync = false
    self._DataAsyncIndex = 1
    self._Timer = false
end

function XUiTemplePhoto:OnAwake()
    self._Groups = { self.PanelPhoto1, self.PanelPhoto2 }
    self:AddGrids(self.PanelPhoto1)
    self:AddGrids(self.PanelPhoto2)
    self:RegisterClickEvent(self.BtnTanchuangClose, self.Close)
    self:RegisterClickEvent(self.BtnClose, self.Close)
end

function XUiTemplePhoto:OnDestroy()
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = false
    end
end

function XUiTemplePhoto:OnStart()
    self:Update()
    for i = 1, #self._DataAsync do
        self:UpdateGrids(self._DataAsync, i)
    end

    ---@type UnityEngine.UI.ScrollRect
    local scrollView = self.ScrollView or XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/PanelPhoto01", "ScrollRect")
    scrollView.verticalNormalizedPosition = 1

    local function ShowGrids()
        if not self:UpdateGridsChess(self._DataAsync, self._DataAsyncIndex) then
            XScheduleManager.UnSchedule(self._Timer)
            self._Timer = false
        end
        self._DataAsyncIndex = self._DataAsyncIndex + 1
    end

    self._Timer = XScheduleManager.ScheduleOnce(function()
        ShowGrids()
        self._Timer = XScheduleManager.ScheduleForever(function()
            ShowGrids()
        end, 100)
    end, 900)
end

function XUiTemplePhoto:Update()
    local dataSource = self._UiControl:GetDataPhoto()

    local amount = #dataSource
    self:InitGridsByAmount(amount)
    self._DataAsync = dataSource
end

function XUiTemplePhoto:InitGridsByAmount(amount)
    local groupAmount = math.ceil(amount / 4)
    for i = 1, groupAmount do
        if not self._Groups[i] then
            local panelPhoto
            if i % 2 == 1 then
                panelPhoto = CS.UnityEngine.Object.Instantiate(self.PanelPhoto1, self.PanelPhoto1.transform.parent)
            else
                panelPhoto = CS.UnityEngine.Object.Instantiate(self.PanelPhoto2, self.PanelPhoto1.transform.parent)
            end
            self._Groups[i] = panelPhoto
            self:AddGrids(panelPhoto)
        end
    end
end

function XUiTemplePhoto:AddGrids(panelPhoto)
    for i = 1, 4 do
        local grid = panelPhoto.transform:Find("GridPhoto" .. i)
        if grid then
            local photoGrid = XUiTemplePhotoGrid.New(grid, self)
            self._Grids[#self._Grids + 1] = photoGrid
            photoGrid:Close()
        end
    end
end

function XUiTemplePhoto:UpdateGrids(dataSource, i)
    local data = dataSource[i]
    if not data then
        return false
    end
    local grid = self._Grids[i]
    if grid then
        if data then
            grid:Open()
            grid:Update(data)
        else
            grid:Close()
        end
        return true
    end
    return false
end

function XUiTemplePhoto:UpdateGridsChess(dataSource, i)
    local data = dataSource[i]
    if not data then
        return false
    end
    local grid = self._Grids[i]
    if grid then
        if data then
            grid:UpdateGrids()
        end
        return true
    end
    return false
end

return XUiTemplePhoto