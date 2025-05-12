local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridCharacter = require("XUi/XUiCharacter/XUiGridCharacter")
local XUiPanelCharacterTowerFetterTotem = require("XUi/XUiCharacterTower/Fetter/XUiPanelCharacterTowerFetterTotem")
local XUiGridCharacterTowerFetterTask = require("XUi/XUiCharacterTower/Fetter/XUiGridCharacterTowerFetterTask")
local XUiGridCharacterTowerFetterItem = require("XUi/XUiCharacterTower/Fetter/XUiGridCharacterTowerFetterItem")
local XUiGridCharacterTowerInformation = require("XUi/XUiCharacterTower/Fetter/XUiGridCharacterTowerInformation")
---@class XUiCharacterTowerFetter : XLuaUi
local XUiCharacterTowerFetter = XLuaUiManager.Register(XLuaUi, "UiCharacterTowerFetter")

local MathLerp = CS.UnityEngine.Mathf.Lerp

function XUiCharacterTowerFetter:OnAwake()
    self:RegisterUiEvents()
    self.GridTask.gameObject:SetActiveEx(false)
    
    self.GridFetterList = {}
    self.GridInformationList = {}
    self.ImgPercent.fillAmount = 0
end

function XUiCharacterTowerFetter:OnStart(relationId, characterId)
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.RelationId = relationId
    self.CharacterId = characterId
    ---@type XCharacterTowerRelation
    self.RelationViewModel = XDataCenter.CharacterTowerManager.GetCharacterTowerRelation(relationId)
    
    self:InitFetterTotemPrefab()
    self:InitDynamicTable()
end

function XUiCharacterTowerFetter:OnEnable()
    self:InitFetterListAndInformation()
    self:RefreshProgress()
    self:SetupDynamicTable()
    self:CheckAutomaticFetter(true)
end

function XUiCharacterTowerFetter:OnGetEvents()
    return {
        XEventId.EVENT_CHARACTER_TOWER_CHECK_FETTER,
    }
end

function XUiCharacterTowerFetter:OnNotify(event, ...)
    if event == XEventId.EVENT_CHARACTER_TOWER_CHECK_FETTER then
        self:CheckAutomaticFetter(false)
    end
end

function XUiCharacterTowerFetter:OnDisable()
    self:CancelSelect()
    self.PlayConditionId = 0
    self:StopProgressAnim()
    self.CurPanelFetterTotem:OnDisable()
end

function XUiCharacterTowerFetter:OnDestroy()

end

function XUiCharacterTowerFetter:InitFetterTotemPrefab()
    local fettersPrefab = self.RelationViewModel:GetRelationFettersPrefab()
    local gameObject = self.PanelFetterTotem:LoadPrefab(fettersPrefab)
    if gameObject == nil or not gameObject:Exist() then
        return
    end
    ---@type XUiPanelCharacterTowerFetterTotem
    self.CurPanelFetterTotem = XUiPanelCharacterTowerFetterTotem.New(gameObject, self, self.RelationId)
end

function XUiCharacterTowerFetter:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelFetterTask)
    self.DynamicTable:SetProxy(XUiGridCharacterTowerFetterTask, self, self.RelationId, self.CharacterId)
    self.DynamicTable:SetDelegate(self)
end

function XUiCharacterTowerFetter:SetupDynamicTable()
    self.DataList = self:GetDataList()
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataASync(1)
end

---@param grid XUiGridCharacterTowerFetterTask
function XUiCharacterTowerFetter:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.DataList[index])
    end
end

function XUiCharacterTowerFetter:GetDataList()
    self.RelationViewModel:CheckPlayAnimCondition(self.CharacterId)
    local conditionIds = self.RelationViewModel:GetRelationConditionIds()
    -- 克隆条件
    local cloneConditions = XTool.Clone(conditionIds)
    table.sort(cloneConditions,function(a, b)
        local isOpenA = self.RelationViewModel:CheckFinishCondition(a, self.CharacterId)
        local isOpenB = self.RelationViewModel:CheckFinishCondition(b, self.CharacterId)
        local isPlayEffectA = XDataCenter.CharacterTowerManager.CheckRelationTaskPlayAnim(a)
        local isPlayEffectB = XDataCenter.CharacterTowerManager.CheckRelationTaskPlayAnim(b)
        if isOpenA and isOpenB then
            if not isPlayEffectA and not isPlayEffectB then
                return a < b
            end
        end
        if isOpenA and not isPlayEffectA then
            return isOpenA
        end
        if isOpenB and not isPlayEffectB then
             return not isOpenB
        end
        if isOpenA ~= isOpenB then
             return isOpenB
        end
        return a < b
    end)
    return cloneConditions
end

function XUiCharacterTowerFetter:InitFetterListAndInformation()
    local fightEventIds = self.RelationViewModel:GetRelationFightEventIds()
    for index, eventId in ipairs(fightEventIds) do
        local gridFetter = self.GridFetterList[index]
        if not gridFetter then
            local goFetter = self:GetGridFetter(index)
            gridFetter = XUiGridCharacterTowerFetterItem.New(goFetter, self, handler(self, self.ClickFetterGrid))
            self.GridFetterList[index] = gridFetter
        end
        gridFetter:Refresh(self.RelationId, eventId, index)

        local gridInformation = self.GridInformationList[index]
        if not gridInformation then
            local goInfo = index == 1 and self.GridInformation or XUiHelper.Instantiate(self.GridInformation, self.PanelInformationContent)
            gridInformation = XUiGridCharacterTowerInformation.New(goInfo, self)
            self.GridInformationList[index] = gridInformation
        end
        gridInformation:Refresh(self.RelationId, eventId, index)
    end

    local layoutGroup = self.PanelFetterContent:GetComponent("HorizontalLayoutGroup")
    self.Right = layoutGroup.padding.right
    self.Left = layoutGroup.padding.left
    self.Spacing = layoutGroup.spacing
end

function XUiCharacterTowerFetter:GetGridFetter(index)
    local goFetter
    if index % 2 == 0 then
        goFetter = index == 2 and self.GridFetter2 or XUiHelper.Instantiate(self.GridFetter2, self.PanelFetterContent)
    else
        goFetter = index == 1 and self.GridFetter1 or XUiHelper.Instantiate(self.GridFetter1, self.PanelFetterContent)
    end
    return goFetter
end

function XUiCharacterTowerFetter:ClickFetterGrid(grid)
    local curGrid = self.CurFetterGrid
    if curGrid and curGrid.Index == grid.Index then
        return
    end
    -- 取消上一个选择
    if curGrid then
        curGrid:SetFetterSelect(false)
    end
    
    -- 选中当前选择
    grid:SetFetterSelect(true)
    
    self.CurFetterGrid = grid
end

function XUiCharacterTowerFetter:CancelSelect()
    if not self.CurFetterGrid then
        return
    end
    
    -- 取消当前选择
    self.CurFetterGrid:SetFetterSelect(false)
    self.CurFetterGrid = nil
end

function XUiCharacterTowerFetter:RefreshProgress()
    -- 异形屏适配需要
    XScheduleManager.ScheduleOnce(function()
        if not self.GameObject or not self.GameObject:Exist() then
            return
        end

        local finishCount, _ = self.RelationViewModel:GetRelationProgress()
        local width, finishWidth = self:GetFetterProgressWidthAndFinishWidth(finishCount)
        -- 更新进度条长度
        local deltaY = self.PanelDegree.sizeDelta.y
        self.PanelDegree.sizeDelta = CS.UnityEngine.Vector2(width, deltaY)
        -- 刷新进度
        local totalWidth = self.PanelDegree.rect.size.x
        self.ImgPercent.fillAmount = finishWidth / totalWidth
    end, 1)
end

function XUiCharacterTowerFetter:GetFetterProgressWidthAndFinishWidth(count)
    local gridFetterWidth = self.GridFetter2.rect.size.x
    local gridFetterWidthOffset = gridFetterWidth / 2
    
    local leftOffset = self.PanelFetter.offsetMin.x + self.Viewport.offsetMin.x + self.PanelFetterContent.offsetMin.x
    local fetterContentWidth = self.PanelFetterContent.rect.size.x
    local panelDegreeX = self.PanelDegree.anchoredPosition3D.x

    local width = leftOffset + fetterContentWidth - self.Right - gridFetterWidthOffset - panelDegreeX

    local finishWidth = 0
    if count > 0 then
        finishWidth = leftOffset + self.Left + gridFetterWidth * (count - 1) + gridFetterWidthOffset + self.Spacing * (count - 1) - panelDegreeX
    end
    
    return width, finishWidth
end

--- 自动检查是否有已完成未激活的羁绊
function XUiCharacterTowerFetter:CheckAutomaticFetter(isFirstEnter)
    local playTaskAnimation = asynTask(self.PlayTaskAnimation, self)
    local playProgressAnim = asynTask(self.PlayProgressAnim, self)
    RunAsyn(function()
        if isFirstEnter then
            -- 首次进入延迟0.5秒 进度条和任务动态列表需要刷新
            asynWaitSecond(0.5)
            self.CurPanelFetterTotem:Refresh()
        end
        playTaskAnimation() -- 播放任务特效
        playProgressAnim() -- 播放进度条进度
    end)
end

function XUiCharacterTowerFetter:AutomaticFetterFinishCallback(storyId, eventId)
    -- 保存播放动画
    XDataCenter.CharacterTowerManager.SaveRelationTaskPlayAnim(self.PlayConditionId)
    self:SetupDynamicTable()
    -- 刷新播放按钮
    for _, grid in pairs(self.GridInformationList) do
        grid:RefreshInfo()
    end
    -- 刷新图腾
    self.CurPanelFetterTotem:RefreshAndPlayAnimation(storyId, eventId)
end

function XUiCharacterTowerFetter:CheckFetterTaskNotPlayAnim()
    local _, _, unPlayConditions = self.RelationViewModel:GetPlayConditionAndFinishConditionNums(self.CharacterId)
    if #unPlayConditions < 1 then
        return false, 0
    end
    local conditionId = unPlayConditions[1]
    return table.contains(self.DynamicTable.DataSource, conditionId)
end

function XUiCharacterTowerFetter:PlayTaskAnimation(cb)
    if not self.GameObject or not self.GameObject:Exist() then
        return
    end
    local isPlay, index = self:CheckFetterTaskNotPlayAnim()
    if not isPlay then
        if cb then
            cb()
        end
        return
    end

    local fetterGrid = self.DynamicTable:GetGridByIndex(index)
    if not fetterGrid then
        if cb then
            cb()
        end
    else
        fetterGrid:PlayAnimation(function(conditionId)
            self.PlayConditionId = conditionId
            if cb then
                cb()
            end
        end)
    end
end

function XUiCharacterTowerFetter:PlayProgressAnim(cb)
    if not self.GameObject or not self.GameObject:Exist() then
        return
    end
    self:StopProgressAnim()

    local isOpen, index = self.RelationViewModel:CheckRelationNotActive(self.CharacterId)
    if not isOpen then
        if cb then
            cb()
        end
        return
    end

    local _, finishWidth = self:GetFetterProgressWidthAndFinishWidth(index)
    local totalWidth = self.PanelDegree.rect.size.x
    local duration = XUiHelper.GetClientConfig("CharacterTowerFetterProgressDuration", XUiHelper.ClientConfigType.Float)
    self.ImageFillAdd = self:DoFillAmount(self.ImgPercent, finishWidth / totalWidth, duration, XUiHelper.EaseType.Linear, function()
        if not self.GameObject or not self.GameObject:Exist() then
            return
        end
        local gridFetter = self.GridFetterList[index]
        if gridFetter then
            gridFetter:ShowFetterEffect()
        end
        if cb then
            cb()
        end
    end)
end

function XUiCharacterTowerFetter:StopProgressAnim()
    if self.ImageFillAdd then
        XScheduleManager.UnSchedule(self.ImageFillAdd)
        self.ImageFillAdd = nil
    end
end

function XUiCharacterTowerFetter:DoFillAmount(image, tarFill, duration, easeType, cb)
    local startFill = image.fillAmount
    easeType = easeType or XUiHelper.EaseType.Linear
    local timer =
    XUiHelper.Tween(
            duration,
            function(t)
                if not image:Exist() then
                    return true
                end
                image.fillAmount = MathLerp(startFill, tarFill, t)
            end,
            cb,
            function(t)
                return XUiHelper.Evaluate(easeType, t)
            end
    )
    return timer
end

function XUiCharacterTowerFetter:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, self.OnBtnMainUiClick)
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick)
    self:BindHelpBtn(self.BtnHelp, "CharacterTowerPlot")
end

function XUiCharacterTowerFetter:OnBtnBackClick()
    self:Close()
end

function XUiCharacterTowerFetter:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiCharacterTowerFetter:OnBtnCloseClick()
    self:CancelSelect()
end

return XUiCharacterTowerFetter