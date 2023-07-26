local XUiHelpNew = XLuaUiManager.Register(XLuaUi, "UiHelpNew")
local XUiGridHelpCourse = require("XUi/XUiHelpCourse/XUiGridHelpCourse")

function XUiHelpNew:OnAwake()
    self.TabPool = {}

end

function XUiHelpNew:OnStart(configs, cb)
    self.Configs = configs
    self.Cb = cb
    self.CurIndex = 1
    self.Tab.gameObject:SetActiveEx(false)

    self:SetupTab()
    self:RegisterClickEvent(self.BtnMask, self.OnBtnMaskClick)
    self.BtnClose.CallBack = function() self:OnBtnCloseClick() end

    self:InitDynamicTable()
end

function XUiHelpNew:InitDynamicTable()
    self.DynamicTable = XDynamicTableCurve.New(self.PanelHelp.gameObject)
    self.DynamicTable:SetProxy(XUiGridHelpCourse)
    self.DynamicTable:SetDelegate(self)
end

function XUiHelpNew:OnEnable()
    self:ReloadData()
end

function XUiHelpNew:ReloadData()
    if not self.Configs then
        return
    end

    local config = self.Configs[self.CurIndex]

    self.Icons = config.ImageAsset
    self.Length = #self.Icons
    self.DynamicTable:SetDataSource(config.ImageAsset)
    self.DynamicTable:ReloadData()
end

--动态列表事件
function XUiHelpNew:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.Icons[index + 1], index + 1, self.Length)
    end
end

function XUiHelpNew:OnBtnMaskClick()
    if self.Cb then
        self.Cb()
    end
    self:Close()
end


function XUiHelpNew:OnBtnCloseClick()
    self:Close()
end

--设置章节
function XUiHelpNew:SetupTab()
    if not self.Configs then
        return
    end

    --小型缓冲池
    if self.BtnTabList and #self.BtnTabList then
        for i, v in ipairs(self.BtnTabList) do
            table.insert(self.TabPool, v)
            v.gameObject:SetActive(false)
        end
    end

    self.BtnTabList = {}
    for i, v in ipairs(self.Configs) do
        if not self.TabPool or #self.TabPool <= 0 then
            local go = CS.UnityEngine.GameObject.Instantiate(self.Tab.gameObject)
            go.transform:SetParent(self.TabGroup.transform, false)
            local btn = go:GetComponent("XUiButton")
            table.insert(self.TabPool, btn)
        end

        local tab = table.remove(self.TabPool, 1)
        tab.gameObject:SetActive(true)
        table.insert(self.BtnTabList, tab)

        tab:SetName(v.Name)
    end

    -- 初始化按钮
    self.TabGroup:Init(self.BtnTabList, function(index) self:OnBtnTabListClick(index) end)
    self.TabGroup:SelectIndex(self.CurIndex)
end


function XUiHelpNew:OnBtnTabListClick(index)
    if self.CurIndex == index then
        return
    end

    self.CurIndex = index
    self:ReloadData()
end