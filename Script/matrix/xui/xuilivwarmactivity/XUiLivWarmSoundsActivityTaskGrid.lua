local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiLivWarmSoundsActivityTaskGrid = XClass(nil, "UiLivWarmSoundsActivityTaskGrid")

function XUiLivWarmSoundsActivityTaskGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self:InitAutoScript()
    self.RewardPanelList = {}
    self.GridCommon.gameObject:SetActive(false)
end

function XUiLivWarmSoundsActivityTaskGrid:Init(rootUi, parent)
    self.RootUi = rootUi
    self.Parent = parent
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiLivWarmSoundsActivityTaskGrid:InitAutoScript()
    self:AutoInitUi()
    self:AutoAddListener()
end

function XUiLivWarmSoundsActivityTaskGrid:AutoInitUi()
    self.TxtOrder = self.Transform:Find("TxtOrder"):GetComponent("Text")
    self.TxtTaskName = self.Transform:Find("TxtTaskName"):GetComponent("Text")
    self.PanelRewardContent = self.Transform:Find("PanelRewardContent")
    self.GridCommon = self.Transform:Find("PanelRewardContent/GridCommon")
    self.RImgIcon = self.Transform:Find("PanelRewardContent/GridCommon/RImgIcon"):GetComponent("RawImage")
    self.ImgQuality = self.Transform:Find("PanelRewardContent/GridCommon/ImgQuality"):GetComponent("Image")
    self.BtnClick = self.Transform:Find("PanelRewardContent/GridCommon/BtnClick"):GetComponent("Button")
    self.TxtCount = self.Transform:Find("PanelRewardContent/GridCommon/TxtCount"):GetComponent("Text")
    self.BtnFinish = self.Transform:Find("BtnFinish"):GetComponent("Button")
    self.ImgAlreadyFinish = self.Transform:Find("ImgAlreadyFinish"):GetComponent("Image")
    self.ImgUnFinish = self.Transform:Find("ImgUnFinish"):GetComponent("Image")
end

function XUiLivWarmSoundsActivityTaskGrid:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiLivWarmSoundsActivityTaskGrid:RegisterClickEvent函数参数错误：参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiLivWarmSoundsActivityTaskGrid:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiLivWarmSoundsActivityTaskGrid:AutoAddListener()
    self.AutoCreateListeners = {}

    local finishXUiBtn = self.BtnFinish:GetComponent("XUiButton")
    if not finishXUiBtn then
        XUiHelper.RegisterClickEvent(self, self.BtnFinish, self.OnBtnFinishClick)
    else
        self.BtnFinish = finishXUiBtn
        self.BtnFinish.CallBack = function() self:OnBtnFinishClick() end
    end

    --local skipXUiBtn = self.BtnSkip:GetComponent("XUiButton")
    --if not skipXUiBtn then
    --    XUiHelper.RegisterClickEvent(self, self.BtnSkip, self.OnBtnSkipClick)
    --else
    --    self.BtnSkip = skipXUiBtn
    --    self.BtnSkip.CallBack = function() self:OnBtnSkipClick() end
    --end
end

function XUiLivWarmSoundsActivityTaskGrid:OnBtnFinishClick()
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
        XUiManager.OpenUiObtain(rewardGoodsList)
        --XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_SIMUCOMBAT_UPDATE)
    end)
end

function XUiLivWarmSoundsActivityTaskGrid:OnBtnSkipClick()
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

function XUiLivWarmSoundsActivityTaskGrid:ResetData(data)
    self.Data = data
    local config = XDataCenter.TaskManager.GetTaskTemplate(self.Data.Id)
    self.tableData = config
    self.TxtTaskName.text = config.Title
    self.TxtOrder.text = config.Desc
    self.RImgIcon:SetRawImage(config.Icon)
    self:UpdateProgress(self.Data)
    local rewards = XRewardManager.GetRewardList(config.RewardId)
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

function XUiLivWarmSoundsActivityTaskGrid:UpdateProgress(data)
    self.ImgAlreadyFinish.gameObject:SetActive(data.State == XDataCenter.TaskManager.TaskState.Finish)
    self.BtnFinish.gameObject:SetActive(data.State == XDataCenter.TaskManager.TaskState.Achieved)
    self.ImgUnFinish.gameObject:SetActive(data.State == XDataCenter.TaskManager.TaskState.Active)
end

return XUiLivWarmSoundsActivityTaskGrid