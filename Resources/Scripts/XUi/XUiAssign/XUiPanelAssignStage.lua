-- 边界公约关卡组界面
local XUiPanelAssignStage = XLuaUiManager.Register(XLuaUi, "UiPanelAssignStage")

local XUiGridAssignStage = require("XUi/XUiAssign/XUiGridAssignStage")

function XUiPanelAssignStage:OnAwake()
    self:InitComponent()
end

function XUiPanelAssignStage:OnStart()
    self.ChapterId = XDataCenter.FubenAssignManager.SelectChapterId
    self.DefaultContentPosX = self.PanelStageContent.localPosition.x
    self.ConditionTxtList = {}
    self.GroupGridList = {}
    self.RewardGridList = {}
    self:InitGroupList()
end

function XUiPanelAssignStage:OnEnable()
    self:Refresh()
end

function XUiPanelAssignStage:InitComponent()
    self.RectTransform = self.Transform:GetComponent("RectTransform")
    self.PanelAsset = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)

    self.TxtLock.gameObject:SetActiveEx(false)
    self.GridCommonPopUp.gameObject:SetActiveEx(false)
    self.RImgRoleSelect.gameObject:SetActiveEx(false)


    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end
    self:BindHelpBtn(self.BtnHelp, "Assign")
    self.BtnTreasure.CallBack = function() self:OnBtnTreasureClick() end
    CsXUiHelper.RegisterClickEvent(self.BtnOccupy, function() self:OnBtnOccupyClick() end)
end

function XUiPanelAssignStage:InitGroupList()
    local data = XDataCenter.FubenAssignManager.GetChapterDataById(self.ChapterId)

    self.ListData = data:GetGroupId()
    local prefabName = CS.XGame.ClientConfig:GetString("GridAssignStage")
    for i, _ in ipairs(self.ListData) do
        local parent = self["Stage" .. i]
        if not parent then
            XLog.Error("找不到ui结点Stage" .. i)
            break
        end
        local prefab = parent:LoadPrefab(prefabName)
        prefab:SetActiveEx(false)
        local grid = XUiGridAssignStage.New(self, prefab)
        grid.Parent = parent
        table.insert(self.GroupGridList, grid)
    end
end

function XUiPanelAssignStage:OnGetEvents()
    return { XEventId.EVENT_FUBEN_ASSIGN_STAGE_CLICK, XEventId.EVENT_FUBEN_ASSIGN_STAGE_DETAIL_CLOSE, XEventId.EVENT_ASSIGN_SELECT_OCCUPY_END }
end

--事件监听
function XUiPanelAssignStage:OnNotify(evt, ...)
    local args = { ... }
    if evt == XEventId.EVENT_FUBEN_ASSIGN_STAGE_CLICK then
        local grid = args[1]
        XDataCenter.FubenAssignManager.SelectGroupId = grid.GroupId
        self:OnDetailShow(grid)
    elseif evt == XEventId.EVENT_FUBEN_ASSIGN_STAGE_DETAIL_CLOSE then
        self:OnDetailHide()
    elseif evt == XEventId.EVENT_ASSIGN_SELECT_OCCUPY_END then
        self:RefreshOccupy()
    end
end

function XUiPanelAssignStage:Refresh()
    local data = XDataCenter.FubenAssignManager.GetChapterDataById(self.ChapterId)
    self.ChapterData = data

    self.TxtTitle.text = data:GetDesc()

    for i, grid in ipairs(self.GroupGridList) do
        if self.ListData[i] then
            grid.GameObject:SetActiveEx(true)
            grid:Refresh(self.ChapterId, self.ListData[i])
        else
            grid.GameObject:SetActiveEx(false)
        end
    end

    -- 奖励
    local rewards = {}
    for _, rewardGroupId in ipairs(data:GetRewardId()) do
        for _, id in ipairs(XRewardManager.GetRewardList(rewardGroupId)) do
            table.insert(rewards, id)
        end
    end
    for i, reward in ipairs(rewards) do
        local grid = self.RewardGridList[i]
        if not grid then
            local obj = CS.UnityEngine.Object.Instantiate(self.GridCommonPopUp)
            obj.transform:SetParent(self.PanelRewrds, false)
            grid = XUiGridCommon.New(self, obj)
            self.RewardGridList[i] = grid
        end
        grid.GameObject:SetActiveEx(true)
        grid:Refresh(reward)
    end

    local isPass = data:IsPass()
    if isPass then
        local isRewarded = data:IsRewarded()
        self.BtnTreasure.gameObject:SetActiveEx(true)
        self.BtnTreasure:SetButtonState(isRewarded and XUiButtonState.Disable or XUiButtonState.Normal)
        self.TxtCondition.gameObject:SetActiveEx(false)
    else
        self.BtnTreasure.gameObject:SetActiveEx(false)
        self.TxtCondition.gameObject:SetActiveEx(true)
    end

    self:RefreshOccupy()
end

function XUiPanelAssignStage:RefreshOccupy()
    local data = XDataCenter.FubenAssignManager.GetChapterDataById(self.ChapterId)
    -- 开启驻守条件
    local isMatch = data:IsPass()
    for i, conditionId in ipairs(data:GetAssignCondition()) do
        local txt = self.ConditionTxtList[i]
        if not txt then
            txt = CS.UnityEngine.Object.Instantiate(self.TxtLock)
            txt.transform:SetParent(self.PanelLock, false)
            txt.gameObject:SetActiveEx(true)
            self.ConditionTxtList[i] = txt
        end
        local ret, desc = XConditionManager.CheckCondition(conditionId)
        if not (ret) then
            isMatch = false
            txt.gameObject:GetComponent("CanvasGroup").alpha = 0.3
        else
            txt.gameObject:GetComponent("CanvasGroup").alpha = 1
        end
        txt.text = desc
    end
    self.IsMatch = isMatch

    local isOccuy = data:IsOccupy()
    if isOccuy then
        local characterIcon = data:GetOccupyCharacterIcon()
        self.RImgRoleSelect.gameObject:SetActiveEx(true)
        self.RImgRoleSelect:SetRawImage(characterIcon)
    else
        self.RImgRoleSelect.gameObject:SetActiveEx(false)
    end
    self.BtnOccupy:SetButtonState(isMatch and (isOccuy and CS.UiButtonState.Select or CS.UiButtonState.Normal) or CS.UiButtonState.Disable)
end

function XUiPanelAssignStage:OnBtnBackClick()
    self:Close()
end

function XUiPanelAssignStage:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiPanelAssignStage:OnBtnOccupyClick()
    if not self.ChapterData then
        return
    end

    if not self.IsMatch then
        XUiManager.TipMsg(CS.XTextManager.GetText("AssignStageOccupyLock"))  -- 未满足驻守条件
        return
    end

    XDataCenter.FubenAssignManager.SelectChapterId = self.ChapterData:GetId()
    XDataCenter.FubenAssignManager.SelectCharacterId = self.ChapterData:GetCharacterId()
    XLuaUiManager.Open("UiAssignOccupy")
end

function XUiPanelAssignStage:OnBtnTreasureClick()
    if not self.ChapterData then
        return
    end
    -- 领奖
    XDataCenter.FubenAssignManager.AssignGetRewardRequest(self.ChapterId, function()
        self:Refresh()
    end)
end

function XUiPanelAssignStage:OnDetailShow(grid)
    self.DefaultContentPosX = self.PanelStageContent.localPosition.x
    self.PanelAsset.GameObject:SetActiveEx(false)

    self:OpenChildUi("UiAssignStageDetail")

    -- 动画 居中当前grid
    self.ScrollRect.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Unrestricted
    local gridTf = grid.Parent.gameObject:GetComponent("RectTransform")
    local diffX = gridTf.localPosition.x + self.PanelStageContent.localPosition.x
    if diffX < XDataCenter.FubenMainLineManager.UiGridChapterMoveMinX or diffX > XDataCenter.FubenMainLineManager.UiGridChapterMoveMaxX then
        local tarPosX = XDataCenter.FubenMainLineManager.UiGridChapterMoveTargetX - gridTf.localPosition.x
        local tarPos = self.PanelStageContent.localPosition
        tarPos.x = tarPosX
        XLuaUiManager.SetMask(true)
        XUiHelper.DoMove(self.PanelStageContent, tarPos, XDataCenter.FubenMainLineManager.UiGridChapterMoveDuration, XUiHelper.EaseType.Sin, function()
            XLuaUiManager.SetMask(false)
        end)
    end
end

function XUiPanelAssignStage:OnDetailHide()
    self.PanelAsset.GameObject:SetActiveEx(true)

    -- 恢复到原来位置
    local tarPos = self.PanelStageContent.localPosition
    tarPos.x = self.DefaultContentPosX
    XLuaUiManager.SetMask(true)
    XUiHelper.DoMove(self.PanelStageContent, tarPos, XDataCenter.FubenMainLineManager.UiGridChapterMoveDuration, XUiHelper.EaseType.Sin, function()
        self.ScrollRect.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic
        XLuaUiManager.SetMask(false)
    end)
end