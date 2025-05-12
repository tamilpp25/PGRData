local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiGridWheelchairManualTask: XUiNode
---@field _Control XWheelchairManualControl
local XUiGridWheelchairManualTask = XClass(XUiNode, "XUiGridWheelchairManualTask")

function XUiGridWheelchairManualTask:OnStart()
    self.RewardPanelList = {}
    self.Grid256New.gameObject:SetActive(false)
    self.ImgComplete.gameObject:SetActive(false)
    
    self.BtnReceive.CallBack = handler(self, self.OnBtnFinishClick)
    self.BtnGo.CallBack = handler(self, self.OnBtnSkipClick)
end

function XUiGridWheelchairManualTask:RefreshData(data)
    self.ImgComplete.gameObject:SetActive(data.State == XDataCenter.TaskManager.TaskState.Finish)
    self.Data = data
    self.Id = data.Id
    local config = XDataCenter.TaskManager.GetTaskTemplate(self.Data.Id)
    self.TxtTitle.text = config.Desc
    
    self:UpdateProgress(data)
    
    self:RefreshReward()
end

function XUiGridWheelchairManualTask:UpdateProgress(data)
    self.Data = data
    local config = XDataCenter.TaskManager.GetTaskTemplate(data.Id)
    if #config.Condition < 2 then--显示进度
        self.ImgProgress.transform.parent.gameObject:SetActive(true)
        if self.TxtNum then
            self.TxtNum.gameObject:SetActive(true)
        end
        local result = config.Result > 0 and config.Result or 1
        XTool.LoopMap(self.Data.Schedule, function(_, pair)
            self.ImgProgress.fillAmount = pair.Value / result

            if self.TxtNum then
                local curValue = math.min(pair.Value, result)
                self.TxtNum.text = curValue .. "/" .. result
            end
        end)
    else
        self.ImgProgress.transform.parent.gameObject:SetActive(false)
        if self.TxtNum then
            self.TxtNum.gameObject:SetActive(false)
        end
    end

    self.BtnReceive.gameObject:SetActive(false)
    self.BtnGo.gameObject:SetActive(false)
    self.ImgUnFinish.gameObject:SetActive(false)

    if self.Data.State == XDataCenter.TaskManager.TaskState.Achieved then
        self.BtnReceive.gameObject:SetActive(true)
    elseif self.Data.State ~= XDataCenter.TaskManager.TaskState.Achieved and self.Data.State ~= XDataCenter.TaskManager.TaskState.Finish then
        local skipId = XDataCenter.TaskManager.GetTaskTemplate(self.Data.Id).SkipId

        if XTool.IsNumberValid(skipId) then
            self.BtnGo.gameObject:SetActive(true)
        else
            self.ImgUnFinish.gameObject:SetActive(true)
        end
    end
end

function XUiGridWheelchairManualTask:RefreshReward()
    local config = XDataCenter.TaskManager.GetTaskTemplate(self.Data.Id)
    local rewards = XRewardManager.GetRewardList(config.RewardId)
    -- reset reward panel
    for i = 1, #self.RewardPanelList do
        self.RewardPanelList[i]:Refresh()
    end

    if not rewards then
        return
    end

    for i = 1, #rewards do
        local panel = self.RewardPanelList[i]
        if not panel then
            if #self.RewardPanelList == 0 then
                panel = XUiGridCommon.New(self.RootUi, self.Grid256New)
            else
                local ui = CS.UnityEngine.Object.Instantiate(self.Grid256New)
                ui.transform:SetParent(self.Grid256New.parent, false)
                panel = XUiGridCommon.New(self.RootUi, ui)
            end
            table.insert(self.RewardPanelList, panel)
        end

        panel:Refresh(rewards[i])
    end
end

function XUiGridWheelchairManualTask:OnBtnFinishClick()
    local weaponCount = 0
    local chipCount = 0
    for i = 1, #self.RewardPanelList do
        local rewardsId = self.RewardPanelList[i].TemplateId
        if XMVCA.XEquip:IsClassifyEqualByTemplateId(rewardsId, XEnumConst.EQUIP.CLASSIFY.WEAPON) then
            weaponCount = weaponCount + 1
        elseif XMVCA.XEquip:IsClassifyEqualByTemplateId(rewardsId, XEnumConst.EQUIP.CLASSIFY.AWARENESS) then
            chipCount = chipCount + 1
        end
    end
    if weaponCount > 0 and XMVCA.XEquip:CheckBagCount(weaponCount, XEnumConst.EQUIP.CLASSIFY.WEAPON) == false or
            chipCount > 0 and XMVCA.XEquip:CheckBagCount(chipCount, XEnumConst.EQUIP.CLASSIFY.AWARENESS) == false then
        return
    end
    XDataCenter.TaskManager.FinishTask(self.Data.Id, function(rewardGoodsList)
        self.ImgComplete.gameObject:SetActive(true)

        if self.BtnFinish then
            self.BtnFinish.gameObject:SetActive(false)
        end
        self:UpdateProgress(XDataCenter.TaskManager.GetTaskDataById(self.Id))
        self.Parent:Refresh(true)
        XUiManager.OpenUiObtain(rewardGoodsList, nil, nil, nil)
        -- 领完奖要刷新下页签红点
        XEventManager.DispatchEvent(XEventId.EVENT_WHEELCHAIRMANUAL_REFRESH_TABS_REDDOT)
    end)
end

function XUiGridWheelchairManualTask:OnBtnSkipClick()
    if XDataCenter.RoomManager.RoomData ~= nil then
        local title = CS.XTextManager.GetText("TipTitle")
        local cancelMatchMsg = CS.XTextManager.GetText("OnlineInstanceQuitRoom")
        XUiManager.DialogTip(title, cancelMatchMsg, XUiManager.DialogType.Normal, nil, function()
            XLuaUiManager.RunMain()
            local skipId = XDataCenter.TaskManager.GetTaskTemplate(self.Data.Id).SkipId
            XFunctionManager.SkipInterface(skipId)
        end)
    else
        local skipId = XDataCenter.TaskManager.GetTaskTemplate(self.Data.Id).SkipId
        XFunctionManager.SkipInterface(skipId)
    end
end

return XUiGridWheelchairManualTask