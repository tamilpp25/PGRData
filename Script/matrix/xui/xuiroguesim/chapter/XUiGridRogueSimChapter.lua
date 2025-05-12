---@class XUiGridRogueSimChapter : XUiNode
---@field private _Control XRogueSimControl
---@field BtnChapter XUiComponent.XUiButton
local XUiGridRogueSimChapter = XClass(XUiNode, "XUiGridRogueSimChapter")

function XUiGridRogueSimChapter:OnStart()
    XUiHelper.RegisterClickEvent(self, self.BtnChapter, self.OnBtnChapterClick, nil, true)
    self.ImgClear.gameObject:SetActiveEx(false)
    -- 是否刷新时间
    self.IsRefreshTime = false
end

function XUiGridRogueSimChapter:OnEnable()
    self.IsRefreshTime = false
end

function XUiGridRogueSimChapter:Refresh(stageId)
    self.StageId = stageId
    local isUnlock = self:IsUnlock()

    -- 名字
    if self.Button then
        local name = self._Control:GetRogueSimStageName(stageId)
        self.Button:SetName(name)
    end
    -- 是否通关
    local isPass = self._Control:CheckStageIsPass(stageId)
    self.ImgClear.gameObject:SetActiveEx(isPass)
    -- 最大分数
    local maxPoint = self._Control:GetStageRecordMaxPoint(stageId)
    if self.TxtScore then
        if maxPoint > 0 then
            local str = self._Control:GetClientConfig("StageMaxScore")
            self.TxtScore.text = string.format(str, maxPoint)
        else
            self.TxtScore.text = self._Control:GetClientConfig("StageMaxScoreEmpty")
        end
    end
    -- 三星
    if self.ImgStars then
        self.ImgStars.gameObject:SetActiveEx(isUnlock)
        self:RefreshStars()
    end
    -- 是否解锁
    self:RefreshStatus()
end

-- 刷新倒计时
function XUiGridRogueSimChapter:RefreshTime()
    if XTool.UObjIsNil(self.GameObject) then
        return
    end
    if not self.IsRefreshTime then
        return
    end
    local leftTime = self._Control:GetStageStartTime(self.StageId) - XTime.GetServerNowTimestamp()
    if leftTime <= 0 then
        self.IsRefreshTime = false
        self:RefreshStatus()
        return
    end
    local timeStr = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
    self.TxtOpenTime.text = string.format(self._Control:GetClientConfig("StageNotUnlockDesc", 1), timeStr)
end

-- 刷新三星
function XUiGridRogueSimChapter:RefreshStars()
    local starMask = self._Control:GetStageRecordStarMask(self.StageId)
    local _, map = self._Control:GetStageStarCount(starMask)
    local conditions = self._Control:GetRogueSimStageStarConditions(self.StageId)
    for i, isReach in ipairs(map) do
        self["StarYes" .. i].gameObject:SetActiveEx(isReach)
        self["StaNo" .. i].gameObject:SetActiveEx(not isReach)

        local isShow = #conditions >= i
        self["Star" .. i].gameObject:SetActiveEx(isShow)
    end
end

-- 关卡是否解锁
function XUiGridRogueSimChapter:IsUnlock()
    local isInTime = self._Control:CheckStageIsInOpenTime(self.StageId)
    if not isInTime then
        local tips = self._Control:GetStageOpenCountDownDesc(self.StageId)
        return false, tips, true
    end
    local isPrePass = self._Control:CheckPreStageIsPass(self.StageId)
    if not isPrePass then
        local tips = self._Control:GetPreStageNotPassDesc(self.StageId)
        return false, tips, false
    end
    return true, "", false
end

function XUiGridRogueSimChapter:RefreshStatus()
    local isUnlock, desc, needRefreshTime = self:IsUnlock()
    self.IsRefreshTime = needRefreshTime
    self.BtnChapter:SetDisable(not isUnlock)
    if not isUnlock then
        self.TxtOpenTime.text = desc
    end
    if self.PanelScore then
        self.PanelScore.gameObject:SetActiveEx(isUnlock)
    end
    if self.ImgStars then
        self.ImgStars.gameObject:SetActiveEx(isUnlock)
    end

    -- 蓝点
    local isRed = XMVCA.XRogueSim:IsShowStageRedPoint(self.StageId)
    self.Button:ShowReddot(isRed)
end

function XUiGridRogueSimChapter:OnDisable()
    self.IsRefreshTime = false
end

function XUiGridRogueSimChapter:OnBtnChapterClick()
    if not self._Control:CheckStageIsInOpenTime(self.StageId) then
        XUiManager.TipMsg(self._Control:GetStageOpenCountDownDesc(self.StageId))
        return
    end
    if not self._Control:CheckPreStageIsPass(self.StageId) then
        XUiManager.TipMsg(self._Control:GetPreStageNotPassDesc(self.StageId))
        return
    end
    -- 打开详情面板
    XLuaUiManager.Open("UiRogueSimChapterDetail", self.StageId)
end

return XUiGridRogueSimChapter
