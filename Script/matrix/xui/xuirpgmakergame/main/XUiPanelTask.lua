local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
--推箱子主界面首个任务显示
local XUiPanelTask = XClass(nil, "XUiPanelTask")

function XUiPanelTask:Ctor(ui, rootUi)
	self.RootUi = rootUi
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RewardPanelListNormal = {}
    self.RewardPanelListPress = {}
    XTool.InitUiObject(self)
end

function XUiPanelTask:Refresh()
    if not self.TxtNormal then return end
    self.TaskId = XDataCenter.RpgMakerGameManager.GetFirstTaskId()
    if not XTool.IsNumberValid(self.TaskId) then
        self.PanelTiaoSuNormal.gameObject:SetActiveEx(false)
        self.PanelTiaoSuPress.gameObject:SetActiveEx(false)
        self.PanelGiftNormal.gameObject:SetActiveEx(false)
        self.PanelGiftPress.gameObject:SetActiveEx(false)
        return
    end
    self.TaskConfig = XDataCenter.TaskManager.GetTaskTemplate(self.TaskId)
    self:RefreshTxt()
    self:RefreshReward(self.RewardPanelListNormal, self.Grid256NewNormal, self.PanelGiftNormal)
    self:RefreshReward(self.RewardPanelListPress, self.Grid256NewPress, self.PanelGiftPress)
    self:RefreshProcess()
end

--#region Ui刷新相关

function XUiPanelTask:RefreshTxt()
    self.TxtNormal.text = self.TaskConfig.Desc
    self.TxtPress.text = self.TaskConfig.Desc
end

function XUiPanelTask:RefreshReward(rewardPanelList, Grid, PanelGift)
    local rewards = XRewardManager.GetRewardList(self.TaskConfig.RewardId)
    for i = 1, #rewardPanelList do
        rewardPanelList[i]:Refresh()
    end
    if not rewards then
        return
    end
    for i = 1, #rewards do
        local panel = rewardPanelList[i]
        local reward = rewards[i]
        if not panel then
            if #rewardPanelList == 0 then
                panel = XUiGridCommon.New(self.RootUi, Grid)
            else
                local ui = CS.UnityEngine.Object.Instantiate(Grid, PanelGift)
                panel = XUiGridCommon.New(self.RootUi, ui)
            end

            if self.ClickFunc then
                XUiHelper.RegisterClickEvent(panel, panel.BtnClick, function()
                    self.ClickFunc(reward)
                end)
            end
            table.insert(rewardPanelList, panel)
        end
        panel:Refresh(reward)
        panel:SetUiActive(panel.TxtName, false)
    end
end

function XUiPanelTask:RefreshProcess()
    if #self.TaskConfig.Condition < 2 then--显示进度
        self.ImgProgressNormal.transform.parent.gameObject:SetActive(true)
        self.ImgProgressPress.transform.parent.gameObject:SetActive(true)
        local result = self.TaskConfig.Result > 0 and self.TaskConfig.Result or 1
        local data = XDataCenter.TaskManager.GetTaskDataById(self.TaskId)
        XTool.LoopMap(data.Schedule, function(_, pair)
            self.ImgProgressNormal.fillAmount = pair.Value / result
            self.ImgProgressPress.fillAmount = pair.Value / result
            pair.Value = (pair.Value >= result) and result or pair.Value
            self.TxtSuNormal.text = pair.Value .. "/" .. result
            self.TxtSuPress.text = pair.Value .. "/" .. result
        end)
    else
        self.ImgProgressNormal.transform.parent.gameObject:SetActive(false)
        self.ImgProgressPress.transform.parent.gameObject:SetActive(false)
    end
end

--#endregion

return XUiPanelTask