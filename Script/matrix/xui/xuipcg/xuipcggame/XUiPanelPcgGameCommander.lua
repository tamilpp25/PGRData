---@class XUiPanelPcgGameCommander : XUiGridPcgFighter
---@field private _Control XPcgControl
---@field Parent XUiPcgGame
local XUiGridPcgFighter = require("XUi/XUiPcg/XUiGrid/XUiGridPcgFighter")
local XUiPanelPcgGameCommander = XClass(XUiGridPcgFighter, "XUiPanelPcgGameCommander")

function XUiPanelPcgGameCommander:OnStart()
    self.TxtEnergyAdd.gameObject:SetActiveEx(false)
    self.TxtEnergyMinus.gameObject:SetActiveEx(false)
    self:RegisterUiEvents()
    self:InitIcon()
end

function XUiPanelPcgGameCommander:OnEnable()
    
end

function XUiPanelPcgGameCommander:OnDisable()
    
end

function XUiPanelPcgGameCommander:OnDestroy()
    self.Super:OnDestroy()
    self:ClearEnergyChangeTimer()
end

function XUiPanelPcgGameCommander:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnSkill, self.OnBtnSkillClick, nil, true)
    self.InputHandler:AddPointerUpListener(function(eventData)
        self:OnPointerUp(eventData)
    end)
    self.InputHandler:AddPressListener(function(time)
        self:OnPress(time)
    end)
end

function XUiPanelPcgGameCommander:OnBtnSkillClick()
    -- 正在播放动画
    if self.Parent:IsAnim() then return end
    
    -- 当前正在使用技能，不处理
    if self.Parent:GetIsUsingSkill() then return end
    
    ---@type XPcgPlayingStage
    local stageData = self._Control.GameSubControl:GetPlayingStageData()
    ---@type XPcgCommander
    local commander = stageData:GetCommander()

    -- 是否配置可使用指挥官技能
    local stageId = stageData:GetId()
    local enablePlayerSkill = self._Control:GetStageEnablePlayerSkill(stageId)
    if not enablePlayerSkill then return end
    
    -- 能量值达到
    local maxEnergy = self._Control:GetStageMaxEnergy(stageId) -- 技能能量上限
    local energy = commander:GetEnergy() -- 当前能量值
    if energy < maxEnergy then
        local tips = self._Control:GetClientConfig("EnergyNoEnoughTips")
        XUiManager.TipError(tips)
        return 
    end
    self.Parent:OpenPanelUseSkill()
end

function XUiPanelPcgGameCommander:OnPointerUp(eventData)
    -- 当前打开弹窗详情，关闭弹窗详情
    if self.Parent:IsShowPanelPopupDetail() then
        self.Parent:ClosePanelPopupDetail()
    end
end

function XUiPanelPcgGameCommander:OnPress(time)
    -- 长按超过0.2秒才响应操作
    if time < 0.2 then return end
    -- 非出牌阶段不可操作
    if not self.Parent:IsPlayCardState() then return end
    -- 正在播放动画
    if self.Parent:IsAnim() then return end
    -- 当前打开弹窗详情，不可操作
    if self.Parent:IsShowPanelPopupDetail() then return end
    -- 游戏结束
    local gameState = self._Control.GameSubControl:GetGameState()
    if gameState == XEnumConst.PCG.GAME_STATE.End then return end
    
    -- 打开详情
    self.Parent:ShowPanelPopupDetail(XEnumConst.PCG.POPUP_DETAIL_TYPE.COMMANDER)
end

function XUiPanelPcgGameCommander:InitIcon()
    -- 头像图标
    local headIcon = self._Control:GetClientConfig("CommanderHeadIcon")
    self.ImgCommanderHead:SetSprite(headIcon)
    -- 技能图标
    local skillIcon = self._Control:GetClientConfig("CommanderSkillIcon")
    self.ImgSkill:SetSprite(skillIcon)
end

function XUiPanelPcgGameCommander:Refresh()
    ---@type XPcgPlayingStage
    local stageData = self._Control.GameSubControl:GetPlayingStageData()
    ---@type XPcgCommander
    local commander = stageData:GetCommander()
    self.Hp = commander:GetHp()
    self.Armor = commander:GetArmor()
    self.Energy = commander:GetEnergy()
    self.StageId = self._Control:GetCurrentStageId()
    self.MaxHp = self._Control:GetStageMaxHp(self.StageId) -- 血量上限

    self:SetTokens(commander:GetTokens())
    self:RefreshHp()
    self:RefreshArmor()
    self:RefreshEnergy()
end

function XUiPanelPcgGameCommander:GetCommanderPosition()
    return self.InputHandler.transform.position
end

-- 设置血量
function XUiPanelPcgGameCommander:SetHp(hp)
    self.Hp = hp
    self:RefreshHp(true)
end

-- 获取血量
function XUiPanelPcgGameCommander:GetHp()
    return self.Hp
end

-- 设置护甲
function XUiPanelPcgGameCommander:SetArmor(armor)
    self.Armor = armor
    self:RefreshArmor(true)
end

-- 获取护甲
function XUiPanelPcgGameCommander:GetArmor()
    return self.Armor
end

-- 设置行动点
function XUiPanelPcgGameCommander:SetEnergy(energy)
    self.Energy = energy
    self:RefreshEnergy()
end

-- 获取Token的层数
function XUiPanelPcgGameCommander:GetTokenLayer(tokenId)
    for _, tokenData in ipairs(self.TokenDatas) do
        if tokenData:GetId() == tokenId then
            return tokenData:GetLayer()
        end
    end
    return 0
end

-- 刷新能量
function XUiPanelPcgGameCommander:RefreshEnergy()
    -- 关卡是否支持使用指挥官技能
    local enablePlayerSkill = self._Control:GetStageEnablePlayerSkill(self.StageId)
    self.GridSkill.gameObject:SetActiveEx(enablePlayerSkill)
    if not enablePlayerSkill then return end

    -- 技能能量显示
    local maxEnergy = self._Control:GetStageMaxEnergy(self.StageId)
    local energy = self.Energy -- 当前能量值
    self.TxtEnergyNum.text = string.format("%s/%s", energy, maxEnergy)
    local progress = energy / maxEnergy
    self.ImgEnergy.fillAmount = progress

    -- 能量变化飘字
    local gameState = self._Control.GameSubControl:GetGameState()
    if gameState ~= XEnumConst.PCG.GAME_STATE.Init and self.LastEnergy and energy ~= self.LastEnergy then
        local energyChange = energy - self.LastEnergy
        local isAdd = energyChange > 0
        self.TxtEnergyAdd.gameObject:SetActiveEx(isAdd)
        self.TxtEnergyMinus.gameObject:SetActiveEx(not isAdd)
        if isAdd then
            self.TxtEnergyAdd.text = "+" .. tostring(energyChange)
        else
            self.TxtEnergyMinus.text = tostring(energyChange)
        end
        self:StartEnergyChangeTimer()
    end
    self.EnergyEffect.gameObject:SetActiveEx(energy >= maxEnergy)
    self.LastEnergy = energy
end

-- 更新血量
function XUiPanelPcgGameCommander:RefreshHp(isAnim)
    if self.Hp == self.LastHp then
        if isAnim then
            self.HpEffect.gameObject:SetActive(false)
            self.HpEffect.gameObject:SetActive(true)
        end
        return 
    end

    local hp = self.Hp
    self.TxtHpNum.text = tostring(hp) .. "/" .. tostring(self.MaxHp)
    self.HpEffect.gameObject:SetActive(false)

    local gameState = self._Control.GameSubControl:GetGameState()
    if gameState == XEnumConst.PCG.GAME_STATE.Init then
        self.ImgLife.fillAmount = hp / self.MaxHp
        self.TxtHpAdd.gameObject:SetActiveEx(false)
        self.TxtHpMinus.gameObject:SetActiveEx(false)
        self.HpEffect.gameObject:SetActive(false)
    else
        local hpChange = hp - self.LastHp
        local isAdd = hpChange > 0
        self.TxtHpAdd.gameObject:SetActiveEx(isAdd)
        self.TxtHpMinus.gameObject:SetActiveEx(not isAdd)
        if isAdd then
            self.TxtHpAdd.text = "+" .. tostring(hpChange)
            self.HpEffect.gameObject:SetActive(true)
        else
            self.TxtHpMinus.text = tostring(hpChange)
        end
        self:PlayAnimHpSlider(self.ImgLife, hp / self.MaxHp, XEnumConst.PCG.ANIM_TIME_ATTR_CHANGE, function()
            self.TxtHpAdd.gameObject:SetActiveEx(false)
            self.TxtHpMinus.gameObject:SetActiveEx(false)
        end)
    end
    self.LastHp = hp
end

-- 更新护甲
function XUiPanelPcgGameCommander:RefreshArmor(isAnim)
    if self.Armor == self.LastArmor then
        if isAnim then
            self.ArmorEffect.gameObject:SetActive(false)
            self.ArmorEffect.gameObject:SetActive(true)
        end
        return 
    end

    local armor = self.Armor
    self.TxtArmorNum.text = armor
    self.ArmorEffect.gameObject:SetActive(false)

    local gameState = self._Control.GameSubControl:GetGameState()
    if gameState == XEnumConst.PCG.GAME_STATE.Init then
        self.ImgArmor.fillAmount = armor / self.MaxHp
        self.TxtArmorAdd.gameObject:SetActiveEx(false)
        self.TxtArmorMinus.gameObject:SetActiveEx(false)
        self.ArmorEffect.gameObject:SetActive(false)
        self.GridArmor.gameObject:SetActiveEx(self.Armor ~= 0)
    else
        self.GridArmor.gameObject:SetActiveEx(true)
        local armorChange = armor - self.LastArmor
        local isAdd = armorChange > 0
        self.TxtArmorAdd.gameObject:SetActiveEx(isAdd)
        self.TxtArmorMinus.gameObject:SetActiveEx(not isAdd)
        if isAdd then
            self.TxtArmorAdd.text = "+" .. tostring(armorChange)
            self.ArmorEffect.gameObject:SetActive(true)
        else
            self.TxtArmorMinus.text = tostring(armorChange)
        end
        self:PlayAnimArmorSlider(self.ImgArmor, armor / self.MaxHp, XEnumConst.PCG.ANIM_TIME_ATTR_CHANGE, function()
            self.TxtArmorAdd.gameObject:SetActiveEx(false)
            self.TxtArmorMinus.gameObject:SetActiveEx(false)
            if self.LastArmor == 0 then
                self.GridArmor.gameObject:SetActiveEx(false)
            end
        end)
    end
    self.LastArmor = armor
end

-- 开启能量变化飘字定时器
function XUiPanelPcgGameCommander:StartEnergyChangeTimer()
    self:ClearEnergyChangeTimer()
    self.EnergyChangeTimer = XScheduleManager.ScheduleOnce(function()
        self.TxtEnergyAdd.gameObject:SetActiveEx(false)
        self.TxtEnergyMinus.gameObject:SetActiveEx(false)
        self.EnergyChangeTimer = nil
    end, 1000)
end

-- 清除能量变化飘字定时器
function XUiPanelPcgGameCommander:ClearEnergyChangeTimer()
    if self.EnergyChangeTimer then
        XScheduleManager.UnSchedule(self.EnergyChangeTimer)
    end
end

-- 获取受击位置
function XUiPanelPcgGameCommander:GetAffectedPos()
    return self.ImgCommanderHead.transform.position
end

-- 播放受击动画
function XUiPanelPcgGameCommander:PlayAnimAffected()
    self.CommanderAffected:PlayTimelineAnimation()
end

-- 播放攻击动画
function XUiPanelPcgGameCommander:PlayAnimAttack(target)
    -- TODO 指挥官攻击动画
end

return XUiPanelPcgGameCommander
