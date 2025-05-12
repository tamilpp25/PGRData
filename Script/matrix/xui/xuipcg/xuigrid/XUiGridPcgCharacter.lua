---@class XUiGridPcgCharacter : XUiGridPcgFighter
---@field private _Control XPcgControl
local XUiGridPcgFighter = require("XUi/XUiPcg/XUiGrid/XUiGridPcgFighter")
local XUiGridPcgCharacter = XClass(XUiGridPcgFighter, "XUiGridPcgCharacter")

function XUiGridPcgCharacter:OnStart()
    self.TokenDatas = {}
    self:RegisterUiEvents()
end

function XUiGridPcgCharacter:OnEnable()
    
end

function XUiGridPcgCharacter:OnDisable()
    
end

function XUiGridPcgCharacter:OnDestroy()
    self.Super:OnDestroy()
    self:KillTween()
    self:ClearAttackTimer()
end

function XUiGridPcgCharacter:RegisterUiEvents()
    if self.Button then
        XUiHelper.RegisterClickEvent(self, self.Button, function()
            if self.PointerUpCb then self.PointerUpCb(self.Idx) end
        end, nil, true)
    end
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
function XUiGridPcgCharacter:SetCharacterData(cfgId, idx, isCircle)
    self.CfgId = cfgId
    self.Idx = idx
    self.IsCircle = isCircle
    self:Refresh()
end

-- 设置卡牌下标
function XUiGridPcgCharacter:ChangeIdx(idx, parent, cb)
    self.Idx = idx
    self.Transform:SetParent(parent, true)
    self:PlayAnimBack(cb)
    self:Refresh()
end

-- 设置颜色类型
function XUiGridPcgCharacter:SetColorType(color)
    self:RefreshColor(color)
end

-- 设置回调
function XUiGridPcgCharacter:SetInputCallBack(pointerUpCb, pressCb)
    self.PointerUpCb = pointerUpCb
    self.PressCb = pressCb
end

-- 设置目标
function XUiGridPcgCharacter:SetQTE(isQTE)
    local colorType = self:GetColorType()
    local isShowQTE = isQTE and self.Idx ~= XEnumConst.PCG.ATTACK_CHAR_INDEX -- 1号进攻位不显示QTE特效
    self.QTERed.gameObject:SetActiveEx(isShowQTE and colorType == XEnumConst.PCG.COLOR_TYPE.RED)
    self.QTEBlue.gameObject:SetActiveEx(isShowQTE and colorType == XEnumConst.PCG.COLOR_TYPE.BLUE)
    self.QTEYellow.gameObject:SetActiveEx(isShowQTE and colorType == XEnumConst.PCG.COLOR_TYPE.YELLOW)
end

-- 设置上锁
function XUiGridPcgCharacter:SetLock(isLock, tips)
    self.ImgLock.gameObject:SetActiveEx(isLock)
    if tips and self.TextLock then
        self.TextLock.text = tips
    end
end

-- 设置加号
function XUiGridPcgCharacter:SetAdd(isAdd)
    self.ImgAdd.gameObject:SetActiveEx(isAdd)
end

-- 设置蓝点
function XUiGridPcgCharacter:SetRed(isRed)
    self.Red.gameObject:SetActiveEx(isRed)
end

function XUiGridPcgCharacter:GetCfgId()
    return self.CfgId
end

function XUiGridPcgCharacter:GetColorType()
    local characterCfg = self._Control:GetConfigCharacter(self.CfgId)
    return characterCfg.ColorType
end

-- 获取Token的层数
function XUiGridPcgCharacter:GetTokenLayer(tokenId)
    for _, tokenData in ipairs(self.TokenDatas) do
        if tokenData:GetId() == tokenId then
            return tokenData:GetLayer()
        end
    end
    return 0
end

-- 显示选中
function XUiGridPcgCharacter:ShowSelected(isShow)
    self.ImgSelect.gameObject:SetActiveEx(isShow)
end

-- 显示当前页签
function XUiGridPcgCharacter:ShowTagNow(isShow)
    self.PanelNow.gameObject:SetActiveEx(isShow)
end

-- 刷新界面
function XUiGridPcgCharacter:Refresh()
    local isCharExit = self.CfgId and self.CfgId ~= 0
    local isAttack = self.Idx == XEnumConst.PCG.ATTACK_CHAR_INDEX -- 1号进攻位
    self.RImgHead.gameObject:SetActiveEx(isCharExit)
    if isCharExit then
        local characterCfg = self._Control:GetConfigCharacter(self.CfgId)
        local icon = self.IsCircle and characterCfg.HeadIconCircle or characterCfg.HeadIcon
        self.RImgHead:SetRawImage(icon)
        self:RefreshColor(characterCfg.ColorType)
        self:RefreshTag(characterCfg.TagIds)
    end
    if self.ImgAdd then
        self.ImgAdd.gameObject:SetActiveEx(not isCharExit)
    end
    if self.HeadLoop then
        self.HeadLoop.gameObject:SetActiveEx(isAttack)
    end
end

-- 刷新背景颜色
function XUiGridPcgCharacter:RefreshColor(color)
    if self.ImgHeadRed then
        self.ImgHeadRed.gameObject:SetActiveEx(color == XEnumConst.PCG.COLOR_TYPE.RED)
    end
    if self.ImgHeadBlue then
        self.ImgHeadBlue.gameObject:SetActiveEx(color == XEnumConst.PCG.COLOR_TYPE.BLUE)
    end
    if self.ImgHeadYellow then
        self.ImgHeadYellow.gameObject:SetActiveEx(color == XEnumConst.PCG.COLOR_TYPE.YELLOW)
    end
end

-- 刷新标签
function XUiGridPcgCharacter:RefreshTag(tagIds)
    if not self.GridTag then return end
    
    self.TagUiObjs = self.TagUiObjs or {}
    self.GridTag.gameObject:SetActiveEx(false)
    for _, uiObj in ipairs(self.TagUiObjs) do
        uiObj.gameObject:SetActiveEx(false)
    end
    
    local CSInstantiate = CS.UnityEngine.Object.Instantiate
    for i, tagId in ipairs(tagIds) do
        local uiObj = self.TagUiObjs[i]
        if not uiObj then
            local go = CSInstantiate(self.GridTag.gameObject, self.GridTag.transform.parent)
            uiObj = go:GetComponent(typeof(CS.UiObject))
            table.insert(self.TagUiObjs, uiObj)
        end
        uiObj.gameObject:SetActiveEx(true)
        local tagCfg = self._Control:GetConfigCharacterTag(tagId)
        uiObj:GetObject("TxtTitle").text = tagCfg.Name
    end
end

-- 播放卡牌归位动画
function XUiGridPcgCharacter:PlayAnimBack(cb)
    self:KillTween()
    local pos = XLuaVector3.New(0, 0, 0)
    local scale = XLuaVector3.New(1, 1, 1)
    local animTime = XEnumConst.PCG.ANIM_TIME_CHARACTER_CHANGE / 1000
    self.Transform:DOScale(scale, animTime)
    if not cb then
        self.Transform:DOLocalMove(pos, animTime)
    else
        self.Transform:DOLocalMove(pos, animTime):OnComplete(function()
            cb()
        end)
    end
end

-- 停止自身Tween函数
function XUiGridPcgCharacter:KillTween()
    self.Transform:DOKill(true)
end

-- 播放攻击动画
---@param target XUiGridPcgMonster
function XUiGridPcgCharacter:PlayAnimAttack(target)
    local colorType = self:GetColorType()
    local attackGo = nil
    if colorType == XEnumConst.PCG.COLOR_TYPE.RED then
        attackGo = self.AttackRed
    elseif colorType == XEnumConst.PCG.COLOR_TYPE.BLUE then
        attackGo = self.AttackBlue
    elseif colorType == XEnumConst.PCG.COLOR_TYPE.YELLOW then
        attackGo = self.AttackYellow
    end
    
    -- Part1:成员起手动画
    self.CharacterAttack:PlayTimelineAnimation()
    self:ClearAttackTimer()
    
    -- Part2:特效移动动画
    self.AttackTimer1 = XScheduleManager.ScheduleOnce(function()
        attackGo.transform.localPosition = XLuaVector3.New(0, 0, 0)
        attackGo.gameObject:SetActiveEx(true)
        local affectedPos = target:GetAffectedPos()
        attackGo.transform:DOMoveX(affectedPos.x, XEnumConst.PCG.ANIM_TIME_CHARACTER_ATTACK_PART2 / 1000):SetEase(CS.DG.Tweening.Ease.OutQuad)
        attackGo.transform:DOMoveY(affectedPos.y, XEnumConst.PCG.ANIM_TIME_CHARACTER_ATTACK_PART2 / 1000):SetEase(CS.DG.Tweening.Ease.Linear)
    end, XEnumConst.PCG.ANIM_TIME_CHARACTER_ATTACK_PART1)
    
    -- Part3:怪物受击动画
    self.AttackTimer2 = XScheduleManager.ScheduleOnce(function()
        attackGo.gameObject:SetActiveEx(false)
        target:PlayAnimAffected(colorType)
    end, XEnumConst.PCG.ANIM_TIME_CHARACTER_ATTACK_PART1 + XEnumConst.PCG.ANIM_TIME_CHARACTER_ATTACK_PART2)
end

function XUiGridPcgCharacter:ClearAttackTimer()
    if self.AttackTimer1 then
        XScheduleManager.UnSchedule(self.AttackTimer1)
        self.AttackTimer1 = nil
    end
    if self.AttackTimer2 then
        XScheduleManager.UnSchedule(self.AttackTimer2)
        self.AttackTimer2 = nil
    end
end

-- 播放出场动画
function XUiGridPcgCharacter:PlayEnableAnim()
    self.Buff.gameObject:SetActiveEx(false)
    self.DeBuff.gameObject:SetActiveEx(false)
    self.PassiveSkillEffect.gameObject:SetActiveEx(false)
    self.CharacterEnable.gameObject:SetActive(false)
    self.CharacterEnable.gameObject:SetActive(true)
    self.CharacterEnable:PlayTimelineAnimation()
end

-- 播放被动技能特效
function XUiGridPcgCharacter:PlayPassiveSkillEffect()
    self.PassiveSkillEffect.gameObject:SetActive(false)
    self.PassiveSkillEffect.gameObject:SetActive(true)
end

return XUiGridPcgCharacter
