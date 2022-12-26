local XUiSignGridDay = require("XUi/XUiSignIn/XUiSignGridDay")
local XUiSignPrefab = XClass(nil, "XUiSignPrefab")


function XUiSignPrefab:Ctor(ui, rootUi, parent, setTomorrow)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.Parent = parent
    self.SetTomorrow = setTomorrow

    self.OnBtnHelpClickCb = function() self:OnBtnHelpClick() end
    XTool.InitUiObject(self)
    self:InitAddListen()

    self.DaySmallGrids = {}
    table.insert(self.DaySmallGrids, XUiSignGridDay.New(self.GridDaySmall, self.RootUi))
    self.DayBigGrids = {}
    table.insert(self.DayBigGrids, XUiSignGridDay.New(self.GridDayBig, self.RootUi))
    self.BtnList = {}
    table.insert(self.BtnList, self.BtnTab)
end

function XUiSignPrefab:InitAddListen()
    self.RootUi:RegisterClickEvent(self.BtnHelp, self.OnBtnHelpClickCb)
end

function XUiSignPrefab:OnBtnHelpClick()
    XUiManager.UiFubenDialogTip("", self.SignInInfos[1].Description or "")
end

---
--- 福利界面打开时'isShow'为false，打脸打开时为true
function XUiSignPrefab:Refresh(signId, round, isShow)
    self.IsShow = isShow
    self.SignId = signId
    self.Round = round

    local signType = XSignInConfigs.GetSignInType(signId)
    if signType == XSignInConfigs.SignType.PurchasePackage then
        if self.PanelPrice then
            self.PanelPrice.gameObject:SetActiveEx(false)
        end
        if self.BtnPurchase then
            self.BtnPurchase.gameObject:SetActiveEx(false)
        end
        if self.OffShelf then
            self.OffShelf.gameObject:SetActiveEx(false)
        end
        if self.PanelPurchaseLimit then
            self.PanelPurchaseLimit.gameObject:SetActiveEx(false)
        end
        if self.PanelPurchaseRemain then
            self.PanelPurchaseRemain.gameObject:SetActiveEx(false)
        end
        if not isShow then
            self:SetBtnReceiveDisable()
        end
    end

    local timeId = XSignInConfigs.GetSignTimeId(signId)
    local beginTimeStamp, endTimeStamp = XFunctionManager.GetTimeByTimeId(timeId)
    self:SetSignTime(self.BeginTime, beginTimeStamp,"MM/dd")
    self:SetSignTime(self.EndTime1, endTimeStamp,"MM/dd")
    self:SetSignTime(self.EndTime2, endTimeStamp,"HH:mm")

    self:InitTabGroup()
end

---
--- 设置签到时间
---@param textComponent userdata 字符串控件
---@param timeStamp number 时间戳
---@param format string 显示的格式
function XUiSignPrefab:SetSignTime(textComponent, timeStamp, format)
    if not textComponent then
        return
    end

    local timeStr = XTime.TimestampToGameDateTimeString(timeStamp, format)
    if timeStr then
        textComponent.text = timeStr
    else
        XLog.Error("XUiSignPrefab:SetSignTime函数错误，formatTimeStr为空")
    end
end

function XUiSignPrefab:InitTabGroup()
    for _, v in ipairs(self.BtnList) do
        v.gameObject:SetActiveEx(false)
    end

    self.SignInInfos = XSignInConfigs.GetSignInInfos(self.SignId)
    self:SetRewardInfos(self.Round)
    if #self.SignInInfos <= 1 then
        return
    end

    local btnGroupList = {}
    for i = 1, #self.SignInInfos do
        local grid = self.BtnList[i]
        if not grid then
            grid = CS.UnityEngine.Object.Instantiate(self.BtnTab.gameObject)
            grid.transform:SetParent(self.PanelTabContent.gameObject.transform, false)
            table.insert(self.BtnList, grid)
        end
        local xBtn = grid.transform:GetComponent("XUiButton")
        local rowImg = XUiHelper.TryGetComponent(grid.transform, "RImgIcon", "RawImage")

        table.insert(btnGroupList, xBtn)
        xBtn:SetName(self.SignInInfos[i].RoundName)
        rowImg:SetRawImage(self.SignInInfos[i].Icon)
        xBtn.gameObject:SetActiveEx(true)
    end

    self.PanelTabContent:Init(btnGroupList, function(index)
        self:SelectPanelRound(index)
    end)

    local curRound = XDataCenter.SignInManager.GetSignRound(self.SignId, true)
    if curRound then
        self.PanelTabContent:SelectIndex(curRound, false)
    end
end

function XUiSignPrefab:SelectPanelRound(index)
    self.Parent:RefreshPanel(index)
end

function XUiSignPrefab:SetRewardInfos(index)
    local signInInfo = self.SignInInfos[index]
    local rewardConfigs = XSignInConfigs.GetSignInRewardConfigs(self.SignId, signInInfo.Round, false)

    for _, v in ipairs(self.DaySmallGrids) do
        v.GameObject:SetActiveEx(false)
    end

    for _, v in ipairs(self.DayBigGrids) do
        v.GameObject:SetActiveEx(false)
    end

    local smallIndex = 1
    local bigIndex = 1

    for _, config in ipairs(rewardConfigs) do
        if config.IsGrandPrix then                          -- 设置大奖励
            local dayGrid = self.DayBigGrids[bigIndex]
            if not dayGrid then
                local grid = CS.UnityEngine.GameObject.Instantiate(self.GridDayBig)
                grid.transform:SetParent(self.PanelDayContent, false)
                dayGrid = XUiSignGridDay.New(grid, self.RootUi)
                table.insert(self.DayBigGrids, dayGrid)
            end

            dayGrid:Refresh(config, self.IsShow, self.SetTomorrow)
            dayGrid.Transform:SetAsLastSibling()
            bigIndex = bigIndex + 1
        else                                                -- 设置小奖励
            local dayGrid = self.DaySmallGrids[smallIndex]
            if not dayGrid then
                local grid = CS.UnityEngine.GameObject.Instantiate(self.GridDaySmall)
                grid.transform:SetParent(self.PanelDayContent, false)
                dayGrid = XUiSignGridDay.New(grid, self.RootUi)
                table.insert(self.DaySmallGrids, dayGrid)
            end

            dayGrid:Refresh(config, self.IsShow, self.SetTomorrow)
            dayGrid.Transform:SetAsLastSibling()
            smallIndex = smallIndex + 1
        end
    end
end

function XUiSignPrefab:SetTomorrowOpen(dayRewardConfig, isRoundLastDay)
    local t = XSignInConfigs.GetSignInConfig(dayRewardConfig.SignId)
    local isActive = t.Type == XSignInConfigs.SignType.Activity

    if isRoundLastDay and isActive then
        for _, v in ipairs(self.DaySmallGrids) do
            if v.GameObject.activeSelf and v.Config and
               v.Config.SignId == dayRewardConfig.SignId and
               v.Config.Round == dayRewardConfig.Round + 1 and
               v.Config.Day == 1 then
                v:SetTomorrow()
                return
            end
        end

        for _, v in ipairs(self.DayBigGrids) do
            if v.GameObject.activeSelf and v.Config and
                v.Config.SignId == dayRewardConfig.SignId and
                v.Config.Round == dayRewardConfig.Round + 1 and
                v.Config.Day == 1 then
                v:SetTomorrow()
                return
            end
        end

        return
    end

    for _, v in ipairs(self.DaySmallGrids) do
       if v.GameObject.activeSelf and v.Config and
          v.Config.SignId == dayRewardConfig.SignId and
          v.Config.Round == dayRewardConfig.Round and
          v.Config.Day - 1 == dayRewardConfig.Day then
            v:SetTomorrow()
            return
        end
    end

    for _, v in ipairs(self.DayBigGrids) do
        if v.GameObject.activeSelf and v.Config and
           v.Config.SignId == dayRewardConfig.SignId and
           v.Config.Round == dayRewardConfig.Round and
           v.Config.Day - 1 == dayRewardConfig.Day then
            v:SetTomorrow()
            return
        end
    end
end

function XUiSignPrefab:SetBtnReceiveDisable()
    if self.BtnReceive then
        self.BtnReceive:SetButtonState(XUiButtonState.Disable)
    end
end


function XUiSignPrefab:SetSignActive(active, round)
    if active and self.GameObject.activeSelf then
        return
    end

    if not active and not self.GameObject.activeSelf then
        return
    end

    if #self.SignInInfos > 1 then
        self.PanelTabContent:SelectIndex(round, false)
    end

    self.GameObject:SetActiveEx(active)
end

function XUiSignPrefab:SetTomorrowForce(isForce)
    self.SetTomorrow = isForce
end

return XUiSignPrefab