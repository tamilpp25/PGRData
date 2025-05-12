local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiGridEquipGuide = require("XUi/XUiEquipGuide/XUiGridEquipGuide")

local XUiGridEquipChip = XClass(nil, "XUiGridEquipChip")

function XUiGridEquipChip:Ctor(characterId, target)
    self.CharacterId = characterId
    self.Target = target
end

function XUiGridEquipChip:Init()
    self.EquipGrid = XUiGridEquipGuide.New(self.GridEquip)
    self.EquipGrid:SetClickCb(handler(self, self.OnBtnClickClicked))
    self:AddListener()
end

function XUiGridEquipChip:AddListener()
    self.BtnObtain.CallBack = function() self:OnBtnObtainClick() end
    self.BtnWear.CallBack = function() self:OnBtnWearClick() end
    self.BtnCulture.CallBack = function() self:OnBtnCultureClick() end
end

function XUiGridEquipChip:Refresh(data)
    self.EquipModel = data
    self.EquipGrid:RefreshEquip(data)
    self.BtnCulture.gameObject:SetActiveEx(false)
    self.BtnObtain.gameObject:SetActiveEx(false)
    self.BtnWear.gameObject:SetActiveEx(false)

    local isWearTemplateIdEquip = data:IsWearTemplateIdEquip()
    local isMaxLvAndBreak = data:IsMaxLevelAndBreakthrough()
    -- 培养（拥有且穿戴）
    if isWearTemplateIdEquip then
        self.BtnCulture.gameObject:SetActiveEx(true)
        self.BtnCulture:SetDisable(isMaxLvAndBreak, not isMaxLvAndBreak)
    -- 穿戴（拥有但未穿戴）
    elseif data:IsExistEquip() then
        self.BtnWear.gameObject:SetActiveEx(true)
    -- 获取（未拥有）
    else
        self.BtnObtain.gameObject:SetActiveEx(true)
    end
end

function XUiGridEquipChip:OnBtnClickClicked()
    local type = self.EquipModel:GetProperty("_EquipType")
    local pos = type == XArrangeConfigs.Types.Weapon 
            and self.GridEquip.transform.anchoredPosition
            or self.Transform.anchoredPosition
    XLuaUiManager.Open("UiEquipGuideTipsPopup", self.EquipModel, self.CharacterId, pos)
end

function XUiGridEquipChip:OnBtnObtainClick()
    local templateId = self.EquipModel:GetProperty("_TemplateId")
    if not XTool.IsNumberValid(templateId) then
        return
    end
    local targetId = self.Target:GetProperty("_Id")
    local characterId = self.CharacterId
    local skipCb = function()
        local isWeapon = XMVCA.XEquip:IsEquipWeapon(templateId)
        local skipScene = isWeapon and XEquipGuideConfigs.SkipScene.WeaponAcquireScene or XEquipGuideConfigs.SkipScene.ChipAcquireScene
        XDataCenter.EquipGuideManager.RecordSkipEvent(characterId, targetId, templateId, XEquipGuideConfigs.SkipType.Acquire, skipScene)
    end
    local data = XEquipGuideConfigs.GeneratorEquipSkipData(templateId, skipCb)
    XLuaUiManager.Open("UiEquipStrengthenSkip", data)
end

function XUiGridEquipChip:OnBtnWearClick()
    local equip = self.EquipModel:GetBestOneEquip()
    if not equip then
        self:OnBtnObtainClick()
        return
    end
    XMVCA:GetAgency(ModuleId.XEquip):PutOn(self.CharacterId, equip.Id)
end

function XUiGridEquipChip:OnBtnCultureClick()
    local equip = self.EquipModel:GetWearEquip()
    if not equip then
        return
    end
    local targetId = self.Target:GetProperty("_Id")
    local isWeapon = equip:IsWeapon()
    local skipScene = isWeapon and XEquipGuideConfigs.SkipScene.WeaponCultureScene or XEquipGuideConfigs.SkipScene.ChipCultureScene
    XDataCenter.EquipGuideManager.RecordSkipEvent(self.CharacterId, targetId, equip.TemplateId, XEquipGuideConfigs.SkipType.Culture, skipScene)
    XMVCA:GetAgency(ModuleId.XEquip):OpenUiEquipDetail(equip.Id, nil, self.CharacterId)
end


local XUiEquipGuideDetail = XLuaUiManager.Register(XLuaUi, "UiEquipGuideDetail")

function XUiEquipGuideDetail:OnAwake()
    self:InitCb()
end 

function XUiEquipGuideDetail:OnStart(target)
    self.Target = target
    --self.Target:RefreshEquip()
    self.GirdItems = {}
    local recommendId = target:GetProperty("_RecommendId")
    self.Recommend = XMVCA.XEquip:GetCharDetailEquipTemplate(recommendId)
    self.CharacterId = self.Target:GetProperty("_CharacterId")
    self:InitView()
end 

function XUiEquipGuideDetail:OnEnable()
    self.Target:RefreshEquip()
    self:UpdateView()
end

function XUiEquipGuideDetail:InitCb()
    self:BindExitBtns()
    self:BindHelpBtn()
    
    self.BtnDelete.CallBack = function() 
        local content = XUiHelper.GetText("EquipGuideCancelTargetTips", XMVCA.XCharacter:GetCharacterLogName(self.CharacterId))
        XUiManager.DialogTip(XUiHelper.GetText("TipTitle"), content, nil, nil, function()
            XDataCenter.EquipGuideManager.EquipGuideSetTargetRequest(0, {}, function()
                self:Close()
                XDataCenter.EquipGuideManager.OpenEquipGuideView(self.CharacterId)
            end)
        end)
    end
    
    self.BtnSwitch.CallBack = function()
        XLuaUiManager.Open("UiEquipGuideRecommend", XDataCenter.EquipGuideManager.GetEquipGuide(self.CharacterId))
    end
end

function XUiEquipGuideDetail:InitView()
    --资产
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset
    , XDataCenter.ItemManager.ItemId.FreeGem
    , XDataCenter.ItemManager.ItemId.ActionPoint
    , XDataCenter.ItemManager.ItemId.Coin)
    local targetId = self.Target:GetProperty("_Id")
    --角色立绘
    self.IconRole:SetRawImage(XMVCA.XCharacter:GetCharHalfBodyBigImage(self.CharacterId))
    --目标描述
    self.TxtName.text = XEquipGuideConfigs.TargetConfig:GetProperty(targetId, "Description")
end 

function XUiEquipGuideDetail:UpdateView()
    local target = self.Target
    
    --进度
    self:BindViewModelPropertyToObj(target, function(progress) 
        self.TxtTaskNumQian.text = string.format("%s%%", math.floor(progress * 100))
        self.ImgProgress.fillAmount = progress
    end, "_Progress")

    --意识
    self:BindViewModelPropertyToObj(
            target,
            function(chipData)
                self:RefreshTemplateGrids(self.Equip, chipData, self.PanelEquip, function()
                    return XUiGridEquipChip.New(self.CharacterId, target)
                end, "GridChips")
            end,
            "_ChipModelList"
    )
    --武器
    self:BindViewModelPropertyToObj(
            target,
            function(weaponData)
                self:RefreshTemplateGrids({ self.Weapon }, { weaponData }, nil, function()
                            return XUiGridEquipChip.New(self.CharacterId, target)
                        end, "GridWeapon")
            end,
            "_WeaponModel"
    )
    --目标达成情况
    --self:BindViewModelPropertyToObj(
    --        target,
    --        function(finish) 
    --            self.BtnDelete.gameObject:SetActiveEx(not finish)
    --            self.BtnSwitch.gameObject:SetActiveEx(not finish)
    --        end,
    --        "_IsFinish"
    --)
    
    self:OnCheckHasStrongerWeapon(false)
    local state = XDataCenter.EquipGuideManager.CheckHasStrongerWeapon()
    self:OnCheckHasStrongerWeapon(state)
end

function XUiEquipGuideDetail:OnCheckHasStrongerWeapon(state)
    self.BtnSwitch:ShowReddot(state)
    self.BtnSwitch:ShowTag(state)
    if state then
        self:PlayAnimation("Panel6StarEnable", function()
        end)
    end
end 