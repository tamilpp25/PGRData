--自走棋关卡层
local XUiExpeditionTierChapter = XClass(nil, "XUiExpeditionTierChapter")
local TierScript = require("XUi/XUiExpedition/MainPage/XUiExpeditionTier")
local TWEEN_TIME = 0.5
local Manager
function XUiExpeditionTierChapter:Ctor(rootUi)
    self.RootUi = rootUi
    self:Init()
end

function XUiExpeditionTierChapter:Init()
    self.Tiers = {}
    self.Chapter = XDataCenter.ExpeditionManager.GetCurrentChapter()
    self.Content = self.RootUi.PanelChapterContent
    self.RectTransform = self.RootUi.Transform:GetComponent("RectTransform")
    self.RootUi.GridTierLayOff.gameObject:SetActiveEx(false)
    self.RootUi.GridTierLayOut.gameObject:SetActiveEx(false)
    self.RootUi.GridTierInfi.gameObject:SetActiveEx(false)
    Manager = XDataCenter.ExpeditionManager
    --CsXUiHelper.RegisterClickEvent(self.RootUi.ScrollRect, handler(self, self.CancelSelect))
    --local dragProxy = self.RootUi.ScrollRect.gameObject:AddComponent(typeof(CS.XUguiDragProxy))
    --dragProxy:RegisterHandler(handler(self, self.OnDragProxy))
end

function XUiExpeditionTierChapter:Show(difficulty)
    if self.Showing then return end
    self.Showing = true
    if self.Difficulty ~= difficulty and self.Tiers[self.Difficulty] then
        for _, tier in pairs(self.Tiers[self.Difficulty]) do
            tier:Hide()
        end
    end
    self.Difficulty = difficulty
    local tiers = self.Chapter:GetStagesByDifficulty(self.Difficulty)
    if not self.Tiers[self.Difficulty] then
        self.Tiers[self.Difficulty] = {}
    end
    local index = 1
    while(true) do
        if tiers[index] and tiers[index]:GetIsUnlock() then
            if not self.Tiers[self.Difficulty][index] then
                self.Tiers[self.Difficulty][index] = TierScript.New(self)
            end
            self.Tiers[self.Difficulty][index]:RefreshData(tiers[index])
        else
            break
        end
        index = index + 1
    end
    self.RootUi:ChangeBg(self.Chapter:GetStageBgByDifficult(self.Difficulty))
    self.RootUi:ChangeBgFx(self.Chapter:GetChapterBgFxByDifficult(self.Difficulty))
    self.RootUi:ChangeRewardIcon(self.Chapter:GetRewardIconByDifficult(self.Difficulty))
    self:GotoLastStage()
    self.Showing = false
end

function XUiExpeditionTierChapter:OnDragProxy(dragType)
    if dragType == 0 then
        self:OnScrollRectBeginDrag()
    elseif dragType == 2 then
        self:OnScrollRectEndDrag()
    end
end

function XUiExpeditionTierChapter:OnScrollRectBeginDrag()
    if self:CancelSelect() then
        self.RootUi.ScrollRect.enabled = false
    end
end

function XUiExpeditionTierChapter:OnScrollRectEndDrag()
    self.RootUi.ScrollRect.enabled = true
end

-- 返回滚动容器是否动画回弹
function XUiExpeditionTierChapter:CancelSelect()
    if not self.StageSelected then
        return false
    end
    self.StageSelected:CancelSelect()
    self.RootUi.ScrollRect.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic
    self.StageSelected = nil
    return self:ScrollRectRollBack()
end

function XUiExpeditionTierChapter:ScrollRectRollBack()
    -- 滚动容器回弹
    local width = self.RectTransform.rect.width
    local innerWidth = self.PanelChapterContent.rect.width
    innerWidth = innerWidth < width and width or innerWidth
    local diff = innerWidth - width
    local tarPosX
    if self.PanelChapterContent.localPosition.x < -width / 2 - diff then
        tarPosX = -width / 2 - diff
    elseif self.PanelChapterContent.localPosition.x > -width / 2 then
        tarPosX = -width / 2
    else
        self.RootUi.ScrollRect.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic
        return false
    end

    self:PlayScrollViewMoveBack(tarPosX)
    return true
end

function XUiExpeditionTierChapter:PlayScrollViewMoveBack(tarPosX)
    local tarPos = self.PanelChapterContent.localPosition
    tarPos.x = tarPosX
    XLuaUiManager.SetMask(true)

    XUiHelper.DoMove(self.PanelChapterContent, tarPos, XDataCenter.FubenMainLineManager.UiGridChapterMoveDuration, XUiHelper.EaseType.Sin, function()
            self.RootUi.ScrollRect.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic
            XLuaUiManager.SetMask(false)
        end)
end
--=================
--滚动到最后的关卡
--=================
function XUiExpeditionTierChapter:GotoLastStage()
    local currentIndex = self.Chapter:GetCurrentIndexByDifficulty(self.Difficulty)
    local tier = self.Tiers[self.Difficulty][currentIndex]
    if not tier then
        return
    end
    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.RootUi.PanelChapterContent)
    self:SetTierSelect(currentIndex, true, false, true)
end
--=================
--滚动到目标的关卡
--=================
function XUiExpeditionTierChapter:GotoTargetStage(tier)
    if not tier then return end
    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.RootUi.PanelChapterContent)
    local tierTransform = tier:GetRectTransform():GetComponent("RectTransform")
    local posX = tierTransform.localPosition.x - self.RootUi.PanelChapter.rect.width / 2
    local scrollRectOffset = (self.RootUi.ScrollRect.content.rect.width - self.RootUi.PanelChapter.rect.width)
    local current = self.RootUi.ScrollRect.horizontalNormalizedPosition * scrollRectOffset
    XLuaUiManager.SetMask(true)
    XUiHelper.Tween(TWEEN_TIME, function(t)
            if XTool.UObjIsNil(self.RootUi.Transform) then
                return
            end
            local temp = current + ((posX - current) * t) 
            local target = temp / scrollRectOffset
            self.RootUi.ScrollRect.horizontalNormalizedPosition = target
            end, function()
            XLuaUiManager.SetMask(false)
            end)
end

--=================
--选中关卡层
--index : 关卡层序号
--value : 是否选中
--isClick : 是否是手动点击的关卡层
--isEnable : 是否是界面显示时自动选中
--=================
function XUiExpeditionTierChapter:SetTierSelect(index, value, isClick, isEnable)
    if not self.Tiers[self.Difficulty][index] then return end
    if self.SetSelecting then return end
    self.SetSelecting = true
    if value and self.CurrentIndex and self.CurrentIndex > 0 and self.CurrentIndex ~= index and self.Tiers[self.Difficulty][self.CurrentIndex] then
        self.Tiers[self.Difficulty][self.CurrentIndex]:SetSelect(false, isClick)
    end
    self.Tiers[self.Difficulty][index]:SetSelect(value, isClick, isEnable)
    if value then
        self.CurrentIndex = index
        self:GotoTargetStage(self.Tiers[self.Difficulty][self.CurrentIndex])
        if isEnable then --界面显示时播放最新关卡层显示动画
            self.Tiers[self.Difficulty][self.CurrentIndex]:PlayAnimEnable(function()
                    --等动画完成后再拉一次画面
                    self:GotoTargetStage(self.Tiers[self.Difficulty][self.CurrentIndex])
                    end)
        end
    else
        self.CurrentIndex = 0
        CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.RootUi.PanelChapterContent)
    end
    self.SetSelecting = false
end

return XUiExpeditionTierChapter