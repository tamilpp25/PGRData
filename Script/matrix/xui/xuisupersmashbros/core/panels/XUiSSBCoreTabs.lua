--==============
--超限乱斗核心页签面板
--==============
local XUiSSBCoreTabs = XClass(nil, "XUiSSBCoreTabs")

function XUiSSBCoreTabs:Ctor(uiPrefab, onSelectTabCb)
    XTool.InitUiObjectByUi(self, uiPrefab)
    self:InitCoreList(onSelectTabCb)
end

function XUiSSBCoreTabs:InitCoreList(onSelectTabCb)
    self.Cores = {}
    self.CoreIndexDic = {}
    local coreList = XDataCenter.SuperSmashBrosManager.GetAllCores()
    
    local script = require("XUi/XUiSuperSmashBros/Core/Grids/XUiSSBCoreTabGrid")
    local btns = {}
    for index, core in pairs(coreList) do
        local prefab = CS.UnityEngine.Object.Instantiate(self.TabCore, self.Transform)
        local grid = script.New(prefab, core, onSelectTabCb)
        self.Cores[index] = grid
        self.CoreIndexDic[core:GetId()] = index
        btns[index] = grid:GetButton()
        -- table.insert(btns, grid:GetButton())
    end
    self.TabGroup:Init(btns, function(index)
        self:SelectIndex(index)
    end)
    self.TabCore.gameObject:SetActiveEx(false)
end

function XUiSSBCoreTabs:Refresh(coreId)
    if not coreId then
        self:SelectIndex(1)
        return
    end
    self.TabGroup:SelectIndex(self.CoreIndexDic[coreId])
end

function XUiSSBCoreTabs:SelectIndex(index)
    self.Cores[index]:OnSelect()
end

return XUiSSBCoreTabs