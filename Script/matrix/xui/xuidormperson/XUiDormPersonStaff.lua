
local XUiDormPersonStaff = XClass(nil, "XUiDormPersonStaff")

function XUiDormPersonStaff:Ctor(ui, defaultSceneId, defaultRoomId)
    XTool.InitUiObjectByUi(self, ui)
    self.DefaultSceneId = defaultSceneId or 1
    self.DefaultRoomId = defaultRoomId or 2
    self:InitTab()
end 

function XUiDormPersonStaff:InitTab()
    local tabCount = XTool.GetTableCount(XDormConfig.SceneType)
    local tab = {}
    local index = 1
    while true do
        local btn = self["BtnBase"..index]
        if XTool.UObjIsNil(btn) then
            break
        end
        local isTab = index <= tabCount
        btn.gameObject:SetActiveEx(isTab)
        if isTab then
            table.insert(tab, btn)
        end
        index = index + 1
    end
    self.BtnTogs:Init(tab, function(tabIndex) self:OnSelectTab(tabIndex) end)
    
    self.DynamicTable = XDynamicTableNormal.New(self.Transform)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(require("XUi/XUiDormPerson/XUiDormPersonListItem"))
    self.Item.gameObject:SetActiveEx(false)
end

function XUiDormPersonStaff:RegisterAnimationCb(animCb)
    self.PlayAnimationCb = animCb
end

function XUiDormPersonStaff:Show()
    local tabIndex = self.TabIndex or self.DefaultSceneId
    self.GameObject:SetActiveEx(true)
    self.BtnTogs:SelectIndex(tabIndex)
end

function XUiDormPersonStaff:Hide()
    self.GameObject:SetActiveEx(false)
end

function XUiDormPersonStaff:OnSelectTab(tabIndex)
    if self.TabIndex == tabIndex then
        return
    end
    self.TabIndex = tabIndex
    self.PlayAnimationCb("QieHuanStaffing")
    self:SetupDynamicTable()
end

function XUiDormPersonStaff:SetupDynamicTable()
    local data = {}
    local dormData = XDataCenter.DormManager.GetDormitoryData(nil, self.TabIndex) or {}
    for _, v in pairs(dormData) do
        if v:WhetherRoomUnlock() then
            local ids = {}
            local list = v:GetCharacter()
            for _, role in ipairs(list) do
                table.insert(ids, role.CharacterId)
            end
            table.insert(data, {
                DormitoryId = v:GetRoomId(),
                DormitoryName = v:GetRoomName(),
                CharacterIdList = ids
            })
        end
    end
    
    table.sort(data, function(a, b) 
        return a.DormitoryId < b.DormitoryId
    end)
    
    self.ListData = data
    
    self.PanelEmpty.gameObject:SetActiveEx(XTool.IsTableEmpty(data))
    self.DynamicTable:SetDataSource(self.ListData)
    self.DynamicTable:ReloadDataSync(self:GetJumpIndex())
end

function XUiDormPersonStaff:OnDynamicTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.ListData[index]
        grid:OnRefresh(data, self.DefaultRoomId)
    end
end

function XUiDormPersonStaff:GetJumpIndex()
    if not XTool.IsNumberValid(self.DefaultRoomId) then
        return
    end
    for index, data in ipairs(self.ListData or {}) do
        if data.DormitoryId == self.DefaultRoomId then
            --self.DefaultRoomId = nil
            return index
        end
    end
end

return XUiDormPersonStaff