---@class XUiPanelFavorabilityStoryReward: XUiNode
---@field _Control XFavorabilityControl
local XUiPanelFavorabilityStoryReward = XClass(XUiNode, 'XUiPanelFavorabilityStoryReward')
local XUiGridFavorabilityStoryReward = require('XUi/XUiFavorability/StoryPanel/XUiGridFavorabilityStoryReward')

function XUiPanelFavorabilityStoryReward:OnStart(characterId)
    self._CharacterId = characterId
    self:InitRewardGrids()
end

function XUiPanelFavorabilityStoryReward:OnEnable()
    self:RefreshProgress()
end

function XUiPanelFavorabilityStoryReward:InitRewardGrids()
    self.GridReward.gameObject:SetActiveEx(false)
    self._RewardGrids = {}
    -- 获取奖励配置
    local plotDatas = XMVCA.XFavorability:GetCharacterStoryById(self._CharacterId)
    if not XTool.IsTableEmpty(plotDatas) then
        local count = XTool.GetTableCount(plotDatas)
        for i, v in ipairs(plotDatas) do
            if XTool.IsNumberValid(v.TaskId) then
                local go = CS.UnityEngine.GameObject.Instantiate(self.GridReward, self.GridReward.transform.parent)
                local grid = XUiGridFavorabilityStoryReward.New(go, self, i, v.TaskId, count)
                grid:Open()
                table.insert(self._RewardGrids, grid)
            end
        end
    end
end

function XUiPanelFavorabilityStoryReward:RefreshProgress()
    local plotDatas = XMVCA.XFavorability:GetCharacterStoryById(self._CharacterId)
    -- 刷新通关进度
    local totalCount = XTool.GetTableCount(plotDatas)
    local passCount = 0

    if not XTool.IsTableEmpty(plotDatas) then
        for i, v in ipairs(plotDatas) do
            if XTool.IsNumberValid(v.StoryId) then
                passCount = passCount + 1
            elseif XTool.IsNumberValid(v.StageId) then
                if XMVCA.XFuben:CheckStageIsPass(v.StageId) then
                    passCount = passCount + 1
                end
            end
        end
    end
    
    self.TxtClearNum.text = passCount
    self.TxtAllNum.text = '/'..tostring(totalCount)
end

return XUiPanelFavorabilityStoryReward