local XUiGridSkinVote = XClass(nil, "XUiGridSkinVote")

local ProgressAnimationDuration = 1

---@class XUiGridSkinVote 投票按钮类
function XUiGridSkinVote:Ctor(ui, onClick)
    XTool.InitUiObjectByUi(self, ui)
    self.OnClick = onClick
    self.BtnClick.CallBack = function() 
        self:OnBtnClick()
    end
end

--- 设置投票数据
---@param voteData XSkinVoteData
--------------------------
function XUiGridSkinVote:SetVoteData(voteData)
    self.VoteData = voteData
end

--- 刷新界面
---@param idx number 下标
---@param voteNameId number 玩家投票Id
---@param isVoteExpired boolean 投票时间过期
--------------------------
function XUiGridSkinVote:Refresh(idx, voteNameId, isVoteExpired)
    local isVoted = XTool.IsNumberValid(voteNameId)
    self.ForbidVote = isVoted or isVoteExpired
    self.PanelVote.gameObject:SetActiveEx(self.ForbidVote)
    local isCurVote = isVoted and voteNameId == self.VoteData.Id
    if self.ForbidVote then
        self:PlayProgressAnimation()
        self.PanelSelect.gameObject:SetActiveEx(false)
        self.PanelNormal.gameObject:SetActiveEx(false)
    end
    self.BtnClick:ShowTag(isCurVote)
    self.BtnClick:SetNameByGroup(0, self.VoteData.Name)
    self.BtnClick:SetNameByGroup(1, string.format("%02d", idx))
end

function XUiGridSkinVote:PlayProgressAnimation()
    local percent = self.VoteData.Percent
    self.TxtProgress.text = "0%"
    self.ImgProgress.fillAmount = 0
    if percent <= 0 then
        return
    end
    local fillAmount = XUiHelper.GetFillAmountValue(percent, 100)
    self.Timer = XUiHelper.Tween(ProgressAnimationDuration, function(delta)
        if XTool.UObjIsNil(self.GameObject) then
            return
        end
        self.TxtProgress.text = math.floor(percent * delta) .. "%"
        self.ImgProgress.fillAmount = fillAmount * delta;
    end, function()
        self.TxtProgress.text = percent .. "%"
        self.ImgProgress.fillAmount = fillAmount;
    end)
end

function XUiGridSkinVote:StopProgressAnimationTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiGridSkinVote:Select(select)
    self.PanelSelect.gameObject:SetActiveEx(select)
    self.PanelNormal.gameObject:SetActiveEx(not select)
    self.IsSelect = select
end

function XUiGridSkinVote:OnBtnClick()
    if self.ForbidVote or self.IsSelect then
        return
    end

    self:Select(true)
    if self.OnClick then
        self:OnClick(self)
    end
end

function XUiGridSkinVote:PlayTimelineAnimation()
    if self.Enable then
        self.Enable:PlayTimelineAnimation()
    end
end

---@class XUiPanelSkinVote 投票主界面
---@field
local XUiPanelSkinVote = XClass(nil, "XUiPanelSkinVote")

--剩余时间标题
local LeftTimeName = {
    VotingPeriod = XUiHelper.GetText("VotingPeriod"),
    StatisticalPeriod = XUiHelper.GetText("StatisticalPeriod"),
}

function XUiPanelSkinVote:Ctor(ui, uiRoot)
    XTool.InitUiObjectByUi(self, ui)
    ---@type XUiSkinVoteMain
    self.UiRoot = uiRoot
    ---@type XSkinVote
    self.ViewModel = XDataCenter.SkinVoteManager.GetViewModel()
    self:InitUi()
    self:InitCb()
end

function XUiPanelSkinVote:InitUi()
    ---@type XUiGridSkinVote[]
    self.GirdVote = {}
    self.SwitchAnim = self.Transform:Find("Animation/QieHuan")
    if not self.TxtDesc then
        self.TxtDesc = self.Transform:Find("RImg03/PanelRight/Text"):GetComponent("Text")
    end
    self.ConfirmAnim = self.BtnConfirm.transform:Find("Animation/Enable")
end

function XUiPanelSkinVote:InitCb()
    self.BtnConfirm.CallBack = function()
        self:OnBtnConfirmClick()
    end
    
    self.BtnName.CallBack = function() 
        self:OnBtnPreviewClick()
    end
    
    self.BtnRightArrow.CallBack = function()
        self.SwitchAnim:PlayTimelineAnimation()
        self.ViewModel:PlayPreviewNext()
    end

    self.BtnLeftArrow.CallBack = function()
        self.SwitchAnim:PlayTimelineAnimation()
        self.ViewModel:PlayPreviewLast()
    end
    
    self.BtnSigh.CallBack = function() 
        self.UiRoot:ShowDialog(XUiHelper.GetText("SkinNameVoteTip"), self.ViewModel:GetActivityDesc())
    end
end

function XUiPanelSkinVote:Show()
    self.GameObject:SetActiveEx(true)
    
    self:Refresh()
end

function XUiPanelSkinVote:Hide()
    self.GameObject:SetActiveEx(false)
    self:OnStopGridTimer()
end

function XUiPanelSkinVote:Refresh()
    local viewModel = self.ViewModel

    self.IsVoteExpired = viewModel:IsVoteExpired()
    self.SmallPreviewList = viewModel:GetActivityPreviewImgSmall()
    if self.TxtDesc then
        self.TxtDesc.text = XUiHelper.ReplaceUnicodeSpace(XUiHelper.ReplaceTextNewLine(viewModel:GetActivityVoteTips()))
    end
    --投票选项
    local nameIds = viewModel:GetProperty("_RandomNameIds")
    for idx, nameId in ipairs(nameIds) do
        local grid = self.GirdVote[idx]
        if not grid then
            local ui = idx == 1 and self.BtnSkinVote or XUiHelper.Instantiate(self.BtnSkinVote, self.PanelSlotContent)
            grid = XUiGridSkinVote.New(ui, handler(self, self.OnGridVoteClick))
            self.GirdVote[idx] = grid
        end
        grid:SetVoteData(viewModel:GetVoteNameData(nameId))
    end

    --是否投票
    self.UiRoot:BindViewModelPropertyToObj(viewModel, function(voteNameId)
        self:OnRefreshVoteView(voteNameId)
    end, "_VoteNameId")

    --预览图下标
    self.UiRoot:BindViewModelPropertyToObj(viewModel, function(index)
        self.RImg02:SetRawImage(self.SmallPreviewList[index])
        self.BtnName:ShowReddot(XDataCenter.SkinVoteManager.CheckPreviewRedPoint())
    end, "_PreviewIndex")
    
    self:RefreshTime()
    self:RefreshBtnState()
end

function XUiPanelSkinVote:RefreshTime()
    local isVoteExpired = self.ViewModel:IsVoteExpired()
    self.TxtLeftTime.text = isVoteExpired and self.ViewModel:GetVoteExpiredTimeStr() or self.ViewModel:GetVoteTimeStr()
    self.TxtLeftName.text = isVoteExpired and LeftTimeName.StatisticalPeriod or LeftTimeName.VotingPeriod
    if self.IsVoteExpired ~= isVoteExpired then
        self:OnRefreshVoteView()
        self:RefreshBtnState()
    end
    self.IsVoteExpired = isVoteExpired
end

function XUiPanelSkinVote:OnRefreshVoteView(voteNameId)
    local viewModel = self.ViewModel
    local isVoteExpired = viewModel:IsVoteExpired()
    voteNameId = voteNameId or viewModel:GetProperty("_VoteNameId")
    for idx, grid in ipairs(self.GirdVote) do
        grid:Refresh(idx, voteNameId, isVoteExpired)
    end
end

function XUiPanelSkinVote:OnStopGridTimer()
    for _, grid in ipairs(self.GirdVote) do
        grid:StopProgressAnimationTimer()
    end
end

function XUiPanelSkinVote:RefreshBtnState()
    local viewModel = self.ViewModel
    local isVoteExpired = viewModel:IsVoteExpired()
    local voteNameId = viewModel:GetProperty("_VoteNameId")
    --未选
    local disable = not XTool.IsNumberValid(self.SelectId)
    self.BtnConfirm:SetDisable(disable)
    -- 过期 || 已投
    local forbidden = isVoteExpired or XTool.IsNumberValid(voteNameId)
    self.BtnConfirm.gameObject:SetActiveEx(not forbidden)
    -- 过期 
    self.BtnEnd.gameObject:SetActiveEx(isVoteExpired)
    -- 已投
    self.BtnVoted.gameObject:SetActiveEx(not isVoteExpired and XTool.IsNumberValid(voteNameId))
end

function XUiPanelSkinVote:OnGridVoteClick(grid)
    if self.LastGrid then
        self.LastGrid:Select(false)
    end
    self.SelectId = grid.VoteData.Id
    self.LastGrid = grid
    self.ConfirmAnim:PlayTimelineAnimation()
    self:RefreshBtnState()
end

function XUiPanelSkinVote:OnBtnConfirmClick()
    if not XTool.IsNumberValid(self.SelectId) then
        XUiManager.TipText("SkinNameVoteNotSelectButConfirm")
        return
    end
    local confirmCb = function()
        XDataCenter.SkinVoteManager.RequestSkinVoteName(self.SelectId, function()
            self:RefreshBtnState()
            if self.LastGrid then
                self.LastGrid:PlayTimelineAnimation()
            end
        end)
    end
    self.UiRoot:ShowDialog(XUiHelper.GetText("TipTitle"), XUiHelper.GetText("SkinNameVoteSecondaryConfirmation"), nil, 
            function()  end, nil, confirmCb)
end

function XUiPanelSkinVote:OnBtnPreviewClick()
    XLuaUiManager.Open("UiSkinVoteSee")
end

return XUiPanelSkinVote