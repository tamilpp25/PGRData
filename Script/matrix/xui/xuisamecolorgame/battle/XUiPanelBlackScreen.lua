---@class XUiSCBattlePanelBlackScreen
local XUiPanelBlackScreen = XClass(nil, "XUiPanelBlackScreen")
local OrderKey = {
    Buff = 1,
    Board = 2,
    Condition = 3,
    Energy = 4,
}

function XUiPanelBlackScreen:Ctor(ui, base, role)
    ---@type XUiSameColorGameBattle
    self.Base = base
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    
    self.Role = role
    self.BattleManager = XDataCenter.SameColorActivityManager.GetBattleManager()
    self.GameObject:SetActiveEx(true)

    self.CanvasOrder = {[OrderKey.Buff] = self.PanelBuffCanvas.sortingOrder,
        [OrderKey.Board] = self.PanelBoardCanvas.sortingOrder,
        [OrderKey.Condition] = self.PanelConditionCanvas.sortingOrder,
        [OrderKey.Energy] = self.PanelEnergyCanvas.sortingOrder,}

    self.OrderPlus = {}
    for _,key in pairs(OrderKey) do
        self.OrderPlus[key] = 0
    end

    self:SetScreenMask()
    self:AddBtnListener()
end

function XUiPanelBlackScreen:OnEnable()
    self:AddEventListener()
end

function XUiPanelBlackScreen:OnDisable()
    self:RemoveEventListener()
end

function XUiPanelBlackScreen:OnSkillEnd()
    self.BattleManager:ClearPrepSkill()
    self:SetScreenMask()
    XEventManager.DispatchEvent(XEventId.EVENT_SC_UNPREP_SKILL)
end

function XUiPanelBlackScreen:OnCDChange(data)
    -- 使用的技能进入倒计时，技能结束
    local preSkill = self.BattleManager:GetPrepSkill()
    if preSkill and preSkill:GetSkillId() == data.SkillGroupId then
        self:OnSkillEnd()
    end
end

function XUiPanelBlackScreen:UseNoParamSkill()
    local skillId = self.Skill:GetSkillId()
    local skillGroupId = self.Skill:GetSkillGroupId()
    XDataCenter.SameColorActivityManager.RequestUseItem(skillGroupId, skillId, {})
end

function XUiPanelBlackScreen:UsePopupSkill()
    local skillId = self.Skill:GetSkillId()
    local skillGroupId = self.Skill:GetSkillGroupId()
    XLuaUiManager.Open("UiSameColorGameChangeColor", self.Role,
        self.Skill:GetHintText(),
        nil,
        function ()
            self:OnBtnCloseClick()
        end,
        function (ball_1, cb)
            XDataCenter.SameColorActivityManager.RequestUseItem(skillGroupId, skillId, {Item1 = ball_1}, cb)
        end)
end

function XUiPanelBlackScreen:CheckAutoDoSkill()
    if self:IsNoneMask() then
        return
    end
    if self:IsPopupMask() then
        self:UsePopupSkill()
    elseif self:IsNullMask() then
        self.BlackScreen.gameObject:SetActiveEx(false)
        self:UseNoParamSkill()
    end
end

function XUiPanelBlackScreen:CloseSkillTips()
    self.TextTipsBoard.gameObject:SetActiveEx(false)
end

-- skill参数为nil，关闭mask
function XUiPanelBlackScreen:SetScreenMask(skill)
    ---@type XSCBattleRoleSkill
    self.Skill = skill

    local str = self:IsBuffMask() and skill:GetHintText() or ""
    self.TextTipsBuff.text = string.gsub(str, "\\n", "\n")
    
    str = (self:IsBoardMask() or self:IsEnergyMask() or self:IsSkillMask()) and skill:GetHintText() or ""
    self.TextTipsBoard.text = string.gsub(str, "\\n", "\n")
     
    str = self:IsConditionMask() and skill:GetHintText() or ""
    self.TextTipsCondition.text = string.gsub(str, "\\n", "\n")

    self.PanelBuffSelect.gameObject:SetActiveEx(self:IsBuffMask())
    self.PanelBoardSelect.gameObject:SetActiveEx(self:IsBoardMask())
    self.PanelConditionSelect.gameObject:SetActiveEx(self:IsConditionMask())
    self.PanelEnergySelect.gameObject:SetActiveEx(self:IsEnergyMask())
    self.PanelSkillSelect.gameObject:SetActiveEx(self:IsSkillMask())
    self.BlackScreen.gameObject:SetActiveEx(not self:IsNoneMask())
    self.TextTipsBuff.gameObject:SetActiveEx(not self:IsNoneMask())
    self.TextTipsBoard.gameObject:SetActiveEx(not self:IsNoneMask())
    self.TextTipsCondition.gameObject:SetActiveEx(not self:IsNoneMask())
    
    self.PanelBuffSelect.transform.position = self.PanelBuffParent.transform.position
    self.PanelBuffSelect:GetComponent("RectTransform").sizeDelta = self.PanelBuffParent.sizeDelta

    if self:IsBuffMask() then
        self.Base:PlayAnimation("PanelBuffTipsLoop", nil, nil, CS.UnityEngine.Playables.DirectorWrapMode.Loop)
    end
    if self:IsBoardMask() then
        self.Base:PlayAnimation("PanelBoardTipsLoop", nil, nil, CS.UnityEngine.Playables.DirectorWrapMode.Loop)
    end
    if self:IsConditionMask() then
        self.Base:PlayAnimation("PanelConditionTipsLoop", nil, nil, CS.UnityEngine.Playables.DirectorWrapMode.Loop)
    end
    if self:IsEnergyMask() then
        self.Base:PlayAnimation("PanelEnergyTipsLoop", nil, nil, CS.UnityEngine.Playables.DirectorWrapMode.Loop)
    end
    if self:IsSkillMask() then
        self.Base:PlayAnimation("PanelSkillTipsLoop", nil, nil, CS.UnityEngine.Playables.DirectorWrapMode.Loop)
    end

    self.OrderPlus[OrderKey.Buff] = self:IsBuffMask() and 2 or 0
    self.OrderPlus[OrderKey.Board] = self:IsBoardMask() and 2 or 0
    self.OrderPlus[OrderKey.Condition] = self:IsConditionMask() and 2 or 0
    -- 准备技能时不是主技能覆盖能量节点层
    self.OrderPlus[OrderKey.Energy] = (self:IsEnergyMask() or (skill and skill:GetIsOn())) and 2 or
                                      skill and not self.BattleManager:CheckPrepSkillIsMain(skill:GetSkillId(0)) and -4 or 0

    self:SetSortingOrder()
    self:CheckAutoDoSkill()
end

function XUiPanelBlackScreen:SetSortingOrder()
    self.PanelBuffCanvas.sortingOrder = self.CanvasOrder[OrderKey.Buff] + self.OrderPlus[OrderKey.Buff]
    self.PanelBoardCanvas.sortingOrder = self.CanvasOrder[OrderKey.Board] + self.OrderPlus[OrderKey.Board]
    self.PanelConditionCanvas.sortingOrder = self.CanvasOrder[OrderKey.Condition] + self.OrderPlus[OrderKey.Condition]
    self.PanelEnergyCanvas.sortingOrder = self.CanvasOrder[OrderKey.Energy] + self.OrderPlus[OrderKey.Energy]
end

function XUiPanelBlackScreen:IsConditionMask()
    return self.Skill and self.Skill:GetScreenMaskType() == XEnumConst.SAME_COLOR_GAME.SKILL_SCREEN_MASK_TYPE.CONDITION
end

function XUiPanelBlackScreen:IsBoardMask()
    return self.Skill and self.Skill:GetScreenMaskType() == XEnumConst.SAME_COLOR_GAME.SKILL_SCREEN_MASK_TYPE.BOARD
end

function XUiPanelBlackScreen:IsBuffMask()
    return self.Skill and self.Skill:GetScreenMaskType() == XEnumConst.SAME_COLOR_GAME.SKILL_SCREEN_MASK_TYPE.BUFF
end

function XUiPanelBlackScreen:IsEnergyMask()
    return self.Skill and self.Skill:GetScreenMaskType() == XEnumConst.SAME_COLOR_GAME.SKILL_SCREEN_MASK_TYPE.ENERGY
end

function XUiPanelBlackScreen:IsSkillMask()
    return self.Skill and self.Skill:GetScreenMaskType() == XEnumConst.SAME_COLOR_GAME.SKILL_SCREEN_MASK_TYPE.SKILL
end

function XUiPanelBlackScreen:IsPopupMask()
    return self.Skill and self.Skill:GetScreenMaskType() == XEnumConst.SAME_COLOR_GAME.SKILL_SCREEN_MASK_TYPE.POPUP
end

function XUiPanelBlackScreen:IsNullMask()
    return self.Skill and self.Skill:GetScreenMaskType() == XEnumConst.SAME_COLOR_GAME.SKILL_SCREEN_MASK_TYPE.NONE
end

function XUiPanelBlackScreen:IsNoneMask()
    if not self.Skill then
        return true
    else
        return false
    end
end

--region Btn - Listener
function XUiPanelBlackScreen:AddBtnListener()
    self.BtnClose.CallBack = function()
        self:OnBtnCloseClick()
    end

    self.PanelBuffSelect:GetObject("BtnClick").CallBack = function()
        self:CheckClickDoSkill()
    end

    self.PanelConditionSelect:GetObject("BtnClick").CallBack = function()
        self:CheckClickDoSkill()
    end

    self.PanelEnergySelect:GetObject("BtnClick").CallBack = function()
        self:CheckClickDoSkill()
    end

    self.PanelSkillSelect:GetObject("BtnClick").CallBack = function()
        self:CheckClickDoSkill()
    end
end

function XUiPanelBlackScreen:OnBtnCloseClick()
    if self:IsNoneMask() then
        return
    end

    if self.Skill:GetUsedCount() == 0 then
        self:OnSkillEnd()
    else
        -- v4.0移除弹窗
        --[[ 
        local callBack = function()
            local skillId = self.Skill:GetSkillId()
            local skillGroupId = self.Skill:GetSkillGroupId()
            XDataCenter.SameColorActivityManager.RequestCancelUseItem(skillGroupId, skillId)
        end
        local content = CSXTextManagerGetText("SameColorGameCancelSkill", self.Skill:GetUsedCount())
        XUiManager.DialogTip(nil, content, XUiManager.DialogType.Normal, nil, callBack)
        ]]
    end
end

function XUiPanelBlackScreen:CheckClickDoSkill()
    if self:IsNoneMask() then
        return
    end
    if self:IsConditionMask() then
        self:UseNoParamSkill()

    elseif self:IsBuffMask() then
        self:UseNoParamSkill()

    elseif self:IsEnergyMask() then
        self:UseNoParamSkill()

    elseif self:IsSkillMask() then
        self:UseNoParamSkill()
    end
end
--endregion

--region Event
function XUiPanelBlackScreen:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_SC_PREP_SKILL, self.SetScreenMask, self)
    XEventManager.AddEventListener(XEventId.EVENT_SC_SKILL_USED, self.OnBtnCloseClick, self)
    XEventManager.AddEventListener(XEventId.EVENT_SC_ACTION_CD_CHANGE, self.OnCDChange, self)  -- 主动技能进入冷却
    XEventManager.AddEventListener(XEventId.EVENT_SC_BATTLE_CLOSE_BLACK_SCENE_TIPS, self.CloseSkillTips, self)
end

function XUiPanelBlackScreen:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_PREP_SKILL, self.SetScreenMask, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_SKILL_USED, self.OnBtnCloseClick, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_ACTION_CD_CHANGE, self.OnCDChange, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_BATTLE_CLOSE_BLACK_SCENE_TIPS, self.CloseSkillTips, self)
end
--endregion

return XUiPanelBlackScreen