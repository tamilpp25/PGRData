local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
local XUiEquipAwarenessV2P6 = XLuaUiManager.Register(XLuaUi, "UiEquipAwarenessV2P6")

function XUiEquipAwarenessV2P6:OnAwake()
    -- 模型初始化
    self.PanelRoleModelGo = self.UiModelGo.transform:FindTransform("PanelRoleModel")
    self.ImgEffectHuanren = self.UiModelGo.transform:FindTransform("ImgEffectHuanren")
    self.ImgEffectHuanren1 = self.UiModelGo.transform:FindTransform("ImgEffectHuanren1")
    self.ImgEffectHuanren.gameObject:SetActive(false)
    self.ImgEffectHuanren1.gameObject:SetActive(false)
    self.UiPanelRoleModel = XUiPanelRoleModel.New(self.PanelRoleModelGo, self.Name, nil, true)

    -- 装备面板初始化
    self.PanelEquip = XMVCA:GetAgency(ModuleId.XEquip):InitPanelEquipV2P6(self.PanelEquip, self, self)
    self.PanelEquip:InitData()

    self:SetButtonCallBack()
    self:InitPanelAsset()
end

function XUiEquipAwarenessV2P6:OnStart(characterId)
    self.CharacterId = characterId
    self:RefreshModel(characterId)

    -- 由动画展开意识面板
    local anim = self.PanelEquip.PanelEquipEnable:GetComponent("PlayableDirector")
    anim.time = anim.duration
    anim:Play()
    self.PanelEquip.PanelAwareness.gameObject:SetActiveEx(true)

    -- 切换按钮不显示，不可点击
    local canvasGroup = self.PanelEquip.BtnFold:GetComponent("CanvasGroup")
    canvasGroup.alpha = 0
    canvasGroup.blocksRaycasts = false

    -- 刷新装备面板
    self.PanelEquip:Open()
    self.PanelEquip.IsShowPanelAwareness = true
    self.PanelEquip:UpdateCharacter(characterId)
    self.PanelEquip:InitUnFoldButton()
end

function XUiEquipAwarenessV2P6:OnEnable()
    self.PanelEquip:UpdateAwarenessView()
end

function XUiEquipAwarenessV2P6:OnDisable()
    self:ReleasePlayEffectTimer()
end

function XUiEquipAwarenessV2P6:SetButtonCallBack()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
end

function XUiEquipAwarenessV2P6:OnBtnBackClick()
    self:Close()
end

function XUiEquipAwarenessV2P6:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiEquipAwarenessV2P6:InitPanelAsset()
    self.AssetPanel = XUiPanelAsset.New(
        self,
        self.PanelAsset,
        XDataCenter.ItemManager.ItemId.FreeGem,
        XDataCenter.ItemManager.ItemId.ActionPoint,
        XDataCenter.ItemManager.ItemId.Coin
    )
end

-- 初始化武器模型
function XUiEquipAwarenessV2P6:RefreshModel(entityId)
    local finishedCallback = function(model)
        self.PanelDrag.Target = model.transform
        self:PlaySwitchEffect()
    end

    local entity = XDataCenter.CharacterManager.GetCharacter(entityId)
    local characterViewModel = entity:GetCharacterViewModel()
    local sourceEntityId = characterViewModel:GetSourceEntityId()
    
    if XRobotManager.CheckIsRobotId(sourceEntityId) then
        local robot2CharEntityId = XRobotManager.GetCharacterId(sourceEntityId)
        local isOwen = XDataCenter.CharacterManager.IsOwnCharacter(robot2CharEntityId)
        if XRobotManager.CheckUseFashion(sourceEntityId) and isOwen then
            local character = XDataCenter.CharacterManager.GetCharacter(robot2CharEntityId)
            local robot2CharViewModel = character:GetCharacterViewModel()
            self.UiPanelRoleModel:UpdateCharacterModel(robot2CharEntityId
            , self.PanelRoleModelGo
            , self.Name
            , finishedCallback
            , nil
            , robot2CharViewModel:GetFashionId())
        else
            local robotConfig = XRobotManager.GetRobotTemplate(sourceEntityId)
            self.UiPanelRoleModel:UpdateRobotModel(sourceEntityId
            , robotConfig.CharacterId
            , nil
            , robotConfig.FashionId
            , robotConfig.WeaponId
            , finishedCallback
            , nil
            , self.PanelRoleModelGo
            , self.Name)
        end
    else
        self.UiPanelRoleModel:UpdateCharacterModel(
        sourceEntityId,
        self.PanelRoleModelGo,
        self.Name,
        finishedCallback,
        nil,
        characterViewModel:GetFashionId()
        )
    end
end

-- 播放切换特效
function XUiEquipAwarenessV2P6:PlaySwitchEffect()
    -- 第一次打开界面延迟播特效
    local isFirst = not self.IsPlayed
    if isFirst then
        self:ReleasePlayEffectTimer()
        self.PlayEffectTimer = XScheduleManager.ScheduleOnce(function() 
            self.PlayEffectTimer = nil
            self:PlaySwitchEffect()
        end, 500)
        self.IsPlayed = true
        return
    end

    local characterType = XMVCA.XCharacter:GetCharacterType(self.CharacterId)
    if characterType == XCharacterConfigs.CharacterType.Normal then
        self.ImgEffectHuanren.gameObject:SetActive(true)
    else
        self.ImgEffectHuanren.gameObject:SetActive(false)
    end
end

function XUiEquipAwarenessV2P6:ReleasePlayEffectTimer()
    if self.PlayEffectTimer then
        XScheduleManager.UnSchedule(self.PlayEffectTimer)
        self.PlayEffectTimer = nil
    end
end

return XUiEquipAwarenessV2P6
