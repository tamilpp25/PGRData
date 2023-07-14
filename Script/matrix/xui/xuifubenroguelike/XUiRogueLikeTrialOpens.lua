local XUiRogueLikeTrialOpens = XLuaUiManager.Register(XLuaUi, "UiRogueLikeTrialOpens")

function XUiRogueLikeTrialOpens:OnAwake()
    
    self.BtnClose.CallBack = function() self:Close() end
end

function XUiRogueLikeTrialOpens:OnStart(rootUi)
    self.RootUi = rootUi
    XDataCenter.FubenRogueLikeManager.SetNeedShowTrialTips(false)
end

function XUiRogueLikeTrialOpens:SetupStarReward()
    
end


function XUiRogueLikeTrialOpens:OnEnable()
    
end


