--虚像地平线成员列表人物详细子页面
local XUiExpeditionRoleListCharaInfo = XLuaUiManager.Register(XLuaUi, "UiExpeditionRoleListCharaInfo")
local XUiExpeditionEquipGrid = require("XUi/XUiExpedition/RoleList/XUiExpeditionEquipGrid/XUiExpeditionEquipGrid")
function XUiExpeditionRoleListCharaInfo:OnAwake()
    self:AddListener()
end
function XUiExpeditionRoleListCharaInfo:OnStart(rootUi)
    self.BtnLevelUp.gameObject:SetActive(true)
    self.BtnJoin.gameObject:SetActive(false)
    self.BtnSupport.gameObject:SetActive(false)
    self.ImgRedPoint.gameObject:SetActive(false)
    self.RootUi = rootUi
    self.RootUi.CharaInfo = self
    self.WearingAwarenessGrids = {}
    local BtnText = self.BtnLevelUp.transform:Find("Text"):GetComponent("Text")
    if BtnText then
        BtnText.text = CS.XTextManager.GetText("ExpeditionRoleListRoleButtonText")
    end
end

function XUiExpeditionRoleListCharaInfo:OnEnable()

end

function XUiExpeditionRoleListCharaInfo:PreSetCharacterId(ECharacterId)
    self.ECharacterId = ECharacterId
end

function XUiExpeditionRoleListCharaInfo:UpdateView(eCharacterId)
    self.ECharacterId = eCharacterId
    self.ECharacterCfg = XExpeditionConfig.GetCharacterCfgById(eCharacterId)
    self.BaseECharacterCfg = XExpeditionConfig.GetBaseCharacterCfgById(self.ECharacterCfg.BaseId)
    self.CharacterId = XExpeditionConfig.GetCharacterIdByBaseId(self.ECharacterCfg.BaseId)
    self.RobotId = self.ECharacterCfg.RobotId
    self.RobotCfg = XRobotManager.GetRobotTemplate(self.RobotId)
    local charConfig = XMVCA.XCharacter:GetCharacterTemplate(self.CharacterId)
    self.TxtName.text = charConfig.Name
    self.TxtNameOther.text = charConfig.TradeName
    local jobType = XRobotManager.GetRobotJobType(self.RobotId)
    self.RImgTypeIcon:SetRawImage(XMVCA.XCharacter:GetNpcTypeIcon(jobType))
    self.TxtLv.text = XRobotManager.GetRobotAbility(self.RobotId)
    self.WeaponGrid = self.WeaponGrid or XUiExpeditionEquipGrid.New(self.GridWeapon, nil, self)
    local usingWeaponId = self.RobotCfg.WeaponId
    if usingWeaponId then
        self.WeaponGrid:Refresh(usingWeaponId, self.RobotCfg.WeaponBeakThrough, 0, true, self.RobotCfg.WeaponLevel)
    end

    for i = 1, 6 do
        self.WearingAwarenessGrids[i] = self.WearingAwarenessGrids[i] or XUiExpeditionEquipGrid.New(CS.UnityEngine.Object.Instantiate(self.GridAwareness), nil, self)
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

    local elementList = XExpeditionConfig.GetCharacterElementByBaseId(self.ECharacterCfg.BaseId)
    for i = 1, 3 do
        local rImg = self["RImgCharElement" .. i]
        if elementList[i] then
            rImg.gameObject:SetActive(true)
            local elementConfig = XExpeditionConfig.GetCharacterElementById(elementList[i])
            rImg:SetRawImage(elementConfig.Icon)
        else
            rImg.gameObject:SetActive(false)
        end
    end
    local partner = XRobotManager.GetRobotPartner(self.RobotId)
    self.PanelNoPartner.gameObject:SetActiveEx(not partner)
    self.PartnerIcon.gameObject:SetActiveEx(partner)   
    self.PartnerIcon:SetRawImage(partner and partner:GetIcon())
end

function XUiExpeditionRoleListCharaInfo:AddListener()
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
    self.BtnCarryPartner.CallBack = function() self:OnClickBtnPartner() end
end

function XUiExpeditionRoleListCharaInfo:OnBtnAwarenessReplace5Click()
    self:OnAwarenessClick(5)
end

function XUiExpeditionRoleListCharaInfo:OnBtnAwarenessReplace4Click()
    self:OnAwarenessClick(4)
end

function XUiExpeditionRoleListCharaInfo:OnBtnAwarenessReplace3Click()
    self:OnAwarenessClick(3)
end

function XUiExpeditionRoleListCharaInfo:OnBtnAwarenessReplace2Click()
    self:OnAwarenessClick(2)
end

function XUiExpeditionRoleListCharaInfo:OnBtnAwarenessReplace1Click()
    self:OnAwarenessClick(1)
end

function XUiExpeditionRoleListCharaInfo:OnBtnAwarenessReplace6Click()
    self:OnAwarenessClick(6)
end

function XUiExpeditionRoleListCharaInfo:OnBtnLevelUpClick()
    self.RootUi:OpenChild(self.RootUi.ChildUiName.UiExpeditionViewRole)
end

function XUiExpeditionRoleListCharaInfo:OnAwarenessClick(site)
    if not self.RobotCfg.WaferId[site] then return end
    XLuaUiManager.Open("UiExpeditionEquipDetail", self.RobotCfg.WaferId[site], self.RobotCfg.WaferBreakThrough[site], self.RobotCfg.WaferLevel[site])
end

function XUiExpeditionRoleListCharaInfo:OnBtnCareerTipsClick()
    XLuaUiManager.Open("UiCharacterCarerrTips",self.CharacterId)
end

function XUiExpeditionRoleListCharaInfo:OnBtnWeaponReplaceClick()
    XLuaUiManager.Open("UiExpeditionEquipDetail", self.RobotCfg.WeaponId, self.RobotCfg.WeaponBeakThrough, self.RobotCfg.WeaponLevel)
end

function XUiExpeditionRoleListCharaInfo:OnBtnElementDetailClick()
    XLuaUiManager.Open("UiCharacterAttributeDetail", self.CharacterId, XEnumConst.UiCharacterAttributeDetail.BtnTab.Element)
end

function XUiExpeditionRoleListCharaInfo:OnClickBtnPartner()
    local partner = XRobotManager.GetRobotPartner(self.RobotId)
    if not partner then return end
    XLuaUiManager.Open("UiPartnerPropertyOther", partner)
end