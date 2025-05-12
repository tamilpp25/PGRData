---@class XUiGridPcgStage : XUiNode
---@field private _Control XPcgControl
local XUiGridPcgStage = XClass(XUiNode, "XUiGridPcgStage")

function XUiGridPcgStage:OnStart()
    self:RegisterUiEvents()
end

function XUiGridPcgStage:OnEnable()
    
end

function XUiGridPcgStage:OnDisable()
    
end

function XUiGridPcgStage:OnDestroy()
end

function XUiGridPcgStage:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.Button, self.OnStageClick, nil, true)
    XUiHelper.RegisterClickEvent(self, self.BtnGiveUp, self.OnBtnGiveUpClick, nil, true)
end

function XUiGridPcgStage:OnStageClick()
    self.ClickCb(self.Index)
end

function XUiGridPcgStage:OnBtnGiveUpClick()
    self.GiveUpCb(self.Index)
end

-- 设置点击回调
function XUiGridPcgStage:SetClickCallBack(clickCb, giveUpCb)
    self.ClickCb = clickCb
    self.GiveUpCb = giveUpCb
end

-- 设置数据
function XUiGridPcgStage:SetData(index, stageId)
    self.Index = index
    self.StageId = stageId
    self:Refresh()
end

function XUiGridPcgStage:Refresh()
    self:RefreshInfo()

    self.PanelScore.gameObject:SetActiveEx(false)
    self.PanelStar.gameObject:SetActiveEx(false)
    local stageType = self._Control:GetStageType(self.StageId)
    if stageType ~= XEnumConst.PCG.STAGE_TYPE.ENDLESS then
        self:RefreshStar()
    else
        self:RefreshScore()
    end
end

function XUiGridPcgStage:RefreshInfo()
    local stageCfg = self._Control:GetConfigStage(self.StageId)
    local isUnlock, tips = self._Control:IsStageUnlock(self.StageId)
    self.TxtName.text = stageCfg.Name
    self.PanelLock.gameObject:SetActiveEx(not isUnlock)
    self.TxtLockTips.text = tips
    local currentStageId = self._Control:GetCurrentStageId()
    local isPlaying = currentStageId == self.StageId
    self.BtnGiveUp.gameObject:SetActiveEx(isPlaying)
    self.TagOngoing.gameObject:SetActiveEx(isPlaying)
    local isPassed = self._Control:IsStagePassed(self.StageId)
    self.TagClear.gameObject:SetActiveEx(isPassed)
    
    -- 背景
    self.ImgBg:SetRawImage(stageCfg.Icon)
    self.RawImgLockBg = self.RawImgLockBg or self.Transform:Find("PanelLock/ImgMask"):GetComponent("RawImage")
    self.RawImgLockBg:SetRawImage(stageCfg.Icon)

    -- 怪物头像
    local monsterId = self._Control:GetStageBossMonsterId(self.StageId)
    local monsterCfg = self._Control:GetConfigMonster(monsterId)
    self.RImgMonsterHead:SetRawImage(monsterCfg.HeadIcon)
end

-- 刷新星级
function XUiGridPcgStage:RefreshStar()
    self.PanelStar.gameObject:SetActiveEx(true)
    
    self.StarUiObjs = self.StarUiObjs or {}
    self.GridStar.gameObject:SetActiveEx(false)
    for _, uiObj in ipairs(self.StarUiObjs) do
        uiObj.gameObject:SetActiveEx(false)
    end

    local stageCfg = self._Control:GetConfigStage(self.StageId)
    ---@type XPcgStageRecord
    local stageRecord = self._Control:GetActivityData():GetStageRecord(self.StageId)
    local stars = stageRecord and stageRecord:GetStars() or 0
    local CSInstantiate = CS.UnityEngine.Object.Instantiate
    for i, _ in ipairs(stageCfg.StarDesc) do
        local uiObj = self.StarUiObjs[i]
        if not uiObj then
            local go = CSInstantiate(self.GridStar.gameObject, self.GridStar.transform.parent)
            uiObj = go:GetComponent(typeof(CS.UiObject))
            table.insert(self.StarUiObjs, uiObj)
        end
        uiObj.gameObject:SetActiveEx(true)
        local isActive = i <= stars
        uiObj:GetObject("ImgStarOn").gameObject:SetActiveEx(isActive)
        uiObj:GetObject("ImgStarOff").gameObject:SetActiveEx(not isActive)
    end
end

-- 刷新分数
function XUiGridPcgStage:RefreshScore()
    local isUnlock, tips = self._Control:IsStageUnlock(self.StageId)
    self.PanelScore.gameObject:SetActiveEx(isUnlock)
    if isUnlock then
        ---@type XPcgStageRecord
        local stageRecord = self._Control:GetActivityData():GetStageRecord(self.StageId)
        local score = stageRecord and stageRecord:GetScore() or 0
        self.TxtScoreNum.text = tostring(score)
    end
end

return XUiGridPcgStage
