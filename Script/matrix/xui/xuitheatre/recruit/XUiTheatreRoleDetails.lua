local XUiGridEquipOther = require("XUi/XUiPlayerInfo/XUiGridEquipOther")

local AWARENESS_COUNT = 6    --意识最大数量

--招募界面：成员详情弹窗
local XUiTheatreRoleDetails = XLuaUiManager.Register(XLuaUi, "UiTheatreRoleDetails")

function XUiTheatreRoleDetails:OnAwake()
    self:AddListener()
    self.WearingAwarenessGrids = {}
    self.WeaponGrid = XUiGridEquipOther.New(self.GridWeapon, {Parent = self}, handler(self, self.ClickWeaponCallback))
    self.GridAwareness.gameObject:SetActiveEx(false)
    self.RImgIconLevelUp:SetRawImage(XTheatreConfigs.GetRoleDetailLevelIcon())
end

function XUiTheatreRoleDetails:OnStart(adventureRole, isRecruitRole, closeCb)
    self.AdventureRole = adventureRole
    self.IsRecruitRole = isRecruitRole  --是否已招募的角色
    self.CloseCallback = closeCb

    local robotObj = adventureRole:GetRawData()
    self.RobotCfg = robotObj:GetConfig()
end

function XUiTheatreRoleDetails:OnEnable()
    self:Refresh()
end

function XUiTheatreRoleDetails:OnDestroy()
    if self.CloseCallback then
        self.CloseCallback()
    end
end

function XUiTheatreRoleDetails:ClickWeaponCallback()
    local adventureRole = self.AdventureRole
    local weaponEquip = adventureRole:GetWeaponEquip()
    XLuaUiManager.Open("UiEquipDetailOther", weaponEquip, adventureRole:GetCharacterViewModel())
end

function XUiTheatreRoleDetails:ClickAwarenessCallback()
end

function XUiTheatreRoleDetails:Refresh()
    local adventureRole = self.AdventureRole
    local characterId = adventureRole:GetCharacterId()
    local charConfig = XMVCA.XCharacter:GetCharacterTemplate(characterId)

    --角色名
    self.TxtName.text = charConfig.Name

    --型号
    self.TxtNameOther.text = charConfig.TradeName

    --职业类型
    local jobType = adventureRole:GetCareerType()
    self.RImgTypeIcon:SetRawImage(XMVCA.XCharacter:GetNpcTypeIcon(jobType))

    --战力
    self.TxtLv.text = math.ceil(adventureRole:GetAbility())

    self.BtnRecruit.gameObject:SetActiveEx(not self.IsRecruitRole)
    self:UpdateWeapon()
    self:UpdateAwareness()
    self:UpdateElement()

    -- 机制
    local generalSkillIds = XMVCA.XCharacter:GetCharacterGeneralSkillIds(characterId)
    for i = 1, self.ListGeneralSkillDetail.childCount, 1 do
        local id = generalSkillIds[i]
        self["BtnGeneralSkill"..i].gameObject:SetActiveEx(id)
        if id then
            local generalSkillConfig = XMVCA.XCharacter:GetModelCharacterGeneralSkill()[id]
            self["BtnGeneralSkill"..i]:SetRawImage(generalSkillConfig.Icon)
        end
    end
end

--刷新能量（属性）
function XUiTheatreRoleDetails:UpdateElement()
    local elementList = self.AdventureRole:GetElementList()
    for i = 1, 3 do
        local rImg = self["RImgCharElement" .. i]
        if elementList[i] then
            rImg.gameObject:SetActive(true)
            local elementConfig = XMVCA.XCharacter:GetCharElement(elementList[i])
            rImg:SetRawImage(elementConfig.Icon)
        else
            rImg.gameObject:SetActive(false)
        end
    end
end

--刷新意识
function XUiTheatreRoleDetails:UpdateAwareness()
    local robotConfig = self.RobotCfg
    for i = 1, AWARENESS_COUNT do
        local equip = self.AdventureRole:GetWearingEquipBySite(i)
        self.WearingAwarenessGrids[i] = self.WearingAwarenessGrids[i] or 
            XUiGridEquipOther.New(CS.UnityEngine.Object.Instantiate(self.GridAwareness), {Parent = self}, function()
                XLuaUiManager.Open("UiEquipDetailOther", equip, self.AdventureRole:GetCharacterViewModel())
            end)
        self.WearingAwarenessGrids[i].Transform:SetParent(self["PanelAwareness" .. i], false)
        if not equip then
            self.WearingAwarenessGrids[i].GameObject:SetActive(false)
        else
            self.WearingAwarenessGrids[i].GameObject:SetActive(true)
            self["BtnAwarenessReplace" .. i].transform:SetAsLastSibling()
            self.WearingAwarenessGrids[i]:Refresh(equip)
        end
    end
end

--刷新武器
function XUiTheatreRoleDetails:UpdateWeapon()
    self.WeaponGrid:Refresh(self.AdventureRole:GetWeaponEquip())
end

function XUiTheatreRoleDetails:AddListener()
    self:RegisterClickEvent(self.BtnClose, self.Close)
    self:RegisterClickEvent(self.BtnRecruit, self.OnBtnRecruitClick)
    self:RegisterClickEvent(self.BtnCareerTips, self.OnBtnCareerTipsClick)
    self:RegisterClickEvent(self.BtnElementDetail, self.OnBtnElementDetailClick)
    self:RegisterClickEvent(self.BtnWeaponClick, self.OnBtnWeaponClick)
    for i = 1, AWARENESS_COUNT do
        local index = i
        self:RegisterClickEvent(self["BtnAwarenessReplace" .. i], function()
            self:OnAwarenessClick(index)
        end)
    end
    XUiHelper.RegisterClickEvent(self, self.BtnGeneralSkill1, function ()
        self:OnBtnGeneralSkillClick(1)
    end)
    XUiHelper.RegisterClickEvent(self, self.BtnGeneralSkill2, function ()
        self:OnBtnGeneralSkillClick(2)
    end)
end

function XUiTheatreRoleDetails:OnBtnWeaponClick()
    XDataCenter.TheatreManager.SetSceneActive(false)
    local adventureRole = self.AdventureRole
    local weaponEquip = adventureRole:GetWeaponEquip()
    XLuaUiManager.Open("UiEquipDetailOther", weaponEquip, adventureRole:GetCharacterViewModel())
end

function XUiTheatreRoleDetails:OnAwarenessClick(site)
    local adventureRole = self.AdventureRole
    local equip = adventureRole:GetWearingEquipBySite(site)
    if not equip then
        return
    end
    XDataCenter.TheatreManager.SetSceneActive(false)
    XLuaUiManager.Open("UiEquipDetailOther", equip, adventureRole:GetCharacterViewModel())
end

function XUiTheatreRoleDetails:OnBtnElementDetailClick()
    XLuaUiManager.Open("UiCharacterAttributeDetail", self.AdventureRole:GetCharacterId(), XEnumConst.UiCharacterAttributeDetail.BtnTab.Element)
end

function XUiTheatreRoleDetails:OnBtnGeneralSkillClick(index)
    local generalSkillIds = XMVCA.XCharacter:GetCharacterGeneralSkillIds(self.AdventureRole:GetCharacterId())
    local curId = generalSkillIds[index]
    if not curId then
        return
    end

    XLuaUiManager.Open("UiCharacterAttributeDetail", self.AdventureRole:GetCharacterId(), XEnumConst.UiCharacterAttributeDetail.BtnTab.GeneralSkill, index)
end

function XUiTheatreRoleDetails:OnBtnCareerTipsClick()
    XLuaUiManager.Open("UiCharacterAttributeDetail", self.AdventureRole:GetCharacterId())
end

function XUiTheatreRoleDetails:OnBtnRecruitClick()
    local adventureManager = XDataCenter.TheatreManager.GetCurrentAdventureManager()
    local adventureChapter = adventureManager:GetCurrentChapter()
    local reqCallback = function()
        self:Close()
    end
    adventureChapter:RequestRecruitRole(self.AdventureRole:GetId(), reqCallback)
end