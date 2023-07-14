local XUiGridResonanceSkill = require("XUi/XUiEquipResonanceSkill/XUiGridResonanceSkill")
local XUiEquipResonanceSelectAfter = XLuaUiManager.Register(XLuaUi, "UiEquipResonanceSelectAfter")

function XUiEquipResonanceSelectAfter:OnAwake()
    self:InitAutoScript()
    local sceneRootTrans = self.UiModelGo
    self.PanelWeapon = sceneRootTrans:FindTransform("PanelWeapon")
    self.EffectAwakeGo = sceneRootTrans:FindTransform("EffectAwakeGo").gameObject
end

function XUiEquipResonanceSelectAfter:OnStart(equipId, pos, characterId, isAwakeDes, forceShowBindCharacter)
    self.CharacterId = characterId
    self.EquipId = equipId
    self.Pos = pos
    self.IsAwakeDes = isAwakeDes
    self.ForceShowBindCharacter = forceShowBindCharacter

    self:InitClassifyPanel()
end

function XUiEquipResonanceSelectAfter:OnEnable()
    CS.XAudioManager.PlaySound(XSoundManager.UiBasicsMusic.UiEquip_ResonanceSelectAfter)
    self:UpdateResonanceSkillGrids()
end

function XUiEquipResonanceSelectAfter:OnDisable()
    self:RemoveWeaponTimer()
end

function XUiEquipResonanceSelectAfter:OnDestroy()
    if self.Resource then
        CS.XResourceManager.Unload(self.Resource)
        self.Resource = nil
    end
    self:RemoveWeaponTimer()
end

function XUiEquipResonanceSelectAfter:OnGetEvents()
    return { XEventId.EVENT_EQUIP_RESONANCE_ACK_NOTYFY }
end

function XUiEquipResonanceSelectAfter:OnNotify(evt, ...)
    local args = { ... }
    local equipId = args[1]
    if equipId ~= self.EquipId then return end

    if evt == XEventId.EVENT_EQUIP_RESONANCE_ACK_NOTYFY then
        self:Close()
    end
end

function XUiEquipResonanceSelectAfter:InitClassifyPanel()
    self.FxUiLihuiChuxian01.gameObject:SetActiveEx(false)
    if XDataCenter.EquipManager.IsClassifyEqual(self.EquipId, XEquipConfig.Classify.Weapon) then
        local modelConfig = XDataCenter.EquipManager.GetWeaponModelCfgByEquipId(self.EquipId, self.Name)
        self.EffectAwakeGo.gameObject:SetActiveEx(false)
        self:RemoveWeaponTimer()
        if modelConfig then
            XModelManager.LoadWeaponModel(modelConfig.ModelId, self.PanelWeapon, modelConfig.TransformConfig, self.Name, function(model)
                -- 延时显示模型
                local delay = XEquipConfig.WeaponResonanceShowDelay
                if delay ~= 0 then
                    model:SetActiveEx(false)
                    self.scheduleIdModel = XScheduleManager.ScheduleOnce(function()
                        model:SetActiveEx(true)
                        XModelManager.PlayWeaponShowing(model, modelConfig.ModelId, self.Name, self.GameObject, { usage = XEquipConfig.WeaponUsage.Show })
                        XModelManager.AutoRotateWeapon(self.PanelWeapon, model, modelConfig.ModelId, self.GameObject)
                    end, delay)
                else
                    XModelManager.PlayWeaponShowing(model, modelConfig.ModelId, self.Name, self.GameObject, { usage = XEquipConfig.WeaponUsage.Show })
                    XModelManager.AutoRotateWeapon(self.PanelWeapon, model, modelConfig.ModelId, self.GameObject)
                end

                -- 延时ui特效
                local resonanceCount = XDataCenter.EquipManager.GetResonanceCount(self.EquipId)
                local effectDelay = XDataCenter.EquipManager.GetWeaponResonanceEffectDelay(self.EquipId, resonanceCount)
                if effectDelay then
                    self.scheduleIdEffect = XScheduleManager.ScheduleOnce(function()
                        self.EffectAwakeGo:SetActiveEx(true)
                    end, effectDelay)
                end
            end, { noShowing = true, gameObject = self.GameObject, noRotation = true })
        end
        self.PanelWeapon.gameObject:SetActiveEx(true)
        self.PanelAwareness.gameObject:SetActiveEx(false)
    elseif XDataCenter.EquipManager.IsClassifyEqual(self.EquipId, XEquipConfig.Classify.Awareness) then
        local equip = XDataCenter.EquipManager.GetEquip(self.EquipId)
        local resource = CS.XResourceManager.Load(XDataCenter.EquipManager.GetEquipLiHuiPath(equip.TemplateId, equip.Breakthrough))
        local texture = resource.Asset
        self.MeshLihui.sharedMaterial:SetTexture("_MainTex", texture)
        if self.Resource then
            CS.XResourceManager.Unload(self.Resource)
        end
        self.Resource = resource
        XScheduleManager.ScheduleOnce(function()
            if XTool.UObjIsNil(self.FxUiLihuiChuxian01) then return end
            self.FxUiLihuiChuxian01.gameObject:SetActiveEx(true)
        end, 500)

        self.PanelAwareness.gameObject:SetActiveEx(true)
        self.PanelWeapon.gameObject:SetActiveEx(false)
    end
end

function XUiEquipResonanceSelectAfter:RemoveWeaponTimer()
    if self.scheduleIdModel then
        XScheduleManager.UnSchedule(self.scheduleIdModel)
        self.scheduleIdModel = nil
    end
    if self.scheduleIdEffect then
        XScheduleManager.UnSchedule(self.scheduleIdEffect)
        self.scheduleIdEffect = nil
    end
end

function XUiEquipResonanceSelectAfter:UpdateResonanceSkillGrids()
    local isAwakeDes = self.IsAwakeDes
    local characterId = self.CharacterId
    local forceShowBindCharacter = self.ForceShowBindCharacter

    self.ImgNewTag.gameObject:SetActiveEx(not isAwakeDes)
    self.TxtSlot.text = CS.XTextManager.GetText("EquipResonancePosText", self.Pos)

    self.ResonanceSkillGridOld = self.ResonanceSkillGridOld or XUiGridResonanceSkill.New(self.GridResonanceSkill, self.EquipId, self.Pos, characterId, nil, isAwakeDes, forceShowBindCharacter)
    self.ResonanceSkillGridNew = self.ResonanceSkillGridNew or XUiGridResonanceSkill.New(self.GridResonanceSkillA, self.EquipId, self.Pos, characterId, nil, isAwakeDes, forceShowBindCharacter)

    local unconfirmedSkillInfo = XDataCenter.EquipManager.GetUnconfirmedResonanceSkillInfo(self.EquipId, self.Pos)
    local bindCharacterId = XDataCenter.EquipManager.GetUnconfirmedResonanceBindCharacterId(self.EquipId, self.Pos)

    if not XDataCenter.EquipManager.CheckEquipPosUnconfirmedResonanced(self.EquipId, self.Pos) then
        self.ResonanceSkillGridNew:Refresh()
        self.BtnConfirm.gameObject:SetActiveEx(true)
        self.BtnChange.gameObject:SetActiveEx(false)
        self.PanelSlotOld.gameObject:SetActiveEx(false)
        self:PlayAnimation("RImgLihui")
    else
        self.ResonanceSkillGridOld:Refresh()
        self.ResonanceSkillGridNew:Refresh(unconfirmedSkillInfo, bindCharacterId)

        self.BtnConfirm.gameObject:SetActiveEx(false)
        self.BtnChange.gameObject:SetActiveEx(true)
        self.PanelSlotOld.gameObject:SetActiveEx(true)
        self:PlayAnimation("ContianerEnable")
    end
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiEquipResonanceSelectAfter:InitAutoScript()
    self:AutoInitUi()
    self:AutoAddListener()
end

function XUiEquipResonanceSelectAfter:AutoInitUi()
    self.PanelSlotNew = self.Transform:Find("SafeAreaContentPane/Contianer/Layout/PanelSlotNew")
    self.GridResonanceSkillA = self.Transform:Find("SafeAreaContentPane/Contianer/Layout/PanelSlotNew/GridResonanceSkill")
    self.RImgResonanceSkillA = self.Transform:Find("SafeAreaContentPane/Contianer/Layout/PanelSlotNew/GridResonanceSkill/RImgResonanceSkill"):GetComponent("RawImage")
    self.BtnChange = self.Transform:Find("SafeAreaContentPane/Contianer/Layout/PanelSlotNew/BtnChange"):GetComponent("Button")
    self.BtnConfirm = self.Transform:Find("SafeAreaContentPane/Contianer/Layout/PanelSlotNew/BtnConfirm"):GetComponent("Button")
    self.PanelSlotOld = self.Transform:Find("SafeAreaContentPane/Contianer/Layout/PanelSlotOld")
    self.GridResonanceSkill = self.Transform:Find("SafeAreaContentPane/Contianer/Layout/PanelSlotOld/GridResonanceSkill")
    self.RImgResonanceSkill = self.Transform:Find("SafeAreaContentPane/Contianer/Layout/PanelSlotOld/GridResonanceSkill/RImgResonanceSkill"):GetComponent("RawImage")
    self.TxtSlot = self.Transform:Find("SafeAreaContentPane/Contianer/Layout/PanelSlotOld/TxtSlot"):GetComponent("Text")
    self.BtnRemain = self.Transform:Find("SafeAreaContentPane/Contianer/Layout/PanelSlotOld/BtnRemain"):GetComponent("Button")
    self.PanelAwareness = self.Transform:Find("SafeAreaContentPane/Left/PanelAwareness")
    self.PanelCharacter = self.Transform:Find("SafeAreaContentPane/Left/PanelCharacter")
end

function XUiEquipResonanceSelectAfter:AutoAddListener()
    self:RegisterClickEvent(self.BtnChange, self.OnBtnChangeClick)
    self:RegisterClickEvent(self.BtnConfirm, self.OnBtnConfirmClick)
    self:RegisterClickEvent(self.BtnRemain, self.OnBtnRemainClick)
end
-- auto
function XUiEquipResonanceSelectAfter:OnBtnConfirmClick()
    self:Close()
end

function XUiEquipResonanceSelectAfter:OnBtnChangeClick()
    XMVCA:GetAgency(ModuleId.XEquip):ResonanceConfirm(self.EquipId, self.Pos, true)
end

function XUiEquipResonanceSelectAfter:OnBtnRemainClick()
    XMVCA:GetAgency(ModuleId.XEquip):ResonanceConfirm(self.EquipId, self.Pos, false)
end