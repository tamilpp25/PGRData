---@class XUiBlackRockChessChapterDetail : XLuaUi 关卡详情
---@field _Control XBlackRockChessControl
local XUiBlackRockChessChapterDetail = XLuaUiManager.Register(XLuaUi, "UiBlackRockChessChapterDetail")

function XUiBlackRockChessChapterDetail:OnAwake()
    self.BtnMask.CallBack = handler(self, self.OnBtnMaskClick)
    self.BtnEnter.CallBack = handler(self, self.OnBtnEnterClick)
end

function XUiBlackRockChessChapterDetail:OnStart(stageId)
    self._StageId = stageId
    self._StageConfig = self._Control:GetStageConfig(stageId)
    self:UpdateView()
end

function XUiBlackRockChessChapterDetail:UpdateView()
    self.TxtTitle.text = self._Control:GetStageName(self._StageId)
    local descList = self._Control:GetStageTargetDesc(self._StageId)
    local desc = ""
    if not XTool.IsTableEmpty(descList) then
        for _, targetDesc in ipairs(descList) do
            desc = desc .. targetDesc .. "\n"
        end
    end
    self.TxtTarget.text = desc

    local difficulty = self._Control:GetStageDifficulty(self._StageId)
    local isNormal = difficulty == XEnumConst.BLACK_ROCK_CHESS.DIFFICULTY.NORMAL
    self.DropList.gameObject:SetActiveEx(not isNormal)
    self.PanelTargetList.gameObject:SetActiveEx(isNormal)
    if isNormal then
        self:ShowStarReward()
    else
        self:ShowNormalReward()
    end
    self:ShowBossInfo()
    self.PanelBubbleSkillDetail.gameObject:SetActiveEx(false)

    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.PanelDetail)

    -- 战斗按钮文本
    local isFighting = XMVCA.XBlackRockChess:IsCurStageId(self._StageId)
    local values = self._Control:GetClientConfigValues("BtnFightName")
    local name = isFighting and values[2] or values[1]
    self.BtnEnter:SetName(name)
end

function XUiBlackRockChessChapterDetail:ShowNormalReward()
    local isPass = self._Control:IsStagePass(self._StageId)
    local rewards = self._Control:GetStageNormalRewards(self._StageId)
    self:RefreshTemplateGrids(self.GridReward, rewards, self.GridReward.parent, nil, "BlackRockChessDetailNormalReward", function(cell, data)
        if cell.Grid256 then
            cell.Grid256.gameObject:SetActiveEx(data.isItem)
            if data.isItem then
                ---@type XUiGridCommon
                local grid = require("XUi/XUiObtain/XUiGridCommon").New(self, cell.Grid256)
                grid:Refresh(data.reward)
                grid:SetReceived(isPass)
            end
        end
        if cell.PanelArms then
            cell.PanelArms.gameObject:SetActiveEx(data.isWeapon)
            if data.isWeapon then
                cell.RImgArms:SetRawImage(self._Control:GetWeaponIcon(data.reward))
                cell.PanelArmsNew.gameObject:SetActiveEx(not isPass)
                self:RegisterClickEvent(cell.PanelArms, function()
                    self._Control:OpenBubblePreview(data.reward, cell.PanelArms, XEnumConst.BLACK_ROCK_CHESS.SKILL_TIP_TYPE.WEAPON)
                end)
            end
        end
        if cell.PanelSkill then
            cell.PanelSkill.gameObject:SetActiveEx(data.isPassSkill or data.isBuff)
            if data.isPassSkill then
                cell.RImgSkill:SetRawImage(self._Control:GetWeaponSkillIcon(data.reward))
                self:RegisterClickEvent(cell.PanelSkill, function()
                    self._Control:OpenBubblePreview(data.reward, cell.PanelSkill, XEnumConst.BLACK_ROCK_CHESS.SKILL_TIP_TYPE.WEAPON_SKILL)
                end)
            elseif data.isBuff then
                local buffConfig = self._Control:GetBuffConfig(data.reward)
                cell.RImgSkill:SetRawImage(buffConfig.Icon)
                self:RegisterClickEvent(cell.PanelSkill, function()
                    self._Control:OpenBubblePreview(data.reward, cell.PanelSkill, XEnumConst.BLACK_ROCK_CHESS.SKILL_TIP_TYPE.CHARACTER_SKILL)
                end)
            end
            cell.PanelSkillNew.gameObject:SetActiveEx(not isPass)
        end
    end)
end

function XUiBlackRockChessChapterDetail:ShowStarReward()
    local templateId = self._Control:GetStageStarRewardTemplateId(self._StageId)
    local rewards = self._Control:GetStarRewardByTemplateId(templateId)
    local star = self._Control:GetStageStar(self._StageId)
    for i = 1, 3 do
        local reward = rewards and rewards[i]
        local go = self["GridStageStar" .. i]
        if XTool.IsTableEmpty(reward) then
            go.gameObject:SetActiveEx(false)
        else
            go.gameObject:SetActiveEx(true)
            local uiObject = {}
            XTool.InitUiObjectByUi(uiObject, go)
            local desc = self._Control:GetConditionDesc(reward.Conditions[1])
            uiObject.TxtUnActive.text = desc
            uiObject.TxtActive.text = desc
            uiObject.PanelUnActive.gameObject:SetActiveEx(star < i)
            uiObject.PanelActive.gameObject:SetActiveEx(star >= i)
            local datas = XRewardManager.GetRewardList(reward.RewardId)
            local poolName = string.format("BlackRockChessDetailHardReward_%s", i)
            self:RefreshTemplateGrids(uiObject.Grid256New, datas, uiObject.Grid256New.parent, nil, poolName, function(cell, data)
                local grid = require("XUi/XUiObtain/XUiGridCommon").New(self, cell.Transform)
                grid:Refresh(data)
                grid:SetReceived(star >= i)
            end)
        end
    end
end

function XUiBlackRockChessChapterDetail:ShowBossInfo()
    local isPassed = self._Control:IsStagePass(self._StageId)
    XUiHelper.RefreshCustomizedList(self.GridBoss.parent, self.GridBoss, #self._StageConfig.ShowBossId, function(index, go)
        local uiObject = {}
        local bossId = self._StageConfig.ShowBossId[index]
        local weaponId = self._Control:GetRoleWeaponId(bossId, 1)
        local skillIds = self._Control:GetWeaponSkillIds(weaponId)
        local bossName = self._Control:GetRoleName(bossId)
        XUiHelper.InitUiClass(uiObject, go)
        uiObject.RImgHead:SetSprite(self._StageConfig.ShowBossIcon[index])
        uiObject.PanelDead.gameObject:SetActiveEx(isPassed)
        uiObject.BtnClick.CallBack = function()
            self:ShowBubbleSkillDetail(bossName, skillIds)
        end
        XUiHelper.RefreshCustomizedList(uiObject.GridSkill.parent, uiObject.GridSkill, #skillIds, function(i, grid)
            local gridObject = {}
            local icon = self._Control:GetWeaponSkillIcon(skillIds[i])
            XUiHelper.InitUiClass(gridObject, grid)
            gridObject.RImgSkill:SetRawImage(icon)
        end)
    end)
end

function XUiBlackRockChessChapterDetail:ShowBubbleSkillDetail(bossName, skillIds)
    self.PanelBubbleSkillDetail.gameObject:SetActiveEx(true)
    if not self._BubbleSkillDetail then
        self._BubbleSkillDetail = {}
        XUiHelper.InitUiClass(self._BubbleSkillDetail, self.PanelBubbleSkillDetail)
    end
    self._BubbleSkillDetail.TxtName.text = bossName
    XUiHelper.RefreshCustomizedList(self._BubbleSkillDetail.GridSkillDetail.parent, self._BubbleSkillDetail.GridSkillDetail, #skillIds, function(index, go)
        local uiObject = {}
        local skillId = skillIds[index]
        local icon = self._Control:GetWeaponSkillIcon(skillId)
        XUiHelper.InitUiClass(uiObject, go)
        uiObject.RImgSkill:SetRawImage(icon)
        uiObject.TxtName.text = self._Control:GetWeaponSkillName(skillId)
        uiObject.TxtDetail.text = XUiHelper.ReplaceTextNewLine(self._Control:GetWeaponSkillDesc(skillId))
    end)
end

function XUiBlackRockChessChapterDetail:OnBtnEnterClick()
    local fightId = XMVCA.XBlackRockChess:GetFightingStageId()
    if XTool.IsNumberValid(fightId) and fightId ~= self._StageId then
        XUiManager.TipError(XUiHelper.GetText("BlackRockChessOtherFightTip"))
        return
    end
    self._Control:EnterStage(self._StageId, function()
        --XLuaUiManager.SafeClose("UiBlackRockChessChapter")
    end)
    self:Close()
end

function XUiBlackRockChessChapterDetail:OnBtnMaskClick()
    if self.PanelBubbleSkillDetail.gameObject.activeSelf then
        self.PanelBubbleSkillDetail.gameObject:SetActiveEx(false)
        return
    end
    self:Close()
end

return XUiBlackRockChessChapterDetail