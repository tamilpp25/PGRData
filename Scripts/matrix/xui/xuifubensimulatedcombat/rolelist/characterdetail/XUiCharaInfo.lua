--成员列表人物详细子页面
local XUiSimulatedCombatListCharaInfo = XLuaUiManager.Register(XLuaUi, "UiSimulatedCombatListCharaInfo")
local XUiSimulatedCombatEquipGrid = require("XUi/XUiFubenSimulatedCombat/RoleList/EquipDetail/XUiEquipGrid")
function XUiSimulatedCombatListCharaInfo:OnAwake()
    self:AddListener()
end
function XUiSimulatedCombatListCharaInfo:OnStart(rootUi)
    self.BtnLevelUp.gameObject:SetActive(true)
    self.BtnJoin.gameObject:SetActive(false)
    self.BtnSupport.gameObject:SetActive(false)
    self.ImgRedPoint.gameObject:SetActive(false)
    self.RootUi = rootUi
    --self.RootUi.CharaInfo = self
    self.WearingAwarenessGrids = {}
    local BtnText = self.BtnLevelUp.transform:Find("Text"):GetComponent("Text")
    if BtnText then
        BtnText.text = CS.XTextManager.GetText("ExpeditionRoleListRoleButtonText")
    end
end

function XUiSimulatedCombatListCharaInfo:OnEnable()

end

function XUiSimulatedCombatListCharaInfo:UpdateView(robotId)
    self.RobotId = robotId
    self.CharacterId = XRobotManager.GetCharacterId(robotId)
    self.RobotCfg = XRobotManager.GetRobotTemplate(self.RobotId)
    
    local charConfig = XCharacterConfigs.GetCharacterTemplate(self.CharacterId)
    self.TxtName.text = charConfig.Name
    self.TxtNameOther.text = charConfig.TradeName
    local jobType = XRobotManager.GetRobotJobType(self.RobotId)
    self.RImgTypeIcon:SetRawImage(XCharacterConfigs.GetNpcTypeIcon(jobType))
    self.TxtLv.text = XRobotManager.GetRobotAbility(self.RobotId)
    self.WeaponGrid = self.WeaponGrid or XUiSimulatedCombatEquipGrid.New(self.GridWeapon, nil, self)
    local usingWeaponId = self.RobotCfg.WeaponId
    if usingWeaponId then
        self.WeaponGrid:Refresh(usingWeaponId, self.RobotCfg.WeaponBeakThrough, 0, true, self.RobotCfg.WeaponLevel)
    end

    for i = 1, 6 do
        self.WearingAwarenessGrids[i] = self.WearingAwarenessGrids[i] or XUiSimulatedCombatEquipGrid.New(CS.UnityEngine.Object.Instantiate(self.GridAwareness), nil, self)
        self.WearingAwarenessGrids[i].Transform:SetParent(self["PanelAwareness" .. i], false)
        local equipId = self.RobotCfg.WaferId[i]
        if not equipId then
            self.WearingAwarenessGrids[i].GameObject:SetActive(false)
            self["PanelNoAwareness" .. i].gameObject:SetActive(true)
        else
            self.WearingAwarenessGrids[i].GameObject:SetActive(true)
            self["BtnAwarenessReplace" .. i].transform:SetAsLastSibling()
            self["PanelNoAwareness" .. i].gameObject:SetActive(false)
            self.WearingAwarenessGrids[i]:Refresh(equipId, self.RobotCfg.WaferBreakThrough[i], i, false, self.RobotCfg.WaferLevel[i])
        end
    end

    local detailConfig = XCharacterConfigs.GetCharDetailTemplate(self.CharacterId)
    local elementList = detailConfig.ObtainElementList
    for i = 1, 3 do
        local rImg = self["RImgCharElement" .. i]
        if elementList[i] then
            rImg.gameObject:SetActive(true)
            local elementConfig = XCharacterConfigs.GetCharElement(elementList[i])
            rImg:SetRawImage(elementConfig.Icon)
        else
            rImg.gameObject:SetActive(false)
        end
    end
end

function XUiSimulatedCombatListCharaInfo:AddListener()
    self:RegisterClickEvent(self.BtnLevelUp, self.OnBtnLevelUpClick)
    self:RegisterClickEvent(self.BtnAwarenessReplace6, self.OnBtnAwarenessReplace6Click)
    self:RegisterClickEvent(self.BtnAwarenessReplace5, self.OnBtnAwarenessReplace5Click)
    self:RegisterClickEvent(self.BtnAwarenessReplace4, self.OnBtnAwarenessReplace4Click)
    self:RegisterClickEvent(self.BtnAwarenessReplace3, self.OnBtnAwarenessReplace3Click)
    self:RegisterClickEvent(self.BtnAwarenessReplace2, self.OnBtnAwarenessReplace2Click)
    self:RegisterClickEvent(self.BtnAwarenessReplace1, self.OnBtnAwarenessReplace1Click)
    self:RegisterClickEvent(self.BtnWeaponReplace, self.OnBtnWeaponReplaceClick)
    self:RegisterClickEvent(self.BtnCareerTips, self.OnBtnCareerTipsClick)
    self:RegisterClickEvent(self.BtnLevelUp, self.OnBtnLevelUpClick)
    self.BtnElementDetail.CallBack = function() self:OnBtnElementDetailClick() end
end

function XUiSimulatedCombatListCharaInfo:OnBtnAwarenessReplace5Click()
    self:OnAwarenessClick(5)
end

function XUiSimulatedCombatListCharaInfo:OnBtnAwarenessReplace4Click()
    self:OnAwarenessClick(4)
end

function XUiSimulatedCombatListCharaInfo:OnBtnAwarenessReplace3Click()
    self:OnAwarenessClick(3)
end

function XUiSimulatedCombatListCharaInfo:OnBtnAwarenessReplace2Click()
    self:OnAwarenessClick(2)
end

function XUiSimulatedCombatListCharaInfo:OnBtnAwarenessReplace1Click()
    self:OnAwarenessClick(1)
end

function XUiSimulatedCombatListCharaInfo:OnBtnAwarenessReplace6Click()
    self:OnAwarenessClick(6)
end

function XUiSimulatedCombatListCharaInfo:OnBtnLevelUpClick()
    self.RootUi:OpenChild(self.RootUi.ChildUiName.UiSimulatedCombatViewRole)
end

function XUiSimulatedCombatListCharaInfo:OnAwarenessClick(site)
    if not self.RobotCfg.WaferId[site] then return end
    XLuaUiManager.Open("UiSimulatedCombatEquipDetail", self.RobotCfg.WaferId[site], self.RobotCfg.WaferBreakThrough[site], self.RobotCfg.WaferLevel[site])
end

function XUiSimulatedCombatListCharaInfo:OnBtnCareerTipsClick()
    XLuaUiManager.Open("UiCharacterCarerrTips",self.CharacterId)
end

function XUiSimulatedCombatListCharaInfo:OnBtnWeaponReplaceClick()
    XLuaUiManager.Open("UiSimulatedCombatEquipDetail", self.RobotCfg.WeaponId, self.RobotCfg.WeaponBeakThrough, self.RobotCfg.WeaponLevel)
end

function XUiSimulatedCombatListCharaInfo:OnBtnElementDetailClick()
    XLuaUiManager.Open("UiCharacterElementDetail", self.CharacterId)
end