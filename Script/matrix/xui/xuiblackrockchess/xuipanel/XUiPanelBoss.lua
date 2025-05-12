---@class XUiPanelBoss : XUiNode
---@field private _Control XBlackRockChessControl
---@field private Parent XUiBlackRockChessBattle
local XUiPanelBoss = XClass(XUiNode, "XUiPanelBoss")

function XUiPanelBoss:OnStart()
    self.GridSkill.gameObject:SetActiveEx(false)

    XUiHelper.RegisterClickEvent(self, self.BtnHead, function()
        self:OnBtnHeadClick()
    end)
end

function XUiPanelBoss:OnEnable()
    self._Control:AddEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_PREVIEW_DAMAGE, self.OnPreviewDamage, self)
end

function XUiPanelBoss:OnDisable()
    self._Control:RemoveEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_PREVIEW_DAMAGE, self.OnPreviewDamage, self)
    self:ClearHideTalkTimer()
end

function XUiPanelBoss:OnGetLuaEvents()
    return {
        XEventId.EVENT_BLACK_ROCK_CHESS_SHOW_TALK
    }
end

function XUiPanelBoss:OnNotify(evt, ...)
    local args = {...}
    if evt == XEventId.EVENT_BLACK_ROCK_CHESS_SHOW_TALK then
        self:ShowTalk(args)
    end
end

function XUiPanelBoss:OnBtnHeadClick()
    self.IsShowBossDetail = not self.IsShowBossDetail
    self.PanelBossDetail.gameObject:SetActiveEx(self.IsShowBossDetail)
    if self.IsShowBossDetail then
        self.TxtBossDetail.text = self._Control:GetRoleDesc(self.BossId)
    end
end

function XUiPanelBoss:Refresh(bossId)
    self.BossId = bossId
    -- 头像
    self:RefreshHead()
    -- 血量
    self:PreviewHpDamage(0)
    -- 技能
    self:RefreshSkillList()
    -- 进场喊话
    self:CheckShowEnterTalk()
end

-- 刷新头像
function XUiPanelBoss:RefreshHead()
    ---@type XChessBoss
    local bossInfo = self._Control:GetChessEnemy():GetBossInfo(self.BossId)
    local weaponId = bossInfo:GetWeaponId()
    local circleIcon = self._Control:GetWeaponCircleIcon(weaponId)
    self.RImgHead:SetRawImage(circleIcon)
end

-- 刷新技能列表
function XUiPanelBoss:RefreshSkillList()
    ---@type XChessBoss
    local bossInfo = self._Control:GetChessEnemy():GetBossInfo(self.BossId)
    local weaponId = bossInfo:GetWeaponId()
    self.SkillIds = self._Control:GetWeaponSkillIds(weaponId)
    
    self.GridUiObjs = self.GridUiObjs or {}
    local CSInstantiate = CS.UnityEngine.Object.Instantiate
    for i, skillId in ipairs(self.SkillIds) do
        local uiObj = self.GridUiObjs[i]
        if not uiObj then
            local go = CSInstantiate(self.GridSkill, self.GridSkill.transform.parent)
            uiObj = go:GetComponent("UiObject")
            table.insert(self.GridUiObjs, uiObj)
            
            -- 点击回调
            local tempIndex = i
            XUiHelper.RegisterClickEvent(self, uiObj:GetObject("Button"), function()
                self:OnSkillClick(tempIndex)
            end)
        end
        uiObj.gameObject:SetActiveEx(true)

        -- 技能图标
        local skillIcon = self._Control:GetWeaponSkillIcon(skillId)
        uiObj:GetObject("RImgSkill"):SetRawImage(skillIcon)
        -- CD
        local isInCd, cd = bossInfo:IsSkillInCD(skillId)
        uiObj:GetObject("PanelCd").gameObject:SetActiveEx(isInCd)
        if isInCd then
            uiObj:GetObject("TxtCdNum").text = tostring(cd)
        end
    end

    -- 隐藏多余
    for i = #self.SkillIds + 1, #self.GridUiObjs do
        self.GridUiObjs[i].gameObject:SetActiveEx(false)
    end
end

function XUiPanelBoss:OnSkillClick(index)
    local skillId = self.SkillIds[index]
    self.Parent:ShowPanelBossDetail(self.BossId, skillId)
end

-- 显示对话
function XUiPanelBoss:ShowTalk(args)
    local id = args[1]
    local cvId = args[2]
    local text = args[3]
    local duration = args[4] -- 持续时间（毫秒）
    if id ~= self.BossId then return end

    if cvId then
        XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.Voice, cvId)
    end
    self.TxtTalkContent.text = text
    self.PanelTalk.gameObject:SetActive(false)
    self.PanelTalk.gameObject:SetActive(true)
    
    -- 隐藏
    self:ClearHideTalkTimer()
    self.HideTalkTimer = XScheduleManager.ScheduleOnce(function()
        self.PanelTalk.gameObject:SetActiveEx(false)
        self.HideTalkTimer = nil
    end, duration)
end

function XUiPanelBoss:ClearHideTalkTimer()
    if self.HideTalkTimer then
        XScheduleManager.UnSchedule(self.HideTalkTimer)
        self.HideTalkTimer = nil
    end
end

-- 进入关卡显示喊话
function XUiPanelBoss:CheckShowEnterTalk()
    if self.IsEnter then return end
    self.IsEnter = true
    
    -- 获取喊话配置表
    local growlsCfg = self._Control:GetChessGrowlsConfig(XEnumConst.BLACK_ROCK_CHESS.CHESS_MEMBER_TYPE.BOSS, XMVCA.XBlackRockChess.GrowlsTriggerType.EnterFight, self.BossId)
    if not growlsCfg then return end
    XEventManager.DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_SHOW_TALK, self.BossId, growlsCfg.CvIds[1], growlsCfg.Text[1], growlsCfg.Duration)
end

-- 预览伤害
function XUiPanelBoss:OnPreviewDamage(id, damage)
    if self.BossId ~= id then return end
    
    self:PreviewHpDamage(damage)
end

-- 预览血条遭受伤害
function XUiPanelBoss:PreviewHpDamage(damage)
    damage = damage or 0
    self:StopTweenSequence()
    local MAX_HP_GRID = 10 -- 一行的血量格子数
    
    ---@type XChessBoss
    local bossInfo = self._Control:GetChessEnemy():GetBossInfo(self.BossId)
    local curHp = bossInfo:GetHp()
    local isInvincible = bossInfo:IsInvincible(bossInfo:GetAttackTimes()) -- 是否无敌
    local leftHp = isInvincible and curHp or math.max(0, curHp - damage)
    self.TxtHpNum.text = tostring(curHp)

    -- 死亡UI
    local isDead = leftHp <= 0
    self.PanelDead.gameObject:SetActiveEx(isDead)
    
    -- 当前血条
    local isDamage = curHp ~= leftHp
    self.ImgHpBarTop.gameObject:SetActiveEx(true)
    local barIndex = math.ceil(leftHp / MAX_HP_GRID)
    if isDamage and leftHp % MAX_HP_GRID == 0 then
        barIndex = barIndex + 1
        self.ImgHpBarTop.gameObject:SetActiveEx(false)
    end

    -- 当前血条
    local left = self._Control:GetGridValueByHp(leftHp, MAX_HP_GRID)
    local color = self._Control:GetClientConfig("EmenyHpColor", math.max(1, barIndex % 10))
    self.ImgHpBarTop.fillAmount = CS.UnityEngine.Mathf.Clamp01(left / MAX_HP_GRID)
    self.ImgHpBarTop.color = XUiHelper.Hexcolor2Color(color)

    -- 底下血条
    local isShowBottom = barIndex > 1
    self.ImgHpBarButtom.gameObject:SetActiveEx(isShowBottom)
    if isShowBottom then
        local colorIndex = (barIndex - 1) % 10
        if colorIndex == 0 then
            colorIndex = 10
        end
        self.ImgHpBarButtom.color = XUiHelper.Hexcolor2Color(self._Control:GetClientConfig("EmenyHpColor", colorIndex))
        self.ImgHpBarButtom.fillAmount = 1
    end

    -- 预览伤害闪烁效果
    self.ImgHpBarPreview.gameObject:SetActiveEx(isDamage)
    if isDamage then
        local previewProgress = curHp % MAX_HP_GRID / MAX_HP_GRID
        -- 已死亡
        if isDead then
            previewProgress = curHp / MAX_HP_GRID
            -- 当前血条消耗完，开始消耗下一血条
        elseif math.ceil(curHp) ~= math.ceil(leftHp) then
            previewProgress = 1
        end

        self.ImgHpBarPreview.fillAmount = previewProgress
        self.ImgHpBarPreview.color = XUiHelper.Hexcolor2Color(color)
        if not self._Seq then
            local CsTween = CS.DG.Tweening
            local PREVIEW_ALPHA_MIN = 0.1
            local PREVIEW_ALPHA_MAX = 0.8
            local PREVIEW_DURATION = 0.2
            self._Seq = CsTween.DOTween.Sequence()
            self._Seq:Append(self.ImgHpBarPreview:DOFade(PREVIEW_ALPHA_MIN, PREVIEW_DURATION):SetEase(CsTween.Ease.Flash))
            self._Seq:Append(self.ImgHpBarPreview:DOFade(PREVIEW_ALPHA_MAX, PREVIEW_DURATION):SetEase(CsTween.Ease.Flash))
            self._Seq:SetLoops(-1)
        end
        self._Seq:Play()
    end
end

function XUiPanelBoss:StopTweenSequence()
    if self._Seq then
        self._Seq:Pause()
    end
end

return XUiPanelBoss
