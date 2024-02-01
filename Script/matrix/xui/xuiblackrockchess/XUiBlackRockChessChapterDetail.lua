---@class XUiBlackRockChessChapterDetail : XLuaUi 关卡详情
---@field _Control XBlackRockChessControl
local XUiBlackRockChessChapterDetail = XLuaUiManager.Register(XLuaUi, "UiBlackRockChessChapterDetail")

function XUiBlackRockChessChapterDetail:OnAwake()
    self:RegisterClickEvent(self.BtnMask, self.Close)
    self:RegisterClickEvent(self.BtnEnter, self.OnBtnEnterClick)
end

function XUiBlackRockChessChapterDetail:OnStart(stageId)
    self._StageId = stageId
    self:InitCompnent()
    self:UpdateView()
end

function XUiBlackRockChessChapterDetail:OnDestroy()

end

function XUiBlackRockChessChapterDetail:InitCompnent()
    local chapterId = self._Control:GetStageChapterId(self._StageId)
    local currencyIds = self._Control:GetCurrencyIds()

    local itemId = currencyIds[chapterId]
    if XTool.IsNumberValid(itemId) then
        if not self.AssetPanel then
            self.AssetPanel = XUiHelper.NewPanelActivityAssetSafe({ itemId }, self.PanelSpecialTool, self)
        else
            self.AssetPanel:Refresh({ itemId })
        end
        self.PanelSpecialTool.gameObject:SetActiveEx(true)
    else
        self.PanelSpecialTool.gameObject:SetActiveEx(false)
    end
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
    self.DropList.gameObject:SetActiveEx(isNormal)
    self.PanelTargetList.gameObject:SetActiveEx(not isNormal)
    if isNormal then
        self:ShowNormalReward()
    else
        self:ShowHardReward()
    end
    self:ShowBuff()
    
    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.PanelDetail)
end

function XUiBlackRockChessChapterDetail:ShowNormalReward()
    local isPass = self._Control:IsStagePass(self._StageId)
    local rewards = self._Control:GetStageNormalRewards(self._StageId)
    self:RefreshTemplateGrids(self.GridReward, rewards, self.GridReward.parent, nil, "BlackRockChessDetailNormalReward", function(cell, data)
        if cell.Grid256 then
            cell.Grid256.gameObject:SetActiveEx(data.isItem)
            if data.isItem then
                ---@type XUiGridCommon
                local grid = XUiGridCommon.New(self, cell.Grid256)
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

function XUiBlackRockChessChapterDetail:ShowHardReward()
    local templateId = self._Control:GetStageStarRewardTemplateId(self._StageId)
    local rewards = self._Control:GetStarRewardByTemplateId(templateId)
    local star = self._Control:GetStageStar(self._StageId)
    for i = 1, 3 do
        local reward = rewards[i]
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
                local grid = XUiGridCommon.New(self, cell.Transform)
                grid:Refresh(data)
                grid:SetReceived(star >= i)
            end)
        end
    end
end

function XUiBlackRockChessChapterDetail:ShowBuff()
    local buffIds = self._Control:GetStageDisplayBuffIds(self._StageId)
    local isEmpty = XTool.IsTableEmpty(buffIds)
    if self.PanelAffix then
        self.PanelAffix.gameObject:SetActiveEx(not isEmpty)
    end
    if isEmpty then
        return
    end
    self:RefreshTemplateGrids(self.BtnAffix, buffIds, self.BtnAffix.transform.parent, nil, "BlackRockChessDetailBuff", 
            function(grid, data)
        local buffConfig = self._Control:GetBuffConfig(data)
        grid.BtnAffix:SetNameByGroup(0, buffConfig.Name)
        grid.BtnAffix:SetRawImage(buffConfig.Icon)
        self:RegisterClickEvent(grid.BtnAffix, function()
            self:OnBtnBuffClick(buffConfig.Name, buffConfig.Icon, buffConfig.Desc)
        end)
    end)
end

function XUiBlackRockChessChapterDetail:OnBtnBuffClick(name, icon, desc)
    local param = {}
    param.Name = name
    param.Icon = icon
    param.Description = desc
    XLuaUiManager.Open("UiReformBuffDetail", param)
end

function XUiBlackRockChessChapterDetail:OnBtnEnterClick()
    self._Control:GetAgency():ClearCurrentCombat()
    self._Control:EnterStage(self._StageId, function() 
        XLuaUiManager.SafeClose("UiBlackRockChessChapter")
    end)
    self:Close()
end

return XUiBlackRockChessChapterDetail