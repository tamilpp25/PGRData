-- 普通解放
local XUiPanelExhibitionNormalInfo = XClass(nil, "XUiPanelExhibitionNormalInfo")
local XUiGridCondition = require("XUi/XUiExhibition/XUiGridCondition")
local ConditionDesNum = 3

function XUiPanelExhibitionNormalInfo:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)

    XUiHelper.RegisterClickEvent(self, self.BtnBreak, self.OnBtnBreakClick)
end

function XUiPanelExhibitionNormalInfo:Refresh(characterId, exhibitionRewardConfig)
    self.CharacterId = characterId
    self.ExhibitionRewardConfig = exhibitionRewardConfig
    local levelId = exhibitionRewardConfig.LevelId
    self.TxtTitle.text = XCharacterConfigs.GetCharLiberationLevelTitle(characterId, levelId)
    self.TxtDesc.text = XCharacterConfigs.GetCharLiberationLevelDesc(characterId, levelId)

    local passed = true
    self.ConditionGrids = self.ConditionGrids or {}
    local conditionIds = exhibitionRewardConfig.ConditionIds
    for i = 1, ConditionDesNum do
        local conditionGrid = self.ConditionGrids[i]
        if not conditionGrid then
            conditionGrid = XUiGridCondition.New(self["GridCondition" .. i])
            self.ConditionGrids[i] = conditionGrid
        end

        local conditionId = conditionIds[i]
        local subPassed = conditionGrid:Refresh(conditionId, characterId)
        passed = passed and subPassed
    end

    local rewardItems = XRewardManager.GetRewardList(exhibitionRewardConfig.RewardId)
    self.RewardPool = self.RewardPool or {}
    XUiHelper.CreateTemplates(self.RootUi, self.RewardPool, rewardItems, XUiGridCommon.New, self.GridRewardItem, self.PanelRewardItem, function(grid, data)
        grid:Refresh(data)
    end)

    local taskId = exhibitionRewardConfig.Id
    local taskFinished = XDataCenter.ExhibitionManager.CheckGrowUpTaskFinish(taskId)
    local canGetReward = passed and not taskFinished
    self.BtnBreak:SetDisable(not canGetReward, canGetReward)
    self.PanelAlreadyBreak.gameObject:SetActive(taskFinished)
    self.BtnBreak.gameObject:SetActive(not taskFinished)

    self.BtnShowInfoToggle.gameObject:SetActiveEx(false)
end

function XUiPanelExhibitionNormalInfo:OnBtnBreakClick()
    -- 条件
    self.ConditionGrids = self.ConditionGrids or {}
    local conditionIds = self.ExhibitionRewardConfig.ConditionIds
    for i = 1, ConditionDesNum do
        local conditionId = conditionIds[i]
        if XTool.IsNumberValid(conditionId) then
            local res, desc = XConditionManager.CheckCondition(conditionId, self.CharacterId)
            if not res then
                XUiManager.TipError(desc)
                return
            end
        end
    end

    self.RootUi:OnBtnBreakClick()
end

function XUiPanelExhibitionNormalInfo:Show()
    self.GameObject:SetActive(true)
end

function XUiPanelExhibitionNormalInfo:Hide()
    self.GameObject:SetActive(false)
end

return XUiPanelExhibitionNormalInfo