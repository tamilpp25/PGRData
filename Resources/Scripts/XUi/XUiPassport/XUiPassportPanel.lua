local XUiPassportPanelGrid = require("XUi/XUiPassport/XUiPassportPanelGrid")

local XUiPassportPanel = XClass(nil, "XUiPassportPanel")

--通行证面板
function XUiPassportPanel:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)

    self:InitDynamicList()
    self:AutoAddListener()
    self:InitData()

    XRedPointManager.AddRedPointEvent(self.BtnTongBlack, self.OnCheckRewardRedPoint, self, { XRedPointConditions.Types.CONDITION_PASSPORT_PANEL_REWARD_RED })
end

function XUiPassportPanel:InitData()
    local activityId = XPassportConfigs.GetDefaultActivityId()
    self.LevelIdList = XPassportConfigs.GetPassportLevelIdList(activityId)
end

function XUiPassportPanel:InitDynamicList()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelItemList)
    self.DynamicTable:SetProxy(XUiPassportPanelGrid)
    self.DynamicTable:SetDelegate(self)
    self.Grid01.gameObject:SetActiveEx(false)

    local gridWidth = self.Grid01:GetComponent("RectTransform").rect.size.x
    local panelWidth = self.PanelItemList:GetComponent("RectTransform").rect.size.x
    self.DynamicTableOffsetIndex = math.floor(panelWidth / gridWidth / 2)
end

function XUiPassportPanel:AutoAddListener()
    local typeInfoIdList = XPassportConfigs.GetPassportActivityIdToTypeInfoIdList()
    for i, typeInfoId in ipairs(typeInfoIdList) do
        if self["BtnUnlockLeftGrid" .. i] then
            XUiHelper.RegisterClickEvent(self, self["BtnUnlockLeftGrid" .. i], function() self:OnBtnUnlockLeftGridClick(typeInfoId) end)
        end
    end

    XUiHelper.RegisterClickEvent(self, self.BtnTongBlack, self.OnBtnTongBlackClick)
end

function XUiPassportPanel:Refresh()
    self:UpdateDynamicTable()
    self:UpdateLeftGrid()
end

--遍历DynamicTable的Grid，根据最大等级的LevelId刷新
function XUiPassportPanel:UpdateRightGrid()
    local currMaxLevel = 0
    for _, v in pairs(self.DynamicTable:GetGrids()) do
        local levelIdCfg = v:GetLevelId()
        local levelCfg = XPassportConfigs.GetPassportLevel(levelIdCfg)
        if currMaxLevel < levelCfg then
            currMaxLevel = levelCfg
        end
    end

    local targetLevel = XPassportConfigs.GetPassportTargetLevel(currMaxLevel)
    if not targetLevel then
        self.PanelRewardRight.gameObject:SetActiveEx(false)
        return
    else
        self.PanelRewardRight.gameObject:SetActiveEx(true)
    end

    self.TxtLevelRight.text = targetLevel and CS.XTextManager.GetText("PassportLevelDesc", targetLevel) or ""

    local grid
    local rewardData
    local typeInfoIdList = XPassportConfigs.GetPassportActivityIdToTypeInfoIdList()
    local isReceiveReward       --是否已领取奖励
    local isCanReceiveReward    --是否可领取奖励
    local isUnLock              --是否已解锁当前通行证奖励

    for i, typeInfoId in ipairs(typeInfoIdList) do
        if self["GridCommonRight" .. i] then
            grid = XUiGridCommon.New(self.RootUi, self["GridCommonRight" .. i])
            local passportRewardId = XPassportConfigs.GetRewardIdByPassportIdAndLevel(typeInfoId, targetLevel)
            rewardData = passportRewardId and XPassportConfigs.GetPassportRewardData(passportRewardId)
            if XTool.IsNumberValid(rewardData) then
                grid:Refresh(rewardData)
                grid.GameObject:SetActive(true)

                isReceiveReward = XDataCenter.PassportManager.IsReceiveReward(typeInfoId, passportRewardId)
                isCanReceiveReward = XDataCenter.PassportManager.IsCanReceiveReward(typeInfoId, passportRewardId)
                if not isReceiveReward and isCanReceiveReward then
                    grid:SetClickCallback(function() self:GridOnClick(passportRewardId) end)
                else
                    grid:AutoAddListener()
                end
            else
                isCanReceiveReward = nil
                isReceiveReward = nil
                grid.GameObject:SetActive(false)
            end
        end

        --已领取标志
        if self["ImgGetOutRight" .. i] then
            self["ImgGetOutRight" .. i].gameObject:SetActiveEx(isReceiveReward)
        end

        --未解锁标志
        if self["ImgLockingRight" .. i] then
            local passportInfo = XDataCenter.PassportManager.GetPassportInfos(typeInfoId)
            local isUnLock = passportInfo and true or false
            self["ImgLockingRight" .. i].gameObject:SetActiveEx(not isUnLock)
        end

        --可领取特效
        local isShowEffect = not isReceiveReward and isCanReceiveReward and XTool.IsNumberValid(rewardData)
        if self["PanelPermitEffect" .. i] then
            self["PanelPermitEffect" .. i].gameObject:SetActiveEx(isShowEffect)
        end
    end
end

function XUiPassportPanel:UpdateLeftGrid()
    local typeInfoIdList = XPassportConfigs.GetPassportActivityIdToTypeInfoIdList()
    local passportInfo
    local isUnLock
    for i, typeInfoId in ipairs(typeInfoIdList) do
        passportInfo = XDataCenter.PassportManager.GetPassportInfos(typeInfoId)
        isUnLock = passportInfo and true or false
        if self["TxtNameLeftGrid" .. i] then
            self["TxtNameLeftGrid" .. i].text = XPassportConfigs.GetPassportTypeInfoName(typeInfoId)
        end
        if self["ImgLockLeftGrid" .. i] then
            self["ImgLockLeftGrid" .. i].gameObject:SetActiveEx(not isUnLock)
        end
        if self["BtnUnlockLeftGrid" .. i] then
            self["BtnUnlockLeftGrid" .. i].gameObject:SetActiveEx(not isUnLock)
        end
    end
end

function XUiPassportPanel:UpdateDynamicTable()
    self.DynamicTable:SetDataSource(self.LevelIdList)

    local index = self:GetDynamicIndex()
    self.DynamicTable:ReloadDataSync(index)
end

function XUiPassportPanel:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self.RootUi)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local levelId = self.LevelIdList[index]
        grid:Refresh(levelId)
        self:UpdateRightGrid()
    end
end

function XUiPassportPanel:GetDynamicIndex()
    local baseInfo = XDataCenter.PassportManager.GetPassportBaseInfo()
    local currLevel = baseInfo:GetLevel()
    local level
    local index = 0
    for i, levelId in ipairs(self.LevelIdList) do
        level = XPassportConfigs.GetPassportLevel(levelId)
        if level >= currLevel then
            index = i
            break
        end
    end

    index = math.max(-1, index - self.DynamicTableOffsetIndex)     --居中显示
    return index
end

function XUiPassportPanel:OnBtnUnlockLeftGridClick(typeInfoId)
    XLuaUiManager.Open("UiPassportCard", typeInfoId, handler(self, self.Refresh))
end

--一键领取
function XUiPassportPanel:OnBtnTongBlackClick()
    XDataCenter.PassportManager.RequestPassportRecvAllReward(handler(self, self.Refresh))
end

function XUiPassportPanel:OnCheckRewardRedPoint(count)
    self.BtnTongBlack:ShowReddot(count >= 0)
end

function XUiPassportPanel:Show()
    self.GameObject:SetActiveEx(true)
    self:Refresh()
end

function XUiPassportPanel:Hide()
    self.GameObject:SetActiveEx(false)
end

function XUiPassportPanel:GridOnClick(passportRewardId)
    local cb = function()
        self.DynamicTable:ReloadDataASync()
    end
    XDataCenter.PassportManager.RequestPassportRecvReward(passportRewardId, cb)
end

return XUiPassportPanel