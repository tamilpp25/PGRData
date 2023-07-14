local Next = next
local XUiDormPerson = XLuaUiManager.Register(XLuaUi, "UiDormPerson")
local XUiDormPersonListItem = require("XUi/XUiDormPerson/XUiDormPersonListItem")
local XUiDormPersonSelect = require("XUi/XUiDormPerson/XUiDormPersonSelect")

function XUiDormPerson:OnAwake()
    XTool.InitUiObject(self)
    self:InitUI()
    self:InitList()
end

function XUiDormPerson:InitList()
    self.DynamicPersonTable = XDynamicTableNormal.New(self.PersonList)
    self.DynamicPersonTable:SetProxy(XUiDormPersonListItem)
    self.DynamicPersonTable:SetDelegate(self)
end

-- 设置人员list
local personlistsortfun = function(a, b)
    return a.DormitoryId < b.DormitoryId
end

function XUiDormPerson:SetPersonList()
    local data = {}
    local dormdatas = XDataCenter.DormManager.GetDormitoryData()
    if Next(dormdatas) == nil then
        data[1] = {
            DormitoryId = -1,
            DormitoryName = "",
            CharacterIdList =            {
                [1] = -1,
            },
        }
    else
        for _, v in pairs(dormdatas) do
            if v:WhetherRoomUnlock() then
                local singledorm = v
                local ids = {}
                local list = singledorm:GetCharacter()
                for _, var in ipairs(list) do
                    table.insert(ids, var.CharacterId)
                end
                table.insert(data, {
                    DormitoryId = singledorm:GetRoomId(),
                    DormitoryName = singledorm:GetRoomName(),
                    CharacterIdList = ids,
                })
            end
        end
    end
    table.sort(data, personlistsortfun)
    self.ListData = data
end

function XUiDormPerson:UpdatePersonList()
    self:SetPersonList()
    if self.ListData and Next(self.ListData) then
        for index, itemData in pairs(self.ListData) do
            local item = self.DynamicPersonTable:GetGridByIndex(index)
            if item then
                item:OnRefresh(itemData, self.CurDormId)
            end
        end
    end
end

function XUiDormPerson:InitPersonList()
    self:SetPersonList()
    self.DynamicPersonTable:SetDataSource(self.ListData)
    self.DynamicPersonTable:ReloadDataASync(1)
end

function XUiDormPerson:SetSelectList(dormId)
    self.SelePanel:SetList(dormId)
    self.SelePanel.GameObject:SetActive(true)
    self:PlayAnimation("SelectEnable")
end

-- [监听动态列表事件]
function XUiDormPerson:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.ListData[index]
        grid:OnRefresh(data, self.CurDormId)
    end
end

function XUiDormPerson:OnStart(curdormId)
    self.CurDormId = curdormId
    self:InitPersonList()
end

function XUiDormPerson:OnEnable()
    self:PlayAnimation("AnimStartEnable", function()
        self.AnimGo.extrapolationMode = 2
    end)
end

function XUiDormPerson:InitUI()
    self.SelePanel = XUiDormPersonSelect.New(self.PanelSelect, self)
    self.SelePanel.GameObject:SetActive(false)
    self:AddListener()
end

function XUiDormPerson:AddListener()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnReturnClick)
end

function XUiDormPerson:OnBtnReturnClick()
    self:Close()
end