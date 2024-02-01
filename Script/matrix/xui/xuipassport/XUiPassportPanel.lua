local XUiPassportPanelGrid = require("XUi/XUiPassport/XUiPassportPanelGrid")

---@field _Control XPassportControl
---@class XUiPassportPanel:XUiNode
local XUiPassportPanel = XClass(XUiNode, "XUiPassportPanel")

--通行证面板
function XUiPassportPanel:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    -- 当前选中普通区or无限区,打开时根据level选择最近的
    self.RewardType = XEnumConst.PASSPORT.REWARD_TYPE.NONE
    self.LastRewardType = XEnumConst.PASSPORT.REWARD_TYPE.NONE
    self.IsShowInfReward = false

    self.LevelIdListNormal = false
    self.LevelIdListInf = false
    XTool.InitUiObject(self)

    self:InitRightGrids()
    self:InitDynamicList()
    self:AutoAddListener()
    self:InitData()
    self:InitInfBtn()

    self:AddRedPointEvent(
            self.BtnTongBlack,
            self.OnCheckRewardRedPoint,
            self,
            { XRedPointConditions.Types.CONDITION_PASSPORT_PANEL_REWARD_RED }
    )
end

function XUiPassportPanel:InitRightGrids()
    self.RightGrids = {}
    local typeInfoIdList = self._Control:GetPassportActivityIdToTypeInfoIdList()
    for i in ipairs(typeInfoIdList) do
        self.RightGrids[i] = XUiGridCommon.New(self.RootUi, self["GridCommonRight" .. i])
    end
end

function XUiPassportPanel:InitData()
    local activityId = self._Control:GetDefaultActivityId()
    self.LevelIdListNormal = self._Control:GetPassportLevelIdListByRewardType(activityId, XEnumConst.PASSPORT.REWARD_TYPE.NORMAL)
    self.LevelIdListInf = self._Control:GetPassportLevelIdListByRewardType(activityId, XEnumConst.PASSPORT.REWARD_TYPE.INFINITE)
end

function XUiPassportPanel:InitDynamicList()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelItemList)
    self.DynamicTable:SetProxy(XUiPassportPanelGrid, self)
    self.DynamicTable:SetDelegate(self)
    self.Grid01.gameObject:SetActiveEx(false)

    local gridWidth = self.Grid01:GetComponent("RectTransform").rect.size.x
    local panelWidth = self.PanelItemList:GetComponent("RectTransform").rect.size.x
    self.DynamicTableOffsetIndex = math.floor(panelWidth / gridWidth / 2)
end

function XUiPassportPanel:AutoAddListener()
    local typeInfoIdList = self._Control:GetPassportActivityIdToTypeInfoIdList()
    for i, typeInfoId in ipairs(typeInfoIdList) do
        if self["BtnUnlockLeftGrid" .. i] then
            XUiHelper.RegisterClickEvent(
                    self,
                    self["BtnUnlockLeftGrid" .. i],
                    function()
                        self:OnBtnUnlockLeftGridClick(typeInfoId)
                    end
            )
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
        local levelCfg = self._Control:GetPassportLevel(levelIdCfg)
        if currMaxLevel < levelCfg then
            currMaxLevel = levelCfg
        end
    end

    local targetLevel = self._Control:GetPassportTargetLevel(currMaxLevel)
    if not targetLevel then
        self.PanelRewardRight.gameObject:SetActiveEx(false)
        return
    else
        self.PanelRewardRight.gameObject:SetActiveEx(true)
    end

    self.TxtLevelRight.text = targetLevel and CS.XTextManager.GetText("PassportLevelDesc", targetLevel) or ""

    local grid
    local rewardData
    local typeInfoIdList = self._Control:GetPassportActivityIdToTypeInfoIdList()

    local isReceiveReward  --是否已领取奖励
    local isCanReceiveReward  --是否可领取奖励
    local isUnLock  --是否已解锁当前通行证奖励
    local isShowEffect  --是否显示特效
    local isPrimeReward  --是否贵重奖励

    for i, typeInfoId in ipairs(typeInfoIdList) do
        local passportRewardId = self._Control:GetRewardIdByPassportIdAndLevel(typeInfoId, targetLevel) --通行证奖励表的id
        grid = self.RightGrids[i]

        if grid then
            rewardData = passportRewardId and self._Control:GetPassportRewardData(passportRewardId)
            if XTool.IsNumberValid(rewardData) then
                grid:Refresh(rewardData)
                grid.GameObject:SetActive(true)

                isReceiveReward = self._Control:IsReceiveReward(typeInfoId, passportRewardId)
                isCanReceiveReward = self._Control:IsCanReceiveReward(typeInfoId, passportRewardId)
                if not isReceiveReward and isCanReceiveReward then
                    grid:SetClickCallback(
                            function()
                                self:GridOnClick(passportRewardId)
                            end
                    )
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
            local passportInfo = self._Control:GetPassportInfos(typeInfoId)
            local isUnLock = passportInfo and true or false
            self["ImgLockingRight" .. i].gameObject:SetActiveEx(not isUnLock)
        end

        --可领取特效
        isShowEffect = not isReceiveReward and isCanReceiveReward and XTool.IsNumberValid(rewardData)
        if self["PanelPermitEffect" .. i] then
            self["PanelPermitEffect" .. i].gameObject:SetActiveEx(isShowEffect)
        end

        --贵重奖励
        isPrimeReward = self._Control:IsPassportPrimeReward(passportRewardId)
        if self["RImgIsPrimeReward" .. i] then
            self["RImgIsPrimeReward" .. i].gameObject:SetActiveEx(isPrimeReward)
        end
    end
end

function XUiPassportPanel:UpdateLeftGrid()
    local typeInfoIdList = self._Control:GetPassportActivityIdToTypeInfoIdList()
    local passportInfo
    local isUnLock
    for i, typeInfoId in ipairs(typeInfoIdList) do
        passportInfo = self._Control:GetPassportInfos(typeInfoId)
        isUnLock = passportInfo and true or false
        if self["TxtNameLeftGrid" .. i] then
            self["TxtNameLeftGrid" .. i].text = self._Control:GetPassportTypeInfoName(typeInfoId)
        end
        if self["ImgLockLeftGrid" .. i] then
            self["ImgLockLeftGrid" .. i].gameObject:SetActiveEx(not isUnLock)
        end
        if self["BtnUnlockLeftGrid" .. i] then
            self["BtnUnlockLeftGrid" .. i].gameObject:SetActiveEx(true)
            self["BtnUnlockLeftGrid" .. i]:SetDisable(isUnLock)
        end
    end
end

function XUiPassportPanel:UpdateDynamicTable()
    self.IsShowInfReward = #self.LevelIdListInf > 0

    local index = self:GetDynamicIndexAndChooseRewardType()
    self.DynamicTable:SetDataSource(self:GetLevelIdList())
    self.DynamicTable:ReloadDataSync(index)
end

function XUiPassportPanel:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self.RootUi)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local levelId = self:GetLevelIdList()[index]
        grid:Refresh(levelId)
        self:UpdateRightGrid()
        self:UpdateInfBtnVisible()
    end
end

-- 获得默认选中index，同时需要更新rewardType
function XUiPassportPanel:GetDynamicIndexAndChooseRewardType()
    local baseInfo = self._Control:GetPassportBaseInfo()
    local currLevel = baseInfo:GetLevel()
    if self.RewardType == XEnumConst.PASSPORT.REWARD_TYPE.NONE then
        local rewardType
        if self.IsShowInfReward and currLevel >= self._Control:GetPassportMaxLevel() then
            rewardType = XEnumConst.PASSPORT.REWARD_TYPE.INFINITE
        else
            local currId = self._Control:GetPassportLevelId(currLevel + 1)
            if currId then
                rewardType = self._Control:GetRewardType(currId)
            end
        end
        self.RewardType = rewardType or XEnumConst.PASSPORT.REWARD_TYPE.NORMAL
    end

    local levelIdList = self:GetLevelIdList()
    -- 手动从普通区切换到无限区的时候，从1开始；反之亦然
    if self.RewardType == XEnumConst.PASSPORT.REWARD_TYPE.NORMAL and
            self.LastRewardType == XEnumConst.PASSPORT.REWARD_TYPE.INFINITE
    then
        return #levelIdList
    end
    if self.RewardType == XEnumConst.PASSPORT.REWARD_TYPE.INFINITE and
            self.LastRewardType == XEnumConst.PASSPORT.REWARD_TYPE.NORMAL
    then
        return 1
    end

    local level = -1
    local index = 0
    for i, levelId in ipairs(levelIdList) do
        level = self._Control:GetPassportLevel(levelId)
        if level >= currLevel then
            index = i
            break
        end
    end
    -- 当前等级超出配置，拉到最后
    if level < currLevel then
        index = #levelIdList
    end

    index = math.max(1, index - self.DynamicTableOffsetIndex) --居中显示
    return index
end

function XUiPassportPanel:OnBtnUnlockLeftGridClick(typeInfoId)
    XLuaUiManager.Open("UiPassportCard", typeInfoId, handler(self, self.Refresh))
end

--一键领取
function XUiPassportPanel:OnBtnTongBlackClick()
    self._Control:RequestPassportRecvAllReward(handler(self, self.Refresh))
end

function XUiPassportPanel:OnCheckRewardRedPoint(count)
    self.BtnTongBlack:ShowReddot(count >= 0)
end

function XUiPassportPanel:Show()
    self:Open()
    self:Refresh()
end

function XUiPassportPanel:Hide()
    self:Close()
end

function XUiPassportPanel:GridOnClick(passportRewardId)
    local cb = function()
        self.DynamicTable:ReloadDataASync()
    end
    self._Control:RequestPassportRecvReward(passportRewardId, cb)
end

-- inf = 无限
function XUiPassportPanel:UpdateInfBtnVisible()
    -- 当玩家将列表拉至正常区最后面位置时
    if self.IsShowInfReward
            and self.RewardType == XEnumConst.PASSPORT.REWARD_TYPE.NORMAL
            and self.DynamicTable:GetGridByIndex(#self:GetLevelIdList())
    then
        -- 当玩家将列表拉至无限区最前面位置时
        self.BtnPlusRight.gameObject:SetActiveEx(true)
        self.BtnPlusLeft.gameObject:SetActiveEx(false)
    elseif self.RewardType == XEnumConst.PASSPORT.REWARD_TYPE.INFINITE and self.DynamicTable:GetGridByIndex(1) then
        self.BtnPlusRight.gameObject:SetActiveEx(false)
        self.BtnPlusLeft.gameObject:SetActiveEx(true)
    else
        self.BtnPlusRight.gameObject:SetActiveEx(false)
        self.BtnPlusLeft.gameObject:SetActiveEx(false)
    end
end

function XUiPassportPanel:InitInfBtn()
    XUiHelper.RegisterClickEvent(self, self.BtnPlusRight, self.OnBtnRewardInfClick)
    XUiHelper.RegisterClickEvent(self, self.BtnPlusLeft, self.OnBtnRewardNormalClick)
end

function XUiPassportPanel:OnBtnRewardNormalClick()
    self:SwitchRewardType(XEnumConst.PASSPORT.REWARD_TYPE.NORMAL, true)
end

function XUiPassportPanel:OnBtnRewardInfClick()
    self:SwitchRewardType(XEnumConst.PASSPORT.REWARD_TYPE.INFINITE, true)
end

function XUiPassportPanel:SwitchRewardType(rewardType, playSwitchAnimation)
    if self.RewardType == rewardType then
        return
    end
    self.LastRewardType = self.RewardType
    self.RewardType = rewardType

    self:UpdateDynamicTable()
    self:UpdateInfBtnVisible()

    if playSwitchAnimation then
        self.RootUi:PlayAnimation("QieHuan")
    end
end

function XUiPassportPanel:GetLevelIdList()
    if self.RewardType == XEnumConst.PASSPORT.REWARD_TYPE.NORMAL then
        return self.LevelIdListNormal
    end
    if self.RewardType == XEnumConst.PASSPORT.REWARD_TYPE.INFINITE then
        return self.LevelIdListInf
    end
    return self.LevelIdListNormal
end

return XUiPassportPanel
