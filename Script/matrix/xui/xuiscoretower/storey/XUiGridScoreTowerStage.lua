---@class XUiGridScoreTowerStage : XUiNode
---@field private _Control XScoreTowerControl
local XUiGridScoreTowerStage = XClass(XUiNode, "XUiGridScoreTowerStage")

function XUiGridScoreTowerStage:OnStart()
    XUiHelper.RegisterClickEvent(self, self.BtnStage, self.OnBtnStageClick, nil, true)
    self.GridCharacter.gameObject:SetActiveEx(false)
    ---@type XScoreTowerStageTeam 关卡队伍
    self.StageTeam = nil
    ---@type XUiGridScoreTowerCharacter[]
    self.GridStageCharacterList = {}
end

function XUiGridScoreTowerStage:OnDestroy()
    self.StageTeam = nil
end

-- 获取关卡ID  ScoreTowerStage表的ID
function XUiGridScoreTowerStage:GetStageId()
    return self.StageId
end

---@param chapterId number 章节ID
---@param towerId number 塔ID
---@param floorId number 层ID
---@param stageId number 关卡ID  ScoreTowerStage表的ID
function XUiGridScoreTowerStage:Refresh(chapterId, towerId, floorId, stageId)
    self.ChapterId = chapterId
    self.TowerId = towerId
    self.FloorId = floorId
    self.StageId = stageId
    self.StageTeam = self._Control:GetStageTeam(chapterId, towerId, floorId, stageId)
    -- Stage.tab的ID
    self.StageCfgId = self._Control:GetStageCfgId(stageId)
    self:RefreshCommon()
    self:RefreshOther()
    self:RefreshCharacterList()
end

function XUiGridScoreTowerStage:RefreshCommon()
    -- 关卡名称
    self.TxtTitle.text = XMVCA.XFuben:GetStageName(self.StageCfgId)
    -- 刷新Boss图标
    local bossIcon = self._Control:GetStageBossIcon(self.StageId)
    local isIconEmpty = string.IsNilOrEmpty(bossIcon)
    self.RImgBoss.gameObject:SetActiveEx(not isIconEmpty)
    if not isIconEmpty then
        self.RImgBoss:SetRawImage(bossIcon)
    end
end

function XUiGridScoreTowerStage:RefreshOther(isAnim)
    -- 子类重写
end

function XUiGridScoreTowerStage:GetStageEntityId(index)
    return 0
end

-- 是否是推荐标签
function XUiGridScoreTowerStage:IsRecommendTag(entityId)
    return self._Control:IsStageSuggestTag(self.StageId, entityId)
end

-- 是否隐藏试用标签
function XUiGridScoreTowerStage:IsHideTryTag()
    return true
end

-- 是否隐藏角色信息
function XUiGridScoreTowerStage:IsHideCharacterInfo()
    return false
end

-- 刷新关卡队伍
function XUiGridScoreTowerStage:RefreshCharacterList()
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
            grid = require("XUi/XUiScoreTower/Common/XUiGridScoreTowerCharacter").New(go, self)
            self.GridStageCharacterList[index] = grid
        end
        grid:Open()
        grid:SetHideTry(self:IsHideTryTag())
        grid:SetHideCharacterInfo(self:IsHideCharacterInfo())
        local entityId = self:GetStageEntityId(index)
        grid:Refresh(entityId, index)
        grid:SetIsRecommend(self:IsRecommendTag(entityId))
    end
    for index = limitCount + 1, #self.GridStageCharacterList do
        self.GridStageCharacterList[index]:Close()
    end
end

-- 设置选择状态
function XUiGridScoreTowerStage:SetSelect(isSelect)
    if self.Select then
        self.Select.gameObject:SetActiveEx(isSelect)
    end
end

function XUiGridScoreTowerStage:OnBtnStageClick()
    XLuaUiManager.Open("UiScoreTowerPopupStageDetail", self.ChapterId, self.TowerId, self.FloorId, self.StageId)
end

return XUiGridScoreTowerStage
