
local XUiSuperSmashBrosSelectCore = XLuaUiManager.Register(XLuaUi, "UiSuperSmashBrosSelectCore")

function XUiSuperSmashBrosSelectCore:OnStart(xRole)
    self.Chara = xRole
    local core = self.Chara:GetCore()
    if core then
        self.Core = core
    end
    self:InitPanel()
end

function XUiSuperSmashBrosSelectCore:InitPanel()
    self:InitBtns()
    self:InitCoreList()
end

function XUiSuperSmashBrosSelectCore:InitBtns()
    self.BtnTanchuangClose.CallBack = function() self:OnClickClose() end
    self.BtnDevelop.CallBack = function() self:OnClickDevelop() end
end

function XUiSuperSmashBrosSelectCore:InitCoreList()
    local script = require("XUi/XUiSuperSmashBros/Character/Grids/XUiSSBSelectCoreGrid")
    local cores = XDataCenter.SuperSmashBrosManager.GetAllCores()
    self.CoreGrids = {}
    local btns = {}
    local index = 1
    local count = 1
    for _, core in pairs(cores or {}) do
        local prefab = CS.UnityEngine.Object.Instantiate(self.GridCore, self.CoreContent)
        local grid = script.New(prefab, core, self)
        if self.Core and self.Core:GetId() == core:GetId() then
            index = count
        end
        table.insert(self.CoreGrids, grid)
        table.insert(btns, grid:GetButton())
        count = count + 1
    end
    self.CoreButtonGroup.CurSelectId = -1
    self.CoreButtonGroup.CanDisSelect = true --可以反选
    self.CoreButtonGroup:Init(btns, function(index) self:OnSelectGrid(index) end)
    self.GridCore.gameObject:SetActiveEx(false)
    if self.Core then
        self.CoreButtonGroup:SelectIndex(index)
    else
        self.CurIndex = -1
    end
end

function XUiSuperSmashBrosSelectCore:OnClickClose()
    self:Close()
end

function XUiSuperSmashBrosSelectCore:OnClickDevelop()
    self:Close()
    XLuaUiManager.Open("UiSuperSmashBrosCore", self.Core)
end

function XUiSuperSmashBrosSelectCore:OnSelectGrid(index)
    for i, core in pairs(self.CoreGrids) do
        core:OnSelect(i == index)
    end
    if self.CurIndex == nil then --首次进入界面选择不触发刷新
        self.CurIndex = index
    elseif self.CurIndex == index then
        self:SetSelect(nil)
        self.CurIndex = -1
    else
        self:SetSelect(self.CoreGrids[index] and self.CoreGrids[index]:GetCore())
        self.CurIndex = index
    end
end

function XUiSuperSmashBrosSelectCore:SetSelect(core)
    self.Core = core
    XDataCenter.SuperSmashBrosManager.EquipCore(self.Core, self.Chara)
end