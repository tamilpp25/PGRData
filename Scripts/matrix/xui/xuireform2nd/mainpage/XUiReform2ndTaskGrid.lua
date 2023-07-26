---@class XUiReform2ndTaskGrid
local XUiReform2ndTaskGrid = XClass(nil, "XUiReform2ndTaskGrid")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")

function XUiReform2ndTaskGrid:Ctor(uiPrefab)
    self.RootUi = nil
    self.Data = nil
    
    XTool.InitUiObjectByUi(self, uiPrefab)
    XUiHelper.RegisterClickEvent(self, self.BtnReceive, self.OnBtnReceiveClick)
    self.WeeksPanel.gameObject:SetActiveEx(false)
end

function XUiReform2ndTaskGrid:SetData(data)
    self.Data = data
end

function XUiReform2ndTaskGrid:SetRootUi(rootUi)
    self.RootUi = rootUi
end

function XUiReform2ndTaskGrid:SetBtnActive()
    self.BtnReceive.gameObject:SetActiveEx(true)
    self.ImgCannotReceive.gameObject:SetActiveEx(false)
    self.ImgAlreadyReceived.gameObject:SetActiveEx(false)
end

function XUiReform2ndTaskGrid:SetBtnCannotReceive()
    self.BtnReceive.gameObject:SetActiveEx(false)
    self.ImgCannotReceive.gameObject:SetActiveEx(true)
    self.ImgAlreadyReceived.gameObject:SetActiveEx(false)
end

function XUiReform2ndTaskGrid:SetBtnAlreadyReceive()
    self.BtnReceive.gameObject:SetActiveEx(false)
    self.ImgCannotReceive.gameObject:SetActiveEx(false)
    self.ImgAlreadyReceived.gameObject:SetActiveEx(true)
end

function XUiReform2ndTaskGrid:OnBtnReceiveClick()
    local taskCondition = self.Data.State

    if taskCondition == XDataCenter.TaskManager.TaskState.Achieved then
        XDataCenter.Reform2ndManager.RequestFinishTask(self.Data.Id, function(rewardGoodsList)
            XUiManager.OpenUiObtain(rewardGoodsList)
            self.RootUi:RefreshTask()
        end)
    end
end

function XUiReform2ndTaskGrid:Refresh()
    local data = self.Data
    local taskCondition = data.State
    
    self.TxtStarNums.text = data.StarNumsTxt

    if taskCondition == XDataCenter.TaskManager.TaskState.Finish then
        self:SetBtnAlreadyReceive()
    elseif taskCondition == XDataCenter.TaskManager.TaskState.Achieved then
        self:SetBtnActive()
    elseif taskCondition == XDataCenter.TaskManager.TaskState.Active then
        self:SetBtnCannotReceive()
    end
    
    self:InitRewardsList()
end

function XUiReform2ndTaskGrid:InitRewardsList()
    local rewards = self.Data.RewardsList

    XUiHelper.RefreshCustomizedList(self.RewardsContent, self.RewardGrid, #rewards, function(index, obj)
        local gridCommont = XUiGridCommon.New(self.RootUi, obj)
        
        gridCommont:Refresh(rewards[index])
    end)
end

return XUiReform2ndTaskGrid
