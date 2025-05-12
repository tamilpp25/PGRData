---@class XUiPanelScoreTowerStage : XUiNode
---@field private _Control XScoreTowerControl
---@field Parent XUiScoreTowerPopupStageDetail
local XUiPanelScoreTowerStage = XClass(XUiNode, "XUiPanelScoreTowerStage")

function XUiPanelScoreTowerStage:OnStart()
    XUiHelper.RegisterClickEvent(self, self.BtnStart, self.OnBtnStartClick, nil, true)
    self.GridCharacter.gameObject:SetActiveEx(false)
    ---@type XScoreTowerStageTeam 关卡队伍
    self.StageTeam = nil
    ---@type XUiGridScoreTowerCharacter[]
    self.GridStageCharacterList = {}
end

function XUiPanelScoreTowerStage:OnDestroy()
    self.StageTeam = nil
end

---@param chapterId number 章节ID
---@param towerId number 塔ID
---@param floorId number 层ID
---@param stageId number 关卡Id ScoreTowerStage表的ID
function XUiPanelScoreTowerStage:Refresh(chapterId, towerId, floorId, stageId)
    self.ChapterId = chapterId
    self.TowerId = towerId
    self.FloorId = floorId
    self.StageId = stageId
    self.StageTeam = self._Control:GetStageTeam(chapterId, towerId, floorId, stageId)
    self.IndexMapping = self.StageTeam:GetIndexMapping()
    -- Stage.tab的ID
    self.StageCfgId = self._Control:GetStageCfgId(stageId)
    self:RefreshCommon()
    self:RefreshOther()
end

function XUiPanelScoreTowerStage:RefreshCommon()
    -- 关卡名称
    self.TxtTitle.text = XMVCA.XFuben:GetStageName(self.StageCfgId)
end

function XUiPanelScoreTowerStage:RefreshOther()
    -- 子类重写
end

-- 是否隐藏试用标签
function XUiPanelScoreTowerStage:IsHideTryTag()
    return true
end

-- 是否显示红点
function XUiPanelScoreTowerStage:IsShowRedDot()
    return false
end

-- 是否是推荐标签
function XUiPanelScoreTowerStage:IsRecommendTag(entityId)
    return self._Control:IsStageSuggestTag(self.StageId, entityId)
end

-- 点击角色
---@param entityId number 实体ID
---@param index number 索引
function XUiPanelScoreTowerStage:OnGridCharacterClick(entityId, index)
    -- Boss无交互功能
end

-- 刷新角色信息
function XUiPanelScoreTowerStage:RefreshCharacterList()
    if not self.StageTeam then
        XLog.Error(string.format("error: StageTeam is nil, chapterId:%s, towerId:%s, floorId:%s, stageId:%s", self.ChapterId, self.TowerId,
            self.FloorId, self.StageId))
        return
    end
    local limitCount = self._Control:GetStageCharacterNum(self.StageId)
    for index = 1, limitCount do
        local grid = self.GridStageCharacterList[index]
        if not grid then
            local go = XUiHelper.Instantiate(self.GridCharacter, self.ListCharacter)
            grid = require("XUi/XUiScoreTower/Common/XUiGridScoreTowerCharacter").New(go, self, handler(self, self.OnGridCharacterClick))
            self.GridStageCharacterList[index] = grid
        end
        grid:Open()
        grid:SetHideTry(self:IsHideTryTag())
        grid:SetShowRedDot(self:IsShowRedDot())
        local entityId = self.StageTeam:GetEntityIdByTeamPos(self.IndexMapping[index]) or 0
        grid:Refresh(entityId, index)
        grid:SetIsRecommend(self:IsRecommendTag(entityId))
    end
    for index = limitCount + 1, #self.GridStageCharacterList do
        self.GridStageCharacterList[index]:Close()
    end
end

-- 进编队前检查
function XUiPanelScoreTowerStage:CheckBeforeEnterFormation()
    return true
end

-- 进入编队前请求协议
function XUiPanelScoreTowerStage:RequestBeforeEnterFormation(callback)
    if callback then
        callback()
    end
end

function XUiPanelScoreTowerStage:OnBtnStartClick()
    if not self.StageTeam or not XTool.IsNumberValid(self.StageCfgId) then
        XLog.Error(string.format("error: StageTeam is nil or StageCfgId is invalid, chapterId:%s, towerId:%s, floorId:%s, stageId:%s",
            self.ChapterId, self.TowerId, self.FloorId, self.StageId))
        return
    end
    if not self:CheckBeforeEnterFormation() then
        return
    end
    self:RequestBeforeEnterFormation(function()
        self:EnterFormation()
    end)
end

-- 进入编队界面
function XUiPanelScoreTowerStage:EnterFormation()
    XLuaUiManager.Open(
        "UiBattleRoleRoom",
        self.StageCfgId,
        self.StageTeam,
        require("XUi/XUiScoreTower/BattleRoom/XUiScoreTowerStageBattleRoleRoom"))
end

return XUiPanelScoreTowerStage
