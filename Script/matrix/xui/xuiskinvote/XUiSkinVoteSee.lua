
local XUiSkinVoteSee = XLuaUiManager.Register(XLuaUi, "UiSkinVoteSee")

function XUiSkinVoteSee:OnAwake()
    ---@type XSkinVote
    self.ViewModel = XDataCenter.SkinVoteManager.GetViewModel()
    self:InitUi()
    self:InitCb()
end

function XUiSkinVoteSee:OnStart()
    self:InitView()
end 

function XUiSkinVoteSee:OnEnable()
    self.Super.OnEnable(self)
end

function XUiSkinVoteSee:InitUi()
end 

function XUiSkinVoteSee:InitCb()
    self:BindExitBtns()
    
    self.BtnScreenShot.CallBack = function() 
        self:SetUiState(not self.UiState)
    end

    self.BtnRightArrow.CallBack = function()
        self:PlayAnimationWithMask("QieHuan")
        self.ViewModel:PlayPreviewNext()
    end

    self.BtnLeftArrow.CallBack = function()
        self:PlayAnimationWithMask("QieHuan")
        self.ViewModel:PlayPreviewLast()
    end
end

function XUiSkinVoteSee:InitView()
    self:SetUiState(true)
    local viewModel = self.ViewModel

    self.FullPreviewList = viewModel:GetActivityPreviewImgFull()
    --预览图下标
    self:BindViewModelPropertyToObj(viewModel, function(index)
        self.BgCommonBg2:SetRawImage(self.FullPreviewList[index])

        XDataCenter.SkinVoteManager.MarkPreviewRedPoint(index)
    end, "_PreviewIndex")

    local endTime = self.ViewModel:GetActivityEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose or not XDataCenter.SkinVoteManager.IsOpen() then
            XDataCenter.SkinVoteManager.OnActivityEnd()
        end
    end)
end

function XUiSkinVoteSee:SetUiState(state)
    local animName = state and "UiEnable" or "UiDisable"
    self:PlayAnimationWithMask(animName)
    self.UiState = state
    self.BtnBack.gameObject:SetActiveEx(state)
    self.BtnMainUi.gameObject:SetActiveEx(state)
    self.BtnLeftArrow.gameObject:SetActiveEx(state)
    self.BtnRightArrow.gameObject:SetActiveEx(state)
end