local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
--######################## XUiGuildDormPersonItem ########################
local XUiGuildDormPersonItem = XClass(nil, "XUiGuildDormPersonItem")

function XUiGuildDormPersonItem:Ctor(ui)
    XUiHelper.InitUiClass(self, ui)
    self.CharacterData = nil
end

function XUiGuildDormPersonItem:SetData(characterData)
    self.CharacterData = characterData
    local iconpath = XDormConfig.GetCharacterStyleConfigQIconById(characterData.CharacterId)
    if iconpath then
        self.ImgIcon:SetRawImage(iconpath)
    end
    local charStyleConfig = XDormConfig.GetCharacterStyleConfigById(characterData.CharacterId)
    if charStyleConfig then
        self.TxtName.text = charStyleConfig.Name
    end
    self.ImgDorm.gameObject:SetActiveEx(characterData.CharacterId 
        == XDataCenter.GuildDormManager.GetCurrentPlayerRoleId())
end

function XUiGuildDormPersonItem:SetSelected(characterId)
    self.ImgSelect.gameObject:SetActiveEx(self.CharacterData.CharacterId == characterId)
end

--######################## XUiGuildDormPerson ########################
local XUiGuildDormPerson = XLuaUiManager.Register(XLuaUi, "UiGuildDormPerson")

function XUiGuildDormPerson:OnAwake()
    self.AllCharacterDatas = nil
    self.CurrentSelectId = nil
    -- 角色动态列表
    self.DynamicSelectTable = XDynamicTableNormal.New(self.PanelSelectList)
    self.DynamicSelectTable:SetProxy(XUiGuildDormPersonItem)
    self.DynamicSelectTable:SetDelegate(self)
    self.DormSelectItem.gameObject:SetActiveEx(false)
    self:RegisterUiEvents()
end

function XUiGuildDormPerson:OnStart()
    -- 设置默认显示全部角色
    self.DropdownType.value = 0
    self:RefreshDynamicSelectTable(0)
end

--######################## 私有方法 ########################

function XUiGuildDormPerson:RefreshDynamicSelectTable(value)
    self.AllCharacterDatas = XDataCenter.GuildDormManager.GetCharacterDatas(value)
    self.ImgNonePerson.gameObject:SetActiveEx(#self.AllCharacterDatas <= 0)
    self.TxtSelect.text = #self.AllCharacterDatas > 0 and "1/1" or "0/1"
    self.CurrentSelectId = #self.AllCharacterDatas > 0 and self.AllCharacterDatas[1].CharacterId or nil
    self.DynamicSelectTable:SetDataSource(self.AllCharacterDatas)
    self.DynamicSelectTable:ReloadDataSync(1)
end

function XUiGuildDormPerson:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnCancel, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnTanchuangClose, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnConfirm, self.OnBtnConfirmClicked)
    self.DropdownType.onValueChanged:AddListener(function()
        self:RefreshDynamicSelectTable(self.DropdownType.value)
    end)
end

function XUiGuildDormPerson:OnBtnConfirmClicked()
    XDataCenter.GuildDormManager.RequestChangeRoleId(self.CurrentSelectId, function()
        self:Close()
    end)
end

function XUiGuildDormPerson:OnDynamicTableEvent(event, index, grid)
    local data = self.DynamicSelectTable.DataSource[index]
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:SetData(data)
        grid:SetSelected(self.CurrentSelectId)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self.CurrentSelectId = data.CharacterId
        for _, grid in pairs(self.DynamicSelectTable:GetGrids()) do
            grid:SetSelected(self.CurrentSelectId)
        end
    end
end

return XUiGuildDormPerson