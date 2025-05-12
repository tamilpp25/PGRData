local XUiGridScoreTowerStage = require("XUi/XUiScoreTower/Storey/XUiGridScoreTowerStage")
---@class XUiGridScoreTowerStageBoss : XUiGridScoreTowerStage
---@field private _Control XScoreTowerControl
local XUiGridScoreTowerStageBoss = XClass(XUiGridScoreTowerStage, "XUiGridScoreTowerStageBoss")

function XUiGridScoreTowerStageBoss:OnStart()
    self.Super.OnStart(self)
    self.GridStar.gameObject:SetActiveEx(false)
    ---@type UiObject[]
    self.GridStageStarList = {}
end

function XUiGridScoreTowerStageBoss:RefreshOther(isAnim)
    -- 是否是最终boss
    local isFinalBoss = self._Control:IsStageFinalBoss(self.StageId)
    self.TxtTarget.gameObject:SetActiveEx(not isFinalBoss)
    self.ListStar.gameObject:SetActiveEx(isFinalBoss)

    if isFinalBoss then
        self:RefreshStar()
        return
    end

    local selectedPluginIdList = self._Control:GetStageSelectedPlugIds(self.ChapterId, self.TowerId, self.StageId)
    local _, reduceScore = self._Control:GetPlugEffectAddFightTimeAndReduceScore(selectedPluginIdList)
    self.TxtTarget.text = self._Control:GetStageBossPassDesc(self.StageId, 1, reduceScore)
end

-- 刷新三星
function XUiGridScoreTowerStageBoss:RefreshStar()
    local curStar = self._Control:GetStageCurStar(self.ChapterId, self.TowerId, self.StageId)
    local totalStar = self._Control:GetStageTotalStar(self.StageId)
    for i = 1, totalStar do
        local star = self.GridStageStarList[i]
        if not star then
            star = XUiHelper.Instantiate(self.GridStar, self.ListStar)
            self.GridStageStarList[i] = star
        end
        star.gameObject:SetActiveEx(true)
        star:GetObject("ImgStarOff").gameObject:SetActiveEx(i > curStar)
        star:GetObject("ImgStarOn").gameObject:SetActiveEx(i <= curStar)
    end
    for i = totalStar + 1, #self.GridStageStarList do
        self.GridStageStarList[i].gameObject:SetActiveEx(false)
    end
end

function XUiGridScoreTowerStageBoss:GetStageEntityId(index)
    -- 检查普通关卡是否全部通关
    local isAllPass = self._Control:IsNormalStageAllPass(self.ChapterId, self.TowerId, self.FloorId)
    if not isAllPass then
        return 0
    end
    return self.StageTeam:GetEntityIdByIndex(index) or 0
end

return XUiGridScoreTowerStageBoss
