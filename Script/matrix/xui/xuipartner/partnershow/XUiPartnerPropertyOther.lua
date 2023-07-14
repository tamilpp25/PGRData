local XUiPanelPartnerOverview = require("XUi/XUiPartner/PartnerShow/XUiPanelPartnerOverview")
local XUiPanelPartnerPassiveSkill = require("XUi/XUiPartner/PartnerShow/XUiPanelPartnerPassiveSkill")
local XUiPartnerPropertyOther = XLuaUiManager.Register(XLuaUi, "UiPartnerPropertyOther")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

local LeftButtonType = {
    Overview = 1, -- 总览
-- Quality = 2, -- 品质
}

function XUiPartnerPropertyOther:OnAwake()
    -- XPartner
    self.Partner = nil
    -- XUiPanelRoleModel
    self.UiPanelRoleModel = nil
    -- 设置被动技能提示面板
    self.UiPanelPartnerPassiveSkill = XUiPanelPartnerPassiveSkill.New(self.PanelTips)
    -- 子面板信息配置
    self.ChillPanelInfoDic = {
        [LeftButtonType.Overview] = {
            uiParent = self.PanelPartnerOverview,
            -- 默认存在于界面中
            instanceGo = self.PanelPartnerOverview,
            proxy = XUiPanelPartnerOverview,
            -- 代理设置参数
            proxyArgs = {
                "Partner"
                , function(skill)
                    self.BtnHidePassiveSkill.gameObject:SetActiveEx(true)
                    self.UiPanelPartnerPassiveSkill:SetData(skill)
                end
            }
        },
    }
    self.CameraFarDic = nil
    self.CameraNearDic = nil
    -- XPartnerConfigs.CameraType
    self.PartnerStatus = nil
    self:RegisterUiEvents()
end

-- partner : XPartner
function XUiPartnerPropertyOther:OnStart(partner)
    self.Partner = partner
    self.PartnerStatus = XPartnerConfigs.CameraType.Standby
    -- 显示伙伴品质
    self.RImgQuality:SetRawImage(partner:GetCharacterQualityIcon())
    -- 伙伴等级
    self.TxtLevel.text = partner:GetLevel()
    -- 加载伙伴模型
    self:InitUiPanelRoleModel()
    self.BtnChangeRaycast.raycastTarget = false
    self.PanelDragRaycast.raycastTarget = false
    self:RefreshModel(self.PartnerStatus, function()
        self:PlayEnterAnim()
    end)
    -- -- 设置默认选中的左边按钮
    -- self.PanelLeftButtonGroup:SelectIndex(1)
    self:OnLeftButtonClicked(1)
end

function XUiPartnerPropertyOther:OnDisable()
    self.UiPanelRoleModel:HideAllEffects()
end

--########################## 私有方法 ##############################
function XUiPartnerPropertyOther:RegisterUiEvents()
    self.BtnBack.CallBack = function() self:Close() end
    self.BtnMainUi.CallBack = function() XLuaUiManager.RunMain() end
    self.BtnChange.CallBack = function() self:OnChangePartnerStatus() end
    self.BtnHidePassiveSkill.CallBack = function() self:OnBtnHidePassiveSkillClicked() end
    -- 注册按钮组
    -- self.PanelLeftButtonGroup:Init({
    --     [LeftButtonType.Overview] = self.BtnTabAll,
    --     [LeftButtonType.Quality] = self.BtnTabQuality,
    -- }, function(tabIndex) self:OnLeftButtonClicked(tabIndex) end, 1000)    
end

function XUiPartnerPropertyOther:OnBtnHidePassiveSkillClicked()
    self.BtnHidePassiveSkill.gameObject:SetActiveEx(false)
    self.UiPanelPartnerPassiveSkill:Close()
end

function XUiPartnerPropertyOther:OnLeftButtonClicked(tabIndex)
    -- 显示/隐藏关联子面板
    for key, data in pairs(self.ChillPanelInfoDic) do
        data.uiParent.gameObject:SetActiveEx(key == tabIndex)
    end
    local childPanelData = self.ChillPanelInfoDic[tabIndex]
    -- 加载panel asset
    local instanceGo = childPanelData.instanceGo
    if instanceGo == nil then
        instanceGo = childPanelData.uiParent:LoadPrefab(childPanelData.assetPath)
        childPanelData.instanceGo = instanceGo
    end
    -- 加载panel proxy
    local instanceProxy = childPanelData.instanceProxy
    if instanceProxy == nil then
        instanceProxy = childPanelData.proxy.New(instanceGo)
        childPanelData.instanceProxy = instanceProxy
    end
    -- 加载proxy参数
    local proxyArgs = {}
    if childPanelData.proxyArgs then
        for _, argName in ipairs(childPanelData.proxyArgs) do
            if type(argName) == "string" then
                proxyArgs[#proxyArgs + 1] = self[argName]
            else
                proxyArgs[#proxyArgs + 1] = argName
            end
        end
    end
    instanceProxy:SetData(table.unpack(proxyArgs))
end

function XUiPartnerPropertyOther:OnChangePartnerStatus(finishCallback, isAutoCloseMask, isCheckAnimExist)
    if isCheckAnimExist == nil then isCheckAnimExist = false end
    -- 检查动画切换动画是否存在，不存在直接不处理
    if isCheckAnimExist then
        local readyPlayAnim = nil
        if self.PartnerStatus == XPartnerConfigs.CameraType.Standby then
            readyPlayAnim = self:GetChangeAnim(XPartnerConfigs.CameraType.Combat)
        elseif self.PartnerStatus == XPartnerConfigs.CameraType.Combat then
            readyPlayAnim = self:GetChangeAnim(XPartnerConfigs.CameraType.Standby)
        end
        if not self.UiPanelRoleModel:CheckAnimaCanPlay(readyPlayAnim) then
            self:RecoverRaycastTargets()
            return
        end
    end
    if isAutoCloseMask == nil then isAutoCloseMask = true end
    if isAutoCloseMask then XLuaUiManager.SetMask(true) end
    -- 播放变身音效
    local voiceId = self:GetChangeVoice()
    if voiceId and voiceId > 0 then
        XSoundManager.PlaySoundByType(voiceId, XSoundManager.SoundType.Sound)
    end
    -- 更改状态
    if self.PartnerStatus == XPartnerConfigs.CameraType.Standby then
        self.PartnerStatus = XPartnerConfigs.CameraType.Combat
        self:SetCameraType(self.PartnerStatus)
        self.UiPanelRoleModel:LoopLoadEffect(self.Partner:GetSToCEffect(), true)
    elseif self.PartnerStatus == XPartnerConfigs.CameraType.Combat then
        self.PartnerStatus = XPartnerConfigs.CameraType.Standby
        self.UiPanelRoleModel:LoopLoadEffect(self:GetBornEffectPath(), true)
    end
    -- 动画无论成功还是失败的回调
    local callback = function()
        -- 变身状态特殊处理
        if self.PartnerStatus == XPartnerConfigs.CameraType.Combat then
            self:SetCameraType(self.PartnerStatus)
            self.UiPanelRoleModel:LoopLoadEffect(self:GetBornEffectPath(), true)
        else
            self.UiPanelRoleModel:LoopLoadEffect(self.Partner:GetStandbyBornEffect(), true)
        end
        -- 刷新模型
        self:RefreshModel(self.PartnerStatus, finishCallback)
        if isAutoCloseMask then
            XLuaUiManager.SetMask(false)
        end
    end
    -- 播放变身动画
    self.UiPanelRoleModel:PlayAnima(self:GetChangeAnim(), true, callback, callback)
end

-- 播放伙伴入场动画（盒子-牛-盒子）
function XUiPartnerPropertyOther:PlayEnterAnim()
    self:OnChangePartnerStatus(function()
        self:OnChangePartnerStatus(nil, nil, true)
        self:RecoverRaycastTargets()
    end, false, true)
end

function XUiPartnerPropertyOther:RecoverRaycastTargets()
    self.BtnChangeRaycast.raycastTarget = true
    self.PanelDragRaycast.raycastTarget = true
end

function XUiPartnerPropertyOther:GetChangeVoice(partnerStatus)
    partnerStatus = partnerStatus or self.PartnerStatus
    local voiceId = 0
    if partnerStatus == XPartnerConfigs.CameraType.Standby then
        voiceId = self.Partner:GetSToCVoice()
    elseif partnerStatus == XPartnerConfigs.CameraType.Combat then
        voiceId = self.Partner:GetCToSVoice()
    end
    return voiceId
end

function XUiPartnerPropertyOther:GetChangeAnim(partnerStatus)
    partnerStatus = partnerStatus or self.PartnerStatus
    local animName
    if partnerStatus == XPartnerConfigs.CameraType.Standby then
        animName = self.Partner:GetCToSAnime()
    elseif partnerStatus == XPartnerConfigs.CameraType.Combat then
        animName = self.Partner:GetSToCAnime()
    end
    return animName
end

function XUiPartnerPropertyOther:GetBornEffectPath(partnerStatus)
    partnerStatus = partnerStatus or self.PartnerStatus
    local effectPath
    if partnerStatus == XPartnerConfigs.CameraType.Standby then
        effectPath = self.Partner:GetCToSEffect()
    elseif partnerStatus == XPartnerConfigs.CameraType.Combat then
        effectPath = self.Partner:GetCombatBornEffect()
    end
    return effectPath
end

function XUiPartnerPropertyOther:GetBornAnim(partnerStatus)
    partnerStatus = partnerStatus or self.PartnerStatus
    local animName
    if partnerStatus == XPartnerConfigs.CameraType.Standby then
        animName = self.Partner:GetStandbyBornAnime()
    elseif partnerStatus == XPartnerConfigs.CameraType.Combat then
        animName = self.Partner:GetCombatBornAnime()
    end
    return animName
end

function XUiPartnerPropertyOther:GetModelId(partnerStatus)
    partnerStatus = partnerStatus or self.PartnerStatus
    local modelId
    if partnerStatus == XPartnerConfigs.CameraType.Standby then
        modelId = self.Partner:GetStandbyModel()
    elseif partnerStatus == XPartnerConfigs.CameraType.Combat then
        modelId = self.Partner:GetCombatModel()
    end
    return modelId
end

function XUiPartnerPropertyOther:InitUiPanelRoleModel()
    local root = self.UiModelGo.transform
    local panelRoleModel = root:FindTransform("PanelRoleModel")
    self.ImgEffectHuanren = root:FindTransform("ImgEffectHuanren")
    -- 初始化镜头信息
    self.CameraFarDic = {
        [XPartnerConfigs.CameraType.Standby] = root:FindTransform("UiCamFarStandby"),
        [XPartnerConfigs.CameraType.Combat] = root:FindTransform("UiCamFarCombat"),
    }
    self.CameraNearDic = {
        [XPartnerConfigs.CameraType.Standby] = root:FindTransform("UiCamNearStandby"),
        [XPartnerConfigs.CameraType.Combat] = root:FindTransform("UiCamNearCombat"),
    }
    -- self.Name 参数看起来只是在武器那边做了一个键标记
    self.UiPanelRoleModel = XUiPanelRoleModel.New(panelRoleModel, self.Name, nil, true, nil, true)
    self.UiPanelRoleModel:SetEffectMaxCount(2)
end

function XUiPartnerPropertyOther:RefreshModel(partnerStatus, bornAnimCallback)
    partnerStatus = partnerStatus or self.PartnerStatus
    local modelId = self:GetModelId(partnerStatus)
    self.ImgEffectHuanren.gameObject:SetActiveEx(false)
    -- 参数2是UiModelTansform的配置表的键，用来设置模型的一些旋转，大小之类的，这里用回UiPartnerMain默认的
    self.UiPanelRoleModel:UpdatePartnerModel(modelId, XModelManager.MODEL_UINAME.XUiPartnerMain, nil, function(model)
        self.ImgEffectHuanren.gameObject:SetActiveEx(true)
        self.PanelDrag.Target = model.transform
        self.UiPanelRoleModel:PlayAnima(self:GetBornAnim(), true, bornAnimCallback, bornAnimCallback)
    end, false, true)
    self:SetCameraType(partnerStatus)
end

function XUiPartnerPropertyOther:SetCameraType(partnerStatus)
    for k, _ in pairs(self.CameraFarDic) do
        self.CameraFarDic[k].gameObject:SetActiveEx(k == partnerStatus)
    end
    for k, _ in pairs(self.CameraNearDic) do
        self.CameraNearDic[k].gameObject:SetActiveEx(k == partnerStatus)
    end
end