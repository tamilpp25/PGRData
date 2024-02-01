
local XUiNieRSaveData = XLuaUiManager.Register(XLuaUi, "UiNieRSaveData")


function XUiNieRSaveData:OnAwake()
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end 
    self.BtnCancel.CallBack = function() self:OnBtnCancelClick() end
    self.BtnOk.CallBack = function() self:OnBtnOkClick() end
    
    
end

function XUiNieRSaveData:OnStart(isWin, isFirstDied)
    if XLuaUiManager.IsUiLoad("UiFubenNierLineChapter") then
        XLuaUiManager.Remove("UiFubenNierLineChapter")
    end
end

function XUiNieRSaveData:OnDestroy()
    
end

function XUiNieRSaveData:OnBtnBackClick()
    self:Close()
end

function XUiNieRSaveData:OnBtnMainUiClick()
    
end

function XUiNieRSaveData:OnBtnCancelClick()
    self:Close()
end

function XUiNieRSaveData:OnBtnOkClick()
    local stageId = XDataCenter.NieRManager.GetCurNieREasterEggStageId()
    XLuaUiManager.PopThenOpen("UiBattleRoleRoom", stageId) --, nil, nil, nil, true)
end