local XUiGridSuitSkill = XClass(nil, "XUiGridSuitSkill")
local CSInstantiate = CS.UnityEngine.Object.Instantiate
local PAGE_SUIT_CONT = 3 -- 一页展示套装的数量

local XUiEquipSuitSkillV2P6 = XLuaUiManager.Register(XLuaUi, "UiEquipSuitSkillV2P6")

function XUiEquipSuitSkillV2P6:OnAwake()
    self:InitSkillListGo()
    self:SetButtonCallBack()
end

function XUiEquipSuitSkillV2P6:OnStart(characterId)
    self.CharacterId = characterId
end

function XUiEquipSuitSkillV2P6:OnEnable()
    self:UpdateView()
end

function XUiEquipSuitSkillV2P6:InitSkillListGo()
    self.SkillGridList = {}
    for i = 1, PAGE_SUIT_CONT do
        local go = self.SkillItem
        if i > 1 then
            go = CSInstantiate(self.SkillItem, self.PanelSkillList)
        end
        local uiGridSuitSkill = XUiGridSuitSkill.New(go)
        table.insert(self.SkillGridList, uiGridSuitSkill)
    end
end

function XUiEquipSuitSkillV2P6:SetButtonCallBack()
    self:RegisterClickEvent(self.BtnBgClose, self.Close)
    self:RegisterClickEvent(self.BtnClose, self.Close)
    self:RegisterClickEvent(self.BtnLeft, self.OnBtnLeftClick)
    self:RegisterClickEvent(self.BtnRight, self.OnBtnRightClick)
end

function XUiEquipSuitSkillV2P6:OnBtnLeftClick()
    if self.CanLeftPage then
        self.PageIndex = self.PageIndex - 1
        self:UpdateSuitList()
    end
end

function XUiEquipSuitSkillV2P6:OnBtnRightClick()
    if self.CanRightPage then
        self.PageIndex = self.PageIndex + 1
        self:UpdateSuitList()
    end
end

function XUiEquipSuitSkillV2P6:UpdateView()
    self.SuitInfoList = XMVCA:GetAgency(ModuleId.XEquip):GetWearingSuitInfoList(self.CharacterId)
    local canSwitch = #self.SuitInfoList > PAGE_SUIT_CONT
    self.BtnLeft.gameObject:SetActiveEx(false)
    self.BtnRight.gameObject:SetActiveEx(false)

    self.PageIndex = 0
    self:UpdateSuitList()
end

-- 刷新套装列表
function XUiEquipSuitSkillV2P6:UpdateSuitList()
    for i = 1, PAGE_SUIT_CONT do
        local infoIndex = self.PageIndex * PAGE_SUIT_CONT + i
        local suitInfo = self.SuitInfoList[infoIndex]
        local uiGridSuitSkill = self.SkillGridList[i]
        uiGridSuitSkill:UpdateView(self.CharacterId, suitInfo)
    end    

    self:UpdateSwitchBtn()
end

-- 刷新切换按钮
function XUiEquipSuitSkillV2P6:UpdateSwitchBtn()
    local canSwitch = #self.SuitInfoList > PAGE_SUIT_CONT
    self.CanLeftPage = self.PageIndex > 0
    self.CanRightPage = #self.SuitInfoList > (self.PageIndex + 1) * PAGE_SUIT_CONT
    self.BtnLeft.gameObject:SetActiveEx(canSwitch)
    self.BtnRight.gameObject:SetActiveEx(canSwitch)
    self.BtnLeft:SetDisable(not self.CanLeftPage)
    self.BtnRight:SetDisable(not self.CanRightPage)
end



-------------------------------------#region XUiGridSuitSkill --------------------------------

function XUiGridSuitSkill:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self.ActiveDesList = {self.TxtActiveDes}
    self.UnActiveDesList = {self.TxtUnActiveDes}
end

function XUiGridSuitSkill:UpdateView(characterId, suitInfo)
    local haveInfo = suitInfo ~= nil
    self.Normal.gameObject:SetActiveEx(haveInfo)
    self.Disable.gameObject:SetActiveEx(not haveInfo)
    if not haveInfo then
        return
    end

    local suitId = suitInfo.SuitId
    local iconPath = XMVCA:GetAgency(ModuleId.XEquip):GetEquipSuitIconPath(suitId)
    self.RImgIcon:SetRawImage(iconPath)

    local activeCount, siteCheckDic = XDataCenter.EquipManager.GetActiveSuitEquipsCount(characterId, suitId)
    local isOverrun = XMVCA:GetAgency(ModuleId.XEquip):IsCharacterOverrunSuit(characterId, suitId)
    local skillDesList = XMVCA:GetAgency(ModuleId.XEquip):GetSuitActiveSkillDesList(suitId, activeCount, isOverrun, isOverrun)

    for _, desGo in ipairs(self.ActiveDesList) do
        desGo.gameObject:SetActiveEx(false)
    end
    for _, desGo in ipairs(self.UnActiveDesList) do
        desGo.gameObject:SetActiveEx(false)
    end
    local activeIndex = 1
    local unActiveIndex = 1
    for _, skillInfo in ipairs(skillDesList) do
        local desGo
        if skillInfo.IsActive then
            desGo = self.ActiveDesList[activeIndex]
            if not desGo then
                desGo = CSInstantiate(self.TxtActiveDes, self.DescContent)
                table.insert(self.ActiveDesList, desGo)
            end
            activeIndex = activeIndex + 1
        else
            desGo = self.UnActiveDesList[unActiveIndex]
            if not desGo then
                desGo = CSInstantiate(self.TxtUnActiveDes, self.DescContent)
                table.insert(self.UnActiveDesList, desGo)
            end
            unActiveIndex = unActiveIndex + 1
        end
        desGo.gameObject:SetActiveEx(true)
        desGo.transform:SetAsLastSibling()
        desGo:GetComponent("Text").text = skillInfo.SkillDes
        local txtTitle = XUiHelper.TryGetComponent(desGo.transform, "TxtTitle", "Text")
        txtTitle.text = skillInfo.PosDes
    end

    -- 没有激活技能，隐藏
    local noActive = activeIndex == 1
    if noActive then
        self.Normal.gameObject:SetActiveEx(false)
        self.Disable.gameObject:SetActiveEx(true)
    end
end

-------------------------------------#endregion XUiGridSuitSkill --------------------------------
