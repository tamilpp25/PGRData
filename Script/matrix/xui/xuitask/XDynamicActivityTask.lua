local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XDynamicActivityTask = XClass(nil, "XDynamicActivityTask")

function XDynamicActivityTask:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RewardPanelList = {}
    XTool.InitUiObject(self)
    self.GridCommon.gameObject:SetActiveEx(false)
    self.ImgComplete.gameObject:SetActiveEx(false)
    self.PanelAnimation.gameObject:SetActiveEx(true)
    self.ImgNotFinish.gameObject:SetActiveEx(true)
    self.BtnFinish.CallBack = function() self:OnBtnFinishClick() end
end

function XDynamicActivityTask:PlayAnimation()
    if self.IsAnimation then
        return
    end

    self.IsAnimation = true
    self.GridTaskTimeline:PlayTimelineAnimation()
end

function XDynamicActivityTask:ResetData(data, base)
    self.Data = data
    self.Base = base
    local config = XDataCenter.TaskManager.GetTaskTemplate(self.Data.Id)
    self.tableData = config
    self.TxtTaskDescribe.text = config.Desc
    self.RImgTaskType:SetRawImage(self.Base.TaskVipBg)
    self.RImgTaskTypeNa:SetRawImage(self.Base.TaskBg)
    self.RImgTaskTypeFihsh:SetRawImage(self.Base.TaskVipGotBg)
    self.RImgTaskTypeNaFinsh:SetRawImage(self.Base.TaskGotBg)

    if self.Data.PointId then
        local itemIcon = XDataCenter.ItemManager.GetItemIcon(self.Data.PointId)
        self.ImgIcon:SetRawImage(itemIcon)
    end
    self:UpdateProgress(self.Data)
    local rewards = XRewardManager.GetRewardList(config.RewardId)
    for i = 1, #self.RewardPanelList do
        self.RewardPanelList[i]:Refresh()
    end

    if rewards then
        for i = 1, #rewards do
            local panel = self.RewardPanelList[i]
            if not panel then
                if #self.RewardPanelList == 0 then
                    panel = XUiGridCommon.New(self.RootUi, self.GridCommon)
                else
                    local ui = CS.UnityEngine.Object.Instantiate(self.GridCommon)
                    ui.transform:SetParent(self.GridCommon.parent, false)
                    panel = XUiGridCommon.New(self.RootUi, ui)
                end
                table.insert(self.RewardPanelList, panel)
            end

            panel:Refresh(rewards[i])
        end
    end

    local isFinish = self.Data.State == XDataCenter.TaskManager.TaskState.Finish
    self.ImgComplete.gameObject:SetActiveEx(isFinish)

    local canGet = self.Data.State == XDataCenter.TaskManager.TaskState.Achieved
    self.ImgNotFinish.gameObject:SetActiveEx(not isFinish and not canGet)

    if self.PanelAnimationGroup then
        self.PanelAnimationGroup.alpha = 1
    end
end

function XDynamicActivityTask:OnBtnFinishClick()
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

    if self.EffectFinish then
        self.EffectFinish.gameObject:SetActiveEx(false)
        self.EffectFinish.gameObject:SetActiveEx(true)
    end

    XDataCenter.TaskManager.FinishTask(self.Data.Id, function(rewardGoodsList)
        XUiManager.OpenUiObtain(rewardGoodsList)
    end)
end

function XDynamicActivityTask:UpdateProgress(data)
    self.RImgTaskType.gameObject:SetActiveEx(data.IsMark)
    self.RImgTaskTypeNa.gameObject:SetActiveEx(not data.IsMark)
    self.RImgTaskTypeFihsh.gameObject:SetActiveEx(false)
    self.RImgTaskTypeNaFinsh.gameObject:SetActiveEx(false)

    self.BtnFinish.gameObject:SetActiveEx(false)
    if self.Data.State == XDataCenter.TaskManager.TaskState.Achieved then
        self.RImgTaskType.gameObject:SetActiveEx(false)
        self.RImgTaskTypeNa.gameObject:SetActiveEx(false)

        self.RImgTaskTypeFihsh.gameObject:SetActiveEx(data.IsMark)
        self.RImgTaskTypeNaFinsh.gameObject:SetActiveEx(not data.IsMark)

        self.BtnFinish.gameObject:SetActiveEx(true)
    end

    local markNum = data.IsMark and 1 or 0
    if not self.OldMark or self.OldMark ~= markNum then
        if data.IsMark then
            if self.EffectNor then self.EffectNor.gameObject:SetActiveEx(false) end
            if self.EffectVip then self.EffectVip.gameObject:SetActiveEx(true) end
        else
            if self.EffectVip then self.EffectVip.gameObject:SetActiveEx(false) end
            if self.EffectNor then self.EffectNor.gameObject:SetActiveEx(true) end
        end
        self.OldMark = data.IsMark and 1 or 0
    end
end

return XDynamicActivityTask