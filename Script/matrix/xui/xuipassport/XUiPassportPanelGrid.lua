local XUiPassportPanelGrid = XClass(nil, "XUiPassportPanelGrid")

--通行证面板中间一列的格子
function XUiPassportPanelGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self.GridObjs = {}
    self:AutoAddListener()
end

function XUiPassportPanelGrid:Init(rootUi)
    self.RootUi = rootUi
end

function XUiPassportPanelGrid:AutoAddListener()
    if self.Btn then
        XUiHelper.RegisterClickEvent(self, self.Btn, self.OnBtnClick)
    end
end

function XUiPassportPanelGrid:Refresh(levelId)
    self.LevelId = levelId
    self:UpdateLevelPanel()
    self:UpdatePermitPanel()
    self:UpdateRImgLock()
end

--当前等级没到显示黑色遮罩
function XUiPassportPanelGrid:UpdateRImgLock()
    local levelId = self:GetLevelId()
    local level = XPassportConfigs.GetPassportLevel(levelId)
    local baseInfo = XDataCenter.PassportManager.GetPassportBaseInfo()
    local currLevel = baseInfo:GetLevel()
    self.RImgLock.gameObject:SetActiveEx(currLevel < level)
end

--刷新物品格子
function XUiPassportPanelGrid:UpdatePermitPanel()
    local levelId = self:GetLevelId()
    local typeInfoIdList = XPassportConfigs.GetPassportActivityIdToTypeInfoIdList()
    local rewardData
    local grid
    local level = XPassportConfigs.GetPassportLevel(levelId)
    local isReceiveReward       --是否已领取奖励
    local isCanReceiveReward    --是否可领取奖励
    local passportInfo
    local isUnLock              --是否已解锁当前通行证奖励
    local isPrimeReward         --是否贵重奖励

    for i, typeInfoId in ipairs(typeInfoIdList) do
        grid = self.GridObjs[i]
        if self["GridCommonPermit" .. i] and not grid then
            grid = XUiGridCommon.New(self.RootUi, self["GridCommonPermit" .. i])
            self.GridObjs[i] = grid
        end

        local passportRewardId = XPassportConfigs.GetRewardIdByPassportIdAndLevel(typeInfoId, level)
        rewardData = passportRewardId and XPassportConfigs.GetPassportRewardData(passportRewardId)
        if XTool.IsNumberValid(rewardData) then
            isReceiveReward = XDataCenter.PassportManager.IsReceiveReward(typeInfoId, passportRewardId)
            isCanReceiveReward = XDataCenter.PassportManager.IsCanReceiveReward(typeInfoId, passportRewardId)
            if not isReceiveReward and isCanReceiveReward then
                grid:SetClickCallback(function() self:GridOnClick(passportRewardId) end)
                self:SetGridCommonPermitEffectActive(i, true)
            else
                grid:AutoAddListener()
                self:SetGridCommonPermitEffectActive(i, false)
            end

            grid:Refresh(rewardData)
            grid.GameObject:SetActive(true)
        else
            isReceiveReward = nil
            grid.GameObject:SetActive(false)
            self:SetGridCommonPermitEffectActive(i, false)
        end

        --已领取标志
        if self["ImgGetOutPermit" .. i] then
            self["ImgGetOutPermit" .. i].gameObject:SetActiveEx(isReceiveReward or false)
        end

        --未解锁标志
        if self["ImgLockingPermit" .. i] then
            passportInfo = XDataCenter.PassportManager.GetPassportInfos(typeInfoId)
            isUnLock = passportInfo and true or false
            self["ImgLockingPermit" .. i].gameObject:SetActiveEx(not isUnLock)

            if self["GridCommonPermitCanvasGroup" .. i] then
                self["GridCommonPermitCanvasGroup" .. i].alpha = isUnLock and 1 or 0.5   --未解锁时半透明
            end
        end

        --贵重奖励
        isPrimeReward = XPassportConfigs.IsPassportPrimeReward(passportRewardId)
        if self["RImgIsPrimeReward" .. i] then
            self["RImgIsPrimeReward" .. i].gameObject:SetActiveEx(isPrimeReward)
        end
    end
end

function XUiPassportPanelGrid:SetGridCommonPermitEffectActive(index, isActive)
    local effectObj = self["GridCommonPermitEffect" .. index]
    if effectObj then
        effectObj.gameObject:SetActiveEx(isActive)
    end
end

function XUiPassportPanelGrid:GridOnClick(passportRewardId)
    XDataCenter.PassportManager.RequestPassportRecvReward(passportRewardId, handler(self, self.UpdatePermitPanel))
end

function XUiPassportPanelGrid:UpdateLevelPanel()
    local levelId = self:GetLevelId()
    local level = XPassportConfigs.GetPassportLevel(levelId)
    local baseInfo = XDataCenter.PassportManager.GetPassportBaseInfo()
    local currLevel = baseInfo:GetLevel()
    local levelDesc = CS.XTextManager.GetText("PassportLevelDesc", level)

    --当前等级
    self.NowLevel.gameObject:SetActiveEx(currLevel == level)
    self.TxtNowLevel.text = levelDesc  

    --超过当前等级
    self.ReachLevel.gameObject:SetActiveEx(currLevel > level)
    self.TxtReachLevel.text = levelDesc

    --当前等级未到达
    self.NotreachedLevel.gameObject:SetActiveEx(currLevel < level)
    self.TxtNotReachedLevel.text = levelDesc
end

function XUiPassportPanelGrid:GetLevelId()
    return self.LevelId
end

return XUiPassportPanelGrid