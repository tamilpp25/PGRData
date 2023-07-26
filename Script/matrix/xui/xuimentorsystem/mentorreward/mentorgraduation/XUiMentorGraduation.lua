local XUiMentorGraduation = XLuaUiManager.Register(XLuaUi, "UiMentorGraduation")
local CSTextManagerGetText = CS.XTextManager.GetText

function XUiMentorGraduation:OnStart(rewardGoodsList, callBack)
    self.CallBack = callBack
    self:SetButtonCallBack()
    self:InitPanel(rewardGoodsList)
end

function XUiMentorGraduation:OnDestroy()
   
end

function XUiMentorGraduation:OnEnable()
   
end

function XUiMentorGraduation:OnDisable()
    if self.CallBack then
        self.CallBack()
    end
end

function XUiMentorGraduation:SetButtonCallBack()
    self.BtnClose.CallBack = function()
        self:OnBtnCloseClick()
    end
    self.BtnMask.CallBack = function()
        self:OnBtnCloseClick()
    end    
end

function XUiMentorGraduation:InitPanel(rewardGoodsList)
    self.TxtTitle.text = CSTextManagerGetText("MentorStudentGraduateTipTittle")
    self.TxtInfo.text = CSTextManagerGetText("MentorStudentGraduateTipInfo")
    local rewardGoods = XRewardManager.MergeAndSortRewardGoodsList(rewardGoodsList)
    self.GridCommon.gameObject:SetActiveEx(false)
    if rewardGoods then
        for _, item in pairs(rewardGoods or {}) do
            local obj = CS.UnityEngine.Object.Instantiate(self.GridCommon,self.PanelRewardContainer)
            local grid = XUiGridCommon.New(self, obj)
            grid:Refresh(item)
            grid.GameObject:SetActiveEx(true)
        end
    end
    
end


function XUiMentorGraduation:OnBtnCloseClick()
    self:Close()
end