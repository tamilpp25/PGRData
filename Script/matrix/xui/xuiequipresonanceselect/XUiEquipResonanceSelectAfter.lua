local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiEquipResonanceSelectAfter = XLuaUiManager.Register(XLuaUi, "UiEquipResonanceSelectAfter")

function XUiEquipResonanceSelectAfter:OnAwake()
    self:RegisterUiEvents()
    local sceneRootTrans = self.UiModelGo
    self.PanelWeapon = sceneRootTrans:FindTransform("PanelWeapon")
    self.EffectAwakeGo = sceneRootTrans:FindTransform("EffectAwakeGo")
end

function XUiEquipResonanceSelectAfter:OnStart(equipId, pos, characterId, isAwakeDes, forceShowBindCharacter, callback)
    self.CharacterId = characterId
    self.EquipId = equipId
    self.Pos = pos
    self.IsAwakeDes = isAwakeDes
    self.ForceShowBindCharacter = forceShowBindCharacter
    self.Callback = callback

    local equip = self._Control:GetEquip(equipId)
    self.TemplateId = equip.TemplateId
    self.IsWeapon = equip:IsWeapon()
    self.ShowQuickResonance = self:IsShowQuickResonance() -- 是否显示快速共鸣面板
    if self.ShowQuickResonance then
        self.TokenInfoDic = self._Control:GetResonanceTokenInfoDic(self.TemplateId)
    end

    self:InitModel()
end

function XUiEquipResonanceSelectAfter:OnEnable()
    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.UiEquip_ResonanceSelectAfter)
    self:Refresh()
end

function XUiEquipResonanceSelectAfter:OnDisable()
end

function XUiEquipResonanceSelectAfter:OnDestroy()
    self:RemoveWeaponTimer()
    self:ReleaseLihuiModel()
    self:ReleaseLihuiTimer()
end

function XUiEquipResonanceSelectAfter:OnGetEvents()
    return { XEventId.EVENT_EQUIP_RESONANCE_NOTYFY }
end

function XUiEquipResonanceSelectAfter:OnNotify(evt, ...)
    if evt == XEventId.EVENT_EQUIP_RESONANCE_NOTYFY then
        self:Refresh()
    end
end

-- 初始化武器模型/意识立绘
function XUiEquipResonanceSelectAfter:InitModel()
    self.FxUiLihuiChuxian01.gameObject:SetActiveEx(false)
    self.PanelWeapon.gameObject:SetActiveEx(false)

    local equip = self._Control:GetEquip(self.EquipId)
    if equip:IsWeapon() then
        self.PanelWeapon.gameObject:SetActiveEx(true)
        local modelConfig = XMVCA.XEquip:GetWeaponModelCfgByEquipId(self.EquipId, self.Name)
        self.EffectAwakeGo.gameObject:SetActiveEx(false)
        self:RemoveWeaponTimer()
        if modelConfig then
            XModelManager.LoadWeaponModel(modelConfig.ModelId, self.PanelWeapon, modelConfig.TransformConfig, self.Name, function(model)
                -- 延时显示模型
                local delay = CS.XGame.ClientConfig:GetInt("WeaponResonanceShowDelay")
                if delay ~= 0 then
                    model:SetActiveEx(false)
                    self.ScheduleIdModel = XScheduleManager.ScheduleOnce(function()
                        model:SetActiveEx(true)
                        XModelManager.PlayWeaponShowing(model, modelConfig.ModelId, self.Name, self.GameObject, { usage = XEnumConst.EQUIP.WEAPON_USAGE.SHOW })
                        XModelManager.AutoRotateWeapon(self.PanelWeapon, model, modelConfig.ModelId, self.GameObject)
                    end, delay)
                else
                    XModelManager.PlayWeaponShowing(model, modelConfig.ModelId, self.Name, self.GameObject, { usage = XEnumConst.EQUIP.WEAPON_USAGE.SHOW })
                    XModelManager.AutoRotateWeapon(self.PanelWeapon, model, modelConfig.ModelId, self.GameObject)
                end

                -- 延时ui特效
                local resonanceCount = XMVCA.XEquip:GetEquipResonanceCount(self.EquipId)
                local effectDelay = XMVCA.XEquip:GetWeaponResonanceEffectDelayByEquipId(self.EquipId, resonanceCount)
                if effectDelay then
                    self.ScheduleIdEffect = XScheduleManager.ScheduleOnce(function()
                        self.EffectAwakeGo.gameObject:SetActiveEx(true)
                    end, effectDelay)
                end
            end, { noShowing = true, gameObject = self.GameObject, noRotation = true })
        end
    elseif equip:IsAwareness() then
        self:ReleaseLihuiModel()
        self:ReleaseLihuiTimer()

        local resPath = XMVCA.XEquip:GetEquipLiHuiPath(equip.TemplateId, equip.Breakthrough)
        self.Loader = self.Loader or self.Transform:GetLoader()
        local texture = self.Loader:Load(resPath)
        
        self.MeshLihui.sharedMaterial:SetTexture("_MainTex", texture)
        self.LihuiTimer = XScheduleManager.ScheduleOnce(function()
            self.FxUiLihuiChuxian01.gameObject:SetActiveEx(true)
        end, 500)
    end
end

-- 释放武器定时器
function XUiEquipResonanceSelectAfter:RemoveWeaponTimer()
    if self.ScheduleIdModel then
        XScheduleManager.UnSchedule(self.ScheduleIdModel)
        self.ScheduleIdModel = nil
    end
    if self.ScheduleIdEffect then
        XScheduleManager.UnSchedule(self.ScheduleIdEffect)
        self.ScheduleIdEffect = nil
    end
end

-- 释放立绘模型
function XUiEquipResonanceSelectAfter:ReleaseLihuiModel()
    
end

-- 释放立绘定时器
function XUiEquipResonanceSelectAfter:ReleaseLihuiTimer()
    if self.LihuiTimer then
        XScheduleManager.UnSchedule(self.LihuiTimer)
        self.LihuiTimer = nil
    end
end

function XUiEquipResonanceSelectAfter:Refresh()
    self:UpdateResonanceSkills()
    self:RefreshPanelCost()
end

function XUiEquipResonanceSelectAfter:UpdateResonanceSkills()
    local equip = self._Control:GetEquip(self.EquipId)
    local unConfirmInfo = equip:GetResonanceUnConfirmInfo(self.Pos) -- 未确认的共鸣信息

    -- 左边共鸣技能
    self.PanelSlotOld.gameObject:SetActiveEx(unConfirmInfo ~= nil)
    if unConfirmInfo then
        if not self.ResonanceSkillGridOld then
            local XUiGridResonanceSkill = require("XUi/XUiEquipResonanceSkill/XUiGridResonanceSkill")
            self.ResonanceSkillGridOld = XUiGridResonanceSkill.New(self.GridResonanceSkillOld, self.EquipId, self.Pos, self.CharacterId, nil, self.IsAwakeDes, 
                self.ForceShowBindCharacter)
        end
        self.ResonanceSkillGridOld:Refresh()
        self.TxtSlot.text = XUiHelper.GetText("EquipResonancePosText", self.Pos)
    end

    -- 右边共鸣技能
    if not self.ResonanceSkillGridNew then
        local XUiGridResonanceSkill = require("XUi/XUiEquipResonanceSkill/XUiGridResonanceSkill")
        self.ResonanceSkillGridNew = XUiGridResonanceSkill.New(self.GridResonanceSkillNew, self.EquipId, self.Pos, self.CharacterId, nil, self.IsAwakeDes, 
            self.ForceShowBindCharacter)
    end
    if unConfirmInfo then
        local skillInfo = equip:GetResonanceUnConfirmSkillInfo(self.Pos)
        self.ResonanceSkillGridNew:Refresh(skillInfo, unConfirmInfo.CharacterId)
    else
        self.ResonanceSkillGridNew:Refresh()
    end
    self.ImgNewTag.gameObject:SetActiveEx(not self.IsAwakeDes)

    -- 按钮
    self.BtnConfirm.gameObject:SetActiveEx(false)
    self.BtnRemain.gameObject:SetActiveEx(false)
    self.BtnChange.gameObject:SetActiveEx(false)
    self.BtnContinue.gameObject:SetActiveEx(false)
    self.BtnChangeAndEnd.gameObject:SetActiveEx(false)
    if unConfirmInfo then
        if self.ShowQuickResonance then
            self.BtnContinue.gameObject:SetActiveEx(true)
            self.BtnChangeAndEnd.gameObject:SetActiveEx(true)
        else
            self.BtnRemain.gameObject:SetActiveEx(true)
            self.BtnChange.gameObject:SetActiveEx(true)
        end
    else
        if self.ShowQuickResonance then
            self.BtnContinue.gameObject:SetActiveEx(true)
            self.BtnConfirm.gameObject:SetActiveEx(true)
        else
            self.BtnConfirm.gameObject:SetActiveEx(true)
        end
    end

    -- 播放动画
    self:PlayAnimation("ContianerEnable")
end

function XUiEquipResonanceSelectAfter:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnConfirm, self.CloseUi)
    self:RegisterClickEvent(self.BtnRemain, self.OnBtnRemainClick)
    self:RegisterClickEvent(self.BtnChange, self.OnBtnChangeClick)
    self:RegisterClickEvent(self.BtnContinue, self.OnBtnContinueClick)
    self:RegisterClickEvent(self.BtnChangeAndEnd, self.OnBtnChangeClick)
    self:RegisterClickEvent(self.BtnSelectCost, self.OnBtnSelectCostClick)

end

-- 关闭UI界面
function XUiEquipResonanceSelectAfter:CloseUi()
    if self.Callback then
        self.Callback()
    end
    self:Close()
end

-- 退出界面，有未确认共鸣技能视为保留原结果
function XUiEquipResonanceSelectAfter:OnBtnBackClick()
    local equip = self._Control:GetEquip(self.EquipId)
    local unconfirmInfo = equip:GetResonanceUnConfirmInfo(self.Pos)
    if unconfirmInfo then
        local tipsTitle = XUiHelper.GetText("EquipResonancePreciousTipTitle")
        local tipsContent = XUiHelper.GetText("ResonanceBackTips")
        XUiManager.DialogTip(tipsTitle, tipsContent, XUiManager.DialogType.Normal, nil, function()
            self:OnBtnRemainClick()
        end)
    else
        self:CloseUi()
    end
end

function XUiEquipResonanceSelectAfter:OnBtnRemainClick()
    XMVCA:GetAgency(ModuleId.XEquip):ResonanceConfirm(self.EquipId, self.Pos, false, function()
        self:CloseUi()
    end)
end

function XUiEquipResonanceSelectAfter:OnBtnChangeClick()
    XMVCA:GetAgency(ModuleId.XEquip):ResonanceConfirm(self.EquipId, self.Pos, true, function()
        self:CloseUi()
    end)
end

function XUiEquipResonanceSelectAfter:OnBtnContinueClick()
    local equip = self._Control:GetEquip(self.EquipId)
    local unconfirmInfo = equip:GetResonanceUnConfirmInfo(self.Pos)

    -- 展示第一个意识，打开意识列表进行选择确认
    if self.IsShowFirstAwareness then
        XLuaUiManager.Open("UiEquipResonanceSelectEquipV2P6", self.EquipId, function(selectEquipId, selectItemId)
            self:RequestResonance(selectEquipId, selectItemId)
        end, true, true)

    -- 选中意识/道具
    elseif self.SelectEquipId or self.SelectItemId then
        self:RequestResonance(self.SelectEquipId, self.SelectItemId)
    -- 未选中
    else
        XLuaUiManager.Open("UiEquipResonanceSelectEquipV2P6", self.EquipId, function(selectEquipId, selectItemId)
            self:RequestResonance(selectEquipId, selectItemId)
        end, false, true)
    end
end

-- 请求共鸣
function XUiEquipResonanceSelectAfter:RequestResonance(selectEquipId, selectItemId)
    local equip = self._Control:GetEquip(self.EquipId)
    local unconfirmInfo = equip:GetResonanceUnConfirmInfo(self.Pos)
    local resonanceInfo = equip:GetResonanceInfo(self.Pos)
    local selectCharacterId = unconfirmInfo and unconfirmInfo.CharacterId or resonanceInfo.CharacterId

    -- 保留旧共鸣结果
    if unconfirmInfo then
        XMVCA:GetAgency(ModuleId.XEquip):ResonanceConfirm(self.EquipId, self.Pos, false)
    end

    -- 请求共鸣
    XMVCA:GetAgency(ModuleId.XEquip):RequestEquipResonance(self.EquipId, {self.Pos}, selectCharacterId, selectEquipId, selectItemId, {}, nil, true)
end

function XUiEquipResonanceSelectAfter:OnBtnSelectCostClick()
    XLuaUiManager.Open("UiEquipResonanceSelectEquipV2P6", self.EquipId, function(selectEquipId, selectItemId)
        if selectItemId then
            self:RefreshCostItem(selectItemId)
        elseif selectEquipId then
            self:RefreshCostAwareness(selectEquipId, false)
        end
    end, false, true)
end

function XUiEquipResonanceSelectAfter:RefreshPanelCost()
    self.PanelCost.gameObject:SetActiveEx(self.ShowQuickResonance)
    if not self.ShowQuickResonance then
        return
    end

    local equip = self._Control:GetEquip(self.EquipId)
    local resonanceInfo = equip:GetResonanceUnConfirmInfo(self.Pos) or equip:GetResonanceInfo(self.Pos)
    if resonanceInfo.IsUseEquip then
        local awarenessIdList = self._Control:GetAwarenessResonanceCanEatEquipIds(self.EquipId)
        if #awarenessIdList > 0 then
            local equipId = awarenessIdList[1] -- 拿第一个意识刷新
            self:RefreshCostAwareness(equipId, true)
            self.IsShowFirstAwareness = true -- 显示可消耗的第一个意识装备
        else
            self:RefreshCostEmpty()
        end
    elseif resonanceInfo.UseItemId and self.TokenInfoDic[resonanceInfo.UseItemId] then
        local costCnt = self.TokenInfoDic[resonanceInfo.UseItemId].CostCnt
        local ownCnt = XDataCenter.ItemManager.GetCount(resonanceInfo.UseItemId)
        if ownCnt >= costCnt then
            self:RefreshCostItem(resonanceInfo.UseItemId)
        else
            self:RefreshCostEmpty()
        end
    else
        self:RefreshCostEmpty()
    end
end

-- 刷新意识装备
function XUiEquipResonanceSelectAfter:RefreshCostAwareness(equipId, isFirst)
    self.GridEmpty.gameObject:SetActiveEx(false)
    self.GridCostItem.gameObject:SetActiveEx(true)
    self.SelectEquipId = isFirst and nil or equipId
    self.SelectItemId = nil
    self.IsShowFirstAwareness = isFirst

    -- 刷新装备UI
    if not self.UiGridEquip then
        local XUiGridEquip = require("XUi/XUiEquip/XUiGridEquip")
        self.UiGridEquip = XUiGridEquip.New(self.GridCostItem, self)
    end
    self.UiGridEquip:Refresh(equipId)

    self.GridCostItem:GetObject("TxtHaveCount").text = ""
    self.GridCostItem:GetObject("TxtNeedCount").text = ""
end

-- 刷新消耗为道具
function XUiEquipResonanceSelectAfter:RefreshCostItem(itemId)
    self.GridEmpty.gameObject:SetActiveEx(false)
    self.GridCostItem.gameObject:SetActiveEx(true)
    self.SelectEquipId = nil
    self.SelectItemId = itemId
    self.IsShowFirstAwareness = false

    -- 刷新道具UI
    if not self.UiGridCommon then
        self.UiGridCommon = XUiGridCommon.New(self, self.GridCostItem)
    end
    self.UiGridCommon:Refresh(itemId)

    -- 刷新拥有和消耗数量
    local ownCnt = XDataCenter.ItemManager.GetCount(itemId)
    local costCnt = self.TokenInfoDic[itemId].CostCnt
    self.GridCostItem:GetObject("TxtHaveCount").text = tostring(ownCnt)
    self.GridCostItem:GetObject("TxtNeedCount").text = "/" .. tostring(costCnt)
end

-- 刷新消耗为空
function XUiEquipResonanceSelectAfter:RefreshCostEmpty()
    self.GridEmpty.gameObject:SetActiveEx(true)
    self.GridCostItem.gameObject:SetActiveEx(false)
    self.SelectEquipId = nil
    self.SelectItemId = nil
    self.IsShowFirstAwareness = false
end

-- 是否显示快速共鸣功能
function XUiEquipResonanceSelectAfter:IsShowQuickResonance()
    if self.IsWeapon then
        return
    end

    -- 未配置代币，不显示快速共鸣
    local isShowToken = self._Control:IsResonanceShowToken(self.TemplateId)
    if not isShowToken then
        return false
    end

    -- 选定技能共鸣，不是随机技能共鸣，不显示快速共鸣
    local equip = self._Control:GetEquip(self.EquipId)
    local info = equip:GetResonanceUnConfirmInfo(self.Pos) or equip:GetResonanceInfo(self.Pos)
    if info.UseItemId then
        local config = self._Control:GetEquipResonanceUseItem(self.TemplateId)
        for _, itemId in ipairs(config.SelectSkillItemId) do
            if itemId == info.UseItemId then
                return false
            end
        end
    end

    return true
end

return XUiEquipResonanceSelectAfter