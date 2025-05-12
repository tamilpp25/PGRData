---@class XUiGridPcgMonster : XUiGridPcgFighter
---@field private _Control XPcgControl
local XUiGridPcgFighter = require("XUi/XUiPcg/XUiGrid/XUiGridPcgFighter")
local XUiGridPcgMonster = XClass(XUiGridPcgFighter, "XUiGridPcgMonster")

function XUiGridPcgMonster:OnStart()
    self.PanelBoss:GetObject("ImgAim").gameObject:SetActiveEx(false)
    self.PanelMonster:GetObject("ImgAim").gameObject:SetActiveEx(false)
    self.TokenDatas = {}
    self:RegisterUiEvents()
end

function XUiGridPcgMonster:OnEnable()
    
end

function XUiGridPcgMonster:OnDisable()
end

function XUiGridPcgMonster:OnDestroy()
    self.Super:OnDestroy()
    self:ClearAttackTimer()
end

function XUiGridPcgMonster:RegisterUiEvents()
    if self.InputHandler then
        self.InputHandler:AddPointerUpListener(function(eventData)
            if self.PointerUpCb then self.PointerUpCb(self.Idx) end
        end)
        self.InputHandler:AddPressListener(function(time)
            if self.PressCb then self.PressCb(self.Idx, time) end
        end)
    end
end

-- 设置怪物数据
function XUiGridPcgMonster:SetMonsterData(cfgId, idx, hp, armor)
    self.CfgId = cfgId
    self.Idx = idx
    self.Hp = hp
    self.Armor = armor
    local cfg = self._Control:GetConfigMonster(cfgId)
    self.Type = cfg.Type
    self.MaxHp = cfg.MaxHp
    self:Refresh()
end

-- 获取Id
function XUiGridPcgMonster:GetCfgId()
    return self.CfgId
end

-- 设置血量
function XUiGridPcgMonster:SetHp(hp)
    self.Hp = hp
    self:RefreshHp(true)
end

-- 获取血量
function XUiGridPcgMonster:GetHp()
    return self.Hp
end

-- 是否死亡
function XUiGridPcgMonster:GetIsDead()
    return self.Hp <= 0
end

-- 设置护甲
function XUiGridPcgMonster:SetArmor(armor)
    self.Armor = armor
    self:RefreshArmor(true)
end

-- 获取护甲
function XUiGridPcgMonster:GetArmor()
    return self.Armor
end

-- 设置行动预览
function XUiGridPcgMonster:SetBehaviorPreviews(behaviorPreviews)
    local panel = self:GetPanel()
    local isShow = #behaviorPreviews > 0
    panel:GetObject("PanelIntent").gameObject:SetActiveEx(isShow)
    if isShow then
        local icon, txt = self._Control.GameSubControl:GetMonsterBehaviorPreviewsIconAndTxt(behaviorPreviews)
        panel:GetObject("RImgIntent"):SetRawImage(icon)
        panel:GetObject("RImgIntent2"):SetRawImage(icon)
        local isShowTxt = not string.IsNilOrEmpty(txt)
        local txtIntentNum = panel:GetObject("TxtIntentNum")
        txtIntentNum.gameObject:SetActiveEx(isShowTxt)
        if isShowTxt then
            txtIntentNum.text = txt
        end
    end
end

-- 设置回调
function XUiGridPcgMonster:SetInputCallBack(pointerUpCb, pressCb)
    self.PointerUpCb = pointerUpCb
    self.PressCb = pressCb
end

-- 设置目标
function XUiGridPcgMonster:SetTarget(isTarget)
    local panel = self:GetPanel()
    panel:GetObject("ImgAim").gameObject:SetActiveEx(isTarget)
end

-- 刷新界面
function XUiGridPcgMonster:Refresh()
    local panel = self:GetPanel()
    self.GridToken = panel:GetObject("GridToken")
    self.PanelBoss.gameObject:SetActiveEx(self.Type == XEnumConst.PCG.MONSTER_TYPE.BOSS)
    self.PanelMonster.gameObject:SetActiveEx(self.Type == XEnumConst.PCG.MONSTER_TYPE.NORMAL)
    local isNew = not self.LastHp or self.LastHp == 0
    self:HideAllBuff()
    self:RefreshInfo()
    self:RefreshArmor(nil, isNew)
    self:RefreshHp(nil, isNew)
end

-- 刷新怪物信息
function XUiGridPcgMonster:RefreshInfo()
    local panel = self:GetPanel()
    local monsterCfg = self._Control:GetConfigMonster(self.CfgId)
    panel:GetObject("RImgHead"):SetRawImage(monsterCfg.HeadIcon)
end

-- 刷新血量
function XUiGridPcgMonster:RefreshHp(isAnim, isNew)
    local panel = self:GetPanel()
    local hpEffect = panel:GetObject("HpEffect")
    if self.Hp == self.LastHp then
        if isAnim then
            hpEffect.gameObject:SetActive(false)
            hpEffect.gameObject:SetActive(true)
        end
        return 
    end

    local hpSlider = panel:GetObject("ImgLife")
    local txtHpNum = panel:GetObject("TxtHpNum")
    local txtHpAdd = panel:GetObject("TxtHpAdd")
    local txtHpMinus = panel:GetObject("TxtHpMinus")
    local hp = self.Hp
    txtHpNum.text = tostring(hp) .. "/" .. tostring(self.MaxHp)
    hpEffect.gameObject:SetActive(false)

    local gameState = self._Control.GameSubControl:GetGameState()
    if gameState == XEnumConst.PCG.GAME_STATE.Init or isNew then
        hpSlider.fillAmount = hp / self.MaxHp
        txtHpAdd.gameObject:SetActiveEx(false)
        txtHpMinus.gameObject:SetActiveEx(false)
        hpEffect.gameObject:SetActive(false)
    else
        local hpChange = hp - self.LastHp
        local isAdd = hpChange > 0
        txtHpAdd.gameObject:SetActiveEx(isAdd)
        txtHpMinus.gameObject:SetActiveEx(not isAdd)
        if isAdd then
            txtHpAdd.text = "+" .. tostring(hpChange)
            hpEffect.gameObject:SetActive(true)
        else
            txtHpMinus.text = tostring(hpChange)
        end
        self:PlayAnimHpSlider(hpSlider, hp / self.MaxHp, XEnumConst.PCG.ANIM_TIME_ATTR_CHANGE, function()
            txtHpAdd.gameObject:SetActiveEx(false)
            txtHpMinus.gameObject:SetActiveEx(false)
            if self:GetIsDead() then
                self:PlayDisableAnim()
            end
        end)
    end
    self.LastHp = hp
end

-- 刷新护甲
function XUiGridPcgMonster:RefreshArmor(isAnim, isNew)
    local panel = self:GetPanel()
    local armorEffect = panel:GetObject("ArmorEffect")
    local gridArmor = panel:GetObject("GridArmor")
    local armorSlider = panel:GetObject("ImgArmor")
    local txtArmorNum = panel:GetObject("TxtArmorNum")
    local txtArmorAdd = panel:GetObject("TxtArmorAdd")
    local txtArmorMinus = panel:GetObject("TxtArmorMinus")
    local armor = self.Armor
    txtArmorNum.text = armor

    local gameState = self._Control.GameSubControl:GetGameState()
    if gameState == XEnumConst.PCG.GAME_STATE.Init or isNew then
        armorSlider.fillAmount = armor / self.MaxHp
        txtArmorAdd.gameObject:SetActiveEx(false)
        txtArmorMinus.gameObject:SetActiveEx(false)
        armorEffect.gameObject:SetActive(false)
        gridArmor.gameObject:SetActiveEx(self.Armor ~= 0)
    else
        if self.Armor == self.LastArmor then
            if isAnim then
                armorEffect.gameObject:SetActive(false)
                armorEffect.gameObject:SetActive(true)
            end
            return
        end

        armorEffect.gameObject:SetActive(false)
        gridArmor.gameObject:SetActiveEx(true)
        local armorChange = armor - self.LastArmor
        local isAdd = armorChange > 0
        txtArmorAdd.gameObject:SetActiveEx(isAdd)
        txtArmorMinus.gameObject:SetActiveEx(not isAdd)
        if isAdd then
            txtArmorAdd.text = "+" .. tostring(armorChange)
            armorEffect.gameObject:SetActive(true)
        else
            txtArmorMinus.text = tostring(armorChange)
        end
        self:PlayAnimArmorSlider(armorSlider, armor / self.MaxHp, XEnumConst.PCG.ANIM_TIME_ATTR_CHANGE, function()
            txtArmorAdd.gameObject:SetActiveEx(false)
            txtArmorMinus.gameObject:SetActiveEx(false)
            if self.LastArmor == 0 then
                gridArmor.gameObject:SetActiveEx(false)
            end
        end)
    end
    self.LastArmor = armor
end

-- 获取面板boss/怪物面板
function XUiGridPcgMonster:GetPanel()
    if self.Type == XEnumConst.PCG.MONSTER_TYPE.BOSS then
        return self.PanelBoss
    else
        return self.PanelMonster
    end
end

-- 播放攻击动画
---@param target XUiPanelPcgGameCommander
function XUiGridPcgMonster:PlayAnimAttack(target)
    -- Part1:起手动画
    self:ClearAttackTimer()
    self.AttackIntent:PlayTimelineAnimation()
    self.MonsterAttack:PlayTimelineAnimation()

    -- Part2:特效移动动画
    local attackGo = self.EffectAttack
    self.AttackTimer2 = XScheduleManager.ScheduleOnce(function()
        attackGo.transform.localPosition = XLuaVector3.New(0, 0, 0)
        attackGo.gameObject:SetActiveEx(true)
        local affectedPos = target:GetAffectedPos()
        attackGo.transform:DOMoveX(affectedPos.x, XEnumConst.PCG.ANIM_TIME_CHARACTER_ATTACK_PART2 / 1000):SetEase(CS.DG.Tweening.Ease.OutQuad)
        attackGo.transform:DOMoveY(affectedPos.y, XEnumConst.PCG.ANIM_TIME_CHARACTER_ATTACK_PART2 / 1000):SetEase(CS.DG.Tweening.Ease.Linear)
    end, XEnumConst.PCG.ANIM_TIME_CHARACTER_ATTACK_PART1)

    -- Part3:指挥官受击动画
    self.AttackTimer3 = XScheduleManager.ScheduleOnce(function()
        attackGo.gameObject:SetActiveEx(false)
        target:PlayAnimAffected()
    end, XEnumConst.PCG.ANIM_TIME_CHARACTER_ATTACK_PART1 + XEnumConst.PCG.ANIM_TIME_CHARACTER_ATTACK_PART2)
end

function XUiGridPcgMonster:ClearAttackTimer()
    if self.AttackTimer2 then
        XScheduleManager.UnSchedule(self.AttackTimer2)
        self.AttackTimer2 = nil
    end
    if self.AttackTimer3 then
        XScheduleManager.UnSchedule(self.AttackTimer3)
        self.AttackTimer3 = nil
    end
end

-- 获取受击位置
function XUiGridPcgMonster:GetAffectedPos()
    return self.Transform.position
end

-- 播放受击动画
function XUiGridPcgMonster:PlayAnimAffected(colorType)
    if not self.AffectedEffectDic then
        self.AffectedEffectDic = {}
        self.AffectedEffectDic[XEnumConst.PCG.COLOR_TYPE.RED] = self.AffectedRed
        self.AffectedEffectDic[XEnumConst.PCG.COLOR_TYPE.BLUE] = self.AffectedBule
        self.AffectedEffectDic[XEnumConst.PCG.COLOR_TYPE.YELLOW] = self.AffectedYellow
    end

    for _, effect in pairs(self.AffectedEffectDic) do
        effect.gameObject:SetActive(false)
    end

    -- 播放受击动效，怪物自爆对自己造成伤害、指挥官造成伤害没有对应的动效
    local effect = self.AffectedEffectDic[colorType]
    if effect then
        effect.gameObject:SetActive(true)
        effect:PlayTimelineAnimation()
    end
end

-- 播放出场动画
function XUiGridPcgMonster:PlayEnableAnim()
    local panel = self:GetPanel()
    panel:GetObject("HpEffect").gameObject:SetActiveEx(false)
    panel:GetObject("ArmorEffect").gameObject:SetActiveEx(false)
    self.Buff.gameObject:SetActiveEx(false)
    self.DeBuff.gameObject:SetActiveEx(false)
    self.MonsterDisable.gameObject:SetActiveEx(false)
    self.MonsterEnable.gameObject:SetActiveEx(true)
    self.MonsterEnable:PlayTimelineAnimation()
end

-- 播放退场动画
function XUiGridPcgMonster:PlayDisableAnim()
    self.MonsterEnable.gameObject:SetActiveEx(false)
    self.MonsterDisable.gameObject:SetActiveEx(true)
    self.MonsterDisable:PlayTimelineAnimation()
end

function XUiGridPcgMonster:Reset()
    self.Hp = 0
    self.LastHp = 0
    self.Armor = 0
    self.LastArmor = 0
end

return XUiGridPcgMonster
