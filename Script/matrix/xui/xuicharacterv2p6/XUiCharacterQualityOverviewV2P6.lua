local XUiCharacterQualityOverviewV2P6 = XLuaUiManager.Register(XLuaUi, "UiCharacterQualityOverviewV2P6")
local XUiGridQualitySkillV2P6 = require("XUi/XUiCharacterV2P6/Grid/XUiGridQualitySkillV2P6")
local XUiGridQualityAttributeV2P6 = require("XUi/XUiCharacterV2P6/Grid/XUiGridQualityAttributeV2P6")

local BtnTypeSvDic = 
{
    "SViewSkillGrowUp",
    "SViewAttributeGrowUp",
}

function XUiCharacterQualityOverviewV2P6:OnAwake()
    self:InitButton()
    self:InitDynamicTable()
end

function XUiCharacterQualityOverviewV2P6:OnStart(characterId, enableCb, closeCb)
    self.CharacterId = characterId
    self.EnableCb = enableCb
    self.CloseCb = closeCb
end

function XUiCharacterQualityOverviewV2P6:RefreshInitSelectIndex()
    if XTool.IsTableEmpty(self.SkillData) then
        self.BtnSkill.gameObject:SetActiveEx(false)
    end

    if XTool.IsTableEmpty(self.AttributeData) then
        self.BtnAttribute.gameObject:SetActiveEx(false)
    end
    local btns = {self.BtnSkill, self.BtnAttribute}
    local index = 1
    for k, btn in pairs(btns) do
        if btn.gameObject.activeSelf then
            index = k
            break
        end
    end
    self.ButtonGroup:SelectIndex(index)
end

function XUiCharacterQualityOverviewV2P6:OnEnable()
    self:RefreshDynamicTableSkill()
    self:RefreshDynamicTableAttribute()
    self:RefreshInitSelectIndex()
    if self.EnableCb then
        self.EnableCb()
    end
end

function XUiCharacterQualityOverviewV2P6:InitDynamicTable()
    self.DynamicTableSkill = XDynamicTableNormal.New(self.SViewSkillGrowUp)
    self.DynamicTableSkill:SetProxy(XUiGridQualitySkillV2P6, self)
    self.DynamicTableSkill:SetDelegate(self)
    self.DynamicTableSkill:SetDynamicEventDelegate(function (event, index, grid)
        self:OnDynamicTableSkillEvent(event, index, grid)
    end)

    self.DynamicTableAttribute = XDynamicTableNormal.New(self.SViewAttributeGrowUp)
    self.DynamicTableAttribute:SetProxy(XUiGridQualityAttributeV2P6, self)
    self.DynamicTableAttribute:SetDelegate(self)
    self.DynamicTableAttribute:SetDynamicEventDelegate(function (event, index, grid)
        self:OnDynamicTableAttributeEvent(event, index, grid)
    end)
end

function XUiCharacterQualityOverviewV2P6:RefreshDynamicTableSkill()
    local dataList = XMVCA.XCharacter:GetCharQualitySkillInfo(self.CharacterId)
    self.SkillData = dataList
    
    local character = XMVCA.XCharacter:GetCharacter(self.CharacterId)
    -- 自动定位
    local index = 1
    for i = #dataList, 1, -1 do
        -- 当前节点是否激活
        local skillApartId = dataList[i]
        local skillQuality = XMVCA.XCharacter:GetCharSkillQualityApartQuality(skillApartId)
        local skillPhase = XMVCA.XCharacter:GetCharSkillQualityApartPhase(skillApartId)
        local star = character.Star
        local charQuality = character.Quality
        local isActive = charQuality > skillQuality or (charQuality == skillQuality and star >= skillPhase)
        if isActive then
            index = i
            break
        end
    end
    self.DynamicTableSkill:SetDataSource(dataList)
    self.DynamicTableSkill:ReloadDataASync(index)
end

function XUiCharacterQualityOverviewV2P6:RefreshDynamicTableAttribute()
    local dataList = XMVCA.XCharacter:GetCharQualityAttributeInfoV2P6(self.CharacterId)
    self.AttributeData = dataList

    local index = 1
    for i = #dataList, 1, -1 do
        local attributeData = dataList[i]
        local charQuality = XMVCA.XCharacter:GetCharacterQuality(self.CharacterId)
        local qualityIndex = 5
        local quality = attributeData[qualityIndex]
        local isCurQuality = charQuality == quality
        if isCurQuality then
            index = i
            break
        end
    end
    self.DynamicTableAttribute:SetDataSource(dataList)
    self.DynamicTableAttribute:ReloadDataASync(index)
end

function XUiCharacterQualityOverviewV2P6:OnDynamicTableSkillEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.SkillData[index], self.CharacterId)
    end
end

function XUiCharacterQualityOverviewV2P6:OnDynamicTableAttributeEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.AttributeData[index], self.CharacterId)
    end
end

function XUiCharacterQualityOverviewV2P6:InitButton()
    XUiHelper.RegisterClickEvent(self, self.BtnTanchuangClose, self.Close)
    local btns = {self.BtnSkill, self.BtnAttribute}
    self.ButtonGroup:Init(btns,function(index)
        self:OnSelectTab(index)
    end)
end

function XUiCharacterQualityOverviewV2P6:OnSelectTab(index)
    self:PlayAnimation("QieHuan")
    for k, svName in pairs(BtnTypeSvDic) do
        self[svName].gameObject:SetActiveEx(index == k)
    end
end

function XUiCharacterQualityOverviewV2P6:OnDestroy()
    if self.CloseCb then
        self.CloseCb()
    end
end

return XUiCharacterQualityOverviewV2P6
